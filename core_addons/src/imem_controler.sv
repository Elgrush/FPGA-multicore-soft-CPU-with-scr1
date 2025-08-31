`include "scr1_arch_description.svh"
`include "memory.svh"
`include "AXI.svh"

module imem_controler (
    input clk, rst_n,

    // RAM access
    output logic                                     mem_we_o,
	output logic [(`RDATA_WIDTH-1):0]                mem_data_o,
	output logic [(`RADDR_WIDTH-1):0]                mem_addr_o,
	input  logic [(`RDATA_WIDTH-1):0]                mem_data_i,

	// Instruction Memory Interface
    output   logic                                   imem2core_req_ack_o,        // IMEM request acknowledge
    input    logic                                   core2imem_req_i,            // IMEM request
    input    type_scr1_mem_cmd_e                     core2imem_cmd_i,            // IMEM command
    input    logic [`SCR1_IMEM_AWIDTH-1:0]           core2imem_addr_i,           // IMEM address
    output   logic [`SCR1_IMEM_DWIDTH-1:0]           imem2core_rdata_o,          // IMEM read data
    output   type_scr1_mem_resp_e                    imem2core_resp_o            // IMEM response

    // AXI stream Interface
    input    logic                                   tValid_i,
    output   logic                                   tValid_o,

    input    logic                                   tReady_i,
    output   logic                                   tReady_o,

    input    TPACKAGE                                tPackage_i,
    output   TPACKAGE                                TPACKAGE_o,

);

    logic   has_request_in_work;
    TDATA_REQ   request_in_work;
    
    logic  has_response_in_work;
    TDATA_RESP response_in_work;

    always_ff @( posedge clk or negedge rst_n ) begin: CoreInterfaceInput
        if(!rst_n) begin
            imem2core_req_ack_o    <= '0;
        end else if(!has_request_in_work && core2imem_req_i) begin
            imem2core_req_ack_o  <= 1'b1;
            has_request_in_work  <= 1'b1;
            request_in_work.tData_command  <= core2imem_cmd_i;
            request_in_work.tData_address <= core2imem_addr_i;
        end else begin
            imem2core_req_ack_o <= 1'b0;
        end
    end

    always_ff @( posedge clk or negedge rst_n ) begin: CoreInterfaceOutput
        if(!rst_n) begin
            imem2core_rdata_o      <= '0;
            imem2core_resp_o       <= '0;
        end else begin
            //TODO
        end
    end

    always_ff @( posedge clk or negedge rst_n ) begin: AXIBlockInput
        if(!rst_n) begin
            tReady_o      <= '0;
        end else begin
            if(TPACKAGE.tPackageType == TREQUEST) begin
                if(!has_request_in_work && !core2imem_req_i && tValid_i) begin
                    has_request_in_work  <= 1'b1;
                    request_in_work      <= tPackage_i.tData;
                end
            end else begin
                if(!has_responce_in_work && tValid_i) begin
                    has_responce_in_work  <= 1'b1;
                    response_in_work      <= tPackage_i.tData;
                end
            end
        end
    end
    
    always_ff @( posedge clk or negedge rst_n ) begin: AXIBlockOutput
        if(!rst_n) begin
            tValid_o      <= '0;
            TPACKAGE_o    <= '0;
        end else begin
            //TODO
        end
    end

    always_ff @( posedge clk or negedge rst_n ) begin: RamBlock
        if(!rst_n) begin
            mem_we_o      <= '0;
            mem_data_o    <= '0;
            mem_addr_o    <= '0;
        end else begin
            //TODO
        end
    end


    //Main Logic
    // TODO

endmodule : imem_controler
