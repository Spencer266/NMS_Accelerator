`timescale 1ns / 1ps


import axi_vip_pkg::*;
import axi4stream_vip_pkg::*;
import axi_stream_master_vip_pkg::*;
import axi_stream_slave_vip_pkg::*;
import axil_master_vip_pkg::*;

module NMS_Module_IP_tb;

  parameter integer BBOX_DATA_WIDTH = 64;
  parameter integer BBOX_IND_WIDTH = 14;
  parameter integer REG_ADDR_WIDTH = 3;
  parameter integer IOU_THRESH_WIDTH = 16;
  parameter integer MEM_ADDR_WIDTH = 10;
  parameter integer C_M_AXIS_S2MM_DATA_WIDTH = 16;
  // User parameters ends
  // Do not modify the parameters beyond this line


  // Parameters of Axi Slave Bus Interface S_AXIL_CONF
  parameter integer C_S_AXIL_CONF_DATA_WIDTH = 32;
  parameter integer C_S_AXIL_CONF_ADDR_WIDTH = 32;

  // Users to add ports here

  // Ports of NMS_Module core
  bit                                      axi_clk;
  bit                                      axi_resetn;
  bit [    C_M_AXIS_S2MM_DATA_WIDTH-1 : 0] s2mm_tdata;
  bit [  C_M_AXIS_S2MM_DATA_WIDTH/8-1 : 0] s2mm_tkeep;
  bit                                      s2mm_tlast;
  bit                                      s2mm_tready;
  bit                                      s2mm_tvalid;


  // Ports of S_AXIS_PRED_BOX
  bit [             BBOX_DATA_WIDTH-1 : 0] mm2s_tdata;
  bit [           BBOX_DATA_WIDTH/8-1 : 0] mm2s_tkeep;
  bit                                      mm2s_tlast;
  bit                                      mm2s_tready;
  bit                                      mm2s_tvalid;

  // Interrupt signal
  bit                                      done_int;

  // User ports ends
  // Do not modify the ports beyond this line


  // Ports of Axi Slave Bus Interface S_AXIL_CONF
  // bit                                      s_axil_conf_aclk;
  // bit                                      s_axil_conf_aresetn;
  bit [    C_S_AXIL_CONF_ADDR_WIDTH-1 : 0] conf_awaddr;
  bit [                             2 : 0] conf_awprot;
  bit                                      conf_awvalid;
  bit                                      conf_awready;
  bit [    C_S_AXIL_CONF_DATA_WIDTH-1 : 0] conf_wdata;
  bit [(C_S_AXIL_CONF_DATA_WIDTH/8)-1 : 0] conf_wstrb;
  bit                                      conf_wvalid;
  bit                                      conf_wready;
  bit [                             1 : 0] conf_bresp;
  bit                                      conf_bvalid;
  bit                                      conf_bready;
  bit [    C_S_AXIL_CONF_ADDR_WIDTH-1 : 0] conf_araddr;
  bit [                             2 : 0] conf_arprot;
  bit                                      conf_arvalid;
  bit                                      conf_arready;
  bit [    C_S_AXIL_CONF_DATA_WIDTH-1 : 0] conf_rdata;
  bit [                             1 : 0] conf_rresp;
  bit                                      conf_rvalid;
  bit                                      conf_rready;


  bit [      C_S_AXIL_CONF_ADDR_WIDTH-1:0] write_addr;
  bit [      C_S_AXIL_CONF_ADDR_WIDTH-1:0] read_addr;
  bit [      C_S_AXIL_CONF_DATA_WIDTH-1:0] data;

  bit [                              63:0] bbox_data    [28];
  initial begin
bbox_data[0] = {12'h0EF, 12'h092, 12'h01D, 12'h02A, 16'h3881};
bbox_data[1] = {12'h036, 12'h0AC, 12'h06A, 12'h025, 16'h38F6};
bbox_data[2] = {12'h028, 12'h0B3, 12'h045, 12'h035, 16'h3806};
bbox_data[3] = {12'h038, 12'h0B1, 12'h068, 12'h027, 16'h3C00};
bbox_data[4] = {12'h042, 12'h0B2, 12'h062, 12'h026, 16'h3BF3};
bbox_data[5] = {12'h02B, 12'h0BC, 12'h042, 12'h031, 16'h3BAC};
bbox_data[6] = {12'h0CC, 12'h098, 12'h043, 12'h08A, 16'h3B60};
bbox_data[7] = {12'h0D1, 12'h093, 12'h042, 12'h096, 16'h3B17};
bbox_data[8] = {12'h0CE, 12'h092, 12'h040, 12'h0AC, 16'h3BFE};
bbox_data[9] = {12'h0CF, 12'h090, 12'h046, 12'h0AD, 16'h3BFD};
bbox_data[10] = {12'h0C5, 12'h0DD, 12'h01D, 12'h02C, 16'h3A1F};
bbox_data[11] = {12'h0CC, 12'h0A4, 12'h041, 12'h09B, 16'h39A3};
bbox_data[12] = {12'h0FF, 12'h0EF, 12'h013, 12'h032, 16'h3963};
bbox_data[13] = {12'h175, 12'h046, 12'h012, 12'h013, 16'h39B8};
bbox_data[14] = {12'h173, 12'h045, 12'h017, 12'h015, 16'h39D0};
bbox_data[15] = {12'h17E, 12'h044, 12'h00C, 12'h018, 16'h384A};
bbox_data[16] = {12'h17B, 12'h046, 12'h00F, 12'h014, 16'h3AFA};
bbox_data[17] = {12'h0F7, 12'h07A, 12'h007, 12'h00E, 16'h3B15};
bbox_data[18] = {12'h0F9, 12'h097, 12'h014, 12'h020, 16'h3AF1};
bbox_data[19] = {12'h0FA, 12'h09B, 12'h014, 12'h01F, 16'h3BB1};
bbox_data[20] = {12'h0F6, 12'h09C, 12'h01A, 12'h01E, 16'h3891};
bbox_data[21] = {12'h110, 12'h0AD, 12'h005, 12'h00C, 16'h3945};
bbox_data[22] = {12'h115, 12'h0AC, 12'h00F, 12'h00F, 16'h3A96};
bbox_data[23] = {12'h114, 12'h0AB, 12'h013, 12'h010, 16'h3B75};
bbox_data[24] = {12'h113, 12'h0AB, 12'h017, 12'h011, 16'h399C};
bbox_data[25] = {12'h11C, 12'h0AA, 12'h010, 12'h012, 16'h3947};
bbox_data[26] = {12'h125, 12'h0AC, 12'h00A, 12'h012, 16'h3A5C};
bbox_data[27] = {12'h124, 12'h0A9, 12'h00D, 12'h015, 16'h390D};
  end

  axi_stream_master_vip axi_stream_master_vip_inst (
      .aclk         (axi_clk),
      .aresetn      (axi_resetn),
      .m_axis_tvalid(mm2s_tvalid),
      .m_axis_tready(mm2s_tready),
      .m_axis_tdata (mm2s_tdata),
      .m_axis_tkeep (mm2s_tkeep),
      .m_axis_tlast (mm2s_tlast)
  );



  axi_stream_slave_vip axi_stream_slave_vip_inst (
      .aclk         (axi_clk),      // input wire aclk
      .aresetn      (axi_resetn),   // input wire aresetn
      .s_axis_tvalid(s2mm_tvalid),  // input wire [0 : 0] s_axis_tvalid
      .s_axis_tready(s2mm_tready),  // output wire [0 : 0] s_axis_tready
      .s_axis_tdata (s2mm_tdata),   // input wire [15 : 0] s_axis_tdata
      .s_axis_tkeep (s2mm_tkeep),   // input wire [1 : 0] s_axis_tkeep
      .s_axis_tlast (s2mm_tlast)    // input wire [0 : 0] s_axis_tlast
  );



  axil_master_vip axil_master_vip_inst (
      .aclk         (axi_clk),       // input wire aclk
      .aresetn      (axi_resetn),    // input wire aresetn
      .m_axi_awaddr (conf_awaddr),   // output wire [31 : 0] m_axi_awaddr
      .m_axi_awprot (conf_awprot),   // output wire [2 : 0] m_axi_awprot
      .m_axi_awvalid(conf_awvalid),  // output wire m_axi_awvalid
      .m_axi_awready(conf_awready),  // input wire m_axi_awready
      .m_axi_wdata  (conf_wdata),    // output wire [31 : 0] m_axi_wdata
      .m_axi_wstrb  (conf_wstrb),    // output wire [3 : 0] m_axi_wstrb
      .m_axi_wvalid (conf_wvalid),   // output wire m_axi_wvalid
      .m_axi_wready (conf_wready),   // input wire m_axi_wready
      .m_axi_bresp  (conf_bresp),    // input wire [1 : 0] m_axi_bresp
      .m_axi_bvalid (conf_bvalid),   // input wire m_axi_bvalid
      .m_axi_bready (conf_bready),   // output wire m_axi_bready
      .m_axi_araddr (conf_araddr),   // output wire [31 : 0] m_axi_araddr
      .m_axi_arprot (conf_arprot),   // output wire [2 : 0] m_axi_arprot
      .m_axi_arvalid(conf_arvalid),  // output wire m_axi_arvalid
      .m_axi_arready(conf_arready),  // input wire m_axi_arready
      .m_axi_rdata  (conf_rdata),    // input wire [31 : 0] m_axi_rdata
      .m_axi_rresp  (conf_rresp),    // input wire [1 : 0] m_axi_rresp
      .m_axi_rvalid (conf_rvalid),   // input wire m_axi_rvalid
      .m_axi_rready (conf_rready)    // output wire m_axi_rready
  );



  NMS_Module_IP DUT (
      .axi_clk   (axi_clk),
      .axi_resetn(axi_resetn),

      .m_axis_s2mm_tdata (s2mm_tdata),
      .m_axis_s2mm_tkeep (s2mm_tkeep),
      .m_axis_s2mm_tlast (s2mm_tlast),
      .m_axis_s2mm_tready(s2mm_tready),
      .m_axis_s2mm_tvalid(s2mm_tvalid),

      .s_axis_mm2s_tdata (mm2s_tdata),
      .s_axis_mm2s_tkeep (mm2s_tkeep),
      .s_axis_mm2s_tlast (mm2s_tlast),
      .s_axis_mm2s_tready(mm2s_tready),
      .s_axis_mm2s_tvalid(mm2s_tvalid),


      .s_axil_conf_awaddr (conf_awaddr),
      .s_axil_conf_awprot (conf_awprot),
      .s_axil_conf_awvalid(conf_awvalid),
      .s_axil_conf_awready(conf_awready),
      .s_axil_conf_wdata  (conf_wdata),
      .s_axil_conf_wstrb  (conf_wstrb),
      .s_axil_conf_wvalid (conf_wvalid),
      .s_axil_conf_wready (conf_wready),
      .s_axil_conf_bresp  (conf_bresp),
      .s_axil_conf_bvalid (conf_bvalid),
      .s_axil_conf_bready (conf_bready),
      .s_axil_conf_araddr (conf_araddr),
      .s_axil_conf_arprot (conf_arprot),
      .s_axil_conf_arvalid(conf_arvalid),
      .s_axil_conf_arready(conf_arready),
      .s_axil_conf_rdata  (conf_rdata),
      .s_axil_conf_rresp  (conf_rresp),
      .s_axil_conf_rvalid (conf_rvalid),
      .s_axil_conf_rready (conf_rready),

      .done_int(done_int)
  );


  always #3 axi_clk = ~axi_clk;


  axil_master_vip_mst_t       axi_lite_master_agent;
  axi_stream_master_vip_mst_t axi_stream_master_agent;
  axi_stream_slave_vip_slv_t  axi_stream_slave_agent;
  axi4stream_transaction      wr_transaction;
  axi4stream_ready_gen        ready_gen;
  xil_axi_resp_t              resp;
  xil_axi4stream_data_byte    trans_bytes             [8];
  xil_axi4stream_uint         delay;
  integer                     loop_ind;

  initial begin

    // Initialize agents
    axi_lite_master_agent = new("axil_master", NMS_Module_IP_tb.axil_master_vip_inst.inst.IF);
    axi_lite_master_agent.start_master();

    axi_stream_master_agent =
        new("axis_master", NMS_Module_IP_tb.axi_stream_master_vip_inst.inst.IF);
    axi_stream_master_agent.vif_proxy.set_dummy_drive_type(XIL_AXI4STREAM_VIF_DRIVE_NONE);
    axi_stream_master_agent.start_master();
    wr_transaction = axi_stream_master_agent.driver.create_transaction("write transaction");

    axi_stream_slave_agent =
        new("axis_slave", NMS_Module_IP_tb.axi_stream_slave_vip_inst.inst.IF);
    axi_stream_slave_agent.vif_proxy.set_dummy_drive_type(XIL_AXI4STREAM_VIF_DRIVE_NONE);
    axi_stream_slave_agent.vif_proxy.clr_ready();
    axi_stream_slave_agent.start_slave();
    ready_gen = axi_stream_slave_agent.driver.create_ready("ready generation");
    ready_gen.set_ready_policy(XIL_AXI4STREAM_READY_GEN_SINGLE);


    // clock and reset
    axi_clk    = 1;
    axi_resetn = 0;
    repeat (16) @(posedge axi_clk);
    #7;
    axi_resetn = 1;


    // write iou_thresh value to register
    repeat (2) @(posedge axi_clk);
    axi_lite_mst_write(32'h0000_3666, 32'h4);


    // write S thresh value to register
    repeat (2) @(posedge axi_clk);
    axi_lite_mst_write(32'h0000_3800, 32'h8);


    // Initialize first AXI stream transaction
    @(posedge axi_clk);
    fetch_bbox_data(bbox_data[0]);
    send_transaction(trans_bytes);


    // write num_pred and start to register
    repeat (2) @(posedge axi_clk);
    axi_lite_mst_write(32'h0000_001F, 32'h0);


    // Send remaining bbox_data transactions
    for (int loop_ind = 1; loop_ind < 15; loop_ind++) begin
      @(negedge mm2s_tready);
      @(posedge axi_clk);
      fetch_bbox_data(bbox_data[loop_ind]);
      send_transaction(trans_bytes);
    end


    // AXI stream slave recieves transactions
    while (s2mm_tlast == 0) begin
      @(posedge s2mm_tvalid);
      @(posedge axi_clk);
      axi_stream_slave_agent.driver.send_tready(ready_gen);
    end


    // write start = 0 to register when done_int is asserted
    wait (done_int == 1);
    axi_lite_mst_write(32'h0000_0000, 32'h0);

    axi_lite_mst_read(data, 32'hC);

    repeat (10) @(posedge axi_clk);

    $finish;

  end


  task automatic fetch_bbox_data(input bit [63:0] bbox);
    integer i;
    for (i = 0; i < 8; i++) begin
      trans_bytes[i] = bbox[i*8+:8];
    end
  endtask : fetch_bbox_data


  task automatic send_transaction(input xil_axi4stream_data_byte data_bytes[8]);
    WR_TRANSACTION_RAND_FAIL : assert (wr_transaction.randomize());
    wr_transaction.set_data(data_bytes);
    wr_transaction.set_delay(0);
    wr_transaction.set_last(1'b0);

    axi_stream_master_agent.driver.send(wr_transaction);
  endtask : send_transaction



  task automatic axi_lite_mst_write(input bit [C_S_AXIL_CONF_DATA_WIDTH-1:0] wr_data,
                                    input bit [C_S_AXIL_CONF_ADDR_WIDTH-1:0] wr_addr);
    write_addr = wr_addr;
    data       = wr_data;
    axi_lite_master_agent.AXI4LITE_WRITE_BURST(write_addr, 0, data, resp);
  endtask : axi_lite_mst_write


  task automatic axi_lite_mst_read(output bit [C_S_AXIL_CONF_DATA_WIDTH-1:0] rd_data,
                                   input  bit [C_S_AXIL_CONF_ADDR_WIDTH-1:0] rd_addr);
    read_addr = rd_addr;
    axi_lite_master_agent.AXI4LITE_READ_BURST(read_addr, 0, rd_data, resp);
  endtask : axi_lite_mst_read

endmodule
