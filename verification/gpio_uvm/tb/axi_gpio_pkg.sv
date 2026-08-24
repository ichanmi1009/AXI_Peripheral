package axi_gpio_pkg;
    import uvm_pkg::*;
    `include "uvm_macros.svh"

    // 의존성 순서대로 include 작성
    `include "axi_gpio_seq_item.sv"
    `include "axi_gpio_sequence.sv"
    `include "axi_gpio_driver.sv"
    `include "axi_gpio_monitor.sv"
    `include "axi_gpio_agent.sv"
    `include "axi_gpio_scoreboard.sv"
    `include "axi_gpio_coverage.sv"
    `include "axi_gpio_env.sv"
    `include "axi_gpio_test.sv"

endpackage
