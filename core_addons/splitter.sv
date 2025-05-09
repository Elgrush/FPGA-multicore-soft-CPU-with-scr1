`include "packet_type.svh"
`include "scr1_memif.svh"   //For data widths

module splitter #(
    parameter int NODE_ID = 0, NODE_COUNT = 8, PACKET_ID_WIDTH = 5,
    QUEUE_DEPTH = 8, INPUT_WIDTH = 100,
    MAX_PAYLOAD = 64, FLIT_PAYLOAD = 8,
    BYTE = 8,
    X = 3, Y = 3) (

    input  logic                                clk, ce, rst_n,
    input  logic [MAX_PAYLOAD - 1 : 0]              packet_in,
    input  logic [$clog2(NODE_COUNT) - 1 : 0]   node_dest,

    input  type_packet_type                     packet_type,
    /*
    typedef enum logic[2:0] {
        //Packets for DMEM
        DMEM_REQ_READ       =  3'b000,
        DMEM_REQ_WRITE      =  3'b001,
        DMEM_RESP_DATA      =  3'b010,
        DMEM_RESP_WRITTEN   =  3'b011,
        DMEM_RESP_BAD       =  3'b100,

        //Packets for IMEM
        IMEM_REQ_READ       =  3'b101,
        IMEM_RESP_DATA      =  3'b110,
        IMEM_RESP_BAD       =  3'b111

    }   type_packet_type;
    */

    input  type_scr1_mem_width_e                mem_width,
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
    
    input  logic                                valid_in,
    input  logic [PACKET_ID_WIDTH - 1 : 0]      packet_id,

    output logic [INPUT_WIDTH - 1 : 0]          output_data,
    output logic                                valid_out,
    output logic                                ack
);

localparam FLIT_COUNT_MAX_WIDTH = $clog2(MAX_PAYLOAD / FLIT_PAYLOAD + (MAX_PAYLOAD % FLIT_PAYLOAD != 0));

logic [FLIT_COUNT_MAX_WIDTH - 1 : 0] FLIT_COUNT;

logic [FLIT_COUNT_MAX_WIDTH - 1 : 0] FLIT_COUNT_SINGLE      =    1;
logic [FLIT_COUNT_MAX_WIDTH - 1 : 0] FLIT_COUNT_BYTE_1      =    MAX_PAYLOAD / BYTE     + (MAX_PAYLOAD % (BYTE    ) != 0);
logic [FLIT_COUNT_MAX_WIDTH - 1 : 0] FLIT_COUNT_BYTE_2      =    MAX_PAYLOAD / BYTE * 2 + (MAX_PAYLOAD % (BYTE * 2) != 0);
logic [FLIT_COUNT_MAX_WIDTH - 1 : 0] FLIT_COUNT_BYTE_4      =    MAX_PAYLOAD / BYTE * 4 + (MAX_PAYLOAD % (BYTE * 4) != 0);
logic [FLIT_COUNT_MAX_WIDTH - 1 : 0] FLIT_COUNT_BYTE_5      =    MAX_PAYLOAD / BYTE * 5 + (MAX_PAYLOAD % (BYTE * 5) != 0);
logic [FLIT_COUNT_MAX_WIDTH - 1 : 0] FLIT_COUNT_BYTE_6      =    MAX_PAYLOAD / BYTE * 6 + (MAX_PAYLOAD % (BYTE * 6) != 0);
logic [FLIT_COUNT_MAX_WIDTH - 1 : 0] FLIT_COUNT_BYTE_8      =    MAX_PAYLOAD / BYTE * 8 + (MAX_PAYLOAD % (BYTE * 8) != 0);

logic [2*$clog2(NODE_COUNT) - 1:0] NOC_ADDRESSES[NODE_COUNT-1:0];

logic [$clog2(NODE_COUNT) - 1 : 0] node_dest_encoded;

