`include "def.v"

module dp(
  input                                 clk,
  input                                 reset,
  input                                 cnt_rst,
  input               [`CMD_FLAG_W-1:0] cmd_flags,
  output reg          [`INT_FLAG_W-1:0] int_flags,
  input                           [3:0] m, n, k,
  output reg           [`WORD_SIZE-1:0] in_a, in_b, in_c,
  input                [`WORD_SIZE-1:0] out_a, out_b, out_c,
  output reg     [`GBUFF_INDX_SIZE-1:0] addr_a, addr_b, addr_c,
  output reg                            wr_en_a, wr_en_b, wr_en_c,
  input                [`LOC_CNT_W-1:0] blk_local_idx,
  input                [`GLB_CNT_W-1:0] a_blk_idx,
  input                [`GLB_CNT_W-1:0] b_blk_idx
);

  // S_BLK_B
  reg                                   rst_arr;
  // S_WRIT
  wire           [`GBUFF_INDX_SIZE-1:0] write_base; 
  // S_FEED
  wire                           [0:31] from_top__net [0:4];
  wire                           [0:31] from_left_net [0:4];
  wire                           [31:0] multi_out_net [0:3];
  reg                            [0:31] mat_a, mat_b;
  wire                                  systolic_array_rst;
 
  // S_READ_A, READ_B
  wire                            [3:0] bufA_idx, bufB_idx;
  wire                            [3:0] addrA_idx, addrB_idx, addrC_idx;
  reg                            [31:0] bufA [0:6];
  reg                            [31:0] bufB [0:6];
  // S_WAIT
  reg                             [3:0] M, N, K;
  reg                      [`CNT_W-1:0] cnt;
  wire                     [`CNT_W-1:0] cnt_zero = {`CNT_W{1'b0}};

  // 4x4 systolic array
  assign from_top__net[0][0:31] = mat_b;
  assign from_left_net[0][0:31] = mat_a;
  assign systolic_array_rst = reset | rst_arr;
  /*
                                            -------------------------
                                            | 0   | 0   | 0   | b33 |
                                            | 0   | 0   | b32 | b23 |
          4X4 Systolic array                | 0   | b31 | b22 | b13 |
       for matrix multiplication            | b30 | b21 | b12 | b03 |
                A X B                       | b20 | b11 | b02 | 0   |
                                            | b10 | b01 | 0   | 0   |
                                            | b00 | 0   | 0   | 0   |
  -------------------------------------------------------------------
  | 0   | 0   | 0   | a03 | a02 | a01 | a00 | c00 | c01 | c02 | c03 |
  -------------------------------------------------------------------
  | 0   | 0   | a13 | a12 | a11 | a10 | 0   | c10 | c11 | c12 | c13 |
  -------------------------------------------------------------------
  | 0   | a23 | a22 | a21 | a20 | 0   | 0   | c20 | c21 | c22 | c23 |
  -------------------------------------------------------------------
  | a33 | a32 | a31 | a30 | 0   | 0   | 0   | c30 | c31 | c32 | c33 |
  -------------------------------------------------------------------
  */
  genvar i, j;
  generate 
    for(i=0; i<4; i=i+1) begin: sys_row // row
      for(j=0; j<4; j=j+1) begin: sys_col // col
        mac ul_mac(
          .clk      (clk),
          .reset    (systolic_array_rst),
          .up_in    (from_top__net[i  ][j * 8 : j * 8 + 7] ),
          .left_in  (from_left_net[j  ][i * 8 : i * 8 + 7] ),
          .up_out   (from_top__net[i+1][j * 8 : j * 8 + 7] ), // move downward
          .left_out (from_left_net[j+1][i * 8 : i * 8 + 7] ), // move right
          .mat_out  (multi_out_net[i  ][31-(j * 8): 24-(j * 8)] )  // move downward
        );
      end
    end
  endgenerate

  // S_WAIT
  always @(posedge clk, posedge reset) begin
    if(reset)
      int_flags[`INT_WAIT] <= 1'b0;
    else if (cmd_flags[`CMD_WAIT])
      int_flags[`INT_WAIT] <= 1'b1;
    else
      int_flags[`INT_WAIT] <= 1'b0;
  end

    // Wait for signal then read config 
    always @(posedge clk, posedge reset) begin
      if(reset) begin
        M <= 0; N <= 0; K <= 0;
      end else if(cmd_flags[`CMD_WAIT]) begin
        M <= m; N <= n; K <= k;
      end else begin
        M <= M; N <= N; K <= K;
      end
    end

  // S_READ_A
  always @(posedge clk, posedge reset) begin
    if(reset)
      int_flags[`INT_READ_A] <= 1'b0;
    else if (cmd_flags[`CMD_READ_A])
      int_flags[`INT_READ_A] <= (cnt <= `BUF_SIZE) ? 1'b0 : 1'b1;
    else
      int_flags[`INT_READ_A] <= 1'b0;
  end

  // S_READ_B
  always @(posedge clk, posedge reset) begin
    if(reset)
      int_flags[`INT_READ_B] <= 1'b0;
    else if (cmd_flags[`CMD_READ_B])
      int_flags[`INT_READ_B] <= (cnt <= `BUF_SIZE) ? 1'b0 : 1'b1;
    else
      int_flags[`INT_READ_B] <= 1'b0;
  end

    // Buffer read/write control
    always @(posedge clk, posedge reset) begin
      if(reset) begin
        wr_en_a <= 0; wr_en_b <= 0; wr_en_c <= 0;
      end else if(cmd_flags[`CMD_READ_A] | cmd_flags[`CMD_READ_B] ) begin
        wr_en_a <= 0; wr_en_b <= 0; wr_en_c <= 1;
      end else if(cmd_flags[`CMD_WRIT] ) begin
        wr_en_a <= 0; wr_en_b <= 0; wr_en_c <= 1;
      end else begin
        wr_en_a <= 0; wr_en_b <= 0; wr_en_c <= 0;
      end
    end

    // Read 4x4 block from bufA & bufB
    assign addrA_idx = cnt[3:0];
    assign bufA_idx = (cnt[3:0] > 2) ? (cnt[3:0] - 2) : 0;
    assign addrB_idx = cnt[3:0];
    assign bufB_idx  = (cnt[3:0] > 2) ? (cnt[3:0] - 2) : 0;
    integer buf_i, buf_j;
    always @(posedge clk, posedge reset) begin
      if(reset) begin
        addr_a <= 0;
        addr_b <= 0;
        for(buf_i=0 ; buf_i<=`BUF_SIZE ; buf_i=buf_i+1) begin: buf_init
          bufA[buf_i] <= 0; bufB[buf_i] <= 0;
        end
      end else if(cmd_flags[`CMD_READ_A]) begin
        // Send read address
        if(cnt < 4) begin
          addr_a <= a_blk_idx * K + blk_local_idx * 4 + addrA_idx;
        end
        // Buffer data
        if(cnt >= 2 && cnt <= 5) begin
          if(blk_local_idx * 4 + addrA_idx <= (K+1)) begin
            bufA[bufA_idx+0] [31:24]    <= out_a[31:24];
            bufA[bufA_idx+1] [23:16]    <= out_a[23:16];
            bufA[bufA_idx+2] [15:8]     <= out_a[15:8 ];
            bufA[bufA_idx+3] [7:0]      <= out_a[7 :0 ];
          end else begin
            bufA[bufA_idx+0] [31:24]    <= 0;
            bufA[bufA_idx+1] [23:16]    <= 0;
            bufA[bufA_idx+2] [15:8]     <= 0;
            bufA[bufA_idx+3] [7:0]      <= 0;
          end
        end
      end else if(cmd_flags[`CMD_READ_B]) begin
        // Send read address
        if(cnt < 4) begin
          addr_b <= b_blk_idx * K + (blk_local_idx-1) * 4 + addrB_idx;
        end
        // Buffer data
        if(cnt >= 2 && cnt <= 5) begin
          if( (blk_local_idx-1) * 4 + addrB_idx <= (K+1)) begin
            bufB[bufB_idx+0] [31:24]    <= out_b[31:24];
            bufB[bufB_idx+1] [23:16]    <= out_b[23:16];
            bufB[bufB_idx+2] [15:8]     <= out_b[15:8 ];
            bufB[bufB_idx+3] [7:0]      <= out_b[7 :0 ];
          end else begin
            bufB[bufB_idx+0] [31:24]    <= 0;
            bufB[bufB_idx+1] [23:16]    <= 0;
            bufB[bufB_idx+2] [15:8]     <= 0;
            bufB[bufB_idx+3] [7:0]      <= 0;
          end
        end
      end else begin
        addr_a <= 0; addr_b <= 0;
        for(buf_j=0 ; buf_j<=`BUF_SIZE ; buf_j=buf_j+1) begin: buf_hold
          bufA[buf_j] <= bufA[buf_j]; bufB[buf_j] <= bufB[buf_j];
        end
      end
    end

  // S_FEED
  always @(posedge clk, posedge reset) begin
    if(reset) begin 
      int_flags[`INT_FEED] <= 1'b0;
    end else if (cmd_flags[`CMD_FEED]) begin
      int_flags[`INT_FEED] <= (cnt <= `BUF_SIZE) ? 1'b0 : 1'b1;
    end else
      int_flags[`INT_FEED] <= 1'b0;
  end

    // Feed input to systolic array
    always @(posedge clk, posedge reset) begin
      if(reset) begin
        mat_a <= 0;
        mat_b <= 0;
      end else if(cmd_flags[`CMD_FEED]) begin
        if(cnt <= `BUF_SIZE) begin
          mat_a <= bufA[cnt];  mat_b <= bufB[cnt];
        end else begin
          mat_a <= 0; mat_b <= 0;
        end
      end
    end

  // S_WRIT
  always @(posedge clk, posedge reset) begin
    if(reset) begin 
      int_flags[`INT_WRIT] <= 1'b0;
    end else if (cmd_flags[`CMD_WRIT]) begin
      int_flags[`INT_WRIT] <= (cnt <= `BUF_SIZE) ? 1'b0 : 1'b1;
    end else
      int_flags[`INT_WRIT] <= 1'b0;
  end

    // Write matrix multiplication result back to buffer C
    assign addrC_idx = cnt[3:0];
    assign write_base = a_blk_idx * 4 + b_blk_idx * M;
    always @(posedge clk, posedge reset) begin
      if(reset) begin
        in_a <= 0; in_b <= 0; in_c <= 0; addr_c <= 0;
      end else if(cmd_flags[`CMD_WRIT]) begin
        if(cnt <= 3) begin
          addr_c <= write_base + addrC_idx;
          in_c[31:24] <= multi_out_net[addrC_idx][7 :0 ];
          in_c[23:16] <= multi_out_net[addrC_idx][15:8 ];
          in_c[15:8 ] <= multi_out_net[addrC_idx][23:16];
          in_c[7 :0 ] <= multi_out_net[addrC_idx][31:24];
        end
      end else begin
        in_a <= 0; in_b <= 0; in_c <= in_c; addr_c <= addr_c;
      end
    end

  // S_BLK_B & S_BLK_A
  always @(posedge clk, posedge reset) begin
    if(reset) begin 
      int_flags[`INT_BLK_A] <= 1'b0;
      int_flags[`INT_BLK_B] <= 1'b0;
      rst_arr <= 1;
    end else if (cmd_flags[`CMD_BLK_A]) begin
      int_flags[`INT_BLK_A] <= 1'b1;
      rst_arr <= 1;
    end else if (cmd_flags[`CMD_BLK_B]) begin
      int_flags[`INT_BLK_B] <= 1'b1;
      rst_arr <= 1;
    end else begin
      int_flags[`INT_BLK_A] <= 1'b0;
      int_flags[`INT_BLK_B] <= 1'b0;
      rst_arr <= 0;
    end
  end

  // Shared counter
  wire do_cnt = 1;
  //wire do_cnt = (cmd_flags[`CMD_WAIT] | cmd_flags[`CMD_READ_A]); 
  always @(posedge clk, posedge reset) begin
    if(reset) begin
      cnt <= cnt_zero;
    end else if(cnt_rst) begin
      cnt <= cnt_zero;
    end else if(do_cnt) begin 
      cnt <= cnt + 1;
    end
  end

endmodule
