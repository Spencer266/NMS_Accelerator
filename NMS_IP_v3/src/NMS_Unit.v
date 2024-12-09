module NMS_Unit #(
    parameter BBOX_IND_WIDTH = 14,
    parameter MEM_ADDR_WIDTH = 10,
    parameter DELAY_WIDTH    = 4,
    parameter S_WIDTH        = 16
) (
    input clk,
    input gen_rst,

    input delay_rst,
    input delay_en,
    input bbox_iter_rst,
    input bbox_iter_en,
    input bbox_last_en,
    input i_counter_en,

    input [BBOX_IND_WIDTH-1:0] num_pred,
    input [       S_WIDTH-1:0] S_thresh,
    input [       S_WIDTH-1:0] pred_bbox_S,

    output i_lt_num_pred,
    output iter_eq_last,
    output delay_eq_8,
    output iter_eq_lstMinus1,
    output S_under_thresh,

    output [BBOX_IND_WIDTH-1:0] i_counter,
    output [MEM_ADDR_WIDTH-1:0] bbox_raddr,
    output [MEM_ADDR_WIDTH-1:0] bbox_waddr
);

  wire [MEM_ADDR_WIDTH-1:0] bbox_iter;
  wire [MEM_ADDR_WIDTH-1:0] bbox_last;
  wire [   DELAY_WIDTH-1:0] delay;
  wire                      bbox_iter_final_rst;
  wire                      delay_final_rst;


  reg  [MEM_ADDR_WIDTH-1:0] bbox_iter_delay = {MEM_ADDR_WIDTH{1'b0}};


  assign delay_final_rst     = gen_rst | delay_rst;
  assign bbox_iter_final_rst = gen_rst | bbox_iter_rst;


  counter #(
      .CNT_WIDTH(MEM_ADDR_WIDTH)
  ) bbox_iter_counter (
      .clk   (clk),
      .resetn(bbox_iter_final_rst),
      .en    (bbox_iter_en),
      .val   (bbox_iter)
  );


  counter #(
      .CNT_WIDTH(MEM_ADDR_WIDTH)
  ) bbox_last_counter (
      .clk   (clk),
      .resetn(gen_rst),
      .en    (bbox_last_en),
      .val   (bbox_last)
  );


  counter #(
      .CNT_WIDTH(BBOX_IND_WIDTH)
  ) i_counter_counter (
      .clk   (clk),
      .resetn(gen_rst),
      .en    (i_counter_en),
      .val   (i_counter)
  );


  counter #(
      .CNT_WIDTH(DELAY_WIDTH)
  ) delay_counter (
      .clk   (clk),
      .resetn(delay_final_rst),
      .en    (delay_en),
      .val   (delay)
  );


  // bbox_iter_delay register
  always @(posedge clk) begin
    if (gen_rst) begin
      bbox_iter_delay <= 0;
    end else begin
      if (bbox_iter_en) begin
        bbox_iter_delay <= bbox_iter;
      end
    end
  end


  // S_under_thresh
  float16_gt_comparator S_thresh_gt_inst (
      .a     (S_thresh),
      .b     (pred_bbox_S),
      .a_gt_b(S_under_thresh)
  );


  assign i_lt_num_pred     = i_counter < num_pred;
  assign iter_eq_last      = bbox_iter == bbox_last;
  assign delay_eq_8        = delay == 4'd8;
  assign iter_eq_lstMinus1 = bbox_iter == (bbox_last - 1);
  assign bbox_raddr        = bbox_iter + delay;
  assign bbox_waddr        = bbox_iter_delay;

endmodule
