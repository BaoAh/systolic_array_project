`include "def.v"

module ctrl(
  input                                 clk,
  input                                 reset,
  output reg                            dp_cnt_rst,
  input               [`INT_FLAG_W-1:0] fb_flags,
  output reg          [`CMD_FLAG_W-1:0] cmd_flags,
  output reg                            task_done,
  input                           [3:0] m, n, k,
  output reg           [`LOC_CNT_W-1:0] blk_local_idx,
  output reg           [`GLB_CNT_W-1:0] a_blk_idx,
  output reg           [`GLB_CNT_W-1:0] b_blk_idx
);

  reg                    [`STATE_W-1:0] curr_state, next_state;

  // Block index counter
  always @(posedge clk, posedge reset) begin
    if(reset) begin
      blk_local_idx <= {`LOC_CNT_W{1'b0}};
      a_blk_idx <= {`GLB_CNT_W{1'b0}};
      b_blk_idx <= {`GLB_CNT_W{1'b0}};
    end else if (fb_flags[`CMD_READ_A]) begin
      blk_local_idx <= blk_local_idx + 1'b1;
    end else if (fb_flags[`CMD_BLK_B]) begin
      blk_local_idx <= 0;
      b_blk_idx <= b_blk_idx + 1'b1;
      a_blk_idx <= {`GLB_CNT_W{1'b0}};
    end else if (fb_flags[`CMD_BLK_A]) begin
      blk_local_idx <= 0;
      a_blk_idx <= a_blk_idx + 1'b1;
    end
  end

  // Wait for interrupt signal
  wire                     wait_done  = fb_flags[`INT_WAIT];
  wire                    read_A_nyet = fb_flags[`INT_READ_A];
  wire                    read_B_nyet = fb_flags[`INT_READ_B];
  wire                      feed_done = fb_flags[`INT_FEED];
  wire                     write_done = fb_flags[`INT_WRIT];
  wire                [3:0] k_blk_cnt = (k%4 == 0) ? k/4 : k/4+1;
  wire                [3:0] m_blk_cnt = (m%4 == 0) ? m/4 : m/4+1;
  wire                [3:0] n_blk_cnt = (n%4 == 0) ? n/4 : n/4+1;
  wire                       blk_done = ( (blk_local_idx % k_blk_cnt) == 0 && 
                                           blk_local_idx != 0);
  wire                     clear_done = fb_flags[`INT_BLK_A] | fb_flags[`INT_BLK_B];
  wire                     blk_M_done = ( a_blk_idx == (m_blk_cnt - 1) );
  wire                     blk_N_done = ( b_blk_idx == (n_blk_cnt - 1) );

  // State Register (S)
  always @(posedge clk, posedge reset) begin
     if(reset)
       curr_state <= {`S_ZVEC | {{(`STATE_W-1){1'b0}}, 1'b1}};
     else
       curr_state <= next_state;
  end // State Register

  // Next State Logic (C)
  always @(*) begin
     next_state = `S_ZVEC;

     case (1'b1)

       // WAIT state
       curr_state[`S_WAIT]: begin
          if(wait_done)
            next_state[`S_READ_A] = 1'b1;
          else
            next_state[`S_WAIT] = 1'b1;
       end

       // READ_A state
       curr_state[`S_READ_A]: begin
          if(read_A_nyet)
            next_state[`S_READ_B] = 1'b1;
          else
            next_state[`S_READ_A] = 1'b1;
       end

       // READ_B state
       curr_state[`S_READ_B]: begin
          if(read_B_nyet)
            next_state[`S_FEED] = 1'b1;
          else
            next_state[`S_READ_B] = 1'b1;
       end

       // FEED state
       curr_state[`S_FEED]: begin
          if(feed_done)
            next_state[`S_BLK_CHK] = 1'b1;
          else
            next_state[`S_FEED] = 1'b1;
       end

       // BLK_CHK state
       curr_state[`S_BLK_CHK]: begin
          if(blk_done)
            next_state[`S_WRIT] = 1'b1;
          else
            next_state[`S_READ_A] = 1'b1;
       end

       // WRIT state
       curr_state[`S_WRIT]: begin
          if(write_done)
            next_state[`S_BLK_A] = 1'b1;
          else
            next_state[`S_WRIT] = 1'b1;
       end
       
       // BLK_A state
       curr_state[`S_BLK_A]: begin
          if(clear_done) begin
            if(blk_M_done)
              next_state[`S_BLK_B] = 1'b1;
            else
              next_state[`S_READ_A] = 1'b1;
          end else 
            next_state[`S_BLK_A] = 1'b1;
       end

       // BLK_B state
       curr_state[`S_BLK_B]: begin
          if(clear_done) begin
            if(blk_N_done)
              next_state[`S_END] = 1'b1;
            else
              next_state[`S_READ_A] = 1'b1;
          end else 
            next_state[`S_BLK_B] = 1'b1;
       end

       // End state
       curr_state[`S_END]: begin
          next_state[`S_END] = 1'b1;
       end

       // default
       default: begin
          next_state[`S_WAIT] = 1'b1;
       end
     endcase

  end // Next State Logic (C)

  // Output Logic (C)
  always @(*) begin
    cmd_flags = {`CMD_FLAG_W{1'b0}}; 
    dp_cnt_rst = 1'b0;
    task_done = 1'b0;

    case (1'b1)

      // WAIT state
      curr_state[`S_WAIT]: begin
        cmd_flags[`CMD_WAIT] = 1'b1;
        if(wait_done) begin
          dp_cnt_rst = 1;
        end
      end

      // READ_A state
      curr_state[`S_READ_A]: begin
        cmd_flags[`CMD_READ_A] = 1'b1;
        if(read_A_nyet) begin
          dp_cnt_rst = 1;
        end
      end

      // READ_B state
      curr_state[`S_READ_B]: begin
        cmd_flags[`CMD_READ_B] = 1'b1;
        if(read_B_nyet) begin
          dp_cnt_rst = 1;
        end
      end

      // FEED state
      curr_state[`S_FEED]: begin
        cmd_flags[`CMD_FEED] = 1'b1;
        if(feed_done) begin
          dp_cnt_rst = 1;
        end
      end

      // BLK_CHK state
      curr_state[`S_BLK_CHK]: begin
        dp_cnt_rst = 1;
      end

      // WRIT state
      curr_state[`S_WRIT]: begin
        cmd_flags[`CMD_WRIT] = 1'b1;
        if(write_done) begin
          dp_cnt_rst = 1;
        end
      end

      // BLK_A state
      curr_state[`S_BLK_A]: begin
        cmd_flags[`CMD_BLK_A] = 1'b1;
        if(clear_done) begin
          dp_cnt_rst = 1;
        end
      end

      // BLK_B state
      curr_state[`S_BLK_B]: begin
        cmd_flags[`CMD_BLK_B] = 1'b1;
        if(clear_done) begin
          dp_cnt_rst = 1;
        end
      end

      // End state
      curr_state[`S_END]: begin
        task_done = 1'b1; 
      end
      
      //default
      default: begin
        cmd_flags[`CMD_WAIT] = 1'b1;
      end
    endcase

  end // Next State Logic (C)

endmodule
