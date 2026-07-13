    `timescale 1ns/1ps

    module fifo_tb_overflow;
        
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

        integer i;

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
            $dumpfile("wave/fifo_overflow.vcd");
            $dumpvars(0,fifo_tb_overflow);

            rst  = 1;
            wr_en = 0;
            rd_en = 0;
            din = 0;

            #20;//2 clk cycles

            rst = 0; 

            /* 
                WRITES FILL
            */
            
            for (i=0; i < DEPTH ;i++)begin
                #10;
                din = i;
                wr_en = 1;

                #10;
                wr_en = 0;
            end
            
            //Illegal write

            #10;
            din = 8'hAA;
            wr_en= 1;

            #10;

            wr_en = 0;

            
            //END
            #20;
            $finish;//signals would run forever otherwise

        end
        

    endmodule