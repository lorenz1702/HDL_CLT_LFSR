`timescale 1ns / 1ps

// AXI Stream Wrapper for the PRNG module
module prng_axi_stream (
    input  logic                 clk,
    input  logic                 reset_n, // Active-low synchronous reset

    // AXI Stream Master Interface
    output logic                 m_axis_tvalid, // Master valid: indicates data is available
    input  logic                 m_axis_tready, // Slave ready: indicates slave can accept data
    output logic[31:0]           m_axis_tdata,  // Data payload
    output logic                 m_axis_tlast   // Last transfer in a packet
);

    localparam int C_W0 = 18;
    localparam int C_W1 = 25;
    localparam int C_Wout = 32;
    localparam int C_Init0 = 1;
    localparam int C_Init1 = 1;
    
    logic [C_Wout-1:0] prng_output_unregistered;
    logic prng_advance_signal;
    
    // Instantiate PRNG
    prng #(
        .W0(C_W0),
        .W1(C_W1),
        .Wout(C_Wout),
        .Init0(C_Init0),
        .Init1(C_Init1)
    ) prng_inst (
        .clk(clk),
        .advance_state(prng_advance_signal),
        .dout(prng_output_unregistered)
    );

    // Registered signals for AXI Stream output.
    // These hold the data and valid signal that are actually driven on the AXI bus.
    logic [C_Wout-1:0] m_axis_tdata_reg;
    logic            m_axis_tvalid_reg;
    
    always_ff @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            // On active-low reset, clear output data and invalidate the stream
            m_axis_tdata_reg  <= '0;
            m_axis_tvalid_reg <= 1'b0;
            prng_advance_signal <= 1'b0;
        end else begin
            // Determine if the PRNG should advance its state for the next cycle.
            // It advances if the current data was valid AND accepted by the slave.
            prng_advance_signal <= (m_axis_tvalid_reg && m_axis_tready);
            
            // If the current data was consumed (m_axis_tvalid_reg is high AND m_axis_tready is high)
            // OR if the stream is currently not valid (meaning we need to present the first data)
            if ((m_axis_tvalid_reg && m_axis_tready) || !m_axis_tvalid_reg) begin
                // Load the new PRNG output into the output data register
                m_axis_tdata_reg  <= prng_output_unregistered;
                // Assert TVALID to indicate that new data is available
                m_axis_tvalid_reg <= 1'b1;
            end
        end
    end

    // Assign the registered internal signals to the AXI Stream output ports
    assign m_axis_tdata  = m_axis_tdata_reg;
    assign m_axis_tvalid = m_axis_tvalid_reg;

    // TLAST is always 0 as stream is continuous
    assign m_axis_tlast  = 1'b0;

endmodule
