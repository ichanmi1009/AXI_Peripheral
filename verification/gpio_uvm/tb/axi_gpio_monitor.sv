class axi_gpio_monitor extends uvm_monitor;
    `uvm_component_utils(axi_gpio_monitor)

    virtual axi_gpio_if a_if;
    uvm_analysis_port #(axi_gpio_seq_item) ap;

    logic [7:0] prev_io_port;

    function new(string name, uvm_component parent);
        super.new(name, parent);
        ap = new("ap", this);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        if (!uvm_config_db#(virtual axi_gpio_if)::get(
                this, "", "a_if", a_if
            )) begin
            `uvm_fatal(
                get_type_name(),
                "virtual interface(a_if)를 config_db에서 찾지 못함.")
        end
    endfunction

    task run_phase(uvm_phase phase);
        prev_io_port = a_if.io_port;
        fork
            watch_write();
            watch_read();
            watch_pin();
        join
    endtask

    task watch_write();
        axi_gpio_seq_item tr;
        forever begin
            @(posedge a_if.clk);
            if (a_if.reset && a_if.awvalid && a_if.awready) begin
                tr       = axi_gpio_seq_item::type_id::create("tr");
                tr.dir   = axi_gpio_seq_item::AXI_WRITE;
                tr.addr  = a_if.awaddr;
                tr.wdata = a_if.wdata;
                tr.wstrb = a_if.wstrb;

                do @(posedge a_if.clk); while (!a_if.bvalid);
                tr.bresp = a_if.bresp;

                `uvm_info(get_type_name(), tr.convert2string(), UVM_HIGH)
                ap.write(tr);
            end
        end
    endtask

    task watch_read();
        axi_gpio_seq_item tr;
        forever begin
            @(posedge a_if.clk);
            if (a_if.reset && a_if.arvalid && a_if.arready) begin
                tr      = axi_gpio_seq_item::type_id::create("tr");
                tr.dir  = axi_gpio_seq_item::AXI_READ;
                tr.addr = a_if.araddr;

                do @(posedge a_if.clk); while (!a_if.rvalid);
                tr.rdata = a_if.rdata;
                tr.rresp = a_if.rresp;

                `uvm_info(get_type_name(), tr.convert2string(), UVM_HIGH)
                ap.write(tr);
            end
        end
    endtask

    task watch_pin();
        axi_gpio_seq_item tr;
        forever begin
            @(posedge a_if.clk);
            if (a_if.io_port !== prev_io_port) begin
                tr                 = axi_gpio_seq_item::type_id::create("tr");
                tr.is_pin_event    = 1'b1;
                tr.io_port_sampled = a_if.io_port;
                tr.drive_en        = a_if.drive_en;
                tr.drive_data      = a_if.drive_data;

                `uvm_info(get_type_name(), tr.convert2string(), UVM_HIGH)
                ap.write(tr);
                prev_io_port = a_if.io_port;
            end
        end
    endtask

endclass
