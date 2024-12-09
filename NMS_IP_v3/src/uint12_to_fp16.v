module uint12_to_fp16 (
    input  [11:0] uint_in,
    output [15:0] fp16_out
);
  reg [ 4:0] exponent;
  reg [ 9:0] mantissa;
  reg [15:0] temp_result;
  reg [ 3:0] i;


  always @(*) begin
    casex (uint_in)
      12'b1xxxxxxxxxxx: i = 4'd11;
      12'b01xxxxxxxxxx: i = 4'd10;
      12'b001xxxxxxxxx: i = 4'd9;
      12'b0001xxxxxxxx: i = 4'd8;
      12'b00001xxxxxxx: i = 4'd7;
      12'b000001xxxxxx: i = 4'd6;
      12'b0000001xxxxx: i = 4'd5;
      12'b00000001xxxx: i = 4'd4;
      12'b000000001xxx: i = 4'd3;
      12'b0000000001xx: i = 4'd2;
      12'b00000000001x: i = 4'd1;
      12'b000000000001: i = 4'd0;
      default: begin
        i = 4'd0;
      end
    endcase
  end

  always @(*) begin
    // If input is zero
    if (uint_in == 12'b0) begin
      temp_result = 16'b0;
    end else begin
      // Step 1: Find the MSB position



      // Step 2: Calculate exponent
      exponent = i + 15;

      // Step 3: Form the mantissa by shifting uint_in
      if (i > 10) begin
        mantissa = uint_in >> (i - 10);
      end else begin
        mantissa = uint_in << (10 - i);
      end

      // Form the final 16-bit floating point value
      temp_result = {1'b0, exponent, mantissa};
    end
  end

  assign fp16_out = temp_result;

endmodule
