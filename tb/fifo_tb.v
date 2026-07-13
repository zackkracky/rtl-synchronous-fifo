    `timescale 1ns/1ps

    module fifo_tb;

        /*
            ALL DECLARATIONS
        */
        parameter DATA_WIDTH = 8;
        parameter DEPTH = 16;

        reg clk;
        reg rst;

        reg wr_en;
        reg rd_en;

        reg [DATA_WIDTH-1:0] din;

        wire [DATA_WIDTH-1:0] dout;
                        
        wire full;
        wire empty;

        wire overflow;
        wire underflow;

        fifo #(
            .DATA_WIDTH(DATA_WIDTH),
            .DEPTH(DEPTH)
        ) dut (

            .clk(clk),
            .rst(rst),

            .wr_en(wr_en),  
            .rd_en(rd_en),

            .din(din),
            .dout(dout),

            .full(full),
            .empty(empty),

            .overflow(overflow),
            .underflow(underflow)

        );

        initial begin
            clk = 0;
        end

        /*
            CLK GENERATION
        */
        always #5 clk = ~clk;
        /*
            RESET INITIATION
        */
        initial begin

            $dumpfile("wave/fifo.vcd");
            $dumpvars(0,fifo_tb);

            rst  = 1;
            wr_en = 0;
            rd_en = 0;
            din = 0;

            #20;//2 clk cycles

            rst = 0; 

            //1st write
            #10;
            
            din = 8'h11;
            wr_en = 1;

            #10;//one cycle

            wr_en = 0;

            //2nd write
            #10;//one cycle for clean write after the previous write
            din   = 8'h22;
            wr_en = 1;

            #10;
            wr_en = 0;

            //3rd write
            #10;
            din   = 8'h33;
            wr_en = 1;

            #10;
            wr_en = 0;

            //4th write
            #10;
            din   = 8'h44;
            wr_en = 1;

            #10;
            wr_en = 0;
            
             //1st read
            #10;
            rd_en = 1;

            #10;
            rd_en = 0;

            //2nd read
            #10;
            rd_en = 1;

            #10;
            rd_en = 0;

            //3rd read
            #10;
            rd_en = 1;

            #10;
            rd_en = 0;

            //4th read
            #10;
            rd_en = 1;

            #10;
            rd_en = 0;    

            //END
            #20;
            $finish;//signals would run forever otherwise

        end
        

    endmodule