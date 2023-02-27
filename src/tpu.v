`include "define.v"

module tpu(
  input                                 clk,
  input                                 rst,
  input                                 start,
  input                           [3:0] m, k, n,
  output              reg                  done,
  output              reg                  wr_en_a, wr_en_b, wr_en_c,
  output              reg [`GBUFF_INDX_SIZE-1:0] addr_a, addr_b, addr_c,  //8
  output              reg [`WORD_SIZE-1:0] in_a, in_b, in_c, //data of a,b,c
  input                [`WORD_SIZE-1:0] out_a, out_b, out_c
);
 
  //---------Write your code here----------------
// `define sys_OFF = 3'd4;

localparam off_1 =  3'd1;
localparam off_2 =  3'd2;
localparam off_3 =  3'd3;
localparam IDLE  = 3'd0;
localparam CAL   = 3'd1;
localparam WRITE = 3'd2;
localparam FINISH = 3'd3;
localparam MAC_HOLD = 3'd4;
localparam IDLE2 = 3'd5;
// mat_A
// reg [0:0] buf_a_0; // offset is 0
reg [`DATA_SIZE*off_1-1:0] buf_a_1;
reg [`DATA_SIZE*off_2-1:0] buf_a_2;
reg [`DATA_SIZE*off_3-1:0] buf_a_3;
//mat_B
//reg [0:0] buf_b_0; //offset is 0
reg [`DATA_SIZE*off_1-1:0] buf_b_1;
reg [`DATA_SIZE*off_2-1:0] buf_b_2;
reg [`DATA_SIZE*off_3-1:0] buf_b_3;
reg [2:0] state,next_state;
reg [4:0] cnt;

