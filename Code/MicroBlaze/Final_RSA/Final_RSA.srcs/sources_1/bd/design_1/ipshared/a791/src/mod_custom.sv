// PROJECT: ECE 4300 RSA Microblaze Implementation
//
// FILENAME: mod_custom.sv         
// CREATED BY: Kyle Thomas Le 
// CREATED ON: 11/16/2020                                                  
//                                                                             
// DESCRIPTION: Find the quotient and remainder of the provided
// dividend and divisor.
//
// TODO: 
//  * Fix variable naming to better reflect what they are doing
//
// Update #1 11/22/2020:
//  * Start state localparam declaration at 0

`timescale 1ns / 1ps

module mod_custom 
    #( parameter WIDTH = 19 )
    ( 
        input clk,
        input reset,  
        input en,
        input [WIDTH-1:0] dividend,
        input [WIDTH-1:0] divisor,
        output [WIDTH-1:0] quotient,
        output [WIDTH-1:0] remainder,
        output done 
    );
   
   // State declaration
   localparam
        INITIALIZE = 2'd0,
        LOOPING = 2'd1,
        FINALIZE = 2'd2;
   
   // Logic declaration
   logic [WIDTH-1 : 0] A, A_next;
   logic [WIDTH-1 : 0] N, N_next;
   logic [WIDTH : 0] p, p_next;   
   logic [WIDTH-1 : 0] p_temp; 
   logic [1:0] state, state_next;
   logic [$clog2(WIDTH) : 0] counter, counter_next; 
   
   // Output logic
    assign quotient = A;
    assign remainder = p;
    assign done = ( state == FINALIZE ); 
   
   
///// State machine logic  
    always_ff@ ( posedge clk ) begin
        if( reset ) begin
            state <= INITIALIZE; 
            counter = WIDTH; 
            A <= dividend;
            N <= divisor;
            p <= 0; 
        end
        else begin
            state <= state_next; 
            counter <= counter_next; 
            A <= A_next;
            N <= N_next;
            p <= p_next; 
        end
    end
    
    always_comb begin
        state_next = state; 
        counter_next = counter; 
        A_next = A;
        N_next = N;
        p_next = p; 
        p_temp = 0; 
        
        case ( state ) 
            INITIALIZE: begin                   // INITIALIZE: Waiting for enable
                if( en ) begin
                    counter_next = WIDTH;
                    A_next = dividend;
                    N_next = divisor; 
                    p_next = 0;
                    state_next = LOOPING; 
                end
                else begin
                    state_next = INITIALIZE; 
                end
            end
            LOOPING: begin                      // LOOPING: Continuously loop for as many bits there 
                if( counter == 'd0 ) begin      // are to calculate the quotient/remainder
                    state_next = FINALIZE; 
                end 
                else begin
                    state_next = LOOPING;
                    {p_next, A_next} = {p , A} << 1;
                    A_next[0] = A[0]; 
                    p_temp = p_next - N; 
                    if( p_temp[WIDTH-1] == 1 ) begin
                        A_next[0] = 1'b0; 
                    end
                    else begin
                        A_next[0] = 1'b1;
                        p_next = p_temp;  
                    end
                    counter_next = counter - 1; 
                end
            end
            FINALIZE: begin                     // FINISH: Finish state, set done flag high
                state_next = INITIALIZE; 
            end
        endcase
    end   
   
endmodule
