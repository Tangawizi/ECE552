/* $Author: karu $ */
/* $LastChangedDate: 2009-04-24 09:28:13 -0500 (Fri, 24 Apr 2009) $ */
/* $Rev: 77 $ */

module mem_system(/*AUTOARG*/
   // Outputs
   DataOut, Done, Stall, CacheHit, err,
   // Inputs
   Addr, DataIn, Rd, Wr, createdump, clk, rst
   );
   
   input [15:0] Addr;
   input [15:0] DataIn;
   input        Rd;
   input        Wr;
   input        createdump;
   input        clk;
   input        rst;
   
   output [15:0] DataOut;
   output Done;
   output Stall;
   output CacheHit;
   output err;


   wire   [15:0]  mem_data, mem_data_out;
   wire   [4:0] tag, tag_out;
   wire   [10:3]  index;
   wire   [2:0] offset;
   reg    [15:0]  mem_addr;
   reg   [2:0] state, next_state;
   reg   cache_compare, cache_write,  memory_read, memory_write, cache_done, cache_en, input_reg, cache_status_en, sys_stall;
   wire   [2:0] mystate, mystate_n;

   reg   [3:0] mem_read_cout;
   wire   [3:0] mem_read_cout_add, mem_read_count_in;
   assign mem_read_cout_in = mem_read_cout;
   cla_4b mem_read_counter(.A(mem_read_cout_in), .B(4'h1), .C_in(0), .S(mem_read_cout_add), .P(), .G(), .C_out());
   wire   valid, dirty, cache_hit, stall, c0_err, c1_err, mem_err, mem_busy, mem_stall, mem_data_available, complete;
   wire   write, read, cache_hit_signal;


   /* data_mem = 1, inst_mem = 0 *
    * needed for cache parameter */
   parameter memtype = 0;
   cache #(0 + memtype) c0(// Outputs
                          .tag_out              (),
                          .data_out             (DataOut),
                          .hit                  (cache_hit),
                          .dirty                (dirty),
                          .valid                (valid),
                          .err                  (err),
                          // Inputs
                          .enable               (cache_en),
                          .clk                  (clk),
                          .rst                  (rst),
                          .createdump           (createdump),
                          .tag_in               (tag),
                          .index                (index),
                          .offset               (offset),
                          .data_in              ((cache_write & ~cache_compare)?mem_data:DataIn),
                          .comp                 (cache_compare),
                          .write                (cache_write),
                          .valid_in             (1'b1));

   four_bank_mem mem(// Outputs
                     .data_out          (mem_data),
                     .stall             (mem_stall),
                     .busy              (mem_busy),
                     .err               (err),
                     // Inputs
                     .clk               (clk),
                     .rst               (rst),
                     .createdump        (createdump),
                     .addr              (Addr),
                     .data_in           (DataIn),
                     .wr                (memory_write),
                     .rd                (memory_read));

   
   // your code here

   
  parameter  COMP_READ = 3'b000, MEM_READ = 3'b001, MEM_READ_STALL = 3'b010, ACCESS_WRITE = 3'b011, COMP_WRITE = 3'b100, MEM_WRITE = 3'b101, MEM_WRITE_STALL = 3'b110;
   assign tag = Addr[15:11];
   assign index = Addr[10:3];
   assign offset = Addr[2:0];
   //assign mystate = state;
   assign mystate_n = next_state;
   assign CacheHit = cache_hit;
   assign Stall = sys_stall;
   assign Done = cache_done;
   assign complete = (mem_read_cout == 4'h3)?1:0;
   reg1 write_reg(.clk(clk), .rst(rst), .en(input_reg), .D(Wr), .Q(write));
   reg1 read_reg(.clk(clk), .rst(rst), .en(input_reg), .D(Rd), .Q(read));
   reg1 cachehitreg(.clk(clk), .rst(rst), .en(cache_status_en), .D(cache_hit), .Q(cache_hit_signal));
   reg3 state_reg(.clk(clk), .rst(rst), .en(1'b1), .D(mystate_n), .Q(mystate));
   reg16 mem_data_reg(.clk(clk), .rst(rst), .en(mem_data_available), .D(mem_data), .Q(mem_data_out));
   always @(*) begin
    state = mystate; 
    cache_compare = 0;
    cache_write = 0;
    memory_read = 0;
    memory_write = 0;
    cache_status_en = 0;
    cache_en = 0;
    mem_addr = Addr;
    sys_stall = 1;
    input_reg = 0;
    case(state)
      COMP_READ: begin 
        cache_en = Rd;
        cache_compare = 1;
        cache_write = 0;
        next_state = ((Rd&~cache_hit)|(Rd&cache_hit&~valid))? MEM_READ : Wr? COMP_WRITE : COMP_READ;
        cache_done = (Rd&cache_hit&valid)? 1:0;
        mem_read_cout = 4'h0;
        cache_status_en = 1;
        sys_stall = 0;
        input_reg = 1;
      end
      MEM_READ: begin 
        mem_addr = {Addr[15:2], mem_read_cout[1:0]};
        memory_read = 1;
        next_state = MEM_READ_STALL;
      end
      MEM_READ_STALL: begin
        next_state = mem_stall? MEM_READ_STALL : ACCESS_WRITE;
      end
      ACCESS_WRITE: begin 
        cache_en = 1;
        cache_write = 1;
        mem_read_cout = mem_read_cout_add;
        cache_done = 1;
        next_state = (complete | (write&cache_hit_signal))?COMP_READ:MEM_READ;
      end
      COMP_WRITE: begin 
        cache_en = 1;
        cache_write = 1;
        cache_compare = 1;
        next_state = MEM_WRITE;
        cache_status_en = 1;
      end
      MEM_WRITE: begin 
        memory_write = 1;
        next_state = MEM_WRITE_STALL;
      end
      MEM_WRITE_STALL: begin 
        next_state = mem_stall? MEM_WRITE_STALL : (write&cache_hit_signal)?ACCESS_WRITE:MEM_READ;
        //cache_done = 1;
      end
      default: next_state = COMP_READ;
    endcase // state
  end
   
endmodule // mem_system

// DUMMY LINE FOR REV CONTROL :9:
