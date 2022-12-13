module mac(
  input                                 clk,
  input                                 reset,
  input                           [7:0] up_in,
  input                           [7:0] left_in,
  output reg                      [7:0] up_out,
  output reg                      [7:0] left_out,
  output reg                      [7:0] mat_out
);

  always @ (posedge clk or posedge reset) begin
    if (reset) begin
      up_out <= 0;
      left_out <= 0;
      mat_out <= 0;
    end else begin
      up_out <= up_in;
      left_out <= left_in;
      mat_out <= mat_out + up_in * left_in;
    end 
  end

endmodule
