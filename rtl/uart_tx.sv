module uart_tx #(
    parameter int DATA_WIDTH = 8
)(
    input logic                     clk_i,
    input logic                     _rst_i,
    input logic                     baudtick_i,
    input logic [DATA_WIDTH-1:0]    uarttx_i,
    input logic                     txstart_i,
    
    output logic                    txdone_o,
    output logic                    uarttx_o

);

    localparam IDLE     = 3'b000;
    localparam START    = 3'b001;
    localparam DATA     = 3'b010;
    localparam STOP     = 3'b011;
    localparam STOP_BIT_TICK  = 16; //1 stopbit
    localparam DATA_BIT = $clog2(DATA_WIDTH);

    logic [3:0]                   s_count, next_s_count;
    logic [DATA_BIT:0]            b_count, next_b_count;
    logic [DATA_WIDTH-1:0]        b, next_b; 
    logic [1:0]                   state, next_state;
    logic                         next_txdone;
    logic                         uarttx, next_tx;
    
    always_comb
        begin: proc_state
            next_state      = state;
            next_s_count    = s_count;
            next_b_count    = b_count;
            next_b          = b;
            next_tx         = uarttx;
            next_txdone     = 0;

            case(state)
                IDLE: begin
                    next_tx         = 1;
                    next_state      = (txstart_i == 0) ? IDLE : START;
                    next_s_count    = 0;
                    next_b          = uarttx_i;
                    next_txdone     = 1;
                end

                START: begin
                    if (baudtick_i == 1) begin
                        next_tx = 0;
                        if (s_count == 15) begin
                            next_state      = DATA;
                            next_s_count    = 0;
                            next_b_count    = 0;
                        end

                        else begin
                            next_state      = START;
                            next_s_count    = s_count + 1; 
                        end
                    end

                    else next_state = START;
                end

                DATA: begin
                    if (baudtick_i == 1) begin
                        next_tx = b[0];
                        if (s_count == 15) begin
                            next_s_count    = 0;
                            next_b          = {1'b0, b[7:1]};
                            if (b_count == DATA_WIDTH - 1) next_state = STOP;
                            else begin
                                next_state      = DATA;
                                next_b_count    = b_count + 1;
                            end
                        end
                        else begin
                            next_state      = DATA;
                            next_s_count    = s_count + 1;
                        end
                    end

                    else next_state = DATA;
                end

                STOP: begin
                    if (baudtick_i == 1) begin
                        next_tx = 1;
                        if (s_count == STOP_BIT_TICK - 1) begin
                            next_txdone     = 1;
                            next_state      = IDLE;
                        end
                        else begin
                            next_s_count    = s_count + 1;
                            next_state      = STOP;
                        end
                    end

                    else next_state = STOP;
                end

                default: next_state = IDLE; 
            endcase
        end
    always_ff @(posedge clk_i)
        if (!_rst_i) begin
            s_count         <= 0;
            txdone_o        <= 0;
            state           <= IDLE;
            b               <= 0;
            uarttx          <= 1;
            b_count         <= 0;
        end

        else begin: proc_output
            s_count         <= next_s_count;
            txdone_o        <= next_txdone;
            state           <= next_state;
            b               <= next_b;
            uarttx          <= next_tx;
            b_count         <= next_b_count;
        end

        assign uarttx_o = uarttx;
endmodule