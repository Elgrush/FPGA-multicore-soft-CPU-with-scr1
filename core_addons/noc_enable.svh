`ifndef NOC_ENABLE
`define NOC_ENABLE 1

// NoC
`define NOC_NODE_COUNT 			8
`define NOC_MAX_PAYLOAD 		32
`define NOC_FLIT_PAYLOAD 		8
`define NOC_FLIT_WIDTH			22
`define NOC_PACKET_ID_WIDTH 	5
`define NOC_BYTE 				8

// Collector
`define COLLECTOR_BUFFER_SIZE 	8

// Splitter
`define SPLITTER_QUEUE_DEPTH 4
`endif
