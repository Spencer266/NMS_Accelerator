from __future__ import division

import torch
import time
import torch.nn as nn
import torch.nn.functional as F
from torch.autograd import Variable
from torchmetrics.detection import MeanAveragePrecision
import matplotlib.pyplot as plt
import numpy as np
import cv2
from pprint import pprint



def unique(tensor):
    tensor_np = tensor.cpu().numpy()
    unique_np = np.unique(tensor_np)
    unique_tensor = torch.from_numpy(unique_np)

    tensor_res = tensor.new(unique_tensor.shape)
    tensor_res.copy_(unique_tensor)
    return tensor_res


def bbox_iou(box1, box2):
    """
    Returns the IoU of two bounding boxes


    """
    #Get the coordinates of bounding boxes
    b1_x1, b1_y1, b1_x2, b1_y2 = box1[:, 0], box1[:, 1], box1[:, 2], box1[:, 3]
    b2_x1, b2_y1, b2_x2, b2_y2 = box2[:, 0], box2[:, 1], box2[:, 2], box2[:, 3]

    #get the corrdinates of the intersection rectangle
    inter_rect_x1 = torch.max(b1_x1, b2_x1)
    inter_rect_y1 = torch.max(b1_y1, b2_y1)
    inter_rect_x2 = torch.min(b1_x2, b2_x2)
    inter_rect_y2 = torch.min(b1_y2, b2_y2)

    #Intersection area
    inter_area = torch.clamp(inter_rect_x2 - inter_rect_x1 + 1, min=0) * torch.clamp(inter_rect_y2 - inter_rect_y1 + 1, min=0)

    #Union Area
    b1_area = (b1_x2 - b1_x1 + 1)*(b1_y2 - b1_y1 + 1)
    b2_area = (b2_x2 - b2_x1 + 1)*(b2_y2 - b2_y1 + 1)

    iou = inter_area / (b1_area + b2_area - inter_area)

    return iou

def predict_transform(prediction, inp_dim, anchors, num_classes, CUDA = True):


    batch_size = prediction.size(0)
    stride =  inp_dim // prediction.size(2)
    grid_size = inp_dim // stride
    bbox_attrs = 5 + num_classes
    num_anchors = len(anchors)

    prediction = prediction.view(batch_size, bbox_attrs*num_anchors, grid_size*grid_size)
    prediction = prediction.transpose(1,2).contiguous()
    prediction = prediction.view(batch_size, grid_size*grid_size*num_anchors, bbox_attrs)
    anchors = [(a[0]/stride, a[1]/stride) for a in anchors]

    #Sigmoid the  centre_X, centre_Y. and object confidencce
    prediction[:,:,0] = torch.sigmoid(prediction[:,:,0])
    prediction[:,:,1] = torch.sigmoid(prediction[:,:,1])
    prediction[:,:,4] = torch.sigmoid(prediction[:,:,4])

    #Add the center offsets
    grid = np.arange(grid_size)
    a,b = np.meshgrid(grid, grid)

    x_offset = torch.FloatTensor(a).view(-1,1)
    y_offset = torch.FloatTensor(b).view(-1,1)

    if CUDA:
        x_offset = x_offset.cuda()
        y_offset = y_offset.cuda()

    x_y_offset = torch.cat((x_offset, y_offset), 1).repeat(1,num_anchors).view(-1,2).unsqueeze(0)

    prediction[:,:,:2] += x_y_offset

    #log space transform height and the width
    anchors = torch.FloatTensor(anchors)

    if CUDA:
        anchors = anchors.cuda()

    anchors = anchors.repeat(grid_size*grid_size, 1).unsqueeze(0)
    prediction[:,:,2:4] = torch.exp(prediction[:,:,2:4])*anchors

    prediction[:,:,5: 5 + num_classes] = torch.sigmoid((prediction[:,:, 5 : 5 + num_classes]))

    prediction[:,:,:4] *= stride

    return prediction

