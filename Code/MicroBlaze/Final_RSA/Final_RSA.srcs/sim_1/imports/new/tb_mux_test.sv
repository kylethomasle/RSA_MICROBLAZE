`timescale 1ns / 1ps

module tb_mult_test();
    logic [31:0] data_a, data_b;
    logic [63:0] data_out;
    logic data_valid; 
    logic clk = 0, reset;
    
    mult_test uut( .*); 
    
    always
    #5 clk = ~clk;
    
    initial begin
        data_a = 'd4294967295;
        data_b = 'd4294967295; 
        reset = 1;
        #10 reset = 0; 
    end
endmodule
