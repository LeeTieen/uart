module fifo_sync #(
    parameter int DATA_WIDTH = 8, int DEPTH = 8
)(
    input logic clk,
    input logic rst_n,
    input logic wr_en,
    input logic rd_en,
    input logic [DATA_WIDTH-1:0] din,

    output logic [DATA_WIDTH-1:0] dout,
    output logic full,
    output logic empty
);

    localparam int PTR_WIDTH = (DEPTH <= 1) ? 1 : $clog2(DEPTH);
    localparam int COUNT_WIDTH = $clog2(DEPTH+1);

    logic [DATA_WIDTH-1:0] mem[0:DEPTH-1];
    logic [PTR_WIDTH-1:0] wr_ptr;
    logic [PTR_WIDTH-1:0] rd_ptr;
    logic [COUNT_WIDTH-1:0] count;
    logic write_ok;
    logic read_ok;

    assign full     = (count == DEPTH);
    assign empty    = (count == 0);
    assign write_ok = ((full != 1) && (wr_en == 1));
    assign read_ok  = ((empty != 1) && (rd_en == 1));

    function automatic logic [PTR_WIDTH-1:0] next_ptr(
        logic [PTR_WIDTH-1:0] ptr
    );
        if(ptr == DEPTH - 1)
            next_ptr = '0;
        else
            next_ptr = ptr + 1'b1;
    endfunction

    always_ff @(posedge clk) begin
        if (!rst_n) begin
            count   <= '0;
            wr_ptr  <= '0;
            rd_ptr  <= '0;
            dout    <= '0;
        end

        else begin
            case({read_ok,write_ok})

                2'b00: begin
                    if (rd_en && empty)
                        dout <= '0;
                end

                2'b01: begin
                    mem[wr_ptr] <= din;
                    wr_ptr      <= next_ptr(wr_ptr);
                    count       <= count + 1'b1;

                    // Special case: read and write when FIFO is empty
                    if (rd_en && empty)
                        dout <= '0;
                end

                2'b10: begin
                    dout        <= mem[rd_ptr];
                    rd_ptr      <= next_ptr(rd_ptr);
                    count       <= count - 1'b1;
                end

                2'b11: begin
                    mem[wr_ptr] <= din;
                    dout        <= mem[rd_ptr];
                    wr_ptr      <= next_ptr(wr_ptr);
                    rd_ptr      <= next_ptr(rd_ptr);
                end
            endcase
        end
    end
endmodule