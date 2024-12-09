#include <stdio.h>
#include "xaxidma.h"
#include "xparameters.h"
#include "xil_exception.h"
#include "xscugic.h"
#include "NMS.h"
#include "data.h"
#include "xil_io.h"
#include "xtime_l.h"

#ifndef DEBUG
extern void xil_printf(const char *format, ...);
#endif

#define DMA_DEV_ID				XPAR_AXIDMA_0_DEVICE_ID
#define INTC_DEVICE_ID          XPAR_SCUGIC_SINGLE_DEVICE_ID
#define S2MM_INTR_ID 			XPAR_FABRIC_AXIDMA_0_VEC_ID
#define DONE_INTR_ID			61U
#define NMS_BASE_ADDR			XPAR_NMS_MODULE_IP_0_BASEADDR
#define IND_BUF_SIZE			100


volatile int Error;
volatile int S2MM_Done;
volatile int NMS_Done;


static XAxiDma AxiDma;
static XScuGic Intc;
static NMS_Config NMS;


/* Function prototypes */
static void S2MMIntrHandler(void *Callback);
static void NMSDoneIntrHandler(void *Callback);
static int SetupIntrSystem(XScuGic * IntcInstancePtr, XAxiDma * AxiDmaPtr, NMS_Config *NMS, u16 S2MMId, u16 NMSDoneId);

u64 PredBoxData[NUM_PRED];
u32 volatile BoxIndData[IND_BUF_SIZE];

BBox BBoxData[NUM_PRED];
u16 BBoxIndData[IND_BUF_SIZE];


