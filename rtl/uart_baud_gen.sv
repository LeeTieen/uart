module uart_baud_gen #(parameter BAUDTICK = 78)(
    input logic clk_i,
    input logic _rst_i,

    output logic tick_o
);

localparam BIT_WIDTH = $clog2(BAUDTICK);

logic [BIT_WIDTH-1:0] count;
logic [BIT_WIDTH-1:0] temp;

assign tick_o = (count == BAUDTICK-1) ? 1 : 0;
assign count = temp;

always_ff @(posedge clk_i)
    begin
        if (!_rst_i) temp <= 0;
        else temp <= (count == BAUDTICK-1) ? 0 : temp + 1;
    end

endmodule

