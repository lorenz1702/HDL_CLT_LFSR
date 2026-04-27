`timescale 1ns / 1ps

module clt_prng_axi_stream #(
    parameter int NUM_STAGES = 3,
    parameter int W0 = 18,
    parameter int W1 = 25,
    parameter int Wout = 32,
    // Base seeds to derive unique starting values for each PRNG
    parameter int BASE_SEED0 = 32'hA5A5A5A5, 
    parameter int BASE_SEED1 = 32'h5A5A5A5A
) (
    input  logic                                clk,
    input  logic                                reset_n,

    // AXI Stream Master Interface
    output logic                                m_axis_tvalid,
    input  logic                                m_axis_tready,
    // The output width grows automatically to prevent overflow during addition
    output logic [Wout + $clog2(NUM_STAGES)-1:0] m_axis_tdata,
    output logic                                m_axis_tlast
);

    // Array to hold the continuous outputs of all PRNG instances
    logic signed [Wout-1:0] prng_dout [NUM_STAGES];
    
    // Signal to advance all PRNGs simultaneously to the next state
    logic prng_advance_signal;

    // Temporary variable for the combinatorial sum
    logic signed [Wout + $clog2(NUM_STAGES) - 1 : 0] sum_temp;

    // Registered AXI signals for clean timing
    logic [Wout + $clog2(NUM_STAGES) - 1 : 0] m_axis_tdata_reg;
    logic                                     m_axis_tvalid_reg;

    // -------------------------------------------------------------------------
    // 1. Instantiate the PRNGs
    // -------------------------------------------------------------------------
    genvar i;
    generate
        for (i = 0; i < NUM_STAGES; i++) begin : gen_prng_stages
            // We XOR the base seed with a multiple of a golden ratio prime 
            // to ensure every PRNG starts with a completely unique seed.
            prng #(
                .W0(W0),
                .W1(W1),
                .Wout(Wout),
                .Init0(BASE_SEED0 ^ (i * 32'h9E3779B1)),
                .Init1(BASE_SEED1 ^ (i * 32'h85EBCA6B))
            ) prng_inst (
                .clk(clk),
                .advance_state(prng_advance_signal),
                .dout(prng_dout[i])
            );
        end
    endgenerate

    // -------------------------------------------------------------------------
    // 2. Combinatorial Adder Tree
    // -------------------------------------------------------------------------
    // PERFORMANCE NOTE: This is a combinatorial sum. 
    // If NUM_STAGES is small (e.g., < 8), Vivado will easily meet timing at 100+ MHz. 
    // If NUM_STAGES is very large (e.g., 32+), this long adder chain will become 
    // a timing bottleneck (reducing your maximum clock frequency, Fmax). 
    // In that case, you must replace this with a pipelined adder tree (adding registers).
    always_comb begin
        sum_temp = 0;
        for (int k = 0; k < NUM_STAGES; k++) begin
            sum_temp = sum_temp + prng_dout[k];
        end
    end

    // -------------------------------------------------------------------------
    // 3. AXI Stream Handshake and Registering
    // -------------------------------------------------------------------------
    // Advance PRNGs if the slave read the data (tready=1 AND tvalid=1) 
    // OR if we are empty and waiting to push the first data (tvalid=0).
    assign prng_advance_signal = (m_axis_tvalid_reg && m_axis_tready) || !m_axis_tvalid_reg;

    always_ff @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            m_axis_tdata_reg  <= '0;
            m_axis_tvalid_reg <= 1'b0;
        end else begin
            // If data was consumed OR no valid data is currently present, 
            // fetch the new combinatorial sum and declare it valid.
            if (prng_advance_signal) begin
                m_axis_tdata_reg  <= sum_temp;
                m_axis_tvalid_reg <= 1'b1;
            end
        end
    end

    // -------------------------------------------------------------------------
    // 4. Output Assignments
    // -------------------------------------------------------------------------
    assign m_axis_tdata  = m_axis_tdata_reg;
    assign m_axis_tvalid = m_axis_tvalid_reg;
    assign m_axis_tlast  = 1'b0; // Continuous stream, no end of packet

endmodule