def write_results(prediction, confidence, num_classes, nms_conf = 0.4, img_names = None):
    '''
    TODO
    1. Recalculate coordinates
    2. Filter by confidence score
    3. Sort by confidence score
    '''

    # print(prediction)
    conf_mask = (prediction[:,:,4] > confidence).float().unsqueeze(2)

    box_corner = prediction.new(prediction.shape)
    box_corner[:,:,0] = (prediction[:,:,0] - prediction[:,:,2]/2)
    box_corner[:,:,1] = (prediction[:,:,1] - prediction[:,:,3]/2)
    box_corner[:,:,2] = (prediction[:,:,0] + prediction[:,:,2]/2)
    box_corner[:,:,3] = (prediction[:,:,1] + prediction[:,:,3]/2)
    prediction[:,:,:4] = box_corner[:,:,:4]
    pred_unfiltered = prediction
    prediction = prediction*conf_mask

    batch_size = prediction.size(0)

    write = False

    for ind in range(batch_size):
        image_pred = prediction[ind]          #image Tensor
        unfiltered = pred_unfiltered[ind]
        #confidence threshholding
        #NMS

        max_conf, max_conf_score = torch.max(image_pred[:,5:5+ num_classes], 1)
        max_conf = max_conf.float().unsqueeze(1)
        max_conf_score = max_conf_score.float().unsqueeze(1)
        seq = (image_pred[:,:5], max_conf, max_conf_score)
        image_pred = torch.cat(seq, 1)


        non_zero_ind =  (torch.nonzero(image_pred[:,4]))
        try:
            image_pred_ = image_pred[non_zero_ind.squeeze(),:].view(-1,7)
        except:
            continue

        if image_pred_.shape[0] == 0:
            continue


        # -------------------------------Addtional processing for evaluating NMS Module in hardware--------------------------------
        # print("No confidence filter:")
        # print(unfiltered.shape)

        max_conf, max_conf_score = torch.max(unfiltered[:,5:5+ num_classes], 1)
        max_conf = max_conf.float().unsqueeze(1)
        max_conf_score = max_conf_score.float().unsqueeze(1)
        seq = (unfiltered[:,:5], max_conf, max_conf_score)
        unfiltered = torch.cat(seq, 1)

        # print("Prediction boxes: [x, y, a, b, S, class_score, class_ind]")
        # print(unfiltered[unfiltered[:, 4] > confidence])
        # print(unfiltered.shape)
        # print(unfiltered.dtype)

        box_size_info = unfiltered[:, :4].clone()
        box_size_info[:,2] = unfiltered[:,2] - unfiltered[:,0]
        box_size_info[:,3] = unfiltered[:,3] - unfiltered[:,1]
        box_size_info = torch.round(box_size_info).type(torch.uint16)
        box_object_scores = unfiltered[:, 4].clone().type(torch.float16)


        img_name = img_names[ind].split('/')[-1]
        img_name = img_name.split('.')[0]
        NMS_Module_input_preprocess(box_size_info, box_object_scores, img_name)

        selected = unfiltered[read_indexes(img_name)]
        batch_index = selected.new(selected.size(0), 1).fill_(ind)

        try:
            hw_output = torch.cat((hw_output, torch.cat((batch_index, selected), dim=1)))
        except NameError:
            hw_output = torch.cat((batch_index, selected), dim=1)

        # hw_output = torch.rand(1, 8).type(int)
        # -------------------------------------------End of additional processing--------------------------------------------------


        #Get the various classes detected in the image
        img_classes = unique(image_pred_[:,-1])  # -1 index holds the class index


        for cls in img_classes:
            #perform NMS


            #get the detections with one particular class
            cls_mask = image_pred_*(image_pred_[:,-1] == cls).float().unsqueeze(1)
            class_mask_ind = torch.nonzero(cls_mask[:,-2]).squeeze()
            image_pred_class = image_pred_[class_mask_ind].view(-1,7)

            #sort the detections such that the entry with the maximum objectness
            #confidence is at the top
            conf_sort_index = torch.sort(image_pred_class[:,4], descending = True )[1]
            image_pred_class = image_pred_class[conf_sort_index]
            idx = image_pred_class.size(0)   #Number of detections


            for i in range(idx):
                #Get the IOUs of all boxes that come after the one we are looking at
                #in the loop
                try:
                    ious = bbox_iou(image_pred_class[i].unsqueeze(0), image_pred_class[i+1:])
                except ValueError:
                    break

                except IndexError:
                    break

                #Zero out all the detections that have IoU > treshhold
                iou_mask = (ious < nms_conf).float().unsqueeze(1)
                image_pred_class[i+1:] *= iou_mask

                #Remove the non-zero entries
                non_zero_ind = torch.nonzero(image_pred_class[:,4]).squeeze()
                image_pred_class = image_pred_class[non_zero_ind].view(-1,7)


            batch_ind = image_pred_class.new(image_pred_class.size(0), 1).fill_(ind)      #Repeat the batch_id for as many detections of the class cls in the image
            seq = batch_ind, image_pred_class

            if not write:
                output = torch.cat(seq,1)
                write = True
            else:
                out = torch.cat(seq,1)
                output = torch.cat((output,out))
    
    try:
        return output, hw_output
    except:
        return 0, 0





