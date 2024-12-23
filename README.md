# About project
This repository contains source code of digital hardware accelerator IP module for Non-Maximum Suppression (NMS) algorithm and SoC system for on-board verification.<br>
<br>
The repo also includes an implementation of YOLOv3 CNN model trained for object detection, which is modified to extract bounding boxes data for hardware accelerator to process.<br>
<br>
The design and SoC system are implemented and executed on Xilinx Zedboard using the Vivado Design Suite toolset.

# Repository structure
The repository is organized to 4 directories related to certain parts of the overall project which can be navigated as follow:

1. [NMS module IP](#1-NMS-module-IP)
2. [SoC system](#2-SoC-system)
3. [SoC software program](#3-SoC-software-program)
4. [YOLOv3 model](#4-YOLOv3-model)

---

### 1. NMS module IP
This IP is designed and verified using Verilog for the Zedboard. The synthesized and implementation result allow the module to work at maximum clock frequency of 167 MHz.<br>
<br>
The module is packaged with AXI4-Lite for configuring and AXI4-Stream interface for data tranfering, along with an interrupt signal.<br>
<br>
Current implementation allows unlimited amount of input bounding boxes and can stored up to 1024 local maximum object bounding boxes.<br>

### 2. SoC system
The SoC system design integrated NMS module IP in the FPGA (PL part) of the Zynq SoC architecture. The ARM Cortex processor (PS part) runs a software program to control and handle all the system tasks such as initilization and configuration of peripherals and modules, data preparation and result display.<br>
<br>
The SoC system is design to run at maximum clock frequency of 150 MHz due to the limitation of Xilinx AXI DMA IP implementation on the Zedboard.

### 3. SoC software program
As previously mentioned, the SoC software program controls running flow and handles many system tasks including:
- Peripherals and modules initilization and configuration.
- Data preparation in the DDR memory.
- Handling interrupt signals.
- Result processing and displaying.
<br>
The software library source code also includes self-written driver for the NMS module IP as a peripheral, as well as the software implementation of original and improved NMS algorithm for comparision.

### 4. YOLOv3 model
An implementation from scratch of YOLOv3 architecture CNN object detection model is cloned from another repository referenced in an article (https://blog.paperspace.com/how-to-implement-a-yolo-object-detector-in-pytorch/). The model is already pre-trained with the COCO dataset and ready to detect object from input images and videos. <br>
<br>
The modified version in this project contains several helper functions to extract pre-NMS bounding boxes data for the hardware side to process and display post-NMS result on output images.
