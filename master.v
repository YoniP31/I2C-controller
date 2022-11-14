module master(
    input i_sclk, //inner system clock
    input i_sdata, //data sent from a slave
    input [6:0] i_address_in, //address of slave
    input i_address_r_w, //master reads data or sends data
    input [7:0] i_sdata_in, //data master sends to a slave
    output reg o_sclk,
    output reg o_sdata
);
//always starts at idle, when detecting a start bit goes to recieving data stracture,
//if there is data queued goes to sending data stracture and generates a clock.
//recieving data: start_bit -> address_frame -> read_data -> stop_bit
//send data: start_bit -> address_frame -> send_data -> stop_bit

parameter s_idle = 'b000;
parameter s_start_bit = 'b001;
parameter s_address_frame = 'b010;
parameter s_send_data = 'b011;
parameter s_read_data = 'b100;
parameter s_stop_bit = 'b101;

integer i = 4'd0;
logic [2:0] state;
logic [6:0] address;
logic [7:0] sdata;
logic [7:0] read_data;
logic address_r_w; //master sending data = 0 | master recieving data = 1
logic address_ack; //acknowledge bit for address frame
logic data_ack; //acknowledge bit for data frame

assign address = i_address_in;
assign address_r_w = i_address_r_w;
assign sdata = i_sdata_in;

//generate o_sclk
always @(posedge i_sclk or negedge i_sclk) begin
    if((state == s_address_frame) | (state == s_send_data) | (state == s_read_data)) begin
        o_sclk <= ~o_sclk;
    end
    else begin
        o_sclk <= o_sclk;
    end
end

always @(posedge i_sclk) begin
    case(state)
    s_idle: begin
        o_sdata <= 1'b1;
        o_sclk <= 1'b1;
        if(address != 0) begin
            o_sdata <= 1'b0;
            state <= s_start_bit;
        end else begin
            state <= s_idle;
        end
    end
    s_start_bit: begin
        o_sclk <= 1'b0;
        state <= s_address_frame;
    end
    s_address_frame: begin
        if(i < 7) begin
            o_sdata <= address[6-i];
            i <= i + 1;
        end
        else if(i == 7) begin
            o_sdata <= address_r_w;
            i <= i + 1;
        end
        else if(i == 8) begin
            if(address_r_w == 1) begin
                address_ack <= i_sdata;
                o_sdata <= i_sdata;
            end
            else begin
                address_ack <= 'b0;
            end
            i <= i + 1;
        end
        else begin
            if((address_r_w == 0) & (address_ack == 0)) begin
                i <= 4'b0;
                o_sdata <= sdata[7];
                state <= s_send_data;
            end
            else if(address_r_w == 1) begin
                i <= 4'b0;
                read_data[0] <= i_sdata;
                state <= s_read_data;
            end
            else begin
                state <= s_idle;
            end
        end
    end
    s_send_data: begin
        if(i < 7) begin
            o_sdata <= sdata[6-i];
            i <= i + 1; 
        end
        else if(i == 7) begin
            data_ack <= i_sdata;
            o_sdata <= i_sdata;
            i <= i + 1;
        end
        else begin
            if(data_ack == 0) begin
                i <= 4'b0;
                state <= s_stop_bit;
            end
            else begin
                state <= s_idle;
            end
        end
    end
    s_read_data: begin
        if(i < 7) begin
            read_data[i+1] <= i_sdata;
            i <= i + 1;
        end
        else if(i == 7) begin
            o_sdata <= 1'b1; //data_ack = 1
            i <= i + 1;
        end
        else begin
            i <= 4'b0;
            state <= s_stop_bit;
        end
    end
    s_stop_bit: begin
        o_sdata <= 1'b1;
        if(i == 0) begin
            i <= i + 1;
        end
        else begin
            o_sclk <= 1'b1;
            state <= s_idle;
        end
    end
    default: begin
        state <= s_idle;
    end
    endcase
end

endmodule