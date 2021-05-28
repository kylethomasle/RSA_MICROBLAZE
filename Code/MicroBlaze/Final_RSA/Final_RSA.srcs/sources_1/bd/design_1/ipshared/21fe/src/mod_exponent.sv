// PROJECT: ECE 4300 RSA Microblaze Implementation
//
// FILENAME: mod_exponent.sv         
// CREATED BY: Kyle Thomas Le 
// CREATED ON: 11/16/2020                                                  
//                                                                             
// DESCRIPTION: Modular exponentiation which uses right to left
// binarny exponentiation to find the remainder when the base 
// is raised to the exponent and modulo'd with n (p * q).
// i.e. Calculate a^b mod n 
//
// TODO: 
//  * Change input to be n and not p and q (since this removes the 
//    general usage of the module), sections of code need to be 
//    removed for this
//  * Fix variable naming to better reflect what they are doing

`timescale 1ns / 1ps

module mod_exponent
    #(parameter WIDTH = 32 )
    (
    input i_clk,                        // Module clk
	input i_reset,                      // Reset 
	input i_en,                         // Enable 
    input [WIDTH-1 : 0] i_p,            // Prime number 1
    input [WIDTH-1 : 0] i_q,            // Prime number 2 
    input [WIDTH-1 :0]  i_base,         // Base (represents a)  
	input [WIDTH*2-1:0] i_exponent,     // Exponent (represents b)
	
    output [WIDTH*2-1:0] o_result,       // Result of calculation
    output o_finish                    // Indicated operation has finished
    );
    
    // State declaration  
    localparam 
        INITIALIZE = 3'd0,
        MODULO_MULT = 3'd1,
        UPDATE = 3'd2,
        DUAL_MOD_MULT = 3'd3,
        DUAL_MOD = 3'd4,
        FINISH = 3'd5;
    
    // Logic declaration    
    logic [2:0] state, state_next;  
    logic [WIDTH-1 : 0] base, base_next;
    logic [WIDTH*2-1 : 0] exponent, exponent_next; 
    logic [WIDTH*2-1 : 0] modulo, modulo_next; 
    logic [WIDTH*2-1 : 0] result, result_next;
    
    // Output logic 
    assign o_finish = (state == FINISH); 
    assign o_result = result;




    
///// Base squared multiplication module
    logic [(WIDTH*2)-1 : 0] base_squared_result; 
    logic base_squared_valid; 
    logic base_squared_resetn;
    
    // Reset state must be held for at least two clock cycles! 
    assign base_squared_resetn = ~(i_reset || state != DUAL_MOD_MULT);
    
    // 32-bit signed multiplier to find base squared 
    // Complex Multiplier IP provided by Xilinx uses AXI bus
    cmpy_0 base_squared_mult
    (
      .aclk(i_clk),                              // input clk
      .aresetn(base_squared_resetn),             // input reset (negative edged)
      .s_axis_a_tvalid(1'b1),                    // input A valid (always asserted)
      .s_axis_a_tdata({73'd0, base}),              // input A data [72 : 0] ( IMAG(72:40), REAL(32:0) ) 
      .s_axis_b_tvalid(1'b1),                    // input B valid (always asserted)
      .s_axis_b_tdata({73'd0, base}),              // input B data [72 : 0] ( IMAG(72:40), REAL(32:0) ) 
      .m_axis_dout_tvalid(base_squared_valid),   // output valid (held until reset) 
      .m_axis_dout_tdata(base_squared_result)    // output data [138 : 0] ( IMAG(138:72), REAL(66:0) ) 
    );

///// Result Mul multiplication module
    logic [(WIDTH*2)-1 : 0] result_mul_result; 
    logic result_mul_valid; 
    logic result_mul_resetn;
    
    // Reset state must be held for at least two clock cycles!
    assign result_mul_resetn = ~(i_reset || state != DUAL_MOD_MULT);
    
    // 32-bit signed multiplier to find base * modulus 
    // Complex Multiplier IP provided by Xilinx uses AXI bus
    cmpy_0 result_mul_mult
    (
      .aclk(i_clk),                              // input clk
      .aresetn(result_mul_resetn),               // input reset (negative edged)
      .s_axis_a_tvalid(1'b1),                    // input A valid (always asserted)
      .s_axis_a_tdata({73'd0, result}),            // input A data [72 : 0] ( IMAG(72:40), REAL(32:0) ) 
      .s_axis_b_tvalid('b1),                    // input B valid (always asserted)
      .s_axis_b_tdata({73'd0, base}),              // input B data [72 : 0] ( IMAG(72:40), REAL(32:0) ) 
      .m_axis_dout_tvalid(result_mul_valid),     // output valid (held until reset) 
      .m_axis_dout_tdata(result_mul_result)      // output data [138 : 0] ( IMAG(138:72), REAL(66:0) )
    );    

///// Modulo multiplication module ( calculate modulo (n) using inputs p and q, this is unique to RSA ) 
    logic [(WIDTH*2)-1 : 0] modulo_result; 
    logic modulo_valid; 
    logic modulo_resetn;
    
    assign modulo_resetn = ~(i_reset || state != MODULO_MULT);
    
    cmpy_0 modulo_mult
    (
      .aclk(i_clk),                              // input clk
      .aresetn(modulo_resetn),                   // input reset (negative edged)
      .s_axis_a_tvalid(1'b1),                    // input A valid (always asserted)
      .s_axis_a_tdata({73'd0, i_p}),             // input A data [72 : 0] ( IMAG(72:40), REAL(32:0) ) 
      .s_axis_b_tvalid(1'b1),                    // input B valid (always asserted)
      .s_axis_b_tdata({73'd0, i_q}),             // input B data [72 : 0] ( IMAG(72:40), REAL(32:0) ) 
      .m_axis_dout_tvalid(modulo_valid),         // output valid (held until reset) 
      .m_axis_dout_tdata(modulo_result)          // output data [138 : 0] ( IMAG(138:72), REAL(66:0) )
    );





///// Base squared modulo with N   
    logic [WIDTH*2-1 : 0] base_remain; 
    logic base_mod_done; 
    logic base_mod_en; 
    
    assign base_mod_en = (state == DUAL_MOD); 
   
    mod_custom #( .WIDTH(WIDTH*2) ) 
        base_squared_mod
    (
        .clk(i_clk),
        .reset(i_reset),
        .en(base_mod_en),
        .dividend(base_squared_result),
        .divisor(modulo),
        .remainder(base_remain),
        .quotient( /* unused */ ),
        .done(base_mod_done)
    );                   

///// Current calculated value (result) modulo with N 
    logic [WIDTH*2-1 : 0] result_mul_remain; 
    logic result_mul_mod_done; 
    logic result_mul_mod_en; 
    
    assign result_mul_mod_en = (state == DUAL_MOD);   
                                                     
    mod_custom #( .WIDTH(WIDTH*2) )
        result_mul_base_mod 
    (
        .clk(i_clk),
        .reset(i_reset),
        .en(result_mul_mod_en),
        .dividend(result_mul_result),
        .divisor(modulo),
        .remainder(result_mul_remain),
        .quotient( /* unused */ ),
        .done(result_mul_mod_done)
    );         




///// State machine logic
    always_ff@ ( posedge i_clk ) begin
        if( i_reset ) begin   
            state = INITIALIZE;                                                       //initialisation of values
            base <= i_base;
            modulo <= 0;
            exponent <= i_exponent;
            result <= 1;                 
        end
        else begin
            state <= state_next;
            base <= base_next;
            modulo <= modulo_next;
            exponent <= exponent_next; 
            result <= result_next; 
        end
    end
    
    always_comb begin
        state_next = state;
        base_next = base;
        modulo_next = modulo;
        exponent_next = exponent;
        result_next = result; 
        
        case ( state ) 
            INITIALIZE: begin                   // INITIALIZE: Waiting for enable 
                if( i_en ) begin
                    state_next = MODULO_MULT;
                    base_next = i_base;
                    modulo_next = 0;
                    exponent_next = i_exponent;
                    result_next = 1;   
                end
                else begin
                    state_next = INITIALIZE; 
                end
            end
            MODULO_MULT: begin                  // MODULO_MULT: Waiting for calculation of N (unique to RSA)
                if( modulo_valid ) begin
                    state_next = UPDATE; 
                    modulo_next = modulo_result;
                end
                else begin
                    state_next = MODULO_MULT; 
                end
            end
            UPDATE: begin                       // UPDATE: Check if exponent is 0, else mod the value again
                if( exponent == 64'd0 ) begin
                    state_next = FINISH; 
                end
                else begin
                    state_next = DUAL_MOD_MULT; 
                end
            end
            DUAL_MOD_MULT: begin                // DUAL_MOD_MULT: Waiting for calculations by both multiplication modules
                if( result_mul_valid && base_squared_valid ) begin
                    state_next = DUAL_MOD; 
                end
                else begin
                    state_next = DUAL_MOD_MULT;
                end   
            end
            DUAL_MOD: begin                     // DUAL_MOD: Waiting for modulus after multiplication is done
                if( base_mod_done && result_mul_mod_done ) begin
                    state_next = UPDATE;
                    if( exponent[0] ) 
                        result_next = result_mul_remain;
                    base_next = base_remain;
                    exponent_next = exponent >> 1; 
                end
                else begin
                    state_next = DUAL_MOD; 
                end   
            end
            FINISH: begin                       // FINISH: Finish state, set done flag high
                state_next = INITIALIZE; 
            end
        endcase
    end

endmodule
