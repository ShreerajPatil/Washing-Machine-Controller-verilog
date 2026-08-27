**Code**
```
module code( 
  input  wire clk, 
  input  wire rst_n,     // System Clock Input 
  input  wire start,     // User command to start the wash cycle 
  input  wire stop,      // User command for emergency stop (Forces transition to IDLE) 
 
  // Stage "done" qualifiers (Inputs from external Timers/Counters) 
  input  wire t_soak,    // SOAK time completed signal 
  input  wire t_wash,    // WASH time completed signal 
  input  wire t_drain,   // DRAIN condition valid (water level low enough) 
  input  wire t_rinse,   // RINSE water level/condition met 
  input  wire t_spin,    // SPIN time/condition met (controls spin phase length) 
 
  // One-hot style state outputs (Control signals for washing machine actuators) 
  output reg  idle,      // Machine is idle (ready or finished) 
  output reg  soak,      // Machine is soaking/filling 
  output reg  wash,      // Machine is washing/agitating 
  output reg  drain,     // Drain pump is active 
  output reg  rinse,     // Machine is rinsing/filling for rinse 
  output reg  spin       // Motor is running high speed for spinning 
); 
 
  // --- State Encoding Definitions --- 
  // Using 3-bit binary encoding for the internal state register 
  localparam IDLE_S  = 3'b000; // State 0: Machine is off/waiting 
  localparam SOAK_S  = 3'b001; // State 1: Soaking phase 
  localparam WASH_S  = 3'b010; // State 2: Washing phase 
  localparam DRAIN_S = 3'b011; // State 3: Draining phase 
  localparam RINSE_S = 3'b100; // State 4: Rinsing phase 
  localparam SPIN_S  = 3'b101; // State 5: Spinning phase 
   // Internal state registers 
  reg [2:0] cs; // Current State 
  reg [2:0] ns; // Next State 
 
  // --- Combinational Logic Block (Determines Next State and Outputs) --- 
  // This is a synchronous FSM implemented with a single always @* block for 
combinational logic 
    // Default assignment: Assume state remains the same (ns = cs) and all outputs are 
OFF (Mealy FSM behavior) 
    ns    = cs; 
    idle  = 1'b0; 
    soak  = 1'b0; 
    wash  = 1'b0; 
    drain = 1'b0; 
    rinse = 1'b0; 
    spin  = 1'b0; 
 
    case (cs) 
      IDLE_S: begin 
        idle = 1'b1; // Output: IDLE is active 
        // Transition: If start is pressed and stop is not asserted, move to SOAK 
        if (start && !stop) begin 
          ns   = SOAK_S; 
          soak = 1'b1; // Output: SOAK becomes active immediately (Mealy-like output) 
        end 
      end 
 
      SOAK_S: begin 
        if (stop) begin // Priority: Emergency stop returns to IDLE 
          ns   = IDLE_S; 
          idle = 1'b1; 
        end else if (t_soak) begin // Transition: SOAK time is done, move to WASH 
          ns   = WASH_S; 
          wash = 1'b1; 
        end else begin 
          soak = 1'b1; // Output: Stay in SOAK 
        end 
      end 
 
      WASH_S: begin 
        if (stop) begin // Priority: Emergency stop returns to IDLE
            ns   = IDLE_S; 
          idle = 1'b1; 
        end else if (t_wash) begin // Transition: WASH time is done, move to DRAIN 
          ns    = DRAIN_S; 
          drain = 1'b1; 
        end else begin 
          wash = 1'b1; // Output: Stay in WASH 
        end 
      end 
 
      DRAIN_S: begin 
        if (stop) begin // Priority: Emergency stop returns to IDLE 
          ns   = IDLE_S; 
          idle = 1'b1; 
        end else if (t_drain && t_rinse) begin // Transition: DRAIN condition met (t_drain) 
AND RINSE condition met (t_rinse), move to RINSE 
          ns    = RINSE_S; 
          rinse = 1'b1; 
          // Note: Keeping drain active during rinse may be needed for continuous draining 
          drain = 1'b1; 
        end else begin 
          drain = 1'b1; // Output: Stay in DRAIN 
        end 
      end 
 
      RINSE_S: begin 
        if (stop) begin // Priority: Emergency stop returns to IDLE 
          ns   = IDLE_S; 
          idle = 1'b1; 
        end else if (t_spin && t_drain && !t_rinse) begin // Transition: SPIN condition met 
(t_spin) AND still draining (t_drain) AND RINSE is done (!t_rinse), move to SPIN 
          ns   = SPIN_S; 
          spin = 1'b1; 
        end else begin 
          rinse = 1'b1; // Output: Stay in RINSE 
          drain = 1'b1; // Output: Keep draining during rinse 
        end 
      end 
 
      SPIN_S: begin 
        if (stop) begin // Priority: Emergency stop returns to IDLE
           ns   = IDLE_S; 
          idle = 1'b1; 
        end else if (!t_spin && !t_drain && !t_rinse) begin // Transition: Cycle finished (all 
timer/drain flags clear), move to IDLE 
          ns   = IDLE_S; 
          idle = 1'b1; 
        end else begin 
          spin = 1'b1; // Output: Stay in SPIN 
        end 
      end 
 
      default: begin 
        // Safety: If an illegal state is reached, force transition to IDLE 
        ns   = IDLE_S; 
        idle = 1'b1; 
      end 
    endcase 
  end 
 
  // --- Sequential Logic Block (State Register Update) --- 
  // Synchronous state update on the positive edge of the clock (posedge clk) 
  // Asynchronous reset on the positive edge of rst_n (posedge rst_n) 
  always @(posedge clk or posedge rst_n) begin 
    // NOTE: The description says "active-low reset" but the logic implements "active-high 
reset" (`if (rst_n)`). 
    // Assuming the intent is the implemented logic: Active-HIGH asynchronous reset 
    if (rst_n)             // If reset is asserted (rst_n = 1) 
      cs <= IDLE_S;        // Asynchronously set current state to IDLE 
    else 
      cs <= ns;            // Otherwise, update current state with next state on clock edge 
  end 
 
endmodule
```
