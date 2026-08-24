class axi_gpio_driver extends uvm_driver #(axi_gpio_seq_item);
    `uvm_component_utils(axi_gpio_driver)

    virtual axi_gpio_if a_if;

    function new(string name, uvm_component parent);
        super.new(name, parent);
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
        reset_signals();
        wait (a_if.reset === 1'b1);

        forever begin
            seq_item_port.get_next_item(req);
            `uvm_info("driver", $sformatf(
                      "get_next_item: %s", req.convert2string()), UVM_DEBUG)

            a_if.drive_en   <= req.drive_en;
            a_if.drive_data <= req.drive_data;

            if (req.dir == axi_gpio_seq_item::AXI_WRITE) do_write(req);
            else do_read(req);

            `uvm_info(get_type_name(), $sformatf(
                      "구동: %s", req.convert2string()), UVM_HIGH)
            seq_item_port.item_done();
        end
    endtask

    task reset_signals();
        a_if.awaddr     <= 0;
        a_if.awprot     <= 0;
        a_if.awvalid    <= 1'b0;
        a_if.wdata      <= 0;
        a_if.wstrb      <= 0;
        a_if.wvalid     <= 1'b0;
        a_if.bready     <= 1'b1;
        a_if.araddr     <= 0;
        a_if.arprot     <= 0;
        a_if.arvalid    <= 1'b0;
        a_if.rready     <= 1'b1;
        a_if.drive_en   <= 0;
        a_if.drive_data <= 0;
    endtask

    task do_write(axi_gpio_seq_item item);
        a_if.awaddr  <= item.addr;
        a_if.awvalid <= 1'b1;
        a_if.wdata   <= item.wdata;
        a_if.wstrb   <= item.wstrb;
        a_if.wvalid  <= 1'b1;

        do @(posedge a_if.clk); while (!(a_if.awready && a_if.wready));
        a_if.awvalid <= 1'b0;
        a_if.wvalid  <= 1'b0;

        a_if.bready  <= 1'b1;
        do @(posedge a_if.clk); while (!a_if.bvalid);
        item.bresp = a_if.bresp;
        @(posedge a_if.clk);
    endtask

    task do_read(axi_gpio_seq_item item);
        a_if.araddr  <= item.addr;
        a_if.arprot  <= 3'b000;
        a_if.arvalid <= 1'b1;

        do @(posedge a_if.clk); while (!a_if.arready);
        a_if.arvalid <= 1'b0;

        a_if.rready  <= 1'b1;
        do @(posedge a_if.clk); while (!a_if.rvalid);
        item.rdata = a_if.rdata;
        item.rresp = a_if.rresp;
        @(posedge a_if.clk);
    endtask

endclass
