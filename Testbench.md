**Code**
```
module test ; 
 
  // DUT inputs 
  reg  clk; 
  reg  rst_n;         // ACTIVE-HIGH async reset (1 = reset) - name kept as rst_n for 
compatibility 
  reg  stop; 
  reg  t_soak; 
  reg  t_wash; 
  reg  t_drain; 
  reg  t_rinse; 
  reg  t_spin; 
 
  // DUT outputs 
  wire idle; 
  wire soak; 
  wire wash; 
  wire drain; 
  wire rinse; 
  wire spin; 
 
  // Instantiate DUT 
  code dut ( 
    .clk   (clk), 
    .rst_n (rst_n),     // ACTIVE-HIGH: 1 = reset, 0 = run 
    .start (start), 
    .stop  (stop), 
    .t_soak(t_soak), 
    .t_wash(t_wash), 
    .t_drain(t_drain), 
    .t_rinse(t_rinse), 
    .t_spin(t_spin), 
    .idle  (idle), 
    .soak  (soak), 
    .wash  (wash), 
    .drain (drain), 
    .rinse (rinse), 
    .spin  (spin) 
  ); 

 
 
  // 50 MHz clock: 20 ns period 
  initial clk = 1'b0; 
  always  #10 clk = ~clk; 
 
  // Helper: clear all timer qualifiers 
  task clear_timers; 
    begin 
      t_soak  = 1'b0; 
      t_wash  = 1'b0; 
      t_drain = 1'b0; 
      t_rinse = 1'b0; 
      t_spin  = 1'b0; 
    end 
  endtask 
 
  // Simple waveform dump (optional) 
  initial begin 
    $dumpfile("wm_tb.vcd"); 
    $dumpvars(0, test); 
  end 
 
  // Stimulus 
  initial begin 
    // Defaults 
    start = 1'b0; 
    stop  = 1'b0; 
    clear_timers(); 
 
    // Apply ACTIVE-HIGH async reset 
    rst_n = 1'b1;                 // assert reset 
    @(posedge clk);               // move away from time 0 
    @(negedge clk);               // avoid releasing on posedge 
    rst_n = 1'b0;                 // release reset 
 
    // Start cycle: go to SOAK 
    @(negedge clk); 
    start = 1'b1; 
    @(posedge clk); // expect SOAK active 
 
    // SOAK -> WASH: assert t_soak for one cycle 

 
    @(negedge clk); 
    t_soak = 1'b1; 
    @(posedge clk); // transition to WASH 
    @(negedge clk); 
    t_soak = 1'b0;  // deassert after transition 
 
    // WASH -> DRAIN: assert t_wash for one cycle 
    @(negedge clk); 
    t_wash = 1'b1; 
    @(posedge clk); // transition to DRAIN 
    @(negedge clk); 
    t_wash = 1'b0; 
 
    // DRAIN -> RINSE: assert t_drain and t_rinse together 
    @(negedge clk); 
    t_drain = 1'b1; 
    t_rinse = 1'b1; 
    @(posedge clk); // transition to RINSE 
    @(negedge clk); 
    // Keep draining during rinse if DUT expects that; keep t_drain = 1 
    t_rinse = 1'b0; // prepare for RINSE -> SPIN per DUT rule 
 
    // RINSE -> SPIN: assert t_spin while t_drain=1 and t_rinse=0 
    @(negedge clk); 
    t_spin = 1'b1; 
    @(posedge clk); // transition to SPIN 
 
    // SPIN -> IDLE: deassert all 
    @(negedge clk); 
    t_spin  = 1'b0; 
    t_drain = 1'b0; 
    clear_timers(); 
    @(posedge clk); // transition to IDLE 
 
    // Test stop behavior: re-enter SOAK then stop -> IDLE 
    @(negedge clk); 
    start = 1'b1; 
    @(posedge clk); // to SOAK 
    @(negedge clk); 
    stop = 1'b1; 
    @(posedge clk); // to IDLE 
@(negedge clk); 
stop = 1'b0; 
// Finish 
#100; 
$finish; 
end 
endmodule
```
