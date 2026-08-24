class axi_gpio_coverage extends uvm_subscriber #(axi_gpio_seq_item);
    `uvm_component_utils(axi_gpio_coverage)

    axi_gpio_seq_item tr;

    covergroup axi_gpio_cg;
        option.per_instance = 1;

        cp_addr: coverpoint tr.addr iff (!tr.is_pin_event) {
            bins cr = {4'h0}; bins idr = {4'h4}; bins odr = {4'h8};
        }
        cp_dir: coverpoint tr.dir iff (!tr.is_pin_event);
        cp_wstrb: coverpoint tr.wstrb iff (!tr.is_pin_event && tr.dir == axi_gpio_seq_item::AXI_WRITE) {
            bins full = {4'hF};
            bins byte0 = {4'h1};
            bins byte1 = {4'h2};
            bins byte2 = {4'h4};
            bins byte3 = {4'h8};
            bins others = default;
        }
        cp_pin: coverpoint tr.drive_en iff (tr.is_pin_event) {
            bins none = {8'h00};
            bins all = {8'hFF};
            bins one_hot[] = {8'h01, 8'h02, 8'h04, 8'h08, 8'h10, 8'h20, 8'h40, 8'h80};
            bins others = default;
        }
        cx_addr_dir: cross cp_addr, cp_dir;
    endgroup

    function new(string name, uvm_component parent);
        super.new(name, parent);
        axi_gpio_cg = new();
    endfunction

    function void write(axi_gpio_seq_item t);
        tr = t;
        axi_gpio_cg.sample();
    endfunction

    function void report_phase(uvm_phase phase);
        super.report_phase(phase);
        `uvm_info("COV", "========================================", UVM_LOW)
        `uvm_info("COV", "======== Functional Coverage 결과 ======", UVM_LOW)
        `uvm_info("COV", $sformatf(
                  " 전체         : %6.2f %%", axi_gpio_cg.get_inst_coverage()
                  ), UVM_LOW)
        `uvm_info("COV", $sformatf(
                  " 레지스터 주소: %6.2f %%",
                  axi_gpio_cg.cp_addr.get_inst_coverage()
                  ), UVM_LOW)
        `uvm_info(
            "COV", $sformatf(
            " R/W 방향     : %6.2f %%", axi_gpio_cg.cp_dir.get_inst_coverage()
            ), UVM_LOW)
        `uvm_info("COV", $sformatf(
                  " WSTRB 패턴   : %6.2f %%",
                  axi_gpio_cg.cp_wstrb.get_inst_coverage()
                  ), UVM_LOW)
        `uvm_info("COV", $sformatf(
                  " 핀 드라이브  : %6.2f %%",
                  axi_gpio_cg.cp_pin.get_inst_coverage()
                  ), UVM_LOW)
        `uvm_info("COV", "=======================================", UVM_LOW)
        if (axi_gpio_cg.get_inst_coverage() < 100.0) begin
            `uvm_warning(
                "COV",
                "커버리지 100% 미달! 시나리오를 추가하거나 더 테스트를 진행하시오.")
        end
    endfunction

endclass
