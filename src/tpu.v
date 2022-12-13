//============================================================================//
// AIC2021 Project1 - TPU Design                                              //
// file: tpu.v                                                                //
// description: TPU top module                                                //
// authors: Wei Cheng (michael1996623@gmail.com)                              //
//============================================================================//

`include "define.v"

module tpu(
  input                                 clk,
  input                                 rst,
  input                                 start,
  input                           [3:0] m, k, n,
  output                                done,
  output                                wr_en_a, wr_en_b, wr_en_c,
  output         [`GBUFF_INDX_SIZE-1:0] addr_a, addr_b, addr_c,
  output               [`WORD_SIZE-1:0] in_a, in_b, in_c,
  input                [`WORD_SIZE-1:0] out_a, out_b, out_c
);
 
  // Write your code here

//  wire                [`CMD_FLAG_W-1:0] fb_flags;
//  wire                [`CMD_FLAG_W-1:0] cmd_flags;
//  wire                [`INT_FLAG_W-1:0] int_flags;
//  
//  assign                                fb_flags = int_flags & cmd_flags;
//  wire                                  dp_cnt_rst;
// 
//  wire                                  task_done;
//
//  wire                 [`LOC_CNT_W-1:0] blk_local_idx;
//  wire                 [`GLB_CNT_W-1:0] a_blk_idx, b_blk_idx;
//
//  ctrl ul_ctrl(
//    .clk(clk),
//    .reset(rst),
//    .dp_cnt_rst(dp_cnt_rst),
//    .fb_flags(fb_flags),
//    .cmd_flags(cmd_flags),
//    .task_done(done),
//    .m(m), .n(n), .k(k),
//    .blk_local_idx(blk_local_idx),
//    .a_blk_idx(a_blk_idx),
//    .b_blk_idx(b_blk_idx)
//  );
//  
//  dp ul_dp(
//    .clk(clk),
//    .reset(rst),
//    .cnt_rst(dp_cnt_rst),
//    .cmd_flags(cmd_flags),
//    .int_flags(int_flags),
//    .m(m), .n(n), .k(k),
//    .in_a(in_a),
//    .in_b(in_b),
//    .in_c(in_c),
//    .out_a(out_a),
//    .out_b(out_b),
//    .out_c(out_c),
//    .addr_a(addr_a),
//    .addr_b(addr_b),
//    .addr_c(addr_c),
//    .wr_en_a(wr_en_a),
//    .wr_en_b(wr_en_b),
//    .wr_en_c(wr_en_c),
//    .blk_local_idx(blk_local_idx),
//    .a_blk_idx(a_blk_idx),
//    .b_blk_idx(b_blk_idx)
//  );

endmodule
