import uvm_pkg::*;
import axi_gpio_pkg::*;  // 헤더 파일

module tb_top ();
    logic clk;
    logic resetn;

    initial begin
        clk = 0;
        resetn = 0;
        repeat (10) @(posedge clk);
        resetn = 1;
    end

    always #5 clk = ~clk;

    axi_gpio_if a_if (
        .clk  (clk),
        .reset(resetn)
    );

    gpio_v1_0 dut (
        .io_port        (a_if.io_port),
        .s00_axi_aclk   (clk),
        .s00_axi_aresetn(resetn),
        .s00_axi_awaddr (a_if.awaddr),
        .s00_axi_awprot (a_if.awprot),
        .s00_axi_awvalid(a_if.awvalid),
        .s00_axi_awready(a_if.awready),
        .s00_axi_wdata  (a_if.wdata),
        .s00_axi_wstrb  (a_if.wstrb),
        .s00_axi_wvalid (a_if.wvalid),
        .s00_axi_wready (a_if.wready),
        .s00_axi_bresp  (a_if.bresp),
        .s00_axi_bvalid (a_if.bvalid),
        .s00_axi_bready (a_if.bready),
        .s00_axi_araddr (a_if.araddr),
        .s00_axi_arprot (a_if.arprot),
        .s00_axi_arvalid(a_if.arvalid),
        .s00_axi_arready(a_if.arready),
        .s00_axi_rdata  (a_if.rdata),
        .s00_axi_rresp  (a_if.rresp),
        .s00_axi_rvalid (a_if.rvalid),
        .s00_axi_rready (a_if.rready)
    );

    initial begin
        uvm_config_db#(virtual axi_gpio_if)::set(null, "*", "a_if", a_if);
        run_test("");
    end

    initial begin
        $fsdbDumpfile(
            "axi_gpio_tb.fsdb");  
        $fsdbDumpvars(0);
    end

endmodule
