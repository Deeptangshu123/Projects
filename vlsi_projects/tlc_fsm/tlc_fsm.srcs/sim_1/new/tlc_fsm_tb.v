`timescale 1ns / 1ps

module tlc_fsm_tb;

    //========================================================
    // Testbench signals
    //========================================================
    reg clock;
    reg reset;
    reg ew_vehicle_detected;

    wire NS_RED;
    wire NS_YELLOW;
    wire NS_GREEN;

    wire EW_RED;
    wire EW_YELLOW;
    wire EW_GREEN;


    //========================================================
    // 100 MHz clock
    // Period = 10 ns
    //========================================================
    always #5 clock = ~clock;


    //========================================================
    // DUT
    //========================================================
    tlc_fsm_top DUT (

        .i_clk_100M   (clock),
        .i_rst_p      (reset),
        .i_EW_vd      (ew_vehicle_detected),

        .o_NS_red     (NS_RED),
        .o_NS_yellow  (NS_YELLOW),
        .o_NS_green   (NS_GREEN),

        .o_EW_red     (EW_RED),
        .o_EW_yellow  (EW_YELLOW),
        .o_EW_green   (EW_GREEN)

    );


    //========================================================
    // Test sequence
    //========================================================
    initial begin

        // Initial conditions
        clock = 0;
        reset = 1;
        ew_vehicle_detected = 0;


        // Hold reset for 20 ns
        #20;
        reset = 0;


        //====================================================
        // TEST 1
        // NS should remain GREEN
        //====================================================
        #100;


        //====================================================
        // TEST 2
        // EW vehicle arrives
        //
        // NS_GREEN continues for 25 clock cycles,
        // then changes to YELLOW.
        //====================================================
        ew_vehicle_detected = 1;

        #350;


        //====================================================
        // TEST 3
        // Remove EW vehicle
        //
        // EW_GREEN should change to YELLOW and then
        // return to NS_GREEN.
        //====================================================
        ew_vehicle_detected = 0;

        #200;


        //====================================================
        // TEST 4
        // Another EW vehicle arrives
        //====================================================
        ew_vehicle_detected = 1;

        #350;


        //====================================================
        // TEST 5
        // Remove EW vehicle again
        //====================================================
        ew_vehicle_detected = 0;

        #200;


        //====================================================
        // End simulation
        //====================================================
        $stop;

    end

endmodule