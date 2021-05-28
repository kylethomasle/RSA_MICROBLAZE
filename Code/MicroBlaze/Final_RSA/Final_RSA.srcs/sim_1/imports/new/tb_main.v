`timescale 1ns / 1ps

module tb_main;
    localparam WIDTH = 32;      // Input width

    // Inputs
    reg [WIDTH-1:0] i_p, i_q;
    reg clk = 0;
    reg reset = 0;
    reg reset1 = 0; 
    reg go = 0;
    reg i_mode;
    reg i_encrypt_decrypt;
    reg [WIDTH-1:0] i_msg;
    reg [WIDTH*2-1:0] i_key;
    reg [WIDTH*2-1:0] i_n;
    // Outputs
    wire [2*WIDTH-1:0] o_msg;
    wire [2*WIDTH-1:0] o_encrypt;
    wire [2*WIDTH-1:0] o_decrypt;
    wire [2*WIDTH-1:0] o_n; 
    wire [31:0] clk_count; 
    wire mod_exp_finish;
   
    // Instantiate test module 
    RSA_Top #( .WIDTH(WIDTH) )
     uut (
        // Inputs
        .i_p(i_p),
        .i_q(i_q),
        .go(go),
        .clk(clk),
        .reset(reset),
        .reset1(reset1),
        .i_mode(i_mode), 
        .i_encrypt_decrypt(i_encrypt_decrypt),
        .i_msg(i_msg),
        .i_key(i_key),
        .i_n(i_n), 
        // Outputs
        .o_msg(o_msg),
        .o_encrypt(o_encrypt),
        .o_decrypt(o_decrypt), 
        .o_n(o_n), 
        .counter(clk_count), 
        .mod_exp_finish(mod_exp_finish)
     );
    
    always 
        #5 clk = ~clk;
    
    initial begin
        go = 0; 
        //i_p = 32'd13;
        //i_q = 32'd11;
//        i_mode = 1; 
//        i_encrypt_decrypt = 1;
        //i_msg = 32'd9 ; 
        i_n = 'd143; 
        i_msg = 'd9; 
        i_mode = 0;
        //i_encrypt_decrypt = 1; 
        i_key = 'd7; 
        #10 reset = 1;
        #10 reset = 0;
        #10 go = 1;
        #49800 $finish;
    end
    
    initial begin 
        #1000 reset1 = 1;
        #10 reset1 = 0;
        #4980000 go = 0; $finish; 
    end
    
endmodule
