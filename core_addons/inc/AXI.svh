`ifndef AXI
`define AXI

enum {TREQ, TRESP} TPACKAGETYPE;

parameter TDATA_WIDTH=$size(type_scr1_mem_cmd_e) + SCR1_IMEM_AWIDTH + SCR1_IMEM_DWIDTH;

typedef struct packed {
    logic TPACKAGETYPE                      tPackageType,
    logic [TDATA_WIDTH-1:0]                 tData,
    logic [TDATA_WIDTH/8-1:0]               tData_width,
    logic [TDATA_WIDTH/8-1:0]               tStrb
} TPACKAGE;

typedef struct packed {
    logic type_scr1_mem_cmd_e               tData_command,
    logic [SCR1_IMEM_AWIDTH/8-1:0]          tData_address,
    logic [SCR1_IMEM_DWIDTH/8-1:0]          tData_data
} TDATA_REQ;

typedef struct packed {
    logic type_scr1_mem_resp_e              tData_resp,
    logic [SCR1_IMEM_AWIDTH/8-1:0]          tData_address,
    logic [SCR1_IMEM_DWIDTH/8-1:0]          tData_data
} TDATA_RESP;

`endif
