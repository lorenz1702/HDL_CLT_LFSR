`timescale 1ns / 1ps

module lfsr (
    input wire clk,
    input wire rst,
    input wire en,
    output reg [3:0] count
);

    // Wird bei jeder steigenden Taktflanke ausgeführt
    always @(posedge clk) begin
        if (rst) begin
            count <= 4'b0000; // Bei Reset auf 0 setzen
        end else if (en) begin
            count <= count + 1; // Wenn enabled, um 1 hochzählen
        end
    end

endmodule