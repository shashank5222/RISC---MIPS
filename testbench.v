`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 16.07.2024 14:10:51
// Design Name: 
// Module Name: testbench
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module testbench();
reg clk1;
reg clk2;
integer k;

mips32 dut(.clk1(clk1),.clk2(clk2));
initial begin 
      clk1=0;
      clk2=0;
      repeat(100) begin
                #5;
                clk1=1;
                clk2=1;
                #5;
                clk1=0;
                clk2=0;
      end
end                
initial begin
      for (k=0;k<32;k=k+1) begin
           dut.Reg[k]=k;
      end     
      dut.Mem[0] <=32'h2801000a; //ADDI R1,R0,data
      dut.Mem[1] <= 32'h28020014; //ADDI r2,r0,data
      dut.Mem[2] <= 32'h28030019;  //ADDI r3 , r0 ,data
      dut.Mem[3] <= 32'h0ce77800;  //dummy code
      dut.Mem[4] <= 32'h0ce77800; //dummy code
      dut.Mem[5] <= 32'h120012cc;//ADD
      dut.Mem[6] <= 32'h0ce77800;//dumy instr
      dut.Mem[7] <= 32'hcceeabc0;//ADD
      dut.Mem[8] <= 32'hfc000000;//hlt
      
      dut.halted =0;
      dut.taken_branch=0;
      dut.Pc=0;
      #280;
      for (k=0;k<6;k=k+1) begin
      $display ("R%1d-%2d" , k ,dut.Reg[k]);
      end
end
initial begin
      $dumpfile("mips32.vcd");
      $dumpvars(0,testbench);
end            
      
           
      
      
           
           
endmodule
