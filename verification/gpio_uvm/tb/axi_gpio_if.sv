interface axi_gpio_if (
    input logic clk,
    input logic reset
);
    wire  [7:0] io_port;
    logic [7:0] drive_en;
    logic [7:0] drive_data;

    genvar gi;
    generate
        for (gi = 0; gi < 8; gi++) begin : g_ext_drv
            assign io_port[gi] = drive_en[gi] ? drive_data[gi] : 1'bz;
        end
    endgenerate

    // Write Address Channel
    logic [ 3:0] awaddr;
    logic [ 2:0] awprot;
    logic        awvalid;
    logic        awready;
    // Write Data Channel
    logic [31:0] wdata;
    logic [ 3:0] wstrb;
    logic        wvalid;
    logic        wready;
    // Write Response Channel
    logic [ 1:0] bresp;
    logic        bvalid;
    logic        bready;
    // Read Address Channel
    logic [ 3:0] araddr;
    logic [ 2:0] arprot;
    logic        arvalid;
    logic        arready;
    // Read Data Channel
    logic [31:0] rdata;
    logic [ 1:0] rresp;
    logic        rvalid;
    logic        rready;

endinterface
