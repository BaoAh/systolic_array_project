// This is generated automatically on 2022/12/13-17:29:16
`ifndef __FLAG_DEF__
`define __FLAG_DEF__

// There're 7 interrupt flags in this design
`define INT_WAIT               	 0  
`define INT_READ_A             	 1  
`define INT_READ_B             	 2  
`define INT_FEED               	 3  
`define INT_WRIT               	 4  
`define INT_BLK_B              	 5  
`define INT_BLK_A              	 6  
`define INT_FLAG_W             	 7  

// There're 7 output flags in this design
`define CMD_WAIT               	 0  
`define CMD_READ_A             	 1  
`define CMD_READ_B             	 2  
`define CMD_FEED               	 3  
`define CMD_WRIT               	 4  
`define CMD_BLK_B              	 5  
`define CMD_BLK_A              	 6  
`define CMD_FLAG_W             	 7  

// There're 9 states in this design
`define S_WAIT                 	 0  
`define S_READ_A               	 1  
`define S_READ_B               	 2  
`define S_FEED                 	 3  
`define S_BLK_CHK              	 4  
`define S_WRIT                 	 5  
`define S_BLK_B                	 6  
`define S_BLK_A                	 7  
`define S_END                  	 8  
`define S_ZVEC                 	 9'b0
`define STATE_W                	 9  

// Macro from template
`define BUF_SIZE               	 6  

// Self-defined macro
`define CNT_W                  	 5  
`define GLB_CNT_W              	 3  
`define LOC_CNT_W              	 3  

`endif
