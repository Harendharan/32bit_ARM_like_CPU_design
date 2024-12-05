
`include "top.v"

module testbench();
	reg clk=1;
	reg reset;

top dut(clk, reset);
  

initial begin
	reset <= 1; 
  	#10;
    reset <= 0;
end
  
  
// Clock
always #5 clk=~clk;

initial begin 
#10000
  if (dut.cpu.dp.rf.rf[5] === 32'd11) begin
     $display("Test Passed: R5 contains 11");
  end
  else $display("Test Failed: R5 = %d, expected 7",dut.cpu.dp.rf.rf[5]);
       
$finish;
end
 
  
endmodule
