//Including NoC
`include "../mesh_3x3/noc/toplevel.sv"

//Including converters
`include "../converters/packet_collector.sv"
`include "../converters/splitter.sv"

//Including core pipeline
`include "../scr1/src/core/pipeline/scr1_ipic.sv"
`include "../scr1/src/core/pipeline/scr1_pipe_csr.sv"
`include "../scr1/src/core/pipeline/scr1_pipe_exu.sv"
`include "../scr1/src/core/pipeline/scr1_pipe_hdu.sv"
`include "../scr1/src/core/pipeline/scr1_pipe_ialu.sv"
`include "../scr1/src/core/pipeline/scr1_pipe_idu.sv"
//`include "../scr1/src/core/pipeline/scr1_pipe_ifu.sv"
//`include "../scr1/src/core/pipeline/scr1_pipe_lsu.sv"
`include "../scr1/src/core/pipeline/scr1_pipe_mprf.sv"
`include "../scr1/src/core/pipeline/scr1_pipe_tdu.sv"
`include "../scr1/src/core/pipeline/scr1_pipe_top.sv"
`include "../scr1/src/core/pipeline/scr1_tracelog.sv"

//Including core custom pipeline
`include "../core_addons/scr1_pipe_ifu.sv"
`include "../core_addons/scr1_pipe_lsu.sv"

//Including core top
`include "../scr1/src/core/scr1_core_top.sv"

//Include core primitives
`include "../scr1/src/core/primitives/scr1_cg.sv"
`include "../scr1/src/core/primitives/scr1_reset_cells.sv"

//Including core reqs
`include "../scr1/src/core/scr1_clk_ctrl.sv"
`include "../scr1/src/core/scr1_dm.sv"
`include "../scr1/src/core/scr1_dmi.sv"
`include "../scr1/src/core/scr1_scu.sv"
`include "../scr1/src/core/scr1_tapc.sv"
`include "../scr1/src/core/scr1_tapc_shift_reg.sv"
`include "../scr1/src/core/scr1_tapc_synchronizer.sv"
