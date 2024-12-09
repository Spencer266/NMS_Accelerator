module S_AXIS_PRED_BOX #(
  parameter BBOX_DATA_WIDTH = 64
) (
  input [BBOX_DATA_WIDTH-1:0] s_axis_mm2s_tdata,
  input [BBOX_DATA_WIDTH/8-1:0] s_axis_mm2s_tkeep,
  input s_axis_mm2s_tlast,
  output s_axis_mm2s_tready,
  input s_axis_mm2s_tvalid,

  input pbox_ready,
  output [BBOX_DATA_WIDTH-1:0] pred_bbox_data
);

  assign s_axis_mm2s_tready = pbox_ready;
  assign pred_bbox_data = s_axis_mm2s_tdata;


  // Additional logic
  (* keep="soft" *)
  wire s_axis_mm2s_tkeep_wire;
  
  (* keep="soft" *)
  wire s_axis_mm2s_tlast_wire;
  
  (* keep="soft" *)
  wire s_axis_mm2s_tvalid_wire;
  
  assign s_axis_mm2s_tkeep_wire = s_axis_mm2s_tkeep;
  assign s_axis_mm2s_tlast_wire = s_axis_mm2s_tlast;
  assign s_axis_mm2s_tvalid_wire = s_axis_mm2s_tvalid;

endmodule