int main(void) {
	int Status;
	XAxiDma_Config *Config;

	u16 NumPredBox;
	u16 NumSelectBox;
	u16 i, j, rep;
	XTime tStart, tEnd;

	NumPredBox = NUM_PRED;



	print("Test interrupt \r\n");
	print("--------------Initial Configuration-------------\r\n");


	/* Initialize DMA engine */
	Config = XAxiDma_LookupConfig(DMA_DEV_ID);
	if (!Config) {
		xil_printf("No configuration found for %d\r\n", DMA_DEV_ID);

		return XST_FAILURE;
	}

	Status = XAxiDma_CfgInitialize(&AxiDma, Config);

	if (Status != XST_SUCCESS) {
		xil_printf("Initialization failed %d\r\n", Status);
		return XST_FAILURE;
	}



	/* Set up Interrupt system  */
	Status = SetupIntrSystem(&Intc, &AxiDma, &NMS, S2MM_INTR_ID, DONE_INTR_ID);
	if (Status != XST_SUCCESS) {
		xil_printf("Setup Interrupt System failed %d\r\n", Status);
		return XST_FAILURE;
	}

	/* Disable then enable interrupts before setup */
	XAxiDma_IntrDisable(&AxiDma, XAXIDMA_IRQ_ALL_MASK, XAXIDMA_DMA_TO_DEVICE);
	XAxiDma_IntrDisable(&AxiDma, XAXIDMA_IRQ_ALL_MASK, XAXIDMA_DEVICE_TO_DMA);
	XAxiDma_IntrEnable(&AxiDma, XAXIDMA_IRQ_ALL_MASK, XAXIDMA_DEVICE_TO_DMA);



	/* Initialize NMS module */
	NMS_Init(&NMS, NMS_BASE_ADDR);


	xil_printf("--------------Initial Configuration Complete-------------\r\n");



	for (rep = 0; rep < NUM_IMG; rep++) {
		NMS_Done = 0;
		S2MM_Done = 0;
		Error = 0;
		NumSelectBox = IND_BUF_SIZE;
		xil_printf("img%d.jpg", rep+1);



		// Data population
		for (i = 0; i < NumPredBox; i++) {
			PredBoxData[i] = bbox_array[rep][i];
		}


		for (i = 0; i < IND_BUF_SIZE; i++) {
			BoxIndData[i] = 0;
		}
		Xil_DCacheFlushRange((UINTPTR)PredBoxData, NUM_PRED * 8);
		Xil_DCacheFlushRange((UINTPTR)BoxIndData, IND_BUF_SIZE * 4);


		// Start measuring time
		XTime_GetTime(&tStart);

		// Start MM2S channel
		Status = XAxiDma_SimpleTransfer(&AxiDma, (UINTPTR)PredBoxData, (u32)(NumPredBox * 8), XAXIDMA_DMA_TO_DEVICE);

		// Configure NMS module
		NMS_SetIOUThresh(&NMS, (u16)0x38F5);
		NMS_SetSThresh(&NMS, (u16)0x3666);
		NMS_SetNumPredAndStart(&NMS, NumPredBox);

		// Start S2MM channel
		XAxiDma_SimpleTransfer(&AxiDma, (UINTPTR)BoxIndData, (u32)(NumSelectBox * 4), XAXIDMA_DEVICE_TO_DMA);

		// Wait for NMS_Done flag
		while (NMS_Done == 0);

		// Wait for S2MM Done flag
		while (S2MM_Done == 0);

		XTime_GetTime(&tEnd);

		NumSelectBox = NMS_HWGetNumBox(&NMS);

		// Print outputs
		printf("\nNMS Hardware: %.8f seconds\r\n", ((double)(tEnd - tStart) / (double)COUNTS_PER_SECOND));
		for (j = 0; j < NumSelectBox; j++) {
			xil_printf("Index %d: %d\r\n", j, BoxIndData[j]);
		}




        //-----------------------------------------Comparison with vanilla NMS-----------------------------------------
		for (i = 0; i < NumPredBox; i++) {
			NMS_SWBoxDataFetch(&BBoxData[i], bbox_array[rep][i], bbox_S[rep][i]);
		}


		for (i = 0; i < IND_BUF_SIZE; i++) {
			BBoxIndData[i] = 0;
		}
		Xil_DCacheFlushRange((UINTPTR)BBoxData, NUM_PRED * 8);
		Xil_DCacheFlushRange((UINTPTR)BBoxIndData, IND_BUF_SIZE * 2);

		XTime_GetTime(&tStart);
		NumSelectBox = NMS_SWVanillaOptimized(NumPredBox, BBoxData, BBoxIndData, 0.38, 0.4);
		XTime_GetTime(&tEnd);
		printf("NMS Optimized: %.8f seconds\r\n", ((double)(tEnd - tStart) / (double)COUNTS_PER_SECOND));
		for (i = 0; i < NumSelectBox; i++) {
			xil_printf("Index %d: %d\r\n", i, BBoxIndData[i]);
		}




		for (i = 0; i < IND_BUF_SIZE; i++) {
			BBoxIndData[i] = 0;
		}
		Xil_DCacheFlushRange((UINTPTR)BBoxData, NUM_PRED * 8);
		Xil_DCacheFlushRange((UINTPTR)BBoxIndData, IND_BUF_SIZE * 2);

		XTime_GetTime(&tStart);
		NumSelectBox = NMS_SWImproved(NumPredBox, BBoxData, BBoxIndData, 0.38, 0.4);
		XTime_GetTime(&tEnd);
		printf("NMS Improved: %.8f seconds\r\n", ((double)(tEnd - tStart) / (double)COUNTS_PER_SECOND));
		for (i = 0; i < NumSelectBox; i++) {
			xil_printf("Index %d: %d\r\n", i, BBoxIndData[i]);
		}

		xil_printf("-----------------------------------------------------------\r\n");
	}
	return XST_SUCCESS;
}



/*****************************************************************************/
/*
*
* This is the DMA TX Interrupt handler function.
*
* It gets the interrupt status from the hardware, acknowledges it, and if any
* error happens, it resets the hardware. Otherwise, if a completion interrupt
* is present, then sets the TxDone.flag
*
* @param	Callback is a pointer to TX channel of the DMA engine.
*
* @return	None.
*
* @note		None.
*
******************************************************************************/
static void S2MMIntrHandler(void *Callback)
{
	u32 IrqStatus = 0x1000;
	XAxiDma *AxiDmaInst = (XAxiDma *)Callback;


	XAxiDma_IntrAckIrq(AxiDmaInst, IrqStatus, XAXIDMA_DEVICE_TO_DMA);

	S2MM_Done = 1;
}



static void NMSDoneIntrHandler(void *Callback)
{
	NMS_Config *NMS_ConfigInst = (NMS_Config *)Callback;
	NMS_ClearStart(NMS_ConfigInst);

	NMS_Done = 1;
}



