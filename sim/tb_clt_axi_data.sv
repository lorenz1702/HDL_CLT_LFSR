`timescale 1ns / 1ps

module tb_clt_axi_data;

    // Parameters for the Central Limit Theorem (CLT) setup
    localparam int NUM_STAGES = 3;
    localparam int W0 = 18;
    localparam int W1 = 25;
    localparam int Wout = 32;
    
    // Two independent base seeds for the PRNG initial states
    localparam int BASE_SEED0 = 32'h12345678; 
    localparam int BASE_SEED1 = 32'h87654321;

    // Total number of valid samples to collect for the Python plot
    localparam int SAMPLES_TO_COLLECT = 1000000;

    logic clk;
    logic rst_n;

    // AXI Stream signals
    logic                                     m_axis_tvalid;
    logic                                     m_axis_tready;
    logic [Wout + $clog2(NUM_STAGES) - 1 : 0] m_axis_tdata;
    logic                                     m_axis_tlast;

    // Instantiate the new CLT PRNG AXI Stream module
    clt_prng_axi_stream #(
        .NUM_STAGES(NUM_STAGES),
        .W0(W0),
        .W1(W1),
        .Wout(Wout),
        .BASE_SEED0(BASE_SEED0),
        .BASE_SEED1(BASE_SEED1)
    ) u_clt (
        .clk(clk),
        .reset_n(rst_n),
        .m_axis_tvalid(m_axis_tvalid),
        .m_axis_tready(m_axis_tready),
        .m_axis_tdata(m_axis_tdata),
        .m_axis_tlast(m_axis_tlast)
    );

    // Clock generator (100 MHz -> 10ns period)
    always #5 clk = ~clk;

    int sample_counter = 0;
    int file_id; // File handle for data export
    real float_val;

    initial begin
        // Initialize signals
        clk = 0;
        rst_n = 0;
        m_axis_tready = 0; // Do not accept data during reset
        sample_counter = 0;

        // Open file for writing the results
        file_id = $fopen("clt_data.txt", "w");
        if (!file_id) begin
            $display("ERROR: Could not open file clt_data.txt for writing.");
            $finish;
        end

        $display("==================================================");
        $display("   STARTING DATA COLLECTION");
        $display("   Stages: %0d, PRNG Width: %0d", NUM_STAGES, Wout);
        $display("   Target samples: %0d", SAMPLES_TO_COLLECT);
        $display("==================================================");

        #100; // Hold reset
        rst_n = 1; // Release reset
        #20;
        
        // Enable the AXI Stream receiver (acting like the Constant block in BD)
        m_axis_tready = 1; 

        // Collection loop
        while (sample_counter < SAMPLES_TO_COLLECT) begin
            @(posedge clk);
            #1; // Wait for non-blocking assignments to stabilize

            // In AXI Stream, a data transfer occurs when BOTH valid and ready are high
            if (m_axis_tvalid && m_axis_tready) begin
                
                // Scaling: The PRNG outputs a 32-bit signed number.
                // We divide by 2^31 (2147483648.0) to normalize a single PRNG to approx [-1.0, 1.0].
                // The sum of NUM_STAGES will therefore fall in the range [-NUM_STAGES, +NUM_STAGES].
                float_val = real'($signed(m_axis_tdata)) / 2147483648.0;
                
                // Write only the raw float value to the file for easy Python parsing
                $fdisplay(file_id, "%f", float_val);
                
                sample_counter++;
                
                // Print progress to console every 100k samples to avoid console spam
                if (sample_counter % 100000 == 0) begin
                    $display("Collected %0d / %0d samples...", sample_counter, SAMPLES_TO_COLLECT);
                end
            end
        end

        // Cleanup and finish
        $fclose(file_id);
        $display("==================================================");
        $display("   DATA COLLECTION FINISHED");
        $display("   Data saved in: clt_data.txt");
        $display("==================================================");

        $finish;
    end

endmodule