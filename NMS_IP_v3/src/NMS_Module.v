`timescale 1ns / 1ps

module NMS_Module #(
    parameter  BBOX_DATA_WIDTH  = 64,
    parameter  BBOX_IND_WIDTH   = 14,
    parameter  REG_DATA_WIDTH   = 32,
    parameter  REG_ADDR_WIDTH   = 4,
    parameter  IOU_THRESH_WIDTH = 16,
    parameter  S_WIDTH          = 16,
    parameter  MEM_ADDR_WIDTH   = 10,
    localparam TotalDataWidth   = BBOX_DATA_WIDTH + BBOX_IND_WIDTH
) (
    input clk,
    input resetn,

    output                       pbox_ready,
    input  [BBOX_DATA_WIDTH-1:0] pred_bbox_data,

    input                       reg_ren,
    input  [REG_DATA_WIDTH-1:0] reg_data,
    input  [REG_ADDR_WIDTH-1:0] reg_addr,
    output [REG_DATA_WIDTH-1:0] num_box_data,
    output                      num_box_wren,

    output tvalid,
    output tlast,
    input  tready,
    output done_int,

    output [BBOX_IND_WIDTH-1:0] bbox_index
);

  wire gen_rst_wire;

  wire start_wire;
  wire pbox_ren_wire;
  wire num_box_wren_wire;


  wire i_lt_num_pred_wire;
  wire iter_eq_last_wire;
  wire delay_eq_8_wire;
  wire iter_eq_lstMinus1_wire;
  wire S_under_thresh_wire;
  wire overlap_wire;
  wire delay_rst_wire, delay_en_wire;
  wire bbox_iter_rst_wire, bbox_iter_en_wire;
  wire bbox_last_en_wire;
  wire i_counter_en_wire;
  wire iou_thresh_pass_wire, pred_S_gt_delay_wire;
  wire bbox_mem_wren_wire, bbox_mem_ren_wire;
  wire wea_wire;


  wire [  BBOX_IND_WIDTH-1:0] num_pred_wire;
  wire [IOU_THRESH_WIDTH-1:0] iou_thresh_wire;
  wire [ BBOX_DATA_WIDTH-1:0] pred_bbox_wire;
  wire [  BBOX_IND_WIDTH-1:0] i_counter_wire;
  wire [  MEM_ADDR_WIDTH-1:0] bbox_raddr_wire;
  wire [  MEM_ADDR_WIDTH-1:0] bbox_waddr_wire;
  wire [         S_WIDTH-1:0] S_thresh_wire;
  wire [         S_WIDTH-1:0] pred_bbox_S_wire;
  wire [  REG_DATA_WIDTH-1:0] num_box_data_wire;


  wire [  TotalDataWidth-1:0] bbox_din_wire;
  wire [  TotalDataWidth-1:0] bbox_dout_wire;


  controller controller_inst (
      .clk              (clk),
      .resetn           (resetn),
      .start            (start_wire),
      .pbox_ren         (pbox_ren_wire),
      .i_lt_num_pred    (i_lt_num_pred_wire),
      .iter_eq_last     (iter_eq_last_wire),
      .delay_eq_8       (delay_eq_8_wire),
      .iter_eq_lstMinus1(iter_eq_lstMinus1_wire),
      .S_under_thresh   (S_under_thresh_wire),
      .overlap          (overlap_wire),
      .delay_rst        (delay_rst_wire),
      .delay_en         (delay_en_wire),
      .bbox_iter_rst    (bbox_iter_rst_wire),
      .bbox_iter_en     (bbox_iter_en_wire),
      .bbox_last_en     (bbox_last_en_wire),
      .i_counter_en     (i_counter_en_wire),
      .iou_thresh_pass  (iou_thresh_pass_wire),
      .pred_S_gt_delay  (pred_S_gt_delay_wire),
      .bbox_mem_ren     (bbox_mem_ren_wire),
      .bbox_mem_wren    (bbox_mem_wren_wire),
      .num_box_wren     (num_box_wren_wire),
      .tready           (tready),
      .tvalid           (tvalid),
      .tlast            (tlast),
      .done_int         (done_int),
      .wea              (wea_wire),
      .gen_rst          (gen_rst_wire)
  );


  registers registers_inst (
      .clk           (clk),
      .gen_rst       (gen_rst_wire),
      .pbox_ren      (pbox_ren_wire),
      .pred_bbox_data(pred_bbox_data),
      .reg_ren       (reg_ren),
      .reg_data      (reg_data),
      .reg_addr      (reg_addr),
      .num_box_data  (num_box_data),
      .num_box_wren  (num_box_wren_wire),
      .start         (start_wire),
      .pbox_ready    (pbox_ready),
      .num_pred      (num_pred_wire),
      .iou_thresh    (iou_thresh_wire),
      .S_thresh      (S_thresh_wire),
      .pred_bbox     (pred_bbox_wire),
      .bbox_raddr    (bbox_raddr_wire)
  );

  assign pred_bbox_S_wire = pred_bbox_wire[S_WIDTH-1:0];

  NMS_Unit NMS_Unit_inst (
      .clk              (clk),
      .gen_rst          (gen_rst_wire),
      .delay_rst        (delay_rst_wire),
      .delay_en         (delay_en_wire),
      .bbox_iter_rst    (bbox_iter_rst_wire),
      .bbox_iter_en     (bbox_iter_en_wire),
      .bbox_last_en     (bbox_last_en_wire),
      .i_counter_en     (i_counter_en_wire),
      .num_pred         (num_pred_wire),
      .S_thresh         (S_thresh_wire),
      .pred_bbox_S      (pred_bbox_S_wire),
      .i_lt_num_pred    (i_lt_num_pred_wire),
      .iter_eq_last     (iter_eq_last_wire),
      .delay_eq_8       (delay_eq_8_wire),
      .iter_eq_lstMinus1(iter_eq_lstMinus1_wire),
      .S_under_thresh   (S_under_thresh_wire),
      .i_counter        (i_counter_wire),
      .bbox_raddr       (bbox_raddr_wire),
      .bbox_waddr       (bbox_waddr_wire)
  );


  wire [BBOX_DATA_WIDTH-1:0] bbox = bbox_dout_wire[TotalDataWidth-1:BBOX_IND_WIDTH];
  CALU CALU_inst (
      .clk            (clk),
      .box1           (pred_bbox_wire),
      .box2           (bbox),
      .iou_thresh     (iou_thresh_wire),
      .iou_thresh_pass(iou_thresh_pass_wire),
      .overlap        (overlap_wire),
      .pred_S_gt_delay(pred_S_gt_delay_wire)
  );


  assign bbox_din_wire = {pred_bbox_wire, i_counter_wire};


  bbox_mem bbox_mem_inst (
      .clk     (clk),
      .gen_rst (gen_rst_wire),
      .mem_din (bbox_din_wire),
      .waddr   (bbox_waddr_wire),
      .mem_wren(bbox_mem_ren_wire),
      .wea     (wea_wire),
      .mem_dout(bbox_dout_wire),
      .raddr   (bbox_raddr_wire),
      .mem_ren (bbox_mem_ren_wire)
  );


  assign bbox_index = bbox_dout_wire[BBOX_IND_WIDTH-1:0];
  assign num_box_wren = num_box_wren_wire;

endmodule
