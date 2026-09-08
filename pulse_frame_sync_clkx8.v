module pulse_frame_sync_clkx8 (
    input  wire           clk,
    input  wire           rst,
    output wire           sim_frame_sync

);


    reg   [ 3:0]  symb_index          ;
    reg   [ 4:0]  slot_index          ;
    reg   [  1:0] dlfe_frame_sync     ;
    reg   [  7:0] dlfe_valid          ;
    reg   [127:0] data_cc0           ;
    reg   [127:0] data_cc1           ;

    wire          clk_sysx8           ;
    wire          rst_sysx8           ;

    reg   [31:0] sim_counter          ;
    reg          sim_start            ;
    reg          sim_start_en         ;

    reg   [15:0] axc_0_counter        ;
    reg   [15:0] axc_1_counter        ;
    reg   [15:0] axc_2_counter        ;
    reg   [15:0] axc_3_counter        ;

    reg   [15:0] space_cp             ;

    assign clk_sysx8=clk;
    assign rst_sysx8=rst;
    assign sim_frame_sync=dlfe_frame_sync[0];

    always @(posedge clk_sysx8) begin
        if(rst_sysx8 == 1'b1) begin
            sim_counter <= 32'd0;
        end
        else begin
            if(sim_start == 1'b0 || sim_start_en == 1'b0) begin
                sim_counter <= sim_counter + 32'd1;
            end
            else begin
                sim_counter <= 32'd0;
            end
        end
    end

    always @(posedge clk_sysx8) begin
        if(rst_sysx8 == 1'b1) begin
            sim_start <= 1'b0;
        end
        else begin
            if(sim_start == 1'b0 && sim_counter == 32'd10000) begin // d27258
                sim_start <= 1'b1;
            end
            else begin
                sim_start <= sim_start;
            end
        end
    end

    always @(posedge clk_sysx8) begin
        if(rst_sysx8 == 1'b1) begin
            sim_start_en <= 1'b0;
        end
        else begin
            if(sim_start_en == 1'b0 && sim_counter == 32'd10000) begin
                sim_start_en <= 1'b1;
            end
            else begin
                sim_start_en <= sim_start_en;
            end
        end
    end


    always @(posedge clk_sysx8) begin
        if(rst_sysx8 == 1'b1) begin
            axc_0_counter <= 32'd0;
            axc_1_counter <= 32'd0;
            axc_2_counter <= 32'd0;
            axc_3_counter <= 32'd0;
        end
        else begin
            if(sim_start == 1'b1) begin

                if(axc_1_counter==32'd0 && axc_0_counter<32'd4150)
                    axc_0_counter <= axc_0_counter + 32'd1;

                if(axc_0_counter==32'd4150 && axc_1_counter<space_cp)
                    axc_1_counter <= axc_1_counter + 32'd1;

                if(axc_1_counter==space_cp)
                begin
                    axc_0_counter <= 32'd0;
                    axc_1_counter <= 32'd0;
                    axc_2_counter <= 32'd0;
                    axc_3_counter <= 32'd0;
                end

            end
        end
    end

    always @(posedge clk_sysx8) begin
        if(rst_sysx8 == 1'b1) begin
            space_cp   <= 32'd8895-32'd4150;         //first CP
        end
        else begin
            if(symb_index==32'd0) begin
                space_cp   <= 32'd8895-32'd4150;     //first CP
            end
            else begin
                space_cp   <= 32'd8767-32'd4150;    ///nomal CP
            end

        end
    end

    always @(posedge clk_sysx8) begin
        if(rst_sysx8 == 1'b1) begin
            symb_index <= 32'd0;
        end
        else begin
            if(axc_1_counter==space_cp && sim_start == 1'b1 ) begin
                if(symb_index<32'd13)
                    symb_index <= symb_index + 32'd1;
                else
                    symb_index <= 32'd0;

            end
        end
    end

    always @(posedge clk_sysx8) begin
        if(rst_sysx8 == 1'b1) begin
            slot_index <= 32'd0;
        end
        else begin                              ///nomal CP
            if(symb_index==32'd13 && axc_1_counter==32'd8767-32'd4150 && sim_start == 1'b1 ) begin
                if(slot_index<32'd19)
                    slot_index <= slot_index + 32'd1;
                else
                    slot_index <= 32'd0;

            end
        end
    end


    always @(posedge clk_sysx8) begin
        if(rst_sysx8 == 1'b1) begin
            dlfe_frame_sync <= 2'b00;
        end
        else begin
            if(sim_start == 1'b1) begin
                if(axc_0_counter == 32'd1 && symb_index == 32'd0 && slot_index == 32'd0) begin
                    dlfe_frame_sync <= 2'b11;
                end
                else begin
                    dlfe_frame_sync <= 2'b00;
                end
            end
            else begin
                dlfe_frame_sync <= 2'b00;
            end
        end
    end



endmodule
