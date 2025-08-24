`include "noc_enable.svh"
`include "noc.svh"
`include "noc_XY.svh"
`include "queue.svh"
`include "router.svh"
`include "scr1_arch_description.svh"
`include "scr1_memif.svh"

module toplevel (
    input clk, rst_n,
	
    input   logic [SCR1_IRQ_LINES_NUM-1:0]          core_irq_lines_i[`Y-1:0][`X-1:0],           // External interrupt request lines
    input   logic                                   core_irq_soft_i[`Y-1:0][`X-1:0],            // Software generated interrupt request
    input   logic                                   core_irq_mtimer_i[`Y-1:0][`X-1:0],          // Machine timer interrupt request
	
    // Instruction Memory Interface
    input   logic                                   imem2core_req_ack_i[`Y-1:0][`X-1:0],        // IMEM request acknowledge
    output  logic                                   core2imem_req_o[`Y-1:0][`X-1:0],            // IMEM request
    output  type_scr1_mem_cmd_e                     core2imem_cmd_o[`Y-1:0][`X-1:0],            // IMEM command
    output  logic [`SCR1_IMEM_AWIDTH-1:0]           core2imem_addr_o[`Y-1:0][`X-1:0],           // IMEM address
    input   logic [`SCR1_IMEM_DWIDTH-1:0]           imem2core_rdata_i[`Y-1:0][`X-1:0],          // IMEM read data
    input   type_scr1_mem_resp_e                    imem2core_resp_i[`Y-1:0][`X-1:0],           // IMEM response

    // Data Memory Interface
    input   logic                                   dmem2core_req_ack_i[`Y-1:0][`X-1:0],        // DMEM request acknowledge
    output  logic                                   core2dmem_req_o[`Y-1:0][`X-1:0],            // DMEM request
    output  type_scr1_mem_cmd_e                     core2dmem_cmd_o[`Y-1:0][`X-1:0],            // DMEM command
    output  type_scr1_mem_width_e                   core2dmem_width_o[`Y-1:0][`X-1:0],          // DMEM data width
    output  logic [`SCR1_DMEM_AWIDTH-1:0]           core2dmem_addr_o[`Y-1:0][`X-1:0],           // DMEM address
    output  logic [`SCR1_DMEM_DWIDTH-1:0]           core2dmem_wdata_o[`Y-1:0][`X-1:0],          // DMEM write data
    input   logic [`SCR1_DMEM_DWIDTH-1:0]           dmem2core_rdata_i[`Y-1:0][`X-1:0],          // DMEM read data
    input   type_scr1_mem_resp_e                    dmem2core_resp_i[`Y-1:0][`X-1:0]            // DMEM response

);

    wire core_availability_signals_out[0:`Y-1][0:`X-1];
    wire core_availability_signals_in[0:`Y-1][0:`X-1];
    wire[$clog2(`NOC_NODE_COUNT)-1:0] node_start_out[0:`Y-1][0:`X-1];
    wire[$clog2(`NOC_NODE_COUNT)-1:0] node_start_in[0:`Y-1][0:`X-1];
    wire[0:`PL-1] core_inputs[0:`Y-1][0:`X-1];
    wire[0:`PL-1] core_outputs[0:`Y-1][0:`X-1];

    generate
        genvar i, j;

        for (i = 0; i < `Y; i = i + 1)
        begin : rows
            for (j = 0; j < `X; j = j + 1)
            begin : columns

                assign core_availability_signals_out[i][j] = 1; 

                core_perifery_top #(
                    .NODE_ID(i * `Y + j), .X(j), .Y(i)
                ) core (
                    .clk(clk), .rst_n(rst_n),
                    .input_data(core_inputs[i][j]),
                    .output_data(core_outputs[i][j]),
                    .network_ready(core_availability_signals_in[i][j]),

                    .core_irq_lines_i(core_irq_lines_i[i][j]),             // External interrupt request
                    .core_irq_soft_i(core_irq_soft_i[i][j]),            // Software generated interrupt request
                    .core_irq_mtimer_i(core_irq_mtimer_i[i][j]),          // Machine timer interrupt request
						  
                    // Instruction Memory Interface
                    .imem2core_req_ack_i(imem2core_req_ack_i [i][j]),
                    .core2imem_req_o(core2imem_req_o [i][j]),
                    .core2imem_cmd_o(core2imem_cmd_o [i][j]),
                    .core2imem_addr_o(core2imem_addr_o [i][j]),
                    .imem2core_rdata_i(imem2core_rdata_i [i][j]),
                    .imem2core_resp_i(imem2core_resp_i [i][j]),

                    // Data Memory Interface
                    .dmem2core_req_ack_i(dmem2core_req_ack_i [i][j]),
                    .core2dmem_req_o(core2dmem_req_o [i][j]),
                    .core2dmem_cmd_o(core2dmem_cmd_o [i][j]),
                    .core2dmem_width_o(core2dmem_width_o [i][j]),
                    .core2dmem_addr_o(core2dmem_addr_o [i][j]),
                    .core2dmem_wdata_o(core2dmem_wdata_o [i][j]),
                    .dmem2core_rdata_i(dmem2core_rdata_i [i][j]),
                    .dmem2core_resp_i(dmem2core_resp_i [i][j])
 
                );

            end
        end

    endgenerate


    noc noc(
        .clk(clk), .rst_n(rst_n),
        .core_inputs(core_inputs),
        .core_outputs(core_outputs),
        .core_availability_signals_out(core_availability_signals_out),
        .core_availability_signals_in(core_availability_signals_in)
    );

    
endmodule