module CALU (
    input             clk,
    input      [63:0] box1,
    input      [63:0] box2,
    input      [15:0] iou_thresh,
    output            iou_thresh_pass,
    output reg        overlap,
    output reg        pred_S_gt_delay
);

  wire [11:0] x1, y1, w1, h1;
  wire [11:0] x2, y2, w2, h2;
  wire [15:0] S1, S2;


  reg [11:0] min_XW, min_YH, max_X, max_Y;
  reg [11:0] intersect_width, intersect_height, intersect_reg;
  reg [15:0] max_Area, area_x_iou;
  reg MinXW_gt_MaxX, MinYH_gt_MaxY;


  wire [11:0] w1xh1, w2xh2, x1xw1, x2xw2, y1xh1, y2xh2, max_Area_wire;
  //  wire a1_gt_a2, x1w1_lt_x2w2, y1h1_lt_y2h2, x1_gt_x2, y1_gt_y2;
  wire [11:0] intersect_width_wire, intersect_height_wire, intersect_wire;
  wire [15:0] max_area_fp16, intersect_fp16, area_x_iou_wire;
  wire [7:0] pred_S_gt;
  wire iou_thresh_pass_wire;


  assign {x1, y1, w1, h1, S1} = box1;
  assign {x2, y2, w2, h2, S2} = box2;



  // Max area
  uint12_adder_2_latency adder1 (
      .CLK(clk),
      .A  (h1),
      .B  (w1),
      .S  (w1xh1)
  );

  uint12_adder_2_latency adder2 (
      .CLK(clk),
      .A  (h2),
      .B  (w2),
      .S  (w2xh2)
  );

  assign max_Area_wire = (w1xh1 > w2xh2) ? w1xh1 : w2xh2;

  uint12_to_fp16 fp16_conv1 (
      .uint_in (max_Area_wire),
      .fp16_out(max_area_fp16)
  );

  always @(posedge clk) begin
    max_Area <= max_area_fp16;
  end




  // Min X+W
  uint12_adder_2_latency adder3 (
      .CLK(clk),
      .A  (x1),
      .B  (w1),
      .S  (x1xw1)
  );

  uint12_adder_2_latency adder4 (
      .CLK(clk),
      .A  (x2),
      .B  (w2),
      .S  (x2xw2)
  );

  always @(posedge clk) begin
    min_XW <= (x1xw1 < x2xw2) ? x1xw1 : x2xw2;
  end




  // Min Y+H
  uint12_adder_2_latency adder5 (
      .CLK(clk),
      .A  (y1),
      .B  (h1),
      .S  (y1xh1)
  );

  uint12_adder_2_latency adder6 (
      .CLK(clk),
      .A  (y2),
      .B  (h2),
      .S  (y2xh2)
  );

  always @(posedge clk) begin
    min_YH <= (y1xh1 < y2xh2) ? y1xh1 : y2xh2;
  end




  // Max X
  reg [11:0] max_X_p1;
  reg [11:0] max_X_p2;
  always @(posedge clk) begin
    max_X_p1 <= (x1 > x2) ? x1 : x2;
    max_X_p2 <= max_X_p1;
  end



  // Max Y
  reg [11:0] max_Y_p1;
  reg [11:0] max_Y_p2;
  always @(posedge clk) begin
    max_Y_p1 <= (y1 > y2) ? y1 : y2;
    max_Y_p2 <= max_Y_p1;
  end

  always @(posedge clk) begin
    max_X <= max_X_p2;
    max_Y <= max_Y_p2;
  end



  // area_x_iou
  (* keep="soft" *)
  wire temp_tvalid_wire;

  fp16_multiply mul1 (
      .aclk                (clk),               // input wire aclk
      .s_axis_a_tvalid     (1'b1),              // input wire s_axis_a_tvalid
      .s_axis_a_tdata      (iou_thresh),     // input wire [15 : 0] s_axis_a_tdata
      .s_axis_b_tvalid     (1'b1),              // input wire s_axis_b_tvalid
      .s_axis_b_tdata      (max_Area),          // input wire [15 : 0] s_axis_b_tdata
      .m_axis_result_tvalid(temp_tvalid_wire),  // output wire m_axis_result_tvalid
      .m_axis_result_tdata (area_x_iou_wire)    // output wire [15 : 0] m_axis_result_tdata
  );

  // always @(posedge clk) begin
  //   area_x_iou <= area_x_iou_wire;
  // end

  uint12_subtract_2_latency sub1 (
      .CLK(clk),
      .A  (min_XW),
      .B  (max_X),
      .S  (intersect_width_wire)
  );

  uint12_subtract_2_latency sub2 (
      .CLK(clk),
      .A  (min_YH),
      .B  (max_Y),
      .S  (intersect_height_wire)
  );



  // overlap condition
  reg MinXW_gt_MaxX_p5, MinXW_gt_MaxX_p6, MinXW_gt_MaxX_p7;
  reg MinYH_gt_MaxY_p5, MinYH_gt_MaxY_p6, MinYH_gt_MaxY_p7;
  always @(posedge clk) begin
    MinXW_gt_MaxX <= min_XW > max_X;
    MinXW_gt_MaxX_p5 <= MinXW_gt_MaxX;
    MinXW_gt_MaxX_p6 <= MinXW_gt_MaxX_p5;
    MinXW_gt_MaxX_p7 <= MinXW_gt_MaxX_p6;

    MinYH_gt_MaxY <= min_YH > max_Y;
    MinYH_gt_MaxY_p5 <= MinYH_gt_MaxY;
    MinYH_gt_MaxY_p6 <= MinYH_gt_MaxY_p5;
    MinYH_gt_MaxY_p7 <= MinYH_gt_MaxY_p6;
  end




  // intersect
  uint12_adder_2_latency adder7 (
      .CLK(clk),
      .A  (intersect_width_wire),
      .B  (intersect_height_wire),
      .S  (intersect_wire)
  );

  // always @(posedge clk) begin
  //   intersect_reg <= intersect_wire;
  // end



  // pred_S_gt
  reg [15:0] S1_p1, S1_p2, S1_p3, S1_p4, S1_p5, S1_p6, S1_p7;
  reg [15:0] S2_p1, S2_p2, S2_p3, S2_p4, S2_p5, S2_p6, S2_p7;

  always @(posedge clk) begin
    S1_p1 <= S1;
    S1_p2 <= S1_p1;
    S1_p3 <= S1_p2;
    S1_p4 <= S1_p3;
    S1_p5 <= S1_p4;
    S1_p6 <= S1_p5;
    S1_p7 <= S1_p6;

    S2_p1 <= S2;
    S2_p2 <= S2_p1;
    S2_p3 <= S2_p2;
    S2_p4 <= S2_p3;
    S2_p5 <= S2_p4;
    S2_p6 <= S2_p5;
    S2_p7 <= S2_p6;
  end

  (* keep="soft" *)
  wire less1_tvalid;
  

  fp16_less_comparator less1 (
      .aclk                (clk),                  // input wire aclk
      .s_axis_a_tvalid     (1'b1),                 // input wire s_axis_a_tvalid
      .s_axis_a_tdata      (S2_p7),      // input wire [15 : 0] s_axis_a_tdata
      .s_axis_b_tvalid     (1'b1),                 // input wire s_axis_b_tvalid
      .s_axis_b_tdata      (S1_p7),       // input wire [15 : 0] s_axis_b_tdata
      .m_axis_result_tvalid(less1_tvalid),        // output wire m_axis_result_tvalid
      .m_axis_result_tdata (pred_S_gt)  // output wire [7 : 0] m_axis_result_tdata
  );


  // iou_thresh_pass
  uint12_to_fp16 fp16_conv2 (
      .uint_in (intersect_wire),
      .fp16_out(intersect_fp16)
  );


  (* keep="soft" *)
  wire less2_tvalid;
  
  wire [7:0] iou_wire;

  fp16_less_comparator less2 (
      .aclk                (clk),                  // input wire aclk
      .s_axis_a_tvalid     (1'b1),                 // input wire s_axis_a_tvalid
      .s_axis_a_tdata      (area_x_iou_wire),      // input wire [15 : 0] s_axis_a_tdata
      .s_axis_b_tvalid     (1'b1),                 // input wire s_axis_b_tvalid
      .s_axis_b_tdata      (intersect_fp16),       // input wire [15 : 0] s_axis_b_tdata
      .m_axis_result_tvalid(less2_tvalid),         // output wire m_axis_result_tvalid
      .m_axis_result_tdata (iou_wire)              // output wire [7 : 0] m_axis_result_tdata
  );

  assign iou_thresh_pass = iou_wire[0];


  // overlap reg
  always @(posedge clk) begin
    overlap <= MinXW_gt_MaxX_p7 & MinYH_gt_MaxY_p7;
  end


  // pred_S_gt_delay
  always @(posedge clk) begin
    pred_S_gt_delay <= pred_S_gt[0];
  end

endmodule
