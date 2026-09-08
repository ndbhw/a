module oran_timing_emulator (
    input   wire         oran_clk       ,
    input   wire         oran_rst       ,
                                 
    input   wire         oran_enable    ,
                                 
    output  reg          oran_tick_1pps ,
    output  reg          oran_frame_sync,
    output  reg   [11:0] oran_frame_num ,
    
    output  reg          oran_subf_tick ,
    output  reg   [ 7:0] oran_subf_index,
    output  reg          oran_symb_tick ,
    output  reg   [ 7:0] oran_symb_index
);
    
    reg   [31:0] sec_timing   ;
    reg   [31:0] rfrm_timing  ;
    reg   [31:0] subf_timing  ;
    reg   [31:0] symb_timing  ;
    
    reg          timing_enable;
    reg          flag_1s      ;
    
    always @(posedge oran_clk) begin 
        if(oran_rst == 1'b1) begin
            sec_timing <= 32'd156249990;
        end
        else begin
            if(oran_enable == 1'b1) begin
                if(sec_timing >= 32'd156249999) begin
                    sec_timing <= 32'd0;
                end
                else begin
                    sec_timing <= sec_timing + 32'd1;
                end
            end 
            else begin
                sec_timing <= sec_timing;
            end
        end
    end
    
    always @(posedge oran_clk) begin 
        if(oran_rst == 1'b1) begin
            timing_enable <= 1'b0;
        end
        else begin
            if(oran_enable == 1'b1) begin
                timing_enable <= 1'b1;
            end
            else begin
                timing_enable <= 1'b0;
            end
        end
    end
    
    always @(posedge oran_clk) begin 
        if(oran_rst == 1'b1) begin
            flag_1s <= 1'b0;
        end
        else begin
            if(sec_timing == 32'd156249999) begin
                flag_1s <= 1'b1;
            end
            else begin
                flag_1s <= 1'b0;
            end
        end
    end
    
    always @(posedge oran_clk) begin 
        if(oran_rst == 1'b1) begin
            oran_tick_1pps <= 1'b0;
        end
        else begin
            if(timing_enable == 1'b1 && flag_1s == 1'b1) begin
                oran_tick_1pps <= 1'b1;
            end
            else begin
                oran_tick_1pps <= 1'b0;
            end
        end
    end
    
    always @(posedge oran_clk) begin 
        if(oran_rst == 1'b1) begin
            rfrm_timing <= 32'd0;
        end
        else begin
            if(timing_enable == 1'b1) begin
                if(rfrm_timing >= 32'd1562499 || flag_1s == 1'b1) begin
                    rfrm_timing <= 32'd0;
                end
                else begin
                    rfrm_timing <= rfrm_timing + 32'd1;
                end
            end
            else begin
                rfrm_timing <= 32'd0;
            end
        end
    end
    
    always @(posedge oran_clk) begin 
        if(oran_rst == 1'b1) begin
            oran_frame_num <= 32'd0;
        end
        else begin
            if(timing_enable == 1'b1) begin
                if(timing_enable == 1'b1 && flag_1s == 1'b1) begin
                    oran_frame_num <= 32'd0;
                end
                else if(rfrm_timing >= 32'd1562499) begin
                    oran_frame_num <= oran_frame_num + 32'd1;
                end
                else begin
                    oran_frame_num <= oran_frame_num;
                end
            end
            else begin
                oran_frame_num <= 32'd0;
            end
        end
    end
    
    always @(posedge oran_clk) begin 
        if(oran_rst == 1'b1) begin
            oran_frame_sync <= 1'b0;
        end
        else begin
            if(timing_enable == 1'b1 && flag_1s == 1'b1) begin
                oran_frame_sync <= 1'b1;
            end
            else if(rfrm_timing >= 32'd1562499) begin
                oran_frame_sync <= 1'b1;
            end
            else begin
                oran_frame_sync <= 1'b0;
            end
        end
    end
    
    always @(posedge oran_clk) begin 
        if(oran_rst == 1'b1) begin
            subf_timing <= 32'd0;
        end
        else begin
            if(timing_enable == 1'b1) begin
                if(subf_timing >= 32'd156249 || flag_1s == 1'b1) begin
                    subf_timing <= 32'd0;
                end
                else begin
                    subf_timing <= subf_timing + 32'd1;
                end
            end
            else begin
                subf_timing <= 32'd0;
            end
        end
    end
    
    always @(posedge oran_clk) begin 
        if(oran_rst == 1'b1) begin
            oran_subf_tick  <= 1'b0;
            oran_subf_index <= 32'd0;
        end
        else begin
            if(timing_enable == 1'b1) begin
                if(rfrm_timing >= 32'd1562499 || flag_1s == 1'b1) begin
                    oran_subf_tick  <= 1'b1;
                    oran_subf_index <= 32'd0;
                end
                else if(subf_timing >= 32'd156249) begin
                    oran_subf_tick  <= 1'b1;
                    oran_subf_index <= oran_subf_index + 32'd1;
                end
                else begin
                    oran_subf_tick  <= 1'b0;
                    oran_subf_index <= oran_subf_index;
                end
            end
            else begin
                oran_subf_tick  <= 1'b0;
                oran_subf_index <= 32'd0;
            end
        end
    end
    
    always @(posedge oran_clk) begin 
        if(oran_rst == 1'b1) begin
            symb_timing <= 32'd0;
        end
        else begin
            if(timing_enable == 1'b1) begin
                if(symb_timing >= 32'd11160 || flag_1s == 1'b1 || subf_timing >= 32'd156249) begin
                    symb_timing <= 32'd0;
                end
                else begin
                    symb_timing <= symb_timing + 32'd1;
                end
            end
            else begin
                symb_timing <= 32'd0;
            end
        end
    end
    
    always @(posedge oran_clk) begin 
        if(oran_rst == 1'b1) begin
            oran_symb_tick  <= 1'b0;
            oran_symb_index <= 32'd0;
        end
        else begin
            if(timing_enable == 1'b1) begin
                if(rfrm_timing >= 32'd1562499 || flag_1s == 1'b1 || subf_timing >= 32'd156249) begin
                    oran_symb_tick  <= 1'b1;
                    oran_symb_index <= 32'd0;
                end
                else if(symb_timing >= 32'd11160) begin
                    oran_symb_tick  <= 1'b1;
                    oran_symb_index <= oran_symb_index + 32'd1;
                end
                else begin
                    oran_symb_tick  <= 1'b0;
                    oran_symb_index <= oran_symb_index;
                end
            end
            else begin
                oran_symb_tick  <= 1'b0;
                oran_symb_index <= 32'd0;
            end
        end
    end
    
endmodule 
