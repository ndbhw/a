
module axis_data_gen (

    input wire i_clk,
    input wire i_rst,

    output wire        m_axis_tvalid,
    output wire [63:0] m_axis_tdata,
    output wire        m_axis_tlast,
    output wire [ 7:0] m_axis_tkeep,
    input  wire        m_axis_tready
);

    //// Phat dung so byte khi PKT_LENGTH >= 24 va chia het cho 8 (tkeep luon 8'hFF).
    parameter integer PKT_LENGTH = 256;
    //// So clock idle (tvalid=0) giua beat cuoi frame truoc va beat dau frame sau.
    parameter integer IFG_CYCLES = 1000;

    //// So clock cho sau khi nha i_rst truoc khi phat frame dau tien.
    parameter integer STARTUP_DELAY = 30000;

    reg         tx_axis_tvalid;
    reg  [63:0] tx_axis_tdata;
    reg         tx_axis_tlast;
    reg  [ 7:0] tx_axis_tkeep;

    assign m_axis_tvalid = tx_axis_tvalid;
    assign m_axis_tdata  = tx_axis_tdata;
    assign m_axis_tlast  = tx_axis_tlast;
    assign m_axis_tkeep  = tx_axis_tkeep;

    localparam [47:0] DEST_ADDR = 48'hFF_FF_FF_FF_FF_FF;
    localparam [47:0] SOURCE_ADDR = 48'h14_FE_B5_DD_9A_82;
    localparam [15:0] LENGTH_TYPE = 16'h0600;

    localparam integer BEATS_PER_PKT = (PKT_LENGTH + 7) / 8;

    localparam [1:0] ST_IDLE = 2'd0, ST_HDR = 2'd1, ST_DATA = 2'd2, ST_END = 2'd3;

    reg [ 1:0] state;
    reg [15:0] beat_cnt;
    reg [31:0] ifg_cnt;
    reg [63:0] data_cnt;
    reg [31:0] pkt_cnt;

    always @(posedge i_clk) begin
        if (i_rst) begin
            state          <= ST_IDLE;
            tx_axis_tvalid <= 1'b0;
            tx_axis_tdata  <= 64'd0;
            tx_axis_tlast  <= 1'b0;
            tx_axis_tkeep  <= 8'hFF;
            beat_cnt       <= 16'd0;
            ifg_cnt        <= STARTUP_DELAY[31:0];
            data_cnt       <= 64'd1;
            pkt_cnt        <= 32'd0;
        end else begin
            case (state)
                ST_IDLE: begin
                    tx_axis_tvalid <= 1'b0;
                    tx_axis_tlast  <= 1'b0;
                    if (|ifg_cnt) begin
                        ifg_cnt <= ifg_cnt - 32'd1;
                    end else begin
                        tx_axis_tvalid <= 1'b1;
                        tx_axis_tkeep  <= 8'hFF;
                        tx_axis_tdata  <= {DEST_ADDR, SOURCE_ADDR[47:32]};
                        beat_cnt       <= 16'd1;
                        state          <= ST_HDR;
                    end
                end

                ST_HDR: begin
                    if (m_axis_tready) begin
                        tx_axis_tdata <= {SOURCE_ADDR[31:0], LENGTH_TYPE, data_cnt[15:0]};
                        data_cnt      <= data_cnt + 64'd1;
                        beat_cnt      <= beat_cnt + 16'd1;
                        state         <= ST_DATA;
                    end
                end

                ST_DATA: begin
                    if (m_axis_tready) begin
                        tx_axis_tdata <= data_cnt;
                        data_cnt      <= data_cnt + 64'd1;
                        beat_cnt      <= beat_cnt + 16'd1;
                        if (beat_cnt >= (BEATS_PER_PKT - 1)) begin
                            tx_axis_tlast <= 1'b1;
                            tx_axis_tkeep <= 8'hFF;
                            state         <= ST_END;
                        end
                    end
                end

                ST_END: begin
                    if (m_axis_tready) begin
                        tx_axis_tvalid <= 1'b0;
                        tx_axis_tlast  <= 1'b0;
                        pkt_cnt        <= pkt_cnt + 32'd1;
                        ifg_cnt        <= IFG_CYCLES[31:0];
                        state          <= ST_IDLE;
                    end
                end

                default: state <= ST_IDLE;
            endcase
        end
    end

endmodule
