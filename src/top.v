//============================================================================//
// AIC2021 Project1 - TPU Design                                              //
// file: top.v                                                                //
// description: Top module complete your TPU design here                      //
// authors: kaikai (deekai9139@gmail.com)                                     //
//          suhan  (jjs93126@gmail.com)                                       //
//============================================================================//

`ifndef __TOP_V
`define __TOP_V

`include "define.v"
`include "global_buffer.v"

module top(clk, rst, start, m, n,  k, done);

  input clk;
  input rst;
  input start;
  input [3:0] m, k, n;
  output done;

  wire                                  wr_en_a,
                                        wr_en_b,
                                        wr_en_out;
  wire           [`GBUFF_INDX_SIZE-1:0] index_a,
                                        index_b,
                                        index_out;
  wire                 [`WORD_SIZE-1:0] data_in_a,
                                        data_in_b,
                                        data_in_o;
  wire                 [`WORD_SIZE-1:0] data_out_a,
                                        data_out_b,
                                        data_out_o;

//----------------------------------------------------------------------------//
// TPU module declaration                                                     //
//----------------------------------------------------------------------------//
tpu ul_tpu( .clk(clk),
            .rst(rst),
            .start(start),
            .m(m), .n(n), .k(k),
            .done(done),
            .wr_en_a(wr_en_a),
            .wr_en_b(wr_en_b),
            .wr_en_c(wr_en_out),
            .addr_a(index_a),
            .addr_b(index_b),
            .addr_c(index_out),
            .in_a(data_in_a),
            .in_b(data_in_b),
            .in_c(data_in_o),
            .out_a(data_out_a),
            .out_b(data_out_b),
            .out_c(data_out_o)
          );

//----------------------------------------------------------------------------//
// Global buffers declaration                                                 //
//----------------------------------------------------------------------------//
  global_buffer GBUFF_A(.clk     (clk       ),
                        .rst     (rst       ),
                        .wr_en   (wr_en_a   ),
                        .index   (index_a   ),
                        .data_in (data_in_a ),
                        .data_out(data_out_a));

  global_buffer GBUFF_B(.clk     (clk       ),
                        .rst     (rst       ),
                        .wr_en   (wr_en_b   ),
                        .index   (index_b   ),
                        .data_in (data_in_b ),
                        .data_out(data_out_b));

  global_buffer GBUFF_OUT(.clk     (clk      ),
                          .rst     (rst      ),
                          .wr_en   (wr_en_out),
                          .index   (index_out),
                          .data_in (data_in_o),
                          .data_out(data_out_o));

endmodule

`endif
