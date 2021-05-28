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
    output logic [31:0] clk_count,      // Counter for module 
    output mod_exp_finish               // Finish signal indicator of mod exp module
    );
    
    wire inverter_finish;
    wire [WIDTH*2-1:0] e, d;
    wire [WIDTH*2-1:0] exponent = encrypt_decrypt ? e : d;  // Give mod exponent module either the encryption or decryption key
    
    reg [31:0] counter, counter_next; 
    
    always_ff @( posedge clk ) begin
        if( reset ) begin
            counter <= 0; 
        end
        else begin
            counter <= counter_next;
        end
    end
    
    assign counter_next = ( mod_exp_finish ) ? 0 : counter + 1; 
    
    always_ff @( posedge clk ) begin
        if( mod_exp_finish ) begin
            clk_count <= counter; 
        end
    end
    
    // Output keys
    assign encrypt_key = e;
    assign decrypt_key = d;
    
    // Inverter (key generator) module 
    inverter_custom #(.WIDTH(WIDTH)) invert
        (
          .i_p                ( p               ),
          .i_q                ( q               ),
          .i_clk              ( clk             ),
          .i_reset            ( reset           ),
          .i_en               ( go              ),
          .o_finish           ( inverter_finish ),
          .o_e                ( e               ),
          .o_d                ( d               )
        );
    
    // Mod exponentiation (encryption/decryption) module    
    mod_exponent #(.WIDTH(WIDTH)) mod
        ( 
          .i_p                ( p              ),
          .i_q                ( q              ),
          .i_base             ( msg_in         ), 
          .i_exponent         ( exponent       ),
          .i_clk              ( clk            ),
          .i_reset            ( reset1         ),
          .i_en               ( inverter_finish ), 
          .o_finish           ( mod_exp_finish ),
          .o_result           ( msg_out        )
        );
    
endmodule