logic [MAX_PAYLOAD - 1 : 0] queue [0 : QUEUE_DEPTH - 1];
logic [$clog2(NODE_COUNT) - 1 : 0] node_queue [0 : QUEUE_DEPTH - 1];  
logic [PACKET_ID_WIDTH - 1 : 0] id_queue [0 : QUEUE_DEPTH - 1];
logic [$clog2(FLIT_COUNT) - 1 : 0] byte_counter;
logic [$clog2(QUEUE_DEPTH) - 1 : 0] head, tail; 
logic [$clog2(QUEUE_DEPTH) : 0] count; 
logic [$clog2(NODE_COUNT) - 1 : 0] node_in;
assign node_in = NODE_ID[$clog2(NODE_COUNT) - 1 : 0];
int i;

generate
    genvar gen_i;
    for (gen_i = 0; gen_i < NODE_COUNT; gen_i = gen_i + 1) begin : address_array_gen
        wire [$clog2(X)-1: 0] c1 = gen_i%X;
        wire [$clog2(Y)-1: 0] c2 = gen_i/X;

        assign NOC_ADDRESSES[gen_i] = {c1, c2};
    end
endgenerate

assign node_dest_encoded = NOC_ADDRESSES[node_dest];

//Computing flit counter
always_comb begin
    case (packet_type)
        DMEM_RESP_WRITTEN, DMEM_RESP_BAD, IMEM_RESP_BAD :   FLIT_COUNT = FLIT_COUNT_SINGLE; // 0 bytes
        IMEM_REQ_READ, DMEM_REQ_READ, IMEM_RESP_DATA    :   FLIT_COUNT = FLIT_COUNT_BYTE_4; // 4 byte address
        //Handling IMEM responses
        default : begin
            case (mem_width)
                SCR1_MEM_WIDTH_BYTE                     :   FLIT_COUNT = FLIT_COUNT_BYTE_5; // 4 byte address and 1 byte data
                SCR1_MEM_WIDTH_HWORD                    :   FLIT_COUNT = FLIT_COUNT_BYTE_6; // 4 byte address and 2 byte data
                default:   // SCR1_MEM_WIDTH_WORD
                                                            FLIT_COUNT = FLIT_COUNT_BYTE_8; // 4 byte address and 4 byte data
            endcase;
        end
    endcase
end


//Acknowledge signal
always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        ack <= 0;
    end
    else begin
        ack <= &{rst_n, valid_in, count < QUEUE_DEPTH};
    end
end

always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        head <= 0;
        tail <= 0;
        count <= 0;
        byte_counter <= 0;
        valid_out <= 0;
        output_data <= 0;
    end else if (ce) begin
        if (&{rst_n, valid_in, count < QUEUE_DEPTH}) begin
            queue[tail] <= packet_in;
            node_queue[tail] <= node_dest_encoded;
            id_queue[tail]   <= packet_id;   
            tail <= (tail + 1) % QUEUE_DEPTH;
            count <= count + 1;
        end

        if (count > 0) begin
            if(packet_type == DMEM_REQ_READ | DMEM_REQ_WRITE)
                output_data <= {1'b1, node_queue[head], mem_width, {FLIT_PAYLOAD{1'b0}}, id_queue[head], node_in, byte_counter};
            else
                output_data <= {1'b1, node_queue[head], packet_type, {FLIT_PAYLOAD{1'b0}}, id_queue[head], node_in, byte_counter};
            for(i=0; i < FLIT_PAYLOAD; i = i + 1)
                output_data[FLIT_COUNT_MAX_WIDTH + $clog2(NODE_COUNT) + PACKET_ID_WIDTH + i] <= queue[head][byte_counter*FLIT_PAYLOAD+i];
            
            //In and out simultaneously
            if(byte_counter == FLIT_COUNT - 1) begin
                head <= (head == QUEUE_DEPTH - 1) ? 0 : head + 1;
                count <= count - !(&{rst_n, valid_in, count < QUEUE_DEPTH});
            end

            valid_out <= 1;
            byte_counter <= (byte_counter == FLIT_COUNT - 1) ? 0 : byte_counter + 1;
        end else begin
            valid_out <= 0;
            output_data <= 0;
        end
    end
end

endmodule
