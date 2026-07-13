module fifo #(  parameter DATA_WIDTH = 8 ,
                parameter DEPTH = 16)(
                    input wire clk,
                    input wire rst,

                    input wire wr_en,
                    input wire rd_en,

                    input wire [DATA_WIDTH-1:0] din,

                    output reg [DATA_WIDTH-1:0] dout,
                    
                    output wire full,
                    output wire empty,

                    output reg overflow,
                    output reg underflow

                );
    /*
        INTERNAL MEMORY
    */
    
    reg [DATA_WIDTH-1:0] memory [0:DEPTH-1];    
   
    /*
        INTERNAL REGISTERS
    */
    
    localparam ADDR_WIDTH = $clog2(DEPTH);

    reg [ADDR_WIDTH-1:0] wr_ptr;//write pointer
    reg [ADDR_WIDTH-1:0] rd_ptr;//read pointer

    reg [ADDR_WIDTH:0] count;

    /*
        NEXT STATE 
    */

    wire [ADDR_WIDTH-1:0] wr_ptr_next;
    wire [ADDR_WIDTH-1:0] rd_ptr_next;
    
    assign wr_ptr_next = (wr_ptr == DEPTH-1) ? 0 : wr_ptr + 1;
    assign rd_ptr_next = (rd_ptr == DEPTH-1) ? 0 : rd_ptr + 1;

    /*
        STATUS FLAGS
    */

    assign full = (count == DEPTH);
    assign empty = (count == 0);

    /*
        OPERATION ENABLE LOGIC
    */

    wire write_ok;
    wire read_ok;

    assign write_ok = wr_en && (!full || rd_en);
    assign read_ok  = rd_en && !empty;


    /*
        SEQUENTIAL LOGIC SECTION
    */
    always@(posedge clk) begin

        if (rst) begin

            wr_ptr <= 0;
            rd_ptr <= 0;
            count <= 0;

            dout <= 0;

            overflow <= 0;
            underflow <= 0;

        end
        else begin
            overflow <= 0;
            underflow <= 0;
            /*
                WRITE OPERATION
            */
            if (wr_en) begin
                if (write_ok) begin

                    memory[wr_ptr] <= din;
                    wr_ptr <= wr_ptr_next;

                end
                else if (wr_en) begin

                    overflow <= 1;

                end
            end
            /*
                READ OPERATION
            */
            if (rd_en) begin
                if (read_ok) begin

                    dout <= memory[rd_ptr];
                    rd_ptr <= rd_ptr_next;

                end
                else if (rd_en) begin

                    underflow <= 1;

                end
            end
            /*
                COUNT UPDATE
            */
            if (write_ok && !read_ok)
                count <= count + 1;
            else if (!write_ok && read_ok)
                count <= count - 1;
        end
    end

endmodule