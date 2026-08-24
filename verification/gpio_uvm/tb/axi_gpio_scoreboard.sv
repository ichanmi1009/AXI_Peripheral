class axi_gpio_scoreboard extends uvm_scoreboard;
    `uvm_component_utils(axi_gpio_scoreboard)

    uvm_analysis_imp #(axi_gpio_seq_item, axi_gpio_scoreboard) imp;

    bit [31:0] reg_cr;
    bit [31:0] reg_idr;
    bit [31:0] reg_odr;

    bit [7:0] ext_en;
    bit [7:0] ext_data;

    int reg_pass = 0;
    int reg_fail = 0;
    int pin_pass = 0;
    int pin_fail = 0;

    function new(string name, uvm_component parent);
        super.new(name, parent);
        imp = new("imp", this);
    endfunction

    function void write(axi_gpio_seq_item tr);
        if (tr.is_pin_event) begin
            ext_en   = tr.drive_en;
            ext_data = tr.drive_data;
            check_pin(tr.io_port_sampled);
        end else if (tr.dir == axi_gpio_seq_item::AXI_WRITE) begin
            do_write(tr);
        end else begin
            do_read(tr);
        end
    endfunction

    function bit [31:0] apply_strb(bit [31:0] cur, bit [31:0] wdata,
                                   bit [3:0] strb);
        bit [31:0] result = cur;
        for (int i = 0; i < 4; i++) if (strb[i]) result[i*8+:8] = wdata[i*8+:8];
        return result;
    endfunction

    function void do_write(axi_gpio_seq_item tr);
        case (tr.addr)
            4'h0: reg_cr = apply_strb(reg_cr, tr.wdata, tr.wstrb);
            4'h4: reg_idr = apply_strb(reg_idr, tr.wdata, tr.wstrb);
            4'h8: reg_odr = apply_strb(reg_odr, tr.wdata, tr.wstrb);
        endcase

        if (tr.bresp !== 2'b00)
            `uvm_error(get_type_name(), $sformatf(
                       "BRESP 오류, addr=0x%0h", tr.addr))
    endfunction

    function logic [7:0] expect_idr();
        logic [7:0] val;
        for (int i = 0; i < 8; i++) begin
            if (reg_cr[i]) val[i] = 1'bz;
            else val[i] = ext_en[i] ? ext_data[i] : 1'bz;
        end
        return val;
    endfunction

    function void do_read(axi_gpio_seq_item tr);
        logic [31:0] expected;

        case (tr.addr)
            4'h0: expected = reg_cr;
            4'h8: expected = reg_odr;
            4'h4: expected = {24'h0, expect_idr()};
            default: return;
        endcase

        if (tr.rdata === expected) begin
            reg_pass++;
            `uvm_info(get_type_name(), $sformatf("PASS addr=0x%0h data=0x%0h",
                                                 tr.addr, tr.rdata), UVM_HIGH)
        end else begin
            reg_fail++;
            `uvm_error(get_type_name(), $sformatf(
                       "FAIL addr=0x%0h expect=0x%0h actual=0x%0h",
                       tr.addr,
                       expected,
                       tr.rdata
                       ))
        end
    endfunction

    function void check_pin(logic [7:0] sampled);
        for (int i = 0; i < 8; i++) begin
            if (reg_cr[i]) begin
                if (sampled[i] === reg_odr[i]) pin_pass++;
                else begin
                    pin_fail++;
                    `uvm_error(get_type_name(), $sformatf(
                               "FAIL io_port[%0d] output expect=%0b actual=%0b",
                               i,
                               reg_odr[i],
                               sampled[i]
                               ))
                end
            end else if (ext_en[i]) begin
                if (sampled[i] === ext_data[i]) pin_pass++;
                else begin
                    pin_fail++;
                    `uvm_error(get_type_name(), $sformatf(
                               "FAIL io_port[%0d] input expect=%0b actual=%0b",
                               i,
                               ext_data[i],
                               sampled[i]
                               ))
                end
            end
        end
    endfunction

    function void report_phase(uvm_phase phase);
        super.report_phase(phase);
        `uvm_info("SCB", "==========================================", UVM_LOW)
        `uvm_info("SCB", "=========== axi_gpio Scoreboard 결과 ===========",
                  UVM_LOW)
        `uvm_info("SCB", $sformatf(
                  " 레지스터 : PASS = %0d, FAIL = %0d", reg_pass, reg_fail),
                  UVM_LOW)
        `uvm_info("SCB", $sformatf(
                  " 핀        : PASS = %0d, FAIL = %0d", pin_pass, pin_fail),
                  UVM_LOW)
        `uvm_info("SCB", "==========================================", UVM_LOW)
    endfunction

endclass
