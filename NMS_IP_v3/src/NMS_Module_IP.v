
`timescale 1 ns / 1 ps

module NMS_Module_IP #(
    // Users to add parameters here
    parameter integer BBOX_DATA_WIDTH          = 64,
    parameter integer BBOX_IND_WIDTH           = 14,
    parameter integer REG_ADDR_WIDTH           = 4,
    parameter integer IOU_THRESH_WIDTH         = 16,
    parameter integer MEM_ADDR_WIDTH           = 10,
    parameter integer C_M_AXIS_S2MM_DATA_WIDTH = 16,
    // User parameters ends
    // Do not modify the parameters beyond this line


    // Parameters of Axi Slave Bus Interface S_AXIL_CONF
    parameter integer C_S_AXIL_CONF_DATA_WIDTH = 32,
    parameter integer C_S_AXIL_CONF_ADDR_WIDTH = 32
) (
    // Users to add ports here

    // Ports of NMS_Module core
    input  wire                                    axi_clk,
    input  wire                                    axi_resetn,
    output wire [  C_M_AXIS_S2MM_DATA_WIDTH-1 : 0] m_axis_s2mm_tdata,
    output wire [C_M_AXIS_S2MM_DATA_WIDTH/8-1 : 0] m_axis_s2mm_tkeep,
    output wire                                    m_axis_s2mm_tlast,
    input  wire                                    m_axis_s2mm_tready,
    output wire                                    m_axis_s2mm_tvalid,


    // Ports of S_AXIS_PRED_BOX
    input  wire [  BBOX_DATA_WIDTH-1 : 0] s_axis_mm2s_tdata,
    input  wire [BBOX_DATA_WIDTH/8-1 : 0] s_axis_mm2s_tkeep,
    input  wire                           s_axis_mm2s_tlast,
    output wire                           s_axis_mm2s_tready,
    input  wire                           s_axis_mm2s_tvalid,

    // Interrupt signal
    output wire done_int,

    // User ports ends
    // Do not modify the ports beyond this line


    // Ports of Axi Slave Bus Interface S_AXIL_CONF
    // input  wire                                      s_axil_conf_aclk,
    // input  wire                                      s_axil_conf_aresetn,
    input  wire [    C_S_AXIL_CONF_ADDR_WIDTH-1 : 0] s_axil_conf_awaddr,
    input  wire [                             2 : 0] s_axil_conf_awprot,
    input  wire                                      s_axil_conf_awvalid,
    output wire                                      s_axil_conf_awready,
    input  wire [    C_S_AXIL_CONF_DATA_WIDTH-1 : 0] s_axil_conf_wdata,
    input  wire [(C_S_AXIL_CONF_DATA_WIDTH/8)-1 : 0] s_axil_conf_wstrb,
    input  wire                                      s_axil_conf_wvalid,
    output wire                                      s_axil_conf_wready,
    output wire [                             1 : 0] s_axil_conf_bresp,
    output wire                                      s_axil_conf_bvalid,
    input  wire                                      s_axil_conf_bready,
    input  wire [    C_S_AXIL_CONF_ADDR_WIDTH-1 : 0] s_axil_conf_araddr,
    input  wire [                             2 : 0] s_axil_conf_arprot,
    input  wire                                      s_axil_conf_arvalid,
    output wire                                      s_axil_conf_arready,
    output wire [    C_S_AXIL_CONF_DATA_WIDTH-1 : 0] s_axil_conf_rdata,
    output wire [                             1 : 0] s_axil_conf_rresp,
    output wire                                      s_axil_conf_rvalid,
    input  wire                                      s_axil_conf_rready
);
  
  wire                                num_box_wren_wire;
  wire [C_S_AXIL_CONF_DATA_WIDTH-1:0] num_box_data_wire;

  // Instantiation of Axi Bus Interface S_AXIL_CONF
  S_AXIL_CONF #(
      .C_S_AXI_DATA_WIDTH(C_S_AXIL_CONF_DATA_WIDTH),
      .C_S_AXI_ADDR_WIDTH(C_S_AXIL_CONF_ADDR_WIDTH)
  ) S_AXIL_CONF_inst (
      .S_AXI_ACLK   (axi_clk),
      .S_AXI_ARESETN(axi_resetn),
      .S_AXI_AWADDR (s_axil_conf_awaddr),
      .S_AXI_AWPROT (s_axil_conf_awprot),
      .S_AXI_AWVALID(s_axil_conf_awvalid),
      .S_AXI_AWREADY(s_axil_conf_awready),
      .S_AXI_WDATA  (s_axil_conf_wdata),
      .S_AXI_WSTRB  (s_axil_conf_wstrb),
      .S_AXI_WVALID (s_axil_conf_wvalid),
      .S_AXI_WREADY (s_axil_conf_wready),
      .S_AXI_BRESP  (s_axil_conf_bresp),
      .S_AXI_BVALID (s_axil_conf_bvalid),
      .S_AXI_BREADY (s_axil_conf_bready),
      .S_AXI_ARADDR (s_axil_conf_araddr),
      .S_AXI_ARPROT (s_axil_conf_arprot),
      .S_AXI_ARVALID(s_axil_conf_arvalid),
      .S_AXI_ARREADY(s_axil_conf_arready),
      .S_AXI_RDATA  (s_axil_conf_rdata),
      .S_AXI_RRESP  (s_axil_conf_rresp),
      .S_AXI_RVALID (s_axil_conf_rvalid),
      .S_AXI_RREADY (s_axil_conf_rready),
      .num_box_data (num_box_data_wire),
      .num_box_wren (num_box_wren_wire)
  );

  // Add user logics here

  wire reset = ~axi_resetn;
  wire reg_ren_logic_wire = s_axil_conf_wready & s_axil_conf_wvalid;
  

  wire                       pbox_ready_wire;
  wire [BBOX_DATA_WIDTH-1:0] pred_bbox_data_wire;
  
  wire [ BBOX_IND_WIDTH-1:0] bbox_index_wire;



  assign m_axis_s2mm_tdata = {
    {(C_M_AXIS_S2MM_DATA_WIDTH - BBOX_IND_WIDTH) {1'b0}}, bbox_index_wire
  };
  assign m_axis_s2mm_tkeep = {(C_M_AXIS_S2MM_DATA_WIDTH / 8) {1'b1}};

  // NMS_Module module core
  NMS_Module NMS_Module_inst (
      .clk   (axi_clk),
      .resetn(reset),

      .pbox_ready    (pbox_ready_wire),
      .pred_bbox_data(pred_bbox_data_wire),
      .reg_ren       (reg_ren_logic_wire),
      .reg_data      (s_axil_conf_wdata),
      .reg_addr      (s_axil_conf_awaddr[REG_ADDR_WIDTH-1:0]),
      .num_box_data  (num_box_data_wire),
      .num_box_wren  (num_box_wren_wire),

      .tvalid    (m_axis_s2mm_tvalid),
      .tlast     (m_axis_s2mm_tlast),
      .tready    (m_axis_s2mm_tready),
      .bbox_index(bbox_index_wire),

      .done_int(done_int)
  );


  // S_AXIS_PRED_BOX interface Instantiation
  S_AXIS_PRED_BOX #(
      .BBOX_DATA_WIDTH(BBOX_DATA_WIDTH)
  ) S_AXIS_PRED_BOX_inst (
      .s_axis_mm2s_tdata (s_axis_mm2s_tdata),
      .s_axis_mm2s_tkeep (s_axis_mm2s_tkeep),
      .s_axis_mm2s_tlast (s_axis_mm2s_tlast),
      .s_axis_mm2s_tready(s_axis_mm2s_tready),
      .s_axis_mm2s_tvalid(s_axis_mm2s_tvalid),

      .pbox_ready    (pbox_ready_wire),
      .pred_bbox_data(pred_bbox_data_wire)
  );

  // User logic ends

endmodule
