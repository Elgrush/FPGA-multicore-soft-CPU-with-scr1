module cpu_with_ram #(parameter int NODE_ID = 0, NODE_COUNT = 9, SPLITTER_DEPTH = 8, COLLECTOR_DEPTH = 8, parameter int PACKET_ID_WIDTH = 5) (
    input  logic clk, rst_n,

    input logic [1 + 2*$clog2(NODE_COUNT) + 17 + PACKET_ID_WIDTH - 1 + 2 : 0] flitIn,
    output logic readFromNoc,

    output logic [1 + 2*$clog2(NODE_COUNT) + 17 + PACKET_ID_WIDTH - 1 + 2 : 0] flitOut,
    input logic writeToNoc
);
    // CPU-Controller
    wire[31:0] dataToCpu;
    wire[31:0] dataFromCpu;
    wire[31:0] logicalRamAddress;
    wire[2:0] instr;
    wire dataReceived;
    wire instrTaken;

    // Controller-RAM
    wire[31:0] rdData;
    wire[31:0] physicalRamAddress;
    wire[31:0] wrData;
    wire we;

    // Controller-Spliiter
    wire[67:0] packetOut;
    wire[$clog2(NODE_COUNT) - 1 : 0] nodeDest;
    wire[PACKET_ID_WIDTH-1:0] packetId;
    wire validControllerSplitter;

    // Controller-Collector
    wire validCollectorRam;
    wire readFromCollector;
    wire [71:0] packetIn;
    wire [$clog2(NODE_COUNT)-1:0] nodeStart;

    sr_cpu #(.NODE_ID(NODE_ID)) core (
        .clk(clk), .rst_n(rst_n),
        .dataToCpu(dataToCpu),
        .dataReceived(dataReceived),
        .instrTaken(instrTaken),
        .dataFromCpu(dataFromCpu),
        .ramAddress(logicalRamAddress),
        .aguInstructionOut(instr)
    );

    sr_mem_ctrl #(
        .NODE_ID(NODE_ID), .NODE_COUNT(NODE_COUNT), .RAM_CHUNK_SIZE(1024), .PACKET_ID_WIDTH(PACKET_ID_WIDTH)
    ) mc (

        // CPU
        .clk(clk), .rst_n(rst_n),
        .memData(dataFromCpu),
        .memAddress(logicalRamAddress),
        .memInstr(instr),
        .dataToCpu(dataToCpu),
        .dataSent(dataReceived),
        .instrTaken(instrTaken),

        // RAM
        .rdData(rdData),
        .ramAddress(physicalRamAddress),
        .wrData(wrData),
        .we(we),

        // splitter/collector
        .packetIn(packetIn),
        .nodeStart(nodeStart),
        .validIn(validCollectorRam),
        .readyToReceive(readFromCollector),

        .packetOut(packetOut), 
        .nodeDest(nodeDest),
        .packetId(packetId),
        .validOut(validControllerSplitter)
    );

    ram #(
        .RAM_SIZE(1024), .NODE_ID(NODE_ID)
    ) ram (
        .clk(clk), .rst_n(rst_n),
        .ramAddress(physicalRamAddress),
        .wrData(wrData),
        .we(we),
        .rdData(rdData)
    );

    splitter #(
        .NODE_ID(NODE_ID), .NODE_COUNT(NODE_COUNT), .QUEUE_DEPTH(SPLITTER_DEPTH), .PACKET_ID_WIDTH(PACKET_ID_WIDTH)
    ) spl (
        .clk(clk), .ce(1'b1), .rst_n(rst_n),
        .packet_in(packetOut),
        .node_dest(nodeDest),
        .valid_in(validControllerSplitter),
        .packet_id(packetId),
        .output_data(flitOut),
        .valid_out()
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
