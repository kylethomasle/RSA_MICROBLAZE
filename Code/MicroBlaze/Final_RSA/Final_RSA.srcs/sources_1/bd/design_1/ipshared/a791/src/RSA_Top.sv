// PROJECT: ECE 4300 RSA Microblaze Implementation
//
// FILENAME: RSA_Top.sv         
// CREATED BY: Kyle Thomas Le 
// CREATED ON: 11/16/2020                                                  
//                                                                             
// DESCRIPTION: Using two prime numbers and an input message,
// generate an output message encrypted using the RSA algorithm.
// Output the corresponding encryption and decryption key.
//
// TODO: 
//  * Allow the user to input their own encryption key
//  * Allow to user to input their own decrpytion key
//  * Output n (p * q) which is part of the public key
//  * Allow user to input n for encryption or decryption
//  * Provide an input that allows to user to choose mode of operation
//
// Update #1 11/22/2020:
//  * Add clock cycle counter to measure time of key generation 
//    and encryption/decryption 
//  * Add state machine to make logic understanding easier/clearer
//  * Reset mod_exponent module on inverter reset

`timescale 1ns / 1ps

module RSA_Top
    #(parameter WIDTH = 16)             //Defines size of input ports
    (
    input [WIDTH-1:0] p, q,             // Input Random Prime numbers
    input clk,                          // System wide clock
    input reset,                        // Resets inverter (key generator) module
    input reset1,                       // Resets modular exponentiation (encryption / decryption) module
    input go,                           // Starts the inverter module
    input encrypt_decrypt,              // 1 for encryption and 0 for decryption
    input [WIDTH-1:0] msg_in,           // Input either message or cipher
    output [WIDTH*2-1:0] msg_out,       // Output either decrypted message or cipher
    output [WIDTH*2-1:0] encrypt_key,   // Output encryption key
    output [WIDTH*2-1:0] decrypt_key,   // Output decryption key
    output logic [31:0] counter,      // Counter for module 
    output mod_exp_finish               // Finish signal indicator of mod exp module
    );
    
    // State declaration       
    localparam
        INITIALIZE = 2'd0,
        GENERATION = 2'd1,
        MOD = 2'd2,
        DONE = 2'd3; 
    
    // Logic declaration 
    logic [1:0] state, state_next;        
    logic mod_enable, inverter_enable;
    logic inverter_finish;
    logic [WIDTH*2-1:0] e, d;
    logic [WIDTH*2-1:0] exponent;   
    
    logic [31:0] count, count_next;
    logic [31:0] clk_count, clk_count_next; 
    
    // Output keys
    assign encrypt_key = e;
    assign decrypt_key = d;
    
    assign mod_enable = (state == MOD); 
    assign inverter_enable = (state == GENERATION);    
    assign counter = clk_count; 
    
 ///// Counter logic  
    // Internal counter
    always_ff @( posedge clk ) begin
        if( reset ) begin
            count <= 0; 
        end
        else begin
            count <= count_next;
        end
    end
    
    assign count_next = ( state == INITIALIZE ) ? 0 : count + 1; 
    
    // Output counter 
    always_ff @( posedge clk ) begin
        clk_count <= clk_count_next; 
    end
    
    assign clk_count_next = ( state == DONE ) ? count : clk_count; 

    
///// Inverter (key generator) module 
    inverter_custom #(.WIDTH(WIDTH)) invert
        (
          .i_p                ( p               ),
          .i_q                ( q               ),
          .i_clk              ( clk             ),
          .i_reset            ( reset           ),
          .i_en               ( inverter_enable ),
          .o_finish           ( inverter_finish ),
          .o_e                ( e               ),
          .o_d                ( d               )
        );
    
///// Mod exponentiation (encryption/decryption) module   
    assign exponent = encrypt_decrypt ? e : d;  // Give mod exponent module either the encryption or decryption key
 
    mod_exponent #(.WIDTH(WIDTH)) mod
        ( 
          .i_p                ( p              ),
          .i_q                ( q              ),
          .i_base             ( msg_in         ), 
          .i_exponent         ( exponent       ),
          .i_clk              ( clk            ),
          .i_reset            ( reset1 | reset ),
          .i_en               ( mod_enable ), 
          .o_finish           ( mod_exp_finish ),
          .o_result           ( msg_out        )
        );
    
///// State machine logic
    always_ff@ ( posedge clk ) begin
        if( reset ) begin
            state <= INITIALIZE;
        end
        else begin
            state <= state_next; 
        end
    end
    
    always_comb begin
        state_next = state; 
    
        case( state )
            INITIALIZE: begin
                if( go ) begin
                    state_next = GENERATION;
                end
                else begin
                    state_next = INITIALIZE; 
                end
            end
            GENERATION: begin
                if( inverter_finish ) begin
                    state_next = MOD;
                end 
                else begin
                    state_next = GENERATION;
                end
            end
            MOD: begin
                if ( mod_exp_finish ) begin
                    state_next = DONE;
                end
                else begin
                    state_next = MOD; 
                end
            end
            DONE: begin
                state_next = INITIALIZE; 
            end
        endcase
    end
    
endmodule