always @(posedge clk or posedge rst) begin
    if(rst)begin
        buf_a_1 <= 8'd0;
        buf_a_2 <= 16'd0;
        buf_a_3 <= 24'd0;
        buf_b_1 <= 8'd0;
        buf_b_2 <= 16'd0;
        buf_b_3 <= 24'd0;
    end
    else begin
        case (state)

            CAL:begin
                buf_a_1         <=  (cnt > {1'd0,k}+5'd1||cnt==5'd0) ? 8'd0 : out_a[23:16];

                buf_a_2[15:8]   <=  (cnt > {1'd0,k}+5'd1||cnt==5'd0) ? 8'd0 : out_a[15:8];
                buf_a_2[7:0]    <=  buf_a_2[15:8];

                buf_a_3[23:16]  <=  (cnt > {1'd0,k}+5'd1||cnt==5'd0) ? 8'd0 : out_a[7:0];
                buf_a_3[15:8]   <=  buf_a_3[23:16];
                buf_a_3[7:0]    <=  buf_a_3[15:8];

                buf_b_1         <=  (cnt > {1'd0,k}+5'd1||cnt==5'd0) ? 8'd0 : out_b[23:16];

                buf_b_2[15:8]   <=  (cnt > {1'd0,k}+5'd1||cnt==5'd0) ? 8'd0 : out_b[15:8];
                buf_b_2[7:0]    <=  buf_b_2[15:8];
                
                buf_b_3[23:16]  <=  (cnt > {1'd0,k}+5'd1||cnt==5'd0) ? 8'd0 : out_b[7:0];
                buf_b_3[15:8]   <=  buf_b_3[23:16];
                buf_b_3[7:0]    <=  buf_b_3[15:8];
			end
			default:begin
				buf_a_1 <= 8'd0;
				buf_a_2 <= 16'd0;
				buf_a_3 <= 24'd0;
				buf_b_1 <= 8'd0;
				buf_b_2 <= 16'd0;
				buf_b_3 <= 24'd0;
			end
        endcase
    end
end

wire out_m = (m > 4'd4);
wire out_n = (n > 4'd4);
wire fit_m = (m[1:0]==2'd0);
reg [1:0] cnt_m,cnt_n;
wire [1:0] rnd_m = m[3:2] + (m[1:0] > 2'd0); 
wire [1:0] rnd_n = n[3:2] + (n[1:0] > 2'd0); 
wire out_limit = (out_n || out_m);

wire                           [0:31] from_top__net [0:4];
wire                           [0:31] from_left_net [0:4];
wire                           [31:0] multi_out_net [0:3];
//wire systolic_array_rst = ((state==CAL&&cnt==5'd0)||rst||state==IDLE);
reg systolic_array_rst;

always @(posedge clk or posedge rst) begin
  	if(rst) systolic_array_rst <= 1;
	else begin
	//	if(state==IDLE) systolic_array_rst <= 1;
		if(state==IDLE2) systolic_array_rst <= 0;
		//if(state==WRITE&&cnt==5'd4) systolic_array_rst <= 1;
		if(next_state==IDLE2) systolic_array_rst <= 1;
	end
end

/*
assign from_top__net[0][0:7] = (((cnt >= {1'd0,k}+5'd1)&&state==CAL)||state!=CAL||(cnt==5'd0&&state==CAL)||state==IDLE) ? 8'd0 : out_b[31:24];
assign from_top__net[0][8:31] = (state!=CAL||state==IDLE) ? 24'd0 : {buf_b_1,buf_b_2[7:0],buf_b_3[7:0]};

assign from_left_net[0][0:7] = (((cnt >= {1'd0,k}+5'd1)&&state==CAL)||state!=CAL||(cnt==5'd0&&state==CAL)||state==IDLE) ? 8'd0 : out_a[31:24];
assign from_left_net[0][8:31] = (state!=CAL||state==IDLE) ? 24'd0 : {buf_a_1,buf_a_2[7:0],buf_a_3[7:0]};
*/
assign from_top__net[0][0:7] = (((cnt >= {1'd0,k}+5'd1)&&state==CAL)||state!=CAL||(cnt==5'd0&&state==CAL)) ? 8'd0 : out_b[31:24];
assign from_top__net[0][8:31] = (state!=CAL) ? 24'd0 : {buf_b_1,buf_b_2[7:0],buf_b_3[7:0]};

assign from_left_net[0][0:7] = (((cnt >= {1'd0,k}+5'd1)&&state==CAL)||state!=CAL||(cnt==5'd0&&state==CAL)) ? 8'd0 : out_a[31:24];
assign from_left_net[0][8:31] = (state!=CAL) ? 24'd0 : {buf_a_1,buf_a_2[7:0],buf_a_3[7:0]};

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

reg [`GBUFF_INDX_SIZE-1:0] last_addr_a,last_addr_b,last_addr_c;	//8 bit

always @(posedge clk or posedge rst) begin
    if(rst)begin
		done <= 0;
		in_a <= 32'd0;
		in_b <= 32'd0;
		in_c <= 32'd0;
		last_addr_a <= 8'd0;
		last_addr_b <= 8'd0;
		last_addr_c <= 8'd0;
        cnt <= 5'd0;
        addr_a <= 8'd0;
        addr_b <= 8'd0;
 		addr_c <= 8'd0;
		cnt_m <= 2'd0;
        cnt_n <= 2'd0;
		wr_en_a <= 0;
		wr_en_b <= 0;
		wr_en_c <= 0;
    end
    else begin
		in_a <= 32'd0;
		in_b <= 32'd0;
		in_c <= 32'd0;
		wr_en_a <= 0;
		wr_en_b <= 0;
		wr_en_c <= 0;
        case(state)
            CAL:begin
                if(cnt == {1'd0,k} + 5'd7)begin
				//if((k>4'd4&&cnt== {1'd0,k} + 5'd4)||k<=4'd4&&cnt=={k,1'd0}+5'd4)begin //not sure???
					cnt <= 5'd0;
                end
				else  cnt <= cnt+5'd1;
				
				if(cnt==5'd0) last_addr_b <= addr_b;

                if(cnt<{1'd0,k})begin
                    addr_a <= addr_a + 8'd1;
                    addr_b <= addr_b + 8'd1;                    
                end
				/*
                else begin
                    addr_a <= 8'd0;
                    addr_b <= 8'd0;
                endi*/
            end
            WRITE:begin
                if(cnt==5'd4)begin
					cnt <= 5'd0;
					wr_en_c<= 0;
					//monster
					if(fit_m==0&&cnt_m==rnd_m-2'd1)begin
						last_addr_c <= last_addr_c+ {6'd0,m[1:0]};
					end
					else last_addr_c <= addr_c+8'd1;


					//last_addr_c <= addr_c+8'd1;
					if(cnt_m==rnd_m-1)begin
						cnt_m <= 2'd0;
						cnt_n <= cnt_n + 2'd1;
						addr_a <= 8'd0;
						//addr_b <= 8'd0;
						
					end
					else begin
						addr_b <= last_addr_b;
                        cnt_m <= cnt_m + 2'd1;
					end

                end
				else begin 
					wr_en_c <= 1;
               		cnt <= cnt + 5'd1;
				end

				addr_c <= last_addr_c + cnt;
			  
				in_c[31:24] <= multi_out_net[cnt[1:0]][7 :0 ];
	            in_c[23:16] <= multi_out_net[cnt[1:0]][15:8 ];
    	        in_c[15:8 ] <= multi_out_net[cnt[1:0]][23:16];
        	    in_c[7 :0 ] <= multi_out_net[cnt[1:0]][31:24];
            end
			FINISH:begin
				wr_en_c <= 0;
        		done <= 1;
			end	
		endcase
        
    end
end

always @(posedge clk or posedge rst) begin
  if(rst) state <= IDLE;
  else state <= next_state;
end

always @(*) begin
  if(rst)begin
    next_state = IDLE;
  end
  else begin
    next_state = state;
    case (state)
      IDLE:  next_state = IDLE2;  //CAL;
      IDLE2: next_state = CAL;
	  CAL:   if(cnt == {1'd0,k} + 5'd7) next_state = WRITE;
	 // CAL:    if((k>4'd4&&cnt== {1'd0,k} + 5'd3)||k<=4'd4&&cnt=={k,1'd0}+4'd3) next_state = WRITE; //MAC_HOLD;
	  //MAC_HOLD: next_state = WRITE;
	  WRITE:begin
	  	if(cnt==5'd4&&cnt_m==rnd_m-1&&cnt_n==rnd_n-1) next_state = FINISH;
      	else if(cnt==5'd4)next_state = IDLE2;  //CAL;
      end	
	  FINISH: next_state = FINISH;
    endcase
  end
end

endmodule
