`timescale 1ns / 1ps


module mult_test(
        input clk,
        input reset,
        input [31:0] data_a,
        input [31:0] data_b,
        output [143:0] data_out,
        output data_valid
    );
    
     cmpy_0 mult_test (
      .aclk(clk),                             // input wire aclk
      .aresetn(~reset),                       // input wire aresetn
      .s_axis_a_tvalid(-1'b1),                   // input wire s_axis_a_tvalid
      .s_axis_a_tdata( {48'd0, data_a} ),                   // input wire [63 : 0] s_axis_a_tdata
      .s_axis_b_tvalid(1'b1),                   // input wire s_axis_b_tvalid
      .s_axis_b_tdata( {48'd0, data_b} ),                   // input wire [63 : 0] s_axis_b_tdata
      .m_axis_dout_tvalid(data_valid),       // output wire m_axis_dout_tvalid
      .m_axis_dout_tdata(data_out)        // output wire [127 : 0] m_axis_dout_tdata
    );
    
endmodule
