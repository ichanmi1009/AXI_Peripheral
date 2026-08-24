class axi_gpio_random_seq extends uvm_sequence #(axi_gpio_seq_item);
    `uvm_object_utils(axi_gpio_random_seq)

    rand int num;
    constraint c_num {num inside {[100 : 500]};}

    function new(string name = "axi_gpio_random_seq");
        super.new(name);
    endfunction

    task body();
        axi_gpio_seq_item item;

        item = axi_gpio_seq_item::type_id::create("item");
        start_item(item);
        item.dir   = axi_gpio_seq_item::AXI_WRITE;
        item.addr  = 4'h0;
        item.wdata = 32'h0;
        item.wstrb = 4'hF;
        finish_item(item);

        `uvm_info(get_type_name(),
                  $sformatf("random 시나리오 시작 (%0d 반복)", num),
                  UVM_LOW)

        repeat (num) begin
            item = axi_gpio_seq_item::type_id::create("item");
            start_item(item);
            if (!item.randomize() with {addr != 4'h0;}) begin
                `uvm_error("SEQ", "randomize 실패")
            end
            finish_item(item);
        end

        `uvm_info(get_type_name(), "random 시나리오 종료.", UVM_LOW)
    endtask
endclass


class axi_gpio_direct_seq extends uvm_sequence #(axi_gpio_seq_item);
    `uvm_object_utils(axi_gpio_direct_seq)

    function new(string name = "axi_gpio_direct_seq");
        super.new(name);
    endfunction

    task body();
        axi_gpio_seq_item item;
        bit [7:0] patterns[] = '{
            8'h00,
            8'hFF,
            8'h00,
            8'hAA,
            8'h55,
            8'hAA,
            8'h01,
            8'h02,
            8'h04,
            8'h08,
            8'h10,
            8'h20,
            8'h40,
            8'h80
        };

        `uvm_info(get_type_name(), "direct 시나리오 시작", UVM_LOW)

        // 8핀 전부 output으로 설정
        item = axi_gpio_seq_item::type_id::create("item");
        start_item(item);
        item.dir   = axi_gpio_seq_item::AXI_WRITE;
        item.addr  = 4'h0;
        item.wdata = 32'hFF;
        item.wstrb = 4'hF;
        finish_item(item);

        item = axi_gpio_seq_item::type_id::create("item");
        start_item(item);
        item.dir  = axi_gpio_seq_item::AXI_READ;
        item.addr = 4'h0;
        finish_item(item);

        // ODR에 패턴을 하나씩 써서 io_port가 그대로 따라오는지 확인 (scoreboard가 체크)
        foreach (patterns[i]) begin
            item = axi_gpio_seq_item::type_id::create("item");
            start_item(item);
            item.dir   = axi_gpio_seq_item::AXI_WRITE;
            item.addr  = 4'h8;
            item.wdata = {24'h0, patterns[i]};
            item.wstrb = 4'hF;
            finish_item(item);
        end

        // 8핀 전부 input으로 전환
        item = axi_gpio_seq_item::type_id::create("item");
        start_item(item);
        item.dir   = axi_gpio_seq_item::AXI_WRITE;
        item.addr  = 4'h0;
        item.wdata = 32'h0;
        item.wstrb = 4'hF;
        finish_item(item);

        item = axi_gpio_seq_item::type_id::create("item");
        start_item(item);
        item.dir  = axi_gpio_seq_item::AXI_READ;
        item.addr = 4'h0;
        finish_item(item);

        // 같은 패턴을 이번엔 외부에서 핀에 넣어주면서 IDR로 읽어 확인
        foreach (patterns[i]) begin
            item = axi_gpio_seq_item::type_id::create("item");
            start_item(item);
            item.dir        = axi_gpio_seq_item::AXI_READ;
            item.addr       = 4'h4;
            item.drive_en   = 8'hFF;
            item.drive_data = patterns[i];
            finish_item(item);
        end

        `uvm_info(get_type_name(), "direct 시나리오 종료.", UVM_LOW)
    endtask
endclass


class axi_gpio_full_seq extends uvm_sequence #(axi_gpio_seq_item);
    `uvm_object_utils(axi_gpio_full_seq)

    function new(string name = "axi_gpio_full_seq");
        super.new(name);
    endfunction

    task body();
        axi_gpio_seq_item item;

        `uvm_info(get_type_name(), "full 시나리오 시작", UVM_LOW)

        item = axi_gpio_seq_item::type_id::create("item");
        start_item(item);
        item.dir   = axi_gpio_seq_item::AXI_WRITE;
        item.addr  = 4'h0;
        item.wdata = 32'hFF;
        item.wstrb = 4'hF;
        finish_item(item);

        // ODR에 0~255 전부 쓰기
        for (int i = 0; i < 256; i++) begin
            item = axi_gpio_seq_item::type_id::create("item");
            start_item(item);
            item.dir   = axi_gpio_seq_item::AXI_WRITE;
            item.addr  = 4'h8;
            item.wdata = i;
            item.wstrb = 4'hF;
            finish_item(item);
        end

        `uvm_info(get_type_name(), "full 시나리오 종료.", UVM_LOW)
    endtask
endclass


class axi_gpio_cross_seq extends uvm_sequence #(axi_gpio_seq_item);
    `uvm_object_utils(axi_gpio_cross_seq)

    function new(string name = "axi_gpio_cross_seq");
        super.new(name);
    endfunction

    task body();
        axi_gpio_seq_item item;
        bit [7:0] dir_pattern[] = '{8'h00, 8'hFF, 8'h0F, 8'hF0, 8'hAA, 8'h55};
        bit [7:0] data_pattern[] = '{
            8'h00,
            8'hFF,
            8'hAA,
            8'h55,
            8'h01,
            8'h02,
            8'h04,
            8'h08,
            8'h10,
            8'h20,
            8'h40,
            8'h80
        };

        `uvm_info(get_type_name(), "cross 시나리오 시작", UVM_LOW)

        // 방향 패턴 x 데이터 패턴을 조합해서, output/input이 섞인 상황을 검증
        foreach (dir_pattern[d]) begin
            foreach (data_pattern[p]) begin
                item = axi_gpio_seq_item::type_id::create("item");
                start_item(item);
                item.dir   = axi_gpio_seq_item::AXI_WRITE;
                item.addr  = 4'h0;
                item.wdata = {24'h0, dir_pattern[d]};
                item.wstrb = 4'hF;
                finish_item(item);

                item = axi_gpio_seq_item::type_id::create("item");
                start_item(item);
                item.dir   = axi_gpio_seq_item::AXI_WRITE;
                item.addr  = 4'h8;
                item.wdata = {24'h0, data_pattern[p]};
                item.wstrb = 4'hF;
                finish_item(item);

                item = axi_gpio_seq_item::type_id::create("item");
                start_item(item);
                item.dir        = axi_gpio_seq_item::AXI_READ;
                item.addr       = 4'h4;
                item.drive_en   = ~dir_pattern[d];
                item.drive_data = data_pattern[p];
                finish_item(item);
            end
        end

        `uvm_info(get_type_name(), "cross 시나리오 종료", UVM_LOW)
    endtask
endclass
