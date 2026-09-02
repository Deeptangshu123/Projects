`timescale 1ns / 1ps

module tlc_fsm_top (
    // Clock and reset
    input  wire i_clk_100M,
    input  wire i_rst_p,

    // East-West vehicle detection
    input  wire i_EW_vd,

    // Traffic light outputs
    output wire o_NS_red,
    output wire o_NS_yellow,
    output wire o_NS_green,

    output wire o_EW_red,
    output wire o_EW_yellow,
    output wire o_EW_green
);

    //========================================================
    // State declaration
    //========================================================
    localparam [1:0]
        NS_GREEN = 2'b00,
        YELLOW   = 2'b01,
        EW_GREEN = 2'b10;

    reg [1:0] state, next_state;

    // Counter
    reg [5:0] counter;


    //========================================================
    // State register and counter
    //========================================================
    always @(posedge i_clk_100M) begin

        if (i_rst_p) begin
            state   <= NS_GREEN;
            counter <= 0;
        end

        else begin
            state <= next_state;

            // Reset counter whenever state changes
            if (state != next_state)
                counter <= 0;

            else
                counter <= counter + 1'b1;
        end

    end


    //========================================================
    // Next-state logic
    //========================================================
    always @(*) begin

        next_state = state;

        case (state)

            //================================================
            // North-South GREEN
            //================================================
            NS_GREEN: begin

                // Wait at least 25 clock cycles before
                // changing to EW traffic
                if ((counter >= 24) && i_EW_vd)
                    next_state = YELLOW;

                else
                    next_state = NS_GREEN;

            end


            //================================================
            // YELLOW
            //================================================
            YELLOW: begin

                // 5 clock-cycle yellow period
                if (counter >= 4) begin

                    // If EW vehicle is present,
                    // give EW traffic the green light
                    if (i_EW_vd)
                        next_state = EW_GREEN;

                    // Otherwise return to NS green
                    else
                        next_state = NS_GREEN;

                end

                else
                    next_state = YELLOW;

            end


            //================================================
            // East-West GREEN
            //================================================
            EW_GREEN: begin

                // Keep EW green while vehicles are detected,
                // but limit the green period to 25 cycles.
                if ((counter >= 24) || !i_EW_vd)
                    next_state = YELLOW;

                else
                    next_state = EW_GREEN;

            end


            //================================================
            // Safety/default state
            //================================================
            default: begin
                next_state = NS_GREEN;
            end

        endcase

    end


    //========================================================
    // Output logic
    //========================================================
    assign o_NS_red    = (state == EW_GREEN);
    assign o_NS_yellow = (state == YELLOW);
    assign o_NS_green  = (state == NS_GREEN);

    assign o_EW_red    = (state == NS_GREEN);
    assign o_EW_yellow = (state == YELLOW);
    assign o_EW_green  = (state == EW_GREEN);

endmodule