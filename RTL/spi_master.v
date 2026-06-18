module spi_master
(
    input clk ,
    input rst , 
    input [7:0] tx_data,
    input miso,
    input start,
    
    output reg mosi,
    output sclk,
    output reg cs,
    output [7:0] rx_data,
    output reg done
);
    parameter IDLE = 2'b00;
    parameter ASSERT = 2'b01;
    parameter TRANSFER = 2'b10;
    parameter DONE = 2'b11;
    
    reg [1:0] state;
    reg [7:0] tx_shift_data;
    reg [7:0] rx_shift_data;
    reg [2:0] bit_count;
    reg en_clk_div;
    
    wire rising_tick;
    wire falling_tick;
    
    clock_div inst(.clk(clk), .rst(rst), .en(en_clk_div), .sclk(sclk),
    .rising_tick(rising_tick),.falling_tick(falling_tick));
    
    assign rx_data = rx_shift_data;
    
    always@(posedge clk)
    begin
        if(rst)
        begin
            state <= IDLE;
            mosi <= 1'b0;
            done <= 1'b0;
            cs <= 1'b1;
            bit_count <= 3'b000;
            en_clk_div <= 1'b0;
            tx_shift_data <= 8'b0;
            rx_shift_data <= 8'b0;
        end
        
        else
        begin
            case(state)
            
                IDLE:
                begin
                    cs <= 1'b1;
                    done <= 1'b0;
                    en_clk_div <= 1'b0;
                    
                    if(start)
                    state <= ASSERT ;
                    else
                    state <= IDLE;
                    
                end
                
                ASSERT:
                begin
                    cs <= 1'b0;
                    done <= 1'b0;
                    en_clk_div <= 1'b0;
                    tx_shift_data <= tx_data << 1;
                    mosi <= tx_data[7];
                    rx_shift_data <= 8'd0;
                    bit_count <= 3'd0;
                    state <= TRANSFER;
                end
                
               TRANSFER:
               begin
                    cs <= 1'b0;
                    done <= 1'b0;
                    en_clk_div <= 1'b1;
                
                    if(falling_tick)
                    begin
                        mosi <= tx_shift_data[7];
                        tx_shift_data <= tx_shift_data << 1;
                    end
                
                    if(rising_tick)
                    begin
                        rx_shift_data <= {rx_shift_data[6:0], miso};
                
                        if(bit_count == 3'd7)
                        begin
                            state <= DONE;
                        end
                        else
                        begin
                            bit_count <= bit_count + 1'b1;
                        end
                    end
                end
                
                DONE:
                begin
                    cs <= 1'b1;
                    done <= 1'b1;
                    en_clk_div <= 1'b0;
                    bit_count <= 3'd0;
                    state <= IDLE;
                end
                
                default:
                begin
                    state <= IDLE;
                end
                
            endcase
        end
    end 
endmodule

//////////////// Clock Divider 100Mhz to 1Mhz //////////////////

module clock_div
(
    input  clk,
    input  rst,
    input  en,

    output reg sclk,
    output reg rising_tick,
    output reg falling_tick
);

reg [5:0] count;

always @(posedge clk)
begin

    rising_tick  <= 1'b0;
    falling_tick <= 1'b0;

    if(rst)
    begin
        sclk <= 1'b0;
        count <= 6'd0;
        rising_tick <= 1'b0;
        falling_tick <= 1'b0;
    end

    else if(en)
    begin

        if(count == 6'd49)
        begin
            count <= 6'd0;

            if(sclk == 1'b0)
            begin
                sclk <= 1'b1;
                rising_tick <= 1'b1;
            end
            else
            begin
                sclk <= 1'b0;
                falling_tick <= 1'b1;
            end
        end

        else
        begin
            count <= count + 1'b1;
        end

    end

    else
    begin
    
        sclk <= 1'b0;
        count <= 6'd0;
        rising_tick <= 1'b0;
        falling_tick <= 1'b0;
    end
end
endmodule
