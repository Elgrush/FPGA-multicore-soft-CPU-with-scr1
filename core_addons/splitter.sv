module splitter #(parameter int NODE_ID = 0, NODE_COUNT = 8, PACKET_ID_WIDTH = 5,
    QUEUE_DEPTH = 8, 
    PAYLOAD = 32, FLIT_PAYLOAD = 8,
    X = 3, Y = 3) (
    input  logic clk, ce, rst_n,
    input  logic [PAYLOAD - 1 : 0] packet_in,
    input  logic [$clog2(NODE_COUNT) - 1 : 0] node_dest,
    input  logic valid_in,
    input  logic [PACKET_ID_WIDTH - 1 : 0] packet_id,
    output logic [INPUT_WIDTH - 1 : 0] output_data,
    output logic valid_out,
    output logic ack
);

localparam int FLIT_COUNT = PAYLOAD / FLIT_PAYLOAD + (PAYLOAD % FLIT_PAYLOAD != 0);
localparam int INPUT_WIDTH = 1 + 2*$clog2(NODE_COUNT) + FLIT_PAYLOAD + PACKET_ID_WIDTH; 

logic [2*$clog2(NODE_COUNT)-1:0] NOC_ADDRESSES[NODE_COUNT-1:0];

logic [$clog2(NODE_COUNT) - 1 : 0] node_dest_encoded;

logic [PAYLOAD - 1 : 0] queue [0 : QUEUE_DEPTH - 1];
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
            output_data <= {1'b1, node_queue[head], {FLIT_PAYLOAD{1'b0}}, id_queue[head], node_in, byte_counter};
            for(i=0; i < FLIT_PAYLOAD; i = i + 1)
                output_data[$clog2(FLIT_COUNT) + $clog2(NODE_COUNT) + PACKET_ID_WIDTH + i] <= queue[head][byte_counter*FLIT_PAYLOAD+i];
            
            //In and out simultaneously
            if(byte_counter == FLIT_COUNT - 1) begin
                head <= (head == QUEUE_DEPTH - 1) ? 0 : head + 1;
                count <= count - !&{rst_n, valid_in, count < QUEUE_DEPTH};
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
