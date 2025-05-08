`include "scr1_arch_description.svh"
`include "scr1_arch_types.svh"

module core_router #(
    parameter int NODE_ID = 0, NODE_COUNT = 9, PACKET_ID_WIDTH = 5,
    SPLITTER_DEPTH = 8, COLLECTOR_DEPTH = 8, QUEUE_DEPTH = 8, 
    PAYLOAD = 32, FLIT_PAYLOAD = 8,
    X = 3, Y = 3,
    WORD = 16, SIZE = 256
) (
    //Basic
    input clk, rst_n,

    //Core integration
    input  logic                                lsu2dmem_req_i,             // Data memory request
    input  type_scr1_mem_cmd_e                  lsu2dmem_cmd_i,             // Data memory command (READ/WRITE)
    input  type_scr1_mem_width_e                lsu2dmem_width_i,           // Data memory data width
    input  logic [`SCR1_DMEM_AWIDTH-1:0]        lsu2dmem_addr_i,            // Data memory address
    input  logic [`SCR1_DMEM_DWIDTH-1:0]        lsu2dmem_wdata_i,           // Data memory write data
    output logic                                dmem2lsu_req_ack_o,         // Data memory request acknowledge
    output logic [`SCR1_DMEM_DWIDTH-1:0]        dmem2lsu_rdata_o,           // Data memory read data
    output type_scr1_mem_resp_e                 dmem2lsu_resp_o             // Data memory response

    //Network integration
    input logic [INPUT_WIDTH - 1 : 0] flitIn,
    output logic readFromNoc,

    output logic [INPUT_WIDTH - 1 : 0] flitOut,
    input logic writeToNoc

);
    localparam INPUT_WIDTH = 1 + 2*$clog2(NODE_COUNT) + FLIT_PAYLOAD + PACKET_ID_WIDTH;
    
    localparam START_MEMORY_ADDRESS =   NODE_ID * SIZE * WORD;
    localparam END_MEMORY_ADDRESS   =  (NODE_ID + 1) * SIZE * WORD - 1;

    logic [SIZE - 1 : 0] internal_memory_data_address;
    logic [SIZE - 1 : 0] external_memory_data_address;

    //First memory access port
    logic [WORD-1 : 0]    data_in_1_o;
    logic [SIZE-1 : 0]    addr_1_o;
    logic                 write_1_o;
    logic [WORD-1 : 0]    data_out_1_i;

    //Second memory access port
    logic [WORD-1 : 0]    data_in_2_o;
    logic [SIZE-1 : 0]    addr_2_o;
    logic                 write_2_o;
    logic [WORD-1 : 0]    data_out_2_i;

    //TODO
    //Request acknwledge

    /* Two ports: 
    First for internal memory,
    Second for NoC requests
    */

    always_ff @( posedge clk or negedge rst_n ) begin //First port logic
        if(!rst_n) begin
            internal_memory_data_address <= '0;
        end else begin
            if(lsu2dmem_addr_i >= START_MEMORY_ADDRESS & su2dmem_addr_i <= END_MEMORY_ADDRESS) begin
                //Memory hit
                /*
                typedef enum logic [SCR1_LSU_CMD_WIDTH_E-1:0] {
                SCR1_LSU_CMD_NONE = '0,
                SCR1_LSU_CMD_LB,
                SCR1_LSU_CMD_LH,
                SCR1_LSU_CMD_LW,
                SCR1_LSU_CMD_LBU,
                SCR1_LSU_CMD_LHU,
                SCR1_LSU_CMD_SB,
                SCR1_LSU_CMD_SH,
                SCR1_LSU_CMD_SW
                } type_scr1_lsu_cmd_sel_e;
                */
            end
        end
    end

    ram #(

    ) memory (
        .clk(clk), .en(1'b1), .rst_n(rst_n),

    )

    splitter #(
            .NODE_ID(NODE_ID), .NODE_COUNT(NODE_COUNT), .QUEUE_DEPTH(SPLITTER_DEPTH), .PACKET_ID_WIDTH(PACKET_ID_WIDTH)
        ) spl (
            .clk(clk), .ce(1'b1), .rst_n(rst_n),
            .packet_in(packetOut),
            .node_dest(nodeDest),
            .valid_in(validControllerSplitter),
            .packet_id(packetId),
            .output_data(flitOut),
            .valid_out(), .ack(dmem2lsu_req_ack_o)
        );

        packet_collector #( 
            .NODE_COUNT(NODE_COUNT), .PACKET_ID_WIDTH(PACKET_ID_WIDTH), .BUFFER_SIZE(COLLECTOR_DEPTH)
        ) pc (
            .clk(clk), .rst_n(rst_n), .ce(1'b1),
            .input_data(flitIn),
            .valid_in(1'b1),

            .valid_out(validCollectorRam),
            .packet_out(packetIn),
            .node_start_out(nodeStart),
            .node_dest_out(),
            .packet_id_out(),
            .send_signal(readFromCollector)
        );
 

endmodule