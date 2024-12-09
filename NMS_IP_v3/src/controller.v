module controller (
    input clk,
    input resetn,

    input  start,
    output pbox_ren,

    input i_lt_num_pred,
    input iter_eq_last,
    input delay_eq_8,
    input iter_eq_lstMinus1,
    input S_under_thresh,
    input overlap,

    output delay_rst,
    output delay_en,
    output bbox_iter_rst,
    output bbox_iter_en,
    output bbox_last_en,
    output i_counter_en,
    output wea,

    input iou_thresh_pass,
    input pred_S_gt_delay,

    output bbox_mem_wren,
    output bbox_mem_ren,
    output num_box_wren,

    input  tready,
    output tvalid,
    output tlast,
    output done_int,

    output gen_rst
);

  // State encoding (binary encode)
  parameter SR = 5'd20;
  parameter S0 = 5'd0;
  parameter S1 = 5'd1;
  parameter S2 = 5'd2;
  parameter S3 = 5'd3;
  parameter S4 = 5'd4;
  parameter S5 = 5'd5;
  parameter S6 = 5'd6;
  parameter S7 = 5'd7;
  parameter S8 = 5'd8;
  parameter S9 = 5'd9;
  parameter S10 = 5'd10;
  parameter S11 = 5'd11;
  parameter S12 = 5'd12;
  parameter S13 = 5'd13;
  parameter S14 = 5'd14;
  parameter S15 = 5'd15;
  parameter S16 = 5'd16;
  parameter S17 = 5'd17;
  parameter S18 = 5'd18;
  parameter S19 = 5'd19;


  reg [4:0] state = SR;

  always @(posedge clk) begin
    if (resetn) begin
      state <= SR;
    end else begin
      case (state)
        SR:  state <= S0;
        S0:  state <= S1;
        S1: begin
          if (start) begin
            state <= S2;
          end else begin
            state <= S1;
          end
        end
        S2:  state <= S3;
        S3:  state <= S4;
        S4: begin
          if (i_lt_num_pred) begin
            state <= S5;
          end else begin
            state <= S13;
          end
        end
        S5: begin
          if (S_under_thresh) begin
            state <= S12;
          end else begin
            state <= S6;
          end
        end
        S6: begin
          if (iter_eq_last) begin
            state <= S11;
          end else begin
            state <= S7;
          end
        end
        S7: begin
          if (delay_eq_8) begin
            state <= S8;
          end else begin
            state <= S7;
          end
        end
        S8: begin
          if (iter_eq_last) begin
            state <= S11;
          end else begin
            if (iou_thresh_pass & overlap) begin
              state <= S9;
            end else begin
              state <= S8;
            end
          end
        end
        S9: begin
          if (pred_S_gt_delay) begin
            state <= S10;
          end else begin
            state <= S12;
          end
        end
        S10: state <= S12;
        S11: state <= S12;
        S12: state <= S3;
        S13: state <= S14;
        S14: begin
          if (iter_eq_last) begin
            state <= S18;
          end else begin
            state <= S15;
          end
        end
        S15: state <= S16;
        S16: begin
          if (tready) begin
            state <= S17;
          end else begin
            state <= S16;
          end
        end
        S17: state <= S14;
        S18: state <= S19;
        S19: begin
          if (start) begin
            state <= S19;
          end else begin
            state <= SR;
          end
        end
        default: begin
          state <= SR;
        end
      endcase
    end
  end



  assign gen_rst       = state == SR;
  assign pbox_ren      = state == S3;

  assign bbox_mem_ren  = ((state > S1) & (state < S13)) | (state == S15);

  assign delay_en      = state == S3 | state == S4 | state == S5 | state == S6 | state == S7;
  assign bbox_iter_en  = state == S8 | state == S17;
  assign bbox_mem_wren = state == S10 | state == S11;
  assign bbox_last_en  = state == S11;
  assign i_counter_en  = state == S12;
  assign bbox_iter_rst = state == S12;
  assign delay_rst     = state == S12 | state == S13;
  assign tvalid        = state == S16;
  assign done_int      = state == S19;
  assign tlast         = iter_eq_lstMinus1;
  assign wea           = bbox_mem_wren;
  assign num_box_wren  = state == S18;

endmodule
