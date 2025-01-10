`default_nettype none
`timescale 1ns / 1ps

module simple_mul #(
    parameter WIDTH = 8,  // width of numbers in bits (integer + fractional)
    parameter FBITS = 4   // number of fractional bits
    ) (
    input wire clk,              // clock
    input wire rst,              // reset
    input wire start,            // start calculation
    output reg busy,             // calculation in progress
    output reg valid,            // result is valid
    output reg ovf,              // overflow
    input wire signed [WIDTH-1:0] a, // multiplier
    input wire signed [WIDTH-1:0] b, // multiplicand
    output reg signed [WIDTH-1:0] val // result (product)
    );

    // Internal signals
    reg signed [2*WIDTH-1:0] product; // full precision product
    reg signed [WIDTH-1:0] rounded_val; // rounded result

    // Truncation parameters
    localparam MSB = 2*WIDTH - (WIDTH - FBITS) - 1;
    localparam LSB = WIDTH - FBITS;
    localparam HALF = {1'b1, {FBITS-1{1'b0}}}; // half for rounding

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            busy <= 0;
            valid <= 0;
            ovf <= 0;
            val <= 0;
        end else begin
            if (start) begin
                // Start the calculation
                busy <= 1;
                valid <= 0;
                ovf <= 0;

                // Perform multiplication
                product <= a * b;

                // Truncate the product
                rounded_val <= product[MSB:LSB];

                // Apply Gaussian rounding
                if (product[FBITS-1] && (product[FBITS-1:0] != HALF || ~product[FBITS])) begin
                    val <= rounded_val + 1;
                end else begin
                    val <= rounded_val;
                end

                // Check for overflow
                if (val[WIDTH-1] != product[2*WIDTH-1]) begin
                    ovf <= 1;
                    valid <= 0;
                end else begin
                    ovf <= 0;
                    valid <= 1;
                end

                // Mark calculation as complete
                busy <= 0;
            end
        end
    end

endmodule
