module counter #(
    parameter CNT_WIDTH = 8,
    localparam MaxVal   = (1 << CNT_WIDTH) - 1,
    localparam ResetVal   = {CNT_WIDTH{1'b0}}
) (
    input                  clk,
    input                  resetn,
    input                  en,
    output [CNT_WIDTH-1:0] val
);

  reg  [CNT_WIDTH-1:0] cnt_reg = {CNT_WIDTH{1'b0}};
  wire                 maxed_val = cnt_reg == MaxVal;


  always @(posedge clk) begin
    if (resetn) begin
      cnt_reg <= ResetVal;
    end else begin
      if (en) begin
        cnt_reg <= (maxed_val) ? {CNT_WIDTH{1'b0}} : cnt_reg + 1;
      end
    end
  end

  assign val = cnt_reg;
endmodule

