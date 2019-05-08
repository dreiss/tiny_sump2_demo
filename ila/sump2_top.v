/* ****************************************************************************

Top module for TinyFPGA-as-SUMP2.

-- Author:      khubbard, dreiss
-- License:     This project is licensed with the CERN Open Hardware Licence
--              v1.2.  You may redistribute and modify this project under the
--              terms of the CERN OHL v.1.2. (http://ohwr.org/cernohl).
--              This project is distributed WITHOUT ANY EXPRESS OR IMPLIED
--              WARRANTY, INCLUDING OF MERCHANTABILITY, SATISFACTORY QUALITY
--              AND FITNESS FOR A PARTICULAR PURPOSE. Please see the CERN OHL
--              v.1.2 for applicable Conditions.
-- 
-- ***************************************************************************/
`default_nettype none

module sump2_top
(
  input  wire         clk_in,
  input  wire         uart_wi,
  output wire         uart_ro,
  input  wire [15:0]  events_din,
  output wire [4:0]   led_bus,
);

wire          lb_wr;
wire          lb_rd;
wire [31:0]   lb_addr;
wire [31:0]   lb_wr_d;
wire [31:0]   lb_rd_d;
wire          lb_rd_rdy;

wire          clk_pll_out;
wire          clk_cap_tree;
wire          clk_lb_tree;
wire          reset_core;
wire          pll_lock;

wire          mesa_wi_loc;
wire          mesa_wo_loc;
wire          mesa_ri_loc;
wire          mesa_ro_loc;

wire          mesa_wi_nib_en;
wire [3:0]    mesa_wi_nib_d;
wire          mesa_wo_byte_en;
wire [7:0]    mesa_wo_byte_d;
wire          mesa_wo_busy;
wire          mesa_ro_byte_en;
wire [7:0]    mesa_ro_byte_d;
wire          mesa_ro_busy;
wire          mesa_ro_done;
wire [7:0]    mesa_core_ro_byte_d;
wire          mesa_core_ro_byte_en;
wire          mesa_core_ro_done;
wire          mesa_core_ro_busy;

wire          mesa_wi_baudlock;

assign led_bus[4] = 1'b1;

assign reset_core = 0;
//assign reset_core = ~pll_lock;  // Requires more resources.

assign mesa_wi_loc = uart_wi;
assign uart_ro     = mesa_ro_loc;



//top_pll u_top_pll
//(
//  .REFERENCECLK ( clk_in      ),
//  .PLLOUTCORE   (             ),
//  .PLLOUTGLOBAL ( clk_pll_out ),
//  .LOCK         ( pll_lock    ),
//  .RESET        ( 1'b1        )
//);
//
//SB_GB u1_sb_gb 
//(
//  .USER_SIGNAL_TO_GLOBAL_BUFFER ( clk_pll_out  ),
//  .GLOBAL_BUFFER_OUTPUT         ( clk_cap_tree )
//);
assign clk_cap_tree = clk_in;

// Toggle Flop To generate slower local bus clock.
reg [7:0] test_cnt;
reg       ck_togl;
always @ ( posedge clk_cap_tree ) begin : proc_div
 begin
   test_cnt <= test_cnt[7:0] + 1;
   ck_togl  <= test_cnt[1];// clk_cap_tree / 4
 end
end // proc_div

SB_GB u0_sb_gb 
(
  .USER_SIGNAL_TO_GLOBAL_BUFFER ( ck_togl      ),
  .GLOBAL_BUFFER_OUTPUT         ( clk_lb_tree  )
);





assign mesa_ro_byte_d[7:0] = mesa_core_ro_byte_d[7:0];
assign mesa_ro_byte_en     = mesa_core_ro_byte_en;
assign mesa_ro_done        = mesa_core_ro_done;
assign mesa_core_ro_busy   = mesa_ro_busy;


//-----------------------------------------------------------------------------
// MesaBus Phy : Convert UART serial to/from binary for Mesa Bus Interface
//  This translates between bits and bytes
//-----------------------------------------------------------------------------
mesa_phy u_mesa_phy
(
  .reset            ( reset_core          ),
  .clk              ( clk_lb_tree         ),
  .clr_baudlock     ( 1'b0                ),
  .disable_chain    ( 1'b1                ),
  .mesa_wi_baudlock ( mesa_wi_baudlock    ),
  .mesa_wi          ( mesa_wi_loc         ),
  .mesa_ro          ( mesa_ro_loc         ),
  .mesa_wo          ( mesa_wo_loc         ),
  .mesa_ri          ( mesa_ri_loc         ),
  .mesa_wi_nib_en   ( mesa_wi_nib_en      ),
  .mesa_wi_nib_d    ( mesa_wi_nib_d[3:0]  ),
  .mesa_wo_byte_en  ( mesa_wo_byte_en     ),
  .mesa_wo_byte_d   ( mesa_wo_byte_d[7:0] ),
  .mesa_wo_busy     ( mesa_wo_busy        ),
  .mesa_ro_byte_en  ( mesa_ro_byte_en     ),
  .mesa_ro_byte_d   ( mesa_ro_byte_d[7:0] ),
  .mesa_ro_busy     ( mesa_ro_busy        ),
  .mesa_ro_done     ( mesa_ro_done        )
);// module mesa_phy


//-----------------------------------------------------------------------------
// MesaBus Core : Decode Slot,Subslot,Command Info and translate to LocalBus
//-----------------------------------------------------------------------------
mesa_core 
#
(
  .spi_prom_en       ( 1'b0                       )
)
u_mesa_core
(
//.reset               ( reset_core               ),
  .reset               ( ~mesa_wi_baudlock        ),
  .clk                 ( clk_lb_tree              ),
  //.spi_sck             ( spi_sck                  ),
  //.spi_cs_l            ( spi_cs_l                 ),
  //.spi_mosi            ( spi_mosi                 ),
  //.spi_miso            ( spi_miso                 ),
  .rx_in_d             ( mesa_wi_nib_d[3:0]       ),
  .rx_in_rdy           ( mesa_wi_nib_en           ),
  .tx_byte_d           ( mesa_core_ro_byte_d[7:0] ),
  .tx_byte_rdy         ( mesa_core_ro_byte_en     ),
  .tx_done             ( mesa_core_ro_done        ),
  .tx_busy             ( mesa_core_ro_busy        ),
  .tx_wo_byte          ( mesa_wo_byte_d[7:0]      ),
  .tx_wo_rdy           ( mesa_wo_byte_en          ),
  .subslot_ctrl        (                          ),
  .bist_req            (                          ),
  .reconfig_req        (                          ),
  .reconfig_addr       (                          ),
  .oob_en              ( 1'b0                     ),
  .oob_done            ( 1'b0                     ),
  .lb_wr               ( lb_wr                    ),
  .lb_rd               ( lb_rd                    ),
  .lb_wr_d             ( lb_wr_d[31:0]            ),
  .lb_addr             ( lb_addr[31:0]            ),
  .lb_rd_d             ( lb_rd_d[31:0]            ),
  .lb_rd_rdy           ( lb_rd_rdy                )
);// module mesa_core


//-----------------------------------------------------------------------------
// Design Specific Logic
//-----------------------------------------------------------------------------
core u_core 
(
//.reset               ( reset_core               ),
  .reset               ( ~mesa_wi_baudlock        ),
  .clk_lb              ( clk_lb_tree              ),
  .clk_cap             ( clk_cap_tree             ),
  .lb_wr               ( lb_wr                    ),
  .lb_rd               ( lb_rd                    ),
  .lb_wr_d             ( lb_wr_d[31:0]            ),
  .lb_addr             ( lb_addr[31:0]            ),
  .lb_rd_d             ( lb_rd_d[31:0]            ),
  .lb_rd_rdy           ( lb_rd_rdy                ),
  .led_bus             ( led_bus[3:0]             ),
  .events_din          ( events_din[15:0]         )
);  


endmodule
