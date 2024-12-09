module registers #(
    parameter BBOX_DATA_WIDTH  = 64,
    parameter REG_DATA_WIDTH   = 32,
    parameter BBOX_IND_WIDTH   = 14,
    parameter REG_ADDR_WIDTH   = 4,
    parameter IOU_THRESH_WIDTH = 16,
    parameter MEM_ADDR_WIDTH   = 10,
    localparam S_WIDTH         = IOU_THRESH_WIDTH
) (
    input clk,
    input gen_rst,

    input                        pbox_ren,
    input  [BBOX_DATA_WIDTH-1:0] pred_bbox_data,
    input                        reg_ren,
    input  [ REG_DATA_WIDTH-1:0] reg_data,
    input  [ REG_ADDR_WIDTH-1:0] reg_addr,
    output [ REG_DATA_WIDTH-1:0] num_box_data,
    input                        num_box_wren,

    output                        start,
    output                        pbox_ready,
    output [  BBOX_IND_WIDTH-1:0] num_pred,
    output [IOU_THRESH_WIDTH-1:0] iou_thresh,
    output [         S_WIDTH-1:0] S_thresh,
    output [ BBOX_DATA_WIDTH-1:0] pred_bbox,
    input  [  MEM_ADDR_WIDTH-1:0] bbox_raddr
);

  reg [    BBOX_IND_WIDTH:0] num_pred_start_reg = {(BBOX_IND_WIDTH + 1) {1'b0}};  // Address: 0x0000
  reg [IOU_THRESH_WIDTH-1:0] iou_thresh_reg = {IOU_THRESH_WIDTH{1'b0}};  // Address: 0x0004
  reg [         S_WIDTH-1:0] S_thresh_reg = {S_WIDTH{1'b0}};  // Address: 0x0008
  reg [  MEM_ADDR_WIDTH-1:0] num_box_reg = {MEM_ADDR_WIDTH{1'b0}};  // Address: 0x000C
  reg [ BBOX_DATA_WIDTH-1:0] pred_bbox_reg = {BBOX_DATA_WIDTH{1'b0}};


  // num_pred_start_reg
  always @(posedge clk) begin
    if (gen_rst) begin
      num_pred_start_reg <= {(BBOX_IND_WIDTH + 1) {1'b0}};
    end else begin
      if (reg_ren & reg_addr == 4'h0) begin
        num_pred_start_reg <= reg_data[BBOX_IND_WIDTH:0];
      end
    end
  end



  // iou_thresh_reg
  always @(posedge clk) begin
    if (gen_rst) begin
      iou_thresh_reg <= {IOU_THRESH_WIDTH{1'b0}};
    end else begin
      if (reg_ren & reg_addr == 4'h4) begin
        iou_thresh_reg <= reg_data[IOU_THRESH_WIDTH-1:0];
      end
    end
  end



  // S_thresh_reg
  always @(posedge clk) begin
    if (gen_rst) begin
      S_thresh_reg <= {S_WIDTH{1'b0}};
    end else begin
      if (reg_ren & reg_addr == 4'h8) begin
        S_thresh_reg <= reg_data[S_WIDTH-1:0];
      end
    end
  end



  // num_box_reg
  always @(posedge clk) begin
    if (gen_rst) begin
      num_box_reg <= {S_WIDTH{1'b0}};
    end else begin
      if (num_box_wren) begin
        num_box_reg <= bbox_raddr;
      end
    end
  end



  // pred_bbox_reg
  always @(posedge clk) begin
    if (gen_rst) begin
      pred_bbox_reg <= {BBOX_DATA_WIDTH{1'b0}};
    end else begin
      if (pbox_ready) begin
        pred_bbox_reg <= pred_bbox_data;
      end
    end
  end


  // output assignments
  assign start        = num_pred_start_reg[0];
  assign num_pred     = num_pred_start_reg[BBOX_IND_WIDTH:1];
  assign pred_bbox    = pred_bbox_reg;
  assign iou_thresh   = iou_thresh_reg;
  assign S_thresh     = S_thresh_reg;
  assign pbox_ready   = pbox_ren;
  assign num_box_data = {{(REG_DATA_WIDTH - MEM_ADDR_WIDTH){1'b0}}, bbox_raddr};

endmodule
