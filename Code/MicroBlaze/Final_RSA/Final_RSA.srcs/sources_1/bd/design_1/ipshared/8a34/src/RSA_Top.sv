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
//  * Code cleanup and organization 
//  * Variable renames
//
// Update #1 11/22/2020:
//  * Add clock cycle counter to measure time of key generation 
//    and encryption/decryption 
//  * Add state machine to make logic understanding easier/clearer
//  * Reset mod_exponent module on inverter reset
//
// Update #2 11/28/2020:
//  * Allow user to input a key and n
//  * Allow user to only generate a message, not encrypt
//  * Move n generation into this module, now output it
//  * Latched all inputs to prevent them from changing while
//    calculations are made

`timescale 1ns / 1ps

module RSA_Top
    #(parameter WIDTH = 16)             //Defines size of input ports
    (
    input [WIDTH-1:0] i_p, i_q,             // Input Random Prime numbers
    input clk,                          // System wide clock
    input reset,                        // Resets inverter (key generator) module
    input reset1,                       // Resets modular exponentiation (encryption / decryption) module
    input go,                           // Starts the system
    input i_mode,                         // 1 for key/msg generation and 0 for only msg generation 
    input i_encrypt_decrypt,              // 1 for encryption and 0 for decryption
    input [WIDTH-1:0] i_msg,           // Input either message or cipher
    input [WIDTH*2-1:0] i_key,          // User inputted key
    input [WIDTH*2-1:0] i_n,            // p * q value given to public 
    
    output [WIDTH*2-1:0] o_msg,       // Output either decrypted message or cipher
    output [WIDTH*2-1:0] o_encrypt,     // Output encryption key
    output [WIDTH*2-1:0] o_decrypt,     // Output decryption key
    output [WIDTH*2-1:0] o_n,           // Output n given to public
    output logic [31:0] counter,        // Counter for module 
    output mod_exp_finish               // Finish signal indicator of mod exp module
    );
    
    // State declaration       
    localparam
        INITIALIZE = 3'd0,
        GO_HOLD = 3'd1,
        GENERATION = 3'd2,
        N = 3'd3,
        MOD = 3'd4,
        DONE = 3'd5; 
    
    // Logic declaration 
    logic [2:0] state, state_next;        
    logic mod_enable, inverter_enable;
    logic inverter_finish;
    logic [WIDTH*2-1:0] e, d;
    logic [WIDTH*2-1:0] exponent;   
    logic [WIDTH*2-1:0] n, n_next;
    logic [WIDTH*2-1:0] n_mult_store, n_mult_next; 
    logic [WIDTH*2-1:0] key, key_next; 
    logic [WIDTH-1:0] p, p_next;
    logic [WIDTH-1:0] q, q_next;
    logic [WIDTH-1:0] msg_in, msg_next;  
    logic mode, mode_next;
    logic encrypt_decrypt, encrypt_decrypt_next; 
    logic [WIDTH*2-1:0] exp_n; 
    
    logic [31:0] count, count_next;
    logic [31:0] clk_count, clk_count_next; 
    
    // Output keys
    assign o_encrypt = ( mode ) ? e :                               // Assign generated key if in key generation mode
                            ( encrypt_decrypt ) ? key : 0;        // Assign input encryption when encrypting in msg generating mode, else 0
    assign o_decrypt = ( mode ) ? d :                               // Assign generated key if in key generation. Assign input decryption if in msg generating mode
                            ( encrypt_decrypt ) ? 0 : key;        // Assign input decrpyion when decrypting in msg generating mode, else 0
    assign o_n = n_mult_store; 
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

///// n multiplication module p * q
    logic [(WIDTH*2)-1 : 0] n_result;
    logic n_valid; 
    logic n_rstn;
    
    // Reset state must be held for at least two clock cycles! 
    assign n_rstn = ~(reset || reset1 || ~(state == GENERATION || state == N) ); 
    
    cmpy_0 n_mult (
      .aclk(clk),                           // input clk
      .aresetn(n_rstn),                     // input reset (negative edged)
      .s_axis_a_tvalid(1'b1),               // input A valid (always asserted)
      .s_axis_a_tdata( {73'd0, p} ),        // input A data [72 : 0] ( IMAG(72:40), REAL(32:0) ) 
      .s_axis_b_tvalid(1'b1),               // input B valid (always asserted)
      .s_axis_b_tdata( {73'd0, q } ),       // input B data [72 : 0] ( IMAG(72:40), REAL(32:0) ) 
      .m_axis_dout_tvalid(n_valid),         // output valid (held until reset) 
      .m_axis_dout_tdata(n_result)          // output data [138 : 0] ( IMAG(138:72), REAL(66:0) ) 
    );

    assign exp_n = ( mode ) ? n_mult_store : n;   // Assign calculated n if in key generation. Assign input n if in msg generating mode

    
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
    assign exponent = (mode) ? ( encrypt_decrypt ? e : d ) : key; // Give mod exponent module either the encryption or decryption key depending on mode
 
    mod_exponent #(.WIDTH(WIDTH)) mod
        ( 
          .i_n                ( exp_n          ),
          .i_base             ( msg_in         ), 
          .i_exponent         ( exponent       ),
          .i_clk              ( clk            ),
          .i_reset            ( reset1 | reset ),
          .i_en               ( mod_enable     ), 
          .o_finish           ( mod_exp_finish ),
          .o_result           ( o_msg          )
        );
    
///// State machine logic
    always_ff@ ( posedge clk ) begin
        if( reset ) begin
            state <= INITIALIZE;
            p <= i_p;
            q <= i_q; 
            msg_in <= i_msg; 
            mode <= i_mode;
            encrypt_decrypt <= i_encrypt_decrypt; 
            key <= i_key;
            n <= i_n; 
            n_mult_store <= 0; 
        end
        else begin
            state <= state_next; 
            p <= p_next;
            q <= q_next;
            msg_in <= msg_next;
            mode <= mode_next;
            encrypt_decrypt <= encrypt_decrypt_next; 
            key <= key_next;
            n <= n_next;
            n_mult_store <= n_mult_next; 
        end
    end
    
    always_comb begin
        p_next = p;
        q_next = q;
        msg_next = msg_in;
        mode_next = mode;
        encrypt_decrypt_next = encrypt_decrypt;
        key_next = key;
        n_next = n; 
        n_mult_next = n_mult_store; 
        state_next = state; 
    
        case( state )
            INITIALIZE: begin
                if( go ) begin
                    state_next = GO_HOLD;
                    p_next = i_p;
                    q_next = i_q; 
                    msg_next = i_msg; 
                    mode_next = i_mode;
                    encrypt_decrypt_next = i_encrypt_decrypt; 
                    key_next = i_key;
                    n_next = i_n;  
                    n_mult_next = 'd0; 
                end
                else begin
                    state_next = INITIALIZE; 
                end
            end
            GO_HOLD: begin
                if ( go ) begin
                    if( mode ) begin
                        state_next = GENERATION;
                    end 
                    else begin
                        state_next = MOD; 
                    end          
                end
                else begin
                    state_next = INITIALIZE; 
                end
            end
            GENERATION: begin
                if( inverter_finish ) begin
                    state_next = N;
                end 
                else begin
                    state_next = GENERATION;
                end
            end
            N: begin
                if( n_valid ) begin
                    state_next = MOD; 
                    n_mult_next = n_result; 
                end
                else begin
                    state_next = N;
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