# ------------------------------------------------Additional NMS hardware functions ----------------------------------------------------
def NMS_Module_input_preprocess(box_size, box_object_scores, img_name):
    object_score_nparray = box_object_scores.numpy()
    object_score_hex = object_score_nparray.view(np.uint16)

    with open(f'bbox/{img_name}.txt', 'w') as self_file, open(f'bbox/singular_box.txt', 'a') as box_file, open(f'bbox/singular_S.txt', 'a') as S_file:
        box_file.write("    {\n")
        self_file.write('const u64 bbox_array[NUM_PRED] = {\n')
        for bbox_ind in range(box_size.shape[0]):
            x_val = f"{box_size[bbox_ind, 0]:03X}" if int(box_size[bbox_ind, 0]) < 4096 else "FFF"
            y_val = f"{box_size[bbox_ind, 1]:03X}" if int(box_size[bbox_ind, 1]) < 4096 else "FFF"
            w_val = f"{box_size[bbox_ind, 2]:03X}" if int(box_size[bbox_ind, 2]) < 4096 else "FFF"
            h_val = f"{box_size[bbox_ind, 3]:03X}" if int(box_size[bbox_ind, 3]) < 4096 else "FFF"
            o_val = f"{object_score_hex[bbox_ind]:04X}"
            # print(f"bbox_data[{bbox_ind}] = {{12'h{x_val}, 12'h{y_val}, 12'h{w_val}, 12'h{h_val}, 16'h{o_val}}};")
            box_file.write(f"        0x{x_val}{y_val}{w_val}{h_val}{o_val},\n")
            self_file.write(f"    0x{x_val}{y_val}{w_val}{h_val}{o_val},\n")

        box_file.write("    },\n")

        self_file.write('};\nconst float bbox_S[NUM_PRED] = {\n')
        S_file.write("    {\n")
        for bbox_ind in range(box_size.shape[0]):
            S_file.write(f"        {box_object_scores[bbox_ind]:.6f},\n")
            self_file.write(f"    {box_object_scores[bbox_ind]:.6f},\n")
        
        S_file.write("    },\n")
        self_file.write('};\n')

    print()


def file_postprocess(num_img):
    with open("bbox/singular_box.txt", 'r') as box_file:
        box_data = box_file.readlines()

    with open("bbox/singular_box.txt", 'w') as box_file:
        box_file.write("")

    with open("bbox/singular_S.txt", 'r') as S_file:
        S_data = S_file.readlines()

    with open("bbox/singular_S.txt", 'w') as S_file:
        S_file.write("")

    with open("bbox/singular.txt", 'w') as file:
        file.write("#ifndef DATA_H\n#define DATA_H\n#include <xil_types.h>\n#define NUM_PRED 10647\n")
        file.write(f"#define NUM_IMG {num_img}\n")
        file.write("const u64 bbox_array[NUM_IMG][NUM_PRED] = {\n")
        file.writelines(box_data)
        file.write("};\nconst float bbox_S[NUM_IMG][NUM_PRED] = {\n")
        file.writelines(S_data)
        file.write("};\n")
        file.write("#endif // DATA_H\n")

 



