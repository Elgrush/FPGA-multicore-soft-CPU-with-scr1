//Including NoC
`include "../mesh_3x3/noc/toplevel.sv"

//Including converters
`include "../converters/packet_collector.sv"
`include "../converters/splitter.sv"

//Including core
`include "../scr1/src/core/pipeline/scr1_ipic.sv"
`include "../scr1/src/core/pipeline/scr1_pipe_csr.sv"
`include "../scr1/src/core/pipeline/scr1_pipe_exu.sv"
`include "../scr1/src/core/pipeline/scr1_pipe_hdu.sv"
`include "../scr1/src/core/pipeline/scr1_pipe_ialu.sv"
`include "../scr1/src/core/pipeline/scr1_pipe_idu.sv"
`include "../scr1/src/core/pipeline/scr1_pipe_ifu.sv"
`include "../scr1/src/core/pipeline/scr1_pipe_lsu.sv"
`include "../scr1/src/core/pipeline/scr1_pipe_mprf.sv"
`include "../scr1/src/core/pipeline/scr1_pipe_tdu.sv"
`include "../scr1/src/core/pipeline/scr1_pipe_top.sv"
`include "../scr1/src/core/pipeline/scr1_tracelog.sv"
`include "../scr1/src/core/primitives/scr1_reset_cells.sv"

`include "../scr1/src/core/scr1_core_top.sv"
