`ifndef PACKET_TYPE
`define PACKET_TYPE

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

`endif // PACKET_TYPE
