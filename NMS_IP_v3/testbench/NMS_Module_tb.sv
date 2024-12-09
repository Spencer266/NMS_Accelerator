`timescale 1ns/1ps

module NMS_Module_tb;

  parameter BBOX_DATA_WIDTH = 64;
  parameter BBOX_IND_WIDTH = 14;
  parameter REG_DATA_WIDTH = 32;
  parameter REG_ADDR_WIDTH = 4;
  parameter IOU_THRESH_WIDTH = 16;
  parameter MEM_ADDR_WIDTH = 10;


  bit                       clk;
  bit                       resetn;

  // pred bbox signals
  bit                       pbox_ready;
  bit [BBOX_DATA_WIDTH-1:0] pred_bbox_data;

  // registers signals
  bit                       reg_ren;
  bit [ REG_DATA_WIDTH-1:0] reg_data;
  bit [ REG_ADDR_WIDTH-1:0] reg_addr;

  // AXI stream related signals
  bit                       tvalid;
  bit                       tlast;
  bit                       tready;
  bit                       done_int;
  bit                       tvalid_old;

  // Output bbox index data
  bit [ BBOX_IND_WIDTH-1:0] bbox_index;


  // Predicted bounding boxes data storage
  bit [               63:0] bbox_data      [10];
  initial begin
    bbox_data[0] = {12'd136, 12'd272, 12'd88, 12'd85, 16'h3b9e};
    bbox_data[1] = {12'd206, 12'd218, 12'd52, 12'd95, 16'h38f5};
    bbox_data[2] = {12'd218, 12'd240, 12'd40, 12'd79, 16'h3967};
    bbox_data[3] = {12'd212, 12'd231, 12'd46, 12'd93, 16'h3a29};
    bbox_data[4] = {12'd2, 12'd240, 12'd55, 12'd118, 16'h3a8a};
    bbox_data[5] = {12'd3, 12'd254, 12'd55, 12'd107, 16'h3b87};
    bbox_data[6] = {12'd8, 12'd255, 12'd51, 12'd106, 16'h3a09};
    bbox_data[7] = {12'd137, 12'd270, 12'd68, 12'd89, 16'h3b4d};
    bbox_data[8] = {12'd143, 12'd270, 12'd70, 12'd88, 16'h3a45};
    bbox_data[9] = {12'd379, 12'd178, 12'd15, 12'd13, 16'h39d6};
  end


  NMS_Module NMS_Module_DUT (
      .clk           (clk),
      .resetn        (resetn),
      .pbox_ready    (pbox_ready),
      .pred_bbox_data(pred_bbox_data),
      .reg_ren       (reg_ren),
      .reg_data      (reg_data),
      .reg_addr      (reg_addr),
      .tvalid        (tvalid),
      .tlast         (tlast),
      .tready        (tready),
      .done_int      (done_int),
      .bbox_index    (bbox_index)
  );


  always #3 clk = ~clk;

  always @(posedge clk) begin
    tvalid_old <= tvalid;
  end


  initial begin
    clk = 1;
    resetn = 1;
    #14;
    resetn = 0;

    // iou_thresh value to register 0x0004
    repeat (2) @(posedge clk);
    reg_data <= 32'h0000_3800;
    reg_addr <= 4'd4;
    reg_ren  <= 1;

    @(posedge clk);
    reg_ren        <= 0;

    // S_thresh value to register 0x0008
    repeat (2) @(posedge clk);
    reg_data <= 32'h0000_3A66;
    reg_addr <= 4'd8;
    reg_ren  <= 1;

    @(posedge clk);
    reg_ren        <= 0;
    pred_bbox_data <= bbox_data[0];

    // num_pred and start value to register 0x0000
    @(posedge clk);
    reg_data <= 32'h0000_0015;
    reg_addr <= 4'd0;
    reg_ren  <= 1;

    @(posedge clk);
    reg_ren <= 0;

    @(posedge clk);

    for (int i = 1; i < 10; i++) begin
      wait (pbox_ready == 1);
      @(posedge clk);
      wait (pbox_ready == 0);
      @(posedge clk);
      pred_bbox_data <= bbox_data[i];
    end


    while (~tlast) begin
      wait (tvalid == 1 && tvalid_old == 1);
      tready <= 1;
      @(posedge clk);
      tready <= 0;
      @(posedge clk);
    end


    wait (done_int == 1);
    reg_data <= 32'h0;
    reg_addr <= 4'h0;
    reg_ren <= 1;

    @(posedge clk);
    reg_ren <= 0;

    repeat (10) @(posedge clk);

    $finish;
  end
endmodule
