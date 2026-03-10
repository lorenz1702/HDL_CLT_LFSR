`timescale 1ns / 1ps

module tb_lfsr;

    // Signale deklarieren
    reg clk;
    reg rst;
    reg en;
    wire [3:0] count;

    // Unser Modul instanziieren (anschließen)
    lfsr uut (
        .clk(clk),
        .rst(rst),
        .en(en),
        .count(count)
    );

    // Einen Takt generieren (alle 5ns invertieren -> 10ns Periode -> 100 MHz)
    always #5 clk = ~clk;

    // Eigentliche Simulation
    initial begin
        // Startwerte setzen
        clk = 0;
        rst = 1;
        en = 0;

        // 20 Nanosekunden warten
        #20;
        
        // Reset loslassen und Zähler aktivieren
        rst = 0;
        en = 1;

        // Den Zähler für 200 Nanosekunden laufen lassen
        #200;

        // Zähler pausieren
        en = 0;
        #50;

        // WICHTIG: Sagt dem Tcl-Befehl "run all", dass er hier stoppen soll!
        $display("Testbench erfolgreich durchgelaufen!");
        $finish;
    end

endmodule