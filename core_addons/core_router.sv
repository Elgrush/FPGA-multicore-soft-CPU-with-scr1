`include "scr1_arch_description.svh"
`include "scr1_arch_types.svh"

module core_router #(
    parameter int NODE_ID = 0, NODE_COUNT = 9, PACKET_ID_WIDTH = 5,
    SPLITTER_DEPTH = 8, COLLECTOR_DEPTH = 8, QUEUE_DEPTH = 8, 
    X = 3, Y = 3,
    BYTE = 8, SIZE = 512
) (
    //Basic
    input clk, rst_n,

    //Core integration
    //scr1_memif.svh
    //DMEM
    input  logic                                lsu2dmem_req_i,             // Data memory request
    input  type_scr1_mem_cmd_e                  lsu2dmem_cmd_i,             // Data memory command (READ/WRITE)
    /*
    typedef enum logic {
    SCR1_MEM_CMD_RD     = 1'b0,
    SCR1_MEM_CMD_WR     = 1'b1
    `ifdef SCR1_XPROP_EN
        ,
        SCR1_MEM_CMD_ERROR  = 'x
    `endif // SCR1_XPROP_EN
    } type_scr1_mem_cmd_e;
    */
    input  type_scr1_mem_width_e                lsu2dmem_width_i,           // Data memory data width
    /*
    typedef enum logic[1:0] {
    SCR1_MEM_WIDTH_BYTE     = 2'b00,
    SCR1_MEM_WIDTH_HWORD    = 2'b01,
    SCR1_MEM_WIDTH_WORD     = 2'b10
    `ifdef SCR1_XPROP_EN
        ,
        SCR1_MEM_WIDTH_ERROR    = 'x
    `endif // SCR1_XPROP_EN
    } type_scr1_mem_width_e;
    */

    input  logic [`SCR1_DMEM_AWIDTH-1:0]        lsu2dmem_addr_i,            // Data memory address
    input  logic [`SCR1_DMEM_DWIDTH-1:0]        lsu2dmem_wdata_i,           // Data memory write data

    output logic                                dmem2lsu_req_ack_o,         // Data memory request acknowledge
    output logic [`SCR1_DMEM_DWIDTH-1:0]        dmem2lsu_rdata_o,           // Data memory read data
    output type_scr1_mem_resp_e                 dmem2lsu_resp_o             // Data memory response
    /*
    typedef enum logic[1:0] {
    SCR1_MEM_RESP_NOTRDY    = 2'b00,
    SCR1_MEM_RESP_RDY_OK    = 2'b01,
    SCR1_MEM_RESP_RDY_ER    = 2'b10
    `ifdef SCR1_XPROP_EN
        ,
        SCR1_MEM_RESP_ERROR     = 'x
    `endif // SCR1_XPROP_EN
    } type_scr1_mem_resp_e;
    */

    //IMEM 
    input   logic                                   ifu2imem_req_i,             // Instruction memory request
    input   type_scr1_mem_cmd_e                     ifu2imem_cmd_i,             // Instruction memory command (READ/WRITE)
    input   logic [`SCR1_IMEM_AWIDTH-1:0]           ifu2imem_addr_i,            // Instruction memory address

    output  logic                                   imem2ifu_req_ack_o,         // Instruction memory request acknowledgement
    output  logic [`SCR1_IMEM_DWIDTH-1:0]           imem2ifu_rdata_o,           // Instruction memory read data
    output  type_scr1_mem_resp_e                    imem2ifu_resp_i,            // Instruction memory response
    
    //Network integration
    input logic [INPUT_WIDTH - 1 : 0] flitIn,
    output logic readFromNoc,

    output logic [INPUT_WIDTH - 1 : 0] flitOut,
    input logic writeToNoc
);

    localparam FLIT_MAX_PAYLOAD = $max(
        ($size(type_packet_type) + $size(type_scr1_mem_width_e) + SCR1_DMEM_AWIDTH + SCR1_DMEM_DWIDTH),  // Memory       request
        ($size(type_packet_type) + $size(type_scr1_mem_width_e) + SCR1_DMEM_DWIDTH),                     // Memory       response
        ($size(type_packet_type) + SCR1_IMEM_AWIDTH),                                                    // Instruction  request
        ($size(type_packet_type) + SCR1_IMEM_DWIDTH)                                                     // Instruction  response
    ) 
    localparam INPUT_WIDTH = 1 + 2*$clog2(NODE_COUNT) + FLIT_PAYLOAD + PACKET_ID_WIDTH;
    
    localparam START_MEMORY_ADDRESS =   NODE_ID * SIZE * BYTE;
    localparam END_MEMORY_ADDRESS   =  (NODE_ID + 1) * SIZE * BYTE - 1;

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
    //Request acknowledge

    /* Two ports: 
    First for internal memory,
    Second for NoC requests
    */

    always_ff @( posedge clk or negedge rst_n ) begin //First port logic
        if(!rst_n) begin
            internal_memory_data_address <= '0;
        end else begin
            if(lsu2dmem_addr_i >= START_MEMORY_ADDRESS & su2dmem_addr_i <= END_MEMORY_ADDRESS) begin
                //Memory hit TODO
                
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