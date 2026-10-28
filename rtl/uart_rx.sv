module uart_rx #(parameter int DATA_WIDTH = 8)(
    input logic                     clk_i,
    input logic                     uartrx_i,
    input logic                     baudtick_i,
    input logic                     _rst_i,

    output logic [DATA_WIDTH-1:0]   uartrx_o,
    output logic                    rxdone_o
);

    localparam IDLE     = 2'b00;
    localparam START    = 2'b01;
    localparam DATA     = 2'b10;
    localparam STOP     = 2'b11;

    localparam STOP_BIT_TICK  = 16; //1 stopbit
    localparam DATA_BIT       = $clog2(DATA_WIDTH);

    logic [3:0]             s_count, next_s_count; //sampling 16x
    logic [DATA_BIT:0]      b_count, next_b_count;
    logic [DATA_WIDTH-1:0]  b, b_test, next_b, rx_pre;
    logic [DATA_WIDTH-1:0]  meta, rx;
    logic [1:0]             state, next_state;
    logic                   next_rx_done;
    
    assign uartrx_o = (rxdone_o) ? b : rx_pre;
    assign b_test = b;

    always_comb
      begin: proc_state
        next_state    = state;
        next_s_count  = s_count;
        next_b_count  = b_count;
        next_b        = b;
        next_rx_done  = 0;

        case(state)
          IDLE:
            begin
              next_state    = (uartrx_i != 0) ? IDLE : START;
              next_s_count  = 0;
            end

          START:
            begin
              if (baudtick_i == 1) begin
                  if (s_count == 7) begin
                    next_state        = DATA;
                    next_s_count      = 0;
                    next_b_count      = 0;
                  end
                  else begin
                    next_state = START;
                    next_s_count = s_count + 1;
                  end
                end
            end

          DATA:
            begin
              if (baudtick_i == 1) begin
                if (s_count == 15) begin
                  next_s_count = 0;
                  next_b       = {rx, b[DATA_WIDTH-1:1]};
                  if (b_count == DATA_WIDTH-1) next_state = STOP;
                  else begin
                    next_state = DATA;
                    next_b_count = b_count + 1;
                  end
                end
                else begin
                  next_s_count = s_count + 1;
                  next_state = DATA;
                end
              end
            else next_state = DATA;
            end

          STOP:
            begin
              if (baudtick_i == 1) begin
                if (s_count == STOP_BIT_TICK-1) begin
                  next_rx_done = 1;
                  next_state = IDLE;
                end
                else begin
                  next_s_count = s_count + 1;
                  next_state = STOP;
                end
              end
              else next_state = STOP;
            end

          default: next_state = IDLE;

        endcase
      end

    always_ff @(posedge clk_i)
      begin: proc_meta
        meta <= uartrx_i;
        rx   <= meta;
      end

    always_ff @(posedge clk_i)
      begin: proc_output
        if(_rst_i == 0) begin
          s_count         <= 0;
          rxdone_o        <= 0;
          state           <= IDLE;
          b               <= 0;
          rx_pre          <= 0;
          b_count         <= 0;
        end
        else begin
          s_count         <= next_s_count;
          rxdone_o        <= next_rx_done;
          state           <= next_state;
          b               <= next_b;
          rx_pre          <= uartrx_o;
          b_count         <= next_b_count;
        end
      end
endmodule

