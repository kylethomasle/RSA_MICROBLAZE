`timescale 1ns / 1ps

module tb_mod_custom();

    parameter WIDTH = 64;
    logic [WIDTH-1:0] a,n;
    logic [WIDTH-1:0] r,q;
    logic clk = 0, reset, en;
    logic done; 
    
    mod_custom #( .WIDTH(WIDTH) )
        uut
    (
        .a(a),
        .n(n),
        .clk(clk),
        .reset(reset),
        .en(en),
        .R(r),
        .Q(q),
        .done(done)
    );
    
    always
        #5 clk = ~clk; 
    
    initial begin
        reset = 1; 
        a = 129203;
        n = 22;
        #20 reset = 0; en = 1; 
    end
        
endmodule