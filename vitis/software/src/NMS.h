#ifndef NMS_H_   /* prevent circular inclusions */
#define NMS_H_

#include "xil_types.h"
#include "xil_io.h"


#define NMS_NUM_PRED_START_OFFSET 0x00
#define NMS_IOU_THRESH_OFFSET	  0x04
#define NMS_S_THRESH_OFFSET       0x08
#define NMS_NUM_BOX_OFFSET		  0x0C

#define NMS_START_MASK 1U
#define NMS_NUM_PRED_MASK 0x0000FFFE


typedef struct NMS_Config {
	UINTPTR BaseAddr;

	u16 NumPred;
	u16 IOUThresh;
	u16 SThresh;
} NMS_Config;


typedef struct BBox {
	u16 x, y, a, b;
	float S;
} BBox;


typedef struct BBoxPack {
  BBox box;
  u16 index;
  struct BBoxPack *next;
} BBoxPack;


void NMS_Init(NMS_Config *NMSConfigIns, UINTPTR BaseAddrVal);
void NMS_SetIOUThresh(NMS_Config *NMSConfigIns, u16 IOUThresh);
void NMS_SetSThresh(NMS_Config *NMSConfigIns, u16 SThresh);
void NMS_SetNumPredAndStart(NMS_Config *NMSConfigIns, u16 NumPred);
void NMS_ClearStart(NMS_Config *NMSConfigIns);
u16 NMS_HWGetNumBox(NMS_Config *NMSConfigIns);
u16 NMS_SWImproved(u16 NumPred, BBox PredBox[], u16 *BoxIndBuff, float IOUThresh, float SThresh);
void NMS_SWBoxDataFetch(BBox *bbox, u64 data, float S);
u16 NMS_SWVanillaOptimized(u16 NumPred, BBox PredBox[], u16 *BoxIndBuff, float IOUThresh, float SThresh);
float IOU(BBox *b1, BBox *b2);
void NMS_PrintBBox(BBox *box);

#endif /* end of protection macro */
