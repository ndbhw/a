module pcap_reader (
    input wire clk,
    input wire rst,
    input wire ready,
    output reg [63:0] m_tdata,
    output reg [7:0] m_tkeep,
    output reg m_tlast,
    output wire o_m_valid,
    output wire [63:0] pcap_time,
    output reg [1:0] CU_check
);

    reg [63:0] addr;
    reg [63:0] time_stamp;
    reg [63:0] length_plane;
    reg start_status;
    reg m_valid;
    
    reg [63:0] file_data;
    reg [63:0] line_buffer [0:2]; 
    reg [31:0] line_count;
    reg [31:0] N_line;
    reg [3:0] N_tkeep;
    reg [31:0] data_count;
    integer file;
    integer scan_result;
    
    localparam IDLE = 3'd0;
    localparam CHECK_HEADER = 3'd1;
    localparam SEND_CPLANE = 3'd2;
    localparam SEARCH_ADDR = 3'd3;
    localparam SEND_DATA = 3'd4;
    localparam DONE = 3'd5;
    
    reg [2:0] state;
    
    initial begin
        file = $fopen("C:/Users/PC/Documents/RT4443/sim_base_4443_oran_4419_50M_2C/Z1_sim_DL_UL/Env/oran/pcap.mem", "r");
        if (file == 0) begin
            $display("Error: Cannot open pcap.mem file");
            $finish;
        end
    end
    
    always @(posedge clk) begin
        if (rst) begin
            m_tdata <= 64'h0;
            m_tkeep <= 8'h0;
            m_tlast <= 1'b0;
            m_valid <= 1'b0;
            CU_check <= 2'b0;
            addr <= 64'h0;
            time_stamp <= 64'h0;
            length_plane <= 64'h0;
            start_status <= 1'b0;
            line_count <= 32'h0;
            data_count <= 32'h0;
            state <= IDLE;
            line_buffer[0] <= 64'h0;
            line_buffer[1] <= 64'h0;
            line_buffer[2] <= 64'h0;
        end
        else if (ready) begin
            case (state)
                IDLE: begin
                    // Read line 1
                    scan_result = $fscanf(file, "%h\n", file_data);
                    if (scan_result == 1) begin
                        if (file_data == 64'h0000000000000000) begin
                            time_stamp <= file_data;
                            state <= CHECK_HEADER;
                        end
                        else begin
                            $display("Error: First line is not timestamp = 0");
                            $finish;
                        end
                    end
                end
                
                CHECK_HEADER: begin
                    // Read line 2
                    scan_result = $fscanf(file, "%h\n", file_data);
                    if (scan_result == 1) begin
                        length_plane <= file_data;
                        if (file_data <= 64'd64) begin
                            // Read line 3
                            scan_result = $fscanf(file, "%h\n", addr);
                            if (scan_result == 1) begin
                                state <= SEND_CPLANE;
                                m_valid <= 1'b1;
                                m_tlast <= 1'b0;
                                m_tkeep <= 8'hFF;
                                m_tdata <= addr;  
                                CU_check <= 2'b01;
                                start_status <= 1'b1;
                                
                                if (file_data % 8 == 0)
                                    N_line <= file_data / 8;
                                else
                                    N_line <= file_data / 8 + 1;
                                N_tkeep <= 8 - (file_data % 8);
                                data_count <= 32'd1;  
                            end
                        end
                        else begin
                            $display("Error: C-plane length > 64 bytes");
                            $finish;
                        end
                    end
                end
                
                SEND_CPLANE: begin
                    // Send C-plane data
                    scan_result = $fscanf(file, "%h\n", file_data);
                    if (scan_result == 1) begin
                        m_tdata <= file_data;
                        data_count <= data_count + 1;
                        
                        if (data_count == N_line - 1) begin
                            m_tlast <= 1'b1;
                            m_tkeep <= 8'hFF >> N_tkeep;
                            state <= SEARCH_ADDR;
                            line_buffer[0] <= file_data;
                            line_count <= 32'd1;
                        end
                        else begin
                            m_tkeep <= 8'hFF;
                        end
                    end
                end
                
SEARCH_ADDR: begin
    m_valid <= 1'b0;
    m_tlast <= 1'b0;
    m_tkeep <= 8'h0;
    m_tdata <= 64'h0;
    CU_check <= 2'b0;
    
    // Read and buffer lines
    scan_result = $fscanf(file, "%h\n", file_data);
    if (scan_result == 1) begin
        // Shift buffer TR??C
        line_buffer[2] <= line_buffer[1];
        line_buffer[1] <= line_buffer[0];
        line_buffer[0] <= file_data;
        

        if (file_data == addr) begin
            time_stamp <= line_buffer[1];        
            length_plane <= line_buffer[0];    
            
            m_valid <= 1'b1;
            m_tlast <= 1'b0;
            m_tkeep <= 8'hFF;
            m_tdata <= file_data;
            
            if (line_buffer[0] <= 64'd64)
                CU_check <= 2'b01;
            else if (line_buffer[0] >= 64'd178)
                CU_check <= 2'b10;
            else begin
                $display("Error: Invalid length_plane value = %d (0x%h)", line_buffer[0], line_buffer[0]);
                $finish;
            end
            
            // Calculate N_line and N_tkeep
            if (line_buffer[0] % 8 == 0)
                N_line <= line_buffer[0] / 8;
            else
                N_line <= line_buffer[0] / 8 + 1;
            N_tkeep <= 8 - (line_buffer[0] % 8);
            data_count <= 32'd1;
            
            state <= SEND_DATA;
            line_count <= 32'd1;
        end
        else begin
            line_count <= line_count + 1;
        end
    end
    else begin
        state <= DONE;
    end
end
                
                SEND_DATA: begin
                    scan_result = $fscanf(file, "%h\n", file_data);
                    if (scan_result == 1) begin
                        m_tdata <= file_data;
                        data_count <= data_count + 1;
                        
                        if (data_count == N_line - 1) begin
                            m_tlast <= 1'b1;
                            m_tkeep <= 8'hFF >> N_tkeep;
                            state <= SEARCH_ADDR;
                            line_buffer[0] <= file_data;
                            line_count <= 32'd1;
                        end
                        else begin
                            m_tkeep <= 8'hFF;
                        end
                    end
                    else begin
                        m_valid <= 1'b0;
                        m_tlast <= 1'b0;
                        m_tkeep <= 8'h0;
                        m_tdata <= 64'h0;
                        CU_check <= 2'b0;
                        state <= DONE;
                    end
                end
                
                DONE: begin
                    m_valid <= 1'b0;
                    m_tlast <= 1'b0;
                    m_tkeep <= 8'h0;
                    m_tdata <= 64'h0;
                    CU_check <= 2'b0;
                end
                
                default: state <= IDLE;
            endcase
        end
    end
    
    // Verilog-2001 has no 'final' block: close the file once the FSM reaches DONE
    reg file_closed;
    initial file_closed = 1'b0;

    always @(posedge clk) begin
        if (rst) begin
            file_closed <= 1'b0;
        end
        else if (state == DONE && file_closed == 1'b0) begin
            $fclose(file);
            file_closed <= 1'b1;
        end
    end
    
    
    
    assign pcap_time = time_stamp;
    assign o_m_valid = m_valid & ready;
    
endmodule