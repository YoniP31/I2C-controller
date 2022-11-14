module slave(
    input i_sclk,
    input i_sdata,
    input [7:0] i_data_out,
    output reg o_sdata
);

parameter ADDRESS = 'd89;
parameter s_idle = 'b00;
parameter s_address_frame = 'b01;
parameter s_send_data = 'b10;
parameter s_read_data = 'b11;

integer j = 4'd0;
logic [1:0] state;
logic [6:0] address_in;
logic [7:0] data_in;
logic address_r_w;

always @(posedge i_sclk) begin
    case(state)
    s_idle: begin
        o_sdata <= 1'd1;
        if(i_sdata == 0) begin
            state <= s_address_frame;
        end
    end
    s_address_frame: begin
        if(j < 7) begin
            address_in[6-j] <= i_sdata;
            j <= j + 1;
        end
        else if(j == 7) begin
            address_r_w <= i_sdata;
            j <= j + 1;
        end
        else begin
            if((address_r_w == 1) & (address_in == ADDRESS)) begin
                o_sdata <= 'b0;
                j <= 'b0;
                state <= s_send_data;
            end
            else if((address_r_w == 0) & (address_in == ADDRESS)) begin
                o_sdata <= 'b0;
                j <= 'b0;
                state <= s_read_data;
            end
            else begin
                j <= 'b0;
                state <= s_idle;
            end
        end
    end
    s_send_data: begin
        if(j < 8) begin
            o_sdata <= i_data_out[7-j];
            j <= j + 1;
        end
        else begin
            o_sdata <= 1'b1;
            state <= s_idle;
        end
    end
    s_read_data: begin
        if(j < 8) begin
            data_in[7-j] <= i_sdata;
            j <= j + 1;
        end
        else begin
            o_sdata <= 1'b0;
            state <= s_idle;
        end
    end
    default: begin
        state <= s_idle;
    end
    endcase
end

endmodule