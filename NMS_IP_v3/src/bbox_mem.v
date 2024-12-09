module bbox_mem #(
    parameter  BBOX_DATA_WIDTH = 64,
    parameter  BBOX_IND_WIDTH  = 14,
    parameter  MEM_ADDR_WIDTH  = 10,
    localparam TotalDataWidth  = BBOX_IND_WIDTH + BBOX_DATA_WIDTH
) (
    input clk,
    input gen_rst,

    input [TotalDataWidth-1:0] mem_din,
    input [MEM_ADDR_WIDTH-1:0] waddr,
    input                      mem_wren,
    input                      wea,

    output [TotalDataWidth-1:0] mem_dout,
    input  [MEM_ADDR_WIDTH-1:0] raddr,
    input                       mem_ren
);


  integer i;

  reg [TotalDataWidth-1:0] mem[(1 << MEM_ADDR_WIDTH)-1:0];
  reg [TotalDataWidth-1:0] mem_dout_reg;


  initial begin
    for (i = 0; i < (1 << MEM_ADDR_WIDTH); i = i + 1) begin
      mem[i] = {TotalDataWidth{1'b0}};  // Initialize all to zero
    end
  end


  always @(posedge clk) begin
    if (mem_wren) begin
      if (wea) begin
        mem[waddr] <= mem_din;
      end
    end
  end


  always @(posedge clk) begin
    if (mem_ren) begin
      mem_dout_reg <= mem[raddr];
    end
  end

  assign mem_dout = mem_dout_reg;

endmodule
