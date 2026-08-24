class axi_gpio_seq_item extends uvm_sequence_item;

    typedef enum bit {
        AXI_WRITE = 0,
        AXI_READ  = 1
    } axi_dir_e;

    rand axi_dir_e        dir;
    rand bit       [ 3:0] addr;  // 0x0=CR, 0x4=IDR, 0x8=ODR
    rand bit       [31:0] wdata;
    rand bit       [ 3:0] wstrb;

    rand bit       [ 7:0] drive_en;
    rand bit       [ 7:0] drive_data;

    logic          [31:0] rdata;
    logic          [ 1:0] bresp;
    logic          [ 1:0] rresp;
    logic          [ 7:0] io_port_sampled;
    bit                   is_pin_event;

    constraint c_addr {addr inside {4'h0, 4'h4, 4'h8};}
    constraint c_wstrb {wstrb != 4'h0;}

    `uvm_object_utils_begin(axi_gpio_seq_item)
        `uvm_field_enum(axi_dir_e, dir, UVM_ALL_ON)
        `uvm_field_int(addr, UVM_ALL_ON)
        `uvm_field_int(wdata, UVM_ALL_ON)
        `uvm_field_int(wstrb, UVM_ALL_ON)
        `uvm_field_int(drive_en, UVM_ALL_ON)
        `uvm_field_int(drive_data, UVM_ALL_ON)
        `uvm_field_int(rdata, UVM_ALL_ON | UVM_NOPACK)
        `uvm_field_int(bresp, UVM_ALL_ON | UVM_NOPACK)
        `uvm_field_int(rresp, UVM_ALL_ON | UVM_NOPACK)
        `uvm_field_int(io_port_sampled, UVM_ALL_ON | UVM_NOPACK)
        `uvm_field_int(is_pin_event, UVM_ALL_ON | UVM_NOPACK)
    `uvm_object_utils_end

    function new(string name = "axi_gpio_seq_item");
        super.new(name);
    endfunction

    function string convert2string();
        if (is_pin_event)
            return $sformatf(
                "PIN io_port=0x%02h drive_en=0x%02h drive_data=0x%02h",
                io_port_sampled,
                drive_en,
                drive_data
            );
        else if (dir == AXI_WRITE)
            return $sformatf(
                "WR addr=0x%0h wdata=0x%08h wstrb=0x%0h bresp=%0d",
                addr,
                wdata,
                wstrb,
                bresp
            );
        else
            return $sformatf(
                "RD addr=0x%0h rdata=0x%08h rresp=%0d", addr, rdata, rresp
            );
    endfunction

endclass