def read_indexes(filename):
    indexes = []
    index_text = []
    read = False
    read_index = False

    try:
        with open(f"nms/log_result.txt", "r") as file:
            for line in file:
                if filename in line:
                    read = True
                
                if read is True:
                    if "Hardware" in line:
                        read_index = True
                        index_text.append(line)
                        continue
                    elif "Optimized" in line:
                        index_text.append(line)
                        read_index = False
                        continue
                    elif "Improved" in line:
                        index_text.append(line)
                        break

                if read_index is True:
                    # Split each line by colon and strip spaces
                    value = line.split(": ")[-1].strip()
                    indexes.append(int(value))  # Convert the extracted value to an integer
                    index_text.insert(1, line)

    
    except FileNotFoundError:
        indexes = [0]
        index_text = ["Data error!"]

    if not indexes:
        indexes = [0]
        index_text = ["Data not found!"]

    with open(f"nms/hw_{filename}.txt", "w") as file:
        for line in index_text:
            file.write(f"{line}")

    return indexes




def NMS_mAP(pred, target, iou_thresh):
    metric = MeanAveragePrecision(box_format='xyxy', iou_type='bbox', iou_thresholds=iou_thresh)
    # metric.update(pred, target)
    res = []
    for i in range(len(pred)):
        metric.update([pred[i]], [target[i]])
        res.append(metric.compute())
    
    unused = ['classes',
              'map_50',
              'map_75',
              'map_per_class',
              'mar_1',
              'mar_10',
              'mar_100',
              'mar_100_per_class',
              'mar_large',
              'mar_small',
              'mar_medium']

    pre_map_large = 1
    pre_map_medium = 1 
    pre_map_small = 1

    for r in res:
        # r['classes'] = torch.tensor([0])
        [r.pop(key) for key in unused]
        if r['map_large'].item() == -1:
            r['map_large'] = torch.tensor(pre_map_large)
        else:
            pre_map_large = r['map_large'].item()
        
        if r['map_medium'].item() == -1:
            r['map_medium'] = torch.tensor(pre_map_medium)
        else:
            pre_map_medium = r['map_medium'].item()

        if r['map_small'].item() == -1:
            r['map_small'] = torch.tensor(pre_map_small)
        else:
            pre_map_small = r['map_small'].item()
        

    fig_, ax_ = metric.plot(res)
    fig_.set_size_inches(15,10)

    # Save the plot as an image file
    plt.savefig('mAP_plot.png', dpi=300, bbox_inches='tight')

    # Display the plot
    # plt.show()

    # Close the plot to free up memory
    plt.close(fig_)

    # Print the mAP results
    # pprint(metric.compute())

# ---------------------------------------------End of Additional NMS hardware functions --------------------------------------------------








def letterbox_image(img, inp_dim):
    '''resize image with unchanged aspect ratio using padding'''
    img_w, img_h = img.shape[1], img.shape[0]
    w, h = inp_dim
    new_w = int(img_w * min(w/img_w, h/img_h))
    new_h = int(img_h * min(w/img_w, h/img_h))
    resized_image = cv2.resize(img, (new_w,new_h), interpolation = cv2.INTER_CUBIC)

    canvas = np.full((inp_dim[1], inp_dim[0], 3), 128)

    canvas[(h-new_h)//2:(h-new_h)//2 + new_h,(w-new_w)//2:(w-new_w)//2 + new_w,  :] = resized_image

    return canvas




def prep_image(img, inp_dim):
    """
    Prepare image for inputting to the neural network.

    Returns a Variable
    """
    img = (letterbox_image(img, (inp_dim, inp_dim)))
    img = img[:,:,::-1].transpose((2,0,1)).copy()
    img = torch.from_numpy(img).float().div(255.0).unsqueeze(0)
    return img




def load_classes(namesfile):
    fp = open(namesfile, "r")
    names = fp.read().split("\n")[:-1]
    return names
