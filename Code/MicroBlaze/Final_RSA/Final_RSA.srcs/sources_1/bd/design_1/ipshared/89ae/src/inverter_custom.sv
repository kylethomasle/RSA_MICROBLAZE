// PROJECT: ECE 4300 RSA Microblaze Implementation
//
// FILENAME: inverter_custom.sv         
// CREATED BY: Kyle Thomas Le 
// CREATED ON: 11/16/2020                                                  
//                                                                             
// DESCRIPTION: Using two prime numbers calculate the encryption
// and decryption key. The encryption key is the lowest value that 
// is a coprime with the totient. Both the encryption key and 
// decryption key are calculated using a modified extended Euclidean
// algorithm. 
//
// TODO: 
//  * Allow the user to input their own encryption key (coprime)

`timescale 1ns / 1ps

module inverter_custom
    #(parameter WIDTH = 32)
    (
        input i_clk,                  // Module clock  
        input i_reset,                // Reset
        input i_en,                   // Enable 
        input [WIDTH-1 : 0] i_p,      // Prime number 1
        input [WIDTH-1 : 0] i_q,      // Prime number 2

        output [(WIDTH*2)-1 : 0] o_e, // Encryption key
        output [(WIDTH*2)-1 : 0] o_d, // Decryption key
        output o_finish               // Indicates operation has finished
    );
    
    // State declaration  
    localparam 
        INITIALIZE = 4'd1,
        TOTIENT_MULT = 4'd2,
        UPDATING = 4'd3,
        XY_MOD = 4'd4,
        Y_MULT = 4'd5,
        CHECK = 4'd6,
        FINISH = 4'd7; 

    // Logic delcaration
    logic [3:0] state, state_next; 
    logic [(WIDTH*2)-1 : 0] totient, totient_next;
    logic [(WIDTH*2)-1 : 0] y_prev, y_prev_next; 
    logic [(WIDTH*2)-1 : 0] decrypt, decrypt_next; 
    logic [WIDTH-1 : 0] e_reg, e_reg_next; 
    logic [WIDTH-1 : 0] e_plus3; 
    logic [(WIDTH*2)-1 : 0] a, a_next;
    logic [(WIDTH*2)-1 : 0] b, b_next;
    logic [(WIDTH*2)-1 : 0] y, y_next; 
    
    // Output logic 
    assign o_finish = (state == FINISH); 
    assign e_plus3 = e_reg + 2;  
    assign o_e = e_reg;
    assign o_d = decrypt; 



     
///// Find quotient and remainder of next values in Euclidean algorithm
    logic [(WIDTH*2)-1 : 0] b_remain; 
    logic [(WIDTH*2)-1 : 0] quotient; 
    logic x_mod_y_done;
    logic x_mod_y_en;  
    
    assign x_mod_y_en = (state == XY_MOD); 
    
    mod_custom #(.WIDTH( WIDTH*2 ) )
        x_mod_y  
    (
        .clk(i_clk),
        .reset(i_reset), 
        .dividend(a),
        .divisor(b),
        .en(x_mod_y_en),
        .remainder(b_remain),
        .quotient(quotient),
        .done(x_mod_y_done)
    ); 
     
     
     
     
     
///// Totient multiplication module (p-1) * (q-1)
    logic [(WIDTH*2)-1 : 0] totient_result; 
    logic totient_valid; 
    logic totient_rstn;
    
    // Reset state must be held for at least two clock cycles! 
    assign totient_rstn = ~(i_reset || state != TOTIENT_MULT); 
    
    cmpy_0 totient_mult (
      .aclk(i_clk),                             // input clk
      .aresetn(totient_rstn),                   // input reset (negative edged)
      .s_axis_a_tvalid(1'b1),                   // input A valid (always asserted)
      .s_axis_a_tdata( {73'd0, i_p-1} ),        // input A data [72 : 0] ( IMAG(72:40), REAL(32:0) ) 
      .s_axis_b_tvalid(1'b1),                   // input B valid (always asserted)
      .s_axis_b_tdata( {73'd0, i_q-1 } ),       // input B data [72 : 0] ( IMAG(72:40), REAL(32:0) ) 
      .m_axis_dout_tvalid(totient_valid),       // output valid (held until reset) 
      .m_axis_dout_tdata(totient_result)        // output data [138 : 0] ( IMAG(138:72), REAL(66:0) ) 
    );
    
///// Y_next multiplication module
    logic [(WIDTH*2)-1 : 0] y_result; 
    logic y_valid; 
    logic y_resetn;
    
    // Reset state must be held for at least two clock cycles! 
    assign y_resetn = ~(i_reset || state != Y_MULT);
    
    cmpy_0 y_mult
    (
      .aclk(i_clk),                                             // input clk
      .aresetn(y_resetn),                                       // input reset (negative edged)
      .s_axis_a_tvalid(1'b1),                                   // input A valid (always asserted)
      .s_axis_a_tdata({73'd0, quotient[2*WIDTH-1], quotient}),  // input A data [72 : 0] ( IMAG(72:40), REAL(32:0) )         
      .s_axis_b_tvalid(1'b1),                                   // input B valid (always asserted)
      .s_axis_b_tdata({73'd0, y[2*WIDTH-1], y}),                // input B data [72 : 0] ( IMAG(72:40), REAL(32:0) ) 
      .m_axis_dout_tvalid(y_valid),                             // output valid (held until reset) 
      .m_axis_dout_tdata(y_result)                              // output data [138 : 0] ( IMAG(138:72), REAL(66:0) ) 
    );
 
 
 
 
 
///// State machine logic   
    always_ff@ ( posedge i_clk ) begin
        if( i_reset ) begin
            state <= INITIALIZE; 
            totient <= 0;
            a <= 0;
            b <= 3;
            e_reg <= 3;
            y <= 1;
            y_prev <= 0; 
            decrypt <= 0;
        end  
        else begin
            state <= state_next;
            totient <= totient_next;
            a <= a_next;
            b <= b_next;
            e_reg <= e_reg_next;
            y <= y_next;
            y_prev <= y_prev_next; 
            decrypt <= decrypt_next; 
        end
    end
    
    always_comb begin
        state_next = state;
        totient_next = totient;
        a_next = a;
        b_next = b;
        e_reg_next = e_reg;
        y_next = y;
        y_prev_next = y_prev;
        decrypt_next = decrypt;   
        
        case( state )
            INITIALIZE: begin                       // INITIALIZE: Waiting for enable
                if( i_en ) begin
                    state_next = TOTIENT_MULT;
                    totient_next = 0;
                    a_next = 0;
                    b_next = 3;
                    e_reg_next = 3;
                    y_next = 1;
                    y_prev_next = 0; 
                end
                else begin
                    state_next = INITIALIZE; 
                end
            end
            TOTIENT_MULT: begin                     // TOTIENT_MULT: Waiting for calculation of Totient
                if( totient_valid ) begin
                    state_next = UPDATING;
                    totient_next = totient_result; 
                    a_next = totient_result; 
                end
                else begin
                    state_next = TOTIENT_MULT;
                end
            end
            UPDATING: begin                         // UPDATING: Check if Euclidean Algorithm finished, else mod and repeat step again
                if ( b == 64'd0 ) begin
                    state_next = CHECK;
                end
                else begin
                    state_next = XY_MOD;
                end
            end
            XY_MOD: begin                           // XY_MOD: Waiting for modulus
                if( x_mod_y_done ) begin
                    state_next = Y_MULT;
                end 
                else begin
                    state_next = XY_MOD; 
                end
            end
            Y_MULT: begin                           // Y_MULT: Wait for multiplication to finish and repeat Euclidean algorithm step
                if( y_valid ) begin
                    state_next = UPDATING; 
                    a_next = b;
                    b_next = b_remain;
                    y_next = y_prev - y_result; 
                    y_prev_next = y; 
                end
                else begin
                    state_next = Y_MULT;
                end 
            end
            CHECK: begin                            // CHECK: Check if Euclidean Algorithm produced a GCD of 1,            
                if ( a==64'd1 ) begin               // else increase e to next odd number and run again. 
                    state_next = FINISH;
                end
                else begin
                    state_next = UPDATING;
                    a_next = totient; 
                    b_next = e_plus3;
                    e_reg_next = e_plus3;
                    y_next = 1;
                    y_prev_next = 0;
                end
            end
            FINISH: begin                       // If GCD produced by Euclidean Algorithm is 1, use y values to find d 
                state_next = INITIALIZE; 
                decrypt_next = (y_prev[2*WIDTH-1]) ? (y + y_prev) : y_prev;
            end
            
        endcase
    end
   
    
endmodule
