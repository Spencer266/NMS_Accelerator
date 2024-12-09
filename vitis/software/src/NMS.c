#include "NMS.h"



// ------------------------------STATIC COMPONENTS-----------------------------
//
//

// Helper function to swap two BBox elements (file-local)
static void swap(BBoxPack* a, BBoxPack* b) {
    BBoxPack temp = *a;
    *a = *b;
    *b = temp;
}

// Heapify function to maintain the heap property (file-local)
static void heapify(BBoxPack arr[], int n, int i) {
    int largest = i;        // Initialize largest as root
    int left = 2 * i + 1;   // Left child
    int right = 2 * i + 2;  // Right child

    // Check if left child is larger than root
    if (left < n && arr[left].box.S < arr[largest].box.S) {
        largest = left;
    }

    // Check if right child is larger than the largest so far
    if (right < n && arr[right].box.S < arr[largest].box.S) {
        largest = right;
    }

    // If the largest is not root, swap and heapify recursively
    if (largest != i) {
        swap(&arr[i], &arr[largest]);
        heapify(arr, n, largest);
    }
}

// Public function to perform heap sort
static void heapSort(BBoxPack arr[], int n) {
    // Build the max heap
    for (int i = n / 2 - 1; i >= 0; i--) {
        heapify(arr, n, i);
    }

    // Extract elements from the heap
    for (int i = n - 1; i >= 0; i--) {
        // Move the current root to the end
        swap(&arr[0], &arr[i]);

        // Heapify the reduced heap
        heapify(arr, i, 0);
    }
}

//
//
// ----------------------------END STATIC COMPONENTS---------------------------



void NMS_Init(NMS_Config *NMSConfigIns, UINTPTR BaseAddrVal) {
  NMSConfigIns->BaseAddr = BaseAddrVal;
  NMSConfigIns->NumPred = 0;
  NMSConfigIns->IOUThresh = 0;
  NMSConfigIns->SThresh = 0;
}


void NMS_SetIOUThresh(NMS_Config *NMSConfigIns, u16 IOUThresh) {
  NMSConfigIns->IOUThresh = IOUThresh;

  Xil_Out32(NMSConfigIns->BaseAddr + NMS_IOU_THRESH_OFFSET, (u32)NMSConfigIns->IOUThresh);
}


void NMS_SetSThresh(NMS_Config *NMSConfigIns, u16 SThresh) {
  NMSConfigIns->SThresh = SThresh;

  Xil_Out32(NMSConfigIns->BaseAddr + NMS_S_THRESH_OFFSET, (u32)NMSConfigIns->SThresh);
}


void NMS_SetNumPredAndStart(NMS_Config *NMSConfigIns, u16 NumPred) {
  NMSConfigIns->NumPred = NumPred;
  u32 RegValue = (u32)((NumPred << 1) | NMS_START_MASK);

  Xil_Out32(NMSConfigIns->BaseAddr + NMS_NUM_PRED_START_OFFSET, RegValue);
}


void NMS_ClearStart(NMS_Config *NMSConfigIns) {
  u32 RegValue = (u32)((NMSConfigIns->NumPred << 1) | 0U);

  Xil_Out32(NMSConfigIns->BaseAddr + NMS_NUM_PRED_START_OFFSET, RegValue);
}


u16 NMS_HWGetNumBox(NMS_Config *NMSConfigIns) {
	u16 num_box = Xil_In32((UINTPTR)(NMSConfigIns->BaseAddr + NMS_NUM_BOX_OFFSET));
	return num_box;
}

u16 NMS_SWImproved(u16 NumPred,
    BBox PredBox[],
    u16 * BoxIndBuff,
    float IOUThresh,
    float SThresh) {
    int i, j, num_box = 0;
    BBox temp;

    BoxIndBuff[0] = 0;

    for (i = 1; i < NumPred; i++) {
        if (PredBox[i].S < SThresh) {
            continue;
        }

    	temp = PredBox[i];

        for (j = 0; j < num_box; j++) {
			if (IOU(&temp, &PredBox[BoxIndBuff[j]]) > IOUThresh) {
				if (temp.S > PredBox[BoxIndBuff[j]].S) {
					BoxIndBuff[j] = i;
				}
				break;
			}
        }

        if (j == num_box) {
        	BoxIndBuff[j] = i;
        	num_box++;
		}
    }


    return num_box;
}



u16 NMS_SWVanillaOptimized(u16 NumPred,
    BBox PredBox[],
    u16 * BoxIndBuff,
    float IOUThresh,
    float SThresh) {
    int i, NumFiltered = 0;
    u16 NumSelect = 0;
    BBoxPack SFiltered[200];
    BBoxPack packTemp;

    // S thresholding filter
    for (i = 0; i < NumPred; i++) {
        if (PredBox[i].S > SThresh) {
            packTemp.box = PredBox[i];
            packTemp.index = i;
            SFiltered[NumFiltered++] = packTemp;
        }
    }

    // Sort the filtered array
    heapSort(SFiltered, NumFiltered);

    // Push the data to a linked list
    BBoxPack * head = NULL;

    for (i = NumFiltered - 1; i >= 0; i--) {
        SFiltered[i].next = head;
        head = & SFiltered[i];
    }

    BBoxPack * iter = head;

    // Implement NMS
    iter = head;
    while (iter != NULL) {
        BBoxPack * currentBox = iter;
        BBoxPack * nextBox = currentBox -> next;

        while (nextBox != NULL) {
            if (IOU( & iter -> box, & nextBox -> box) > IOUThresh) {
                currentBox -> next = nextBox -> next;
                nextBox = nextBox -> next;
            } else {
                currentBox = nextBox;
                nextBox = nextBox -> next;
            }
        }

        iter = iter -> next;
    }

    iter = head;
    while (iter != NULL) {
        BoxIndBuff[NumSelect++] = iter -> index;
        iter = iter -> next;
    }

    return NumSelect;
}



void NMS_SWBoxDataFetch(BBox *bbox, u64 data, float S) {
	u16 x = (u16)(data >> 52);
	u16 y = (u16)((data >> 40) & 0x0FFF);
	u16 w = (u16)((data >> 28) & 0x0FFF);
	u16 h = (u16)((data >> 16) & 0x0FFF);

	bbox->x = x;
	bbox->y = y;
	bbox->a = x + w;
	bbox->b = y + h;
	bbox->S = S;
}



float IOU(BBox *b1, BBox *b2) {
	u16 x, y, a, b, intersection;

	x = b1->x > b2->x ? b1->x : b2->x;
	y = b1->y > b2->y ? b1->y : b2->y;
	a = b1->a < b2->a ? b1->a : b2->a;
	b = b1->b < b2->b ? b1->b : b2->b;

	intersection = (a - x > 0 ? a - x : 0) * (b - y > 0 ? b - y : 0);
	u16 a1 = (b1->a - b1->x) * (b1->b - b1->y);
	u16 a2 = (b2->a - b2->x) * (b2->b - b2->y);
	float uni = (float)(a1 + a2 - intersection);


	return (uni > 0) ? (intersection / uni) : 0;
}


void NMS_PrintBBox(BBox *box) {
	printf("x = %d, y = %d, a = %d, b = %d, S = %lf\n", box->x,
			box->y, box->a, box->b, box->S);
}