/*****************************************************************************/
/*
*
* This function setups the interrupt system so interrupts can occur for the
* DMA, it assumes INTC component exists in the hardware system.
*
* @param	IntcInstancePtr is a pointer to the instance of the INTC.
* @param	AxiDmaPtr is a pointer to the instance of the DMA engine
* @param	TxIntrId is the TX channel Interrupt ID.
* @param	RxIntrId is the RX channel Interrupt ID.
*
* @return
*		- XST_SUCCESS if successful,
*		- XST_FAILURE.if not successful
*
* @note		None.
*
******************************************************************************/
static int SetupIntrSystem(XScuGic * IntcInstancePtr, XAxiDma * AxiDmaPtr, NMS_Config *NMS, u16 S2MMId, u16 NMSDoneId)
{
	int Status;

#ifdef XPAR_INTC_0_DEVICE_ID

	/* Initialize the interrupt controller and connect the ISRs */
	Status = XIntc_Initialize(IntcInstancePtr, INTC_DEVICE_ID);
	if (Status != XST_SUCCESS) {

		xil_printf("Failed init intc\r\r\n");
		return XST_FAILURE;
	}

	Status = XIntc_Connect(IntcInstancePtr, TxIntrId,
			       (XInterruptHandler) TxIntrHandler, AxiDmaPtr);
	if (Status != XST_SUCCESS) {

		xil_printf("Failed tx connect intc\r\r\n");
		return XST_FAILURE;
	}

	Status = XIntc_Connect(IntcInstancePtr, RxIntrId,
			       (XInterruptHandler) RxIntrHandler, AxiDmaPtr);
	if (Status != XST_SUCCESS) {

		xil_printf("Failed rx connect intc\r\r\n");
		return XST_FAILURE;
	}

	/* Start the interrupt controller */
	Status = XIntc_Start(IntcInstancePtr, XIN_REAL_MODE);
	if (Status != XST_SUCCESS) {

		xil_printf("Failed to start intc\r\r\n");
		return XST_FAILURE;
	}

	XIntc_Enable(IntcInstancePtr, TxIntrId);
	XIntc_Enable(IntcInstancePtr, RxIntrId);

#else

	XScuGic_Config *IntcConfig;


	/*
	 * Initialize the interrupt controller driver so that it is ready to
	 * use.
	 */
	IntcConfig = XScuGic_LookupConfig(INTC_DEVICE_ID);
	if (NULL == IntcConfig) {
		return XST_FAILURE;
	}

	Status = XScuGic_CfgInitialize(IntcInstancePtr, IntcConfig,
					IntcConfig->CpuBaseAddress);
	if (Status != XST_SUCCESS) {
		return XST_FAILURE;
	}


	XScuGic_SetPriorityTriggerType(IntcInstancePtr, S2MMId, 0xA0, 0x3);

	XScuGic_SetPriorityTriggerType(IntcInstancePtr, NMSDoneId, 0x98, 0x3);
	/*
	 * Connect the device driver handler that will be called when an
	 * interrupt for the device occurs, the handler defined above performs
	 * the specific interrupt processing for the device.
	 */
	Status = XScuGic_Connect(IntcInstancePtr, S2MMId,
				(Xil_InterruptHandler)S2MMIntrHandler,
				AxiDmaPtr);
	if (Status != XST_SUCCESS) {
		return Status;
	}

	Status = XScuGic_Connect(IntcInstancePtr, NMSDoneId,
				(Xil_InterruptHandler)NMSDoneIntrHandler,
				NMS);
	if (Status != XST_SUCCESS) {
		return Status;
	}

	XScuGic_Enable(IntcInstancePtr, S2MMId);
	XScuGic_Enable(IntcInstancePtr, NMSDoneId);


#endif

	/* Enable interrupts from the hardware */

	Xil_ExceptionInit();
	Xil_ExceptionRegisterHandler(XIL_EXCEPTION_ID_INT,
			(Xil_ExceptionHandler)XScuGic_InterruptHandler,
			(void *)IntcInstancePtr);

	Xil_ExceptionEnable();

	return XST_SUCCESS;
}
