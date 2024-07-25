`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 16.07.2024 11:26:20
// Design Name: 
// Module Name: mips32
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


module mips32(clk1,clk2);
input wire clk1;
input wire clk2;

reg[31:0] Pc,IF_ID_IR,IF_ID_NPC;
reg[31:0] ID_EX_IR,ID_EX_NPC,ID_EX_A,ID_EX_B,ID_EX_IMM;
reg[2:0] ID_EX_TYPE,EX_MEM_TYPE,MEM_WB_TYPE;
reg[31:0] EX_MEM_IR , EX_MEM_ALUout ,EX_MEM_B;
reg[31:0] MEM_WB_IR,MEM_WB_ALUout,MEM_WB_LMD;
reg ex_mem_condition;
reg[31:0] Reg[0:31];
reg[31:0] Mem[0:1023];
reg halted;
reg taken_branch;
parameter ADD = 6'b000000;
parameter SUB = 6'b000001;
parameter AND = 6'b000010;
parameter OR = 6'b000011;
parameter SLT = 6'b000100;
parameter MUL = 6'b000101;
parameter HLT = 6'b000110;
parameter LD = 6'b000111;
parameter SD = 6'b001000;
parameter ADDI = 6'b001001;
parameter SUBI = 6'b001010;
parameter SLTI = 6'b001011;
parameter BEQZ = 6'b001101;
parameter BNEQZ = 6'b001110;

parameter RR_ALU = 3'b000;
parameter RM_ALU = 3'b001;
parameter LOAD = 3'b010;
parameter STORE = 3'b011;
parameter BRANCH = 3'b100;
parameter hlt = 3'b101;

// IF stage

always @(posedge clk1)begin
     if (halted==0)begin
         if ((EX_MEM_IR[31:26]==BEQZ)&&(ex_mem_condition==1)||(EX_MEM_IR[31:26]==BNEQZ)&& (ex_mem_condition==0))begin
              IF_ID_IR <=Mem[EX_MEM_ALUout];
              taken_branch =1'b1;
              IF_ID_NPC = EX_MEM_ALUout+1;
              Pc = Pc+1;
         end else begin
              IF_ID_IR <= Mem[Pc];
              IF_ID_NPC = Pc+1;
              Pc = Pc+1;
         end
     end
end

// ID stage will start now 
always @(posedge clk2) begin
     if (halted==0) begin
         if (IF_ID_IR[25:21]==0)begin
             ID_EX_A <=0;
         end else begin
             ID_EX_A <= IF_ID_IR[25:21];
         end
         if (IF_ID_IR[20:16]==0) begin
             ID_EX_B <= 0;
         end else begin
             ID_EX_B <= IF_ID_IR[20:16];
         end
     end
     ID_EX_NPC = IF_ID_NPC;
     ID_EX_IR = IF_ID_IR;
     ID_EX_IMM = {{16{IF_ID_IR[15]}}, {IF_ID_IR[15:0]}};
     case (IF_ID_IR[31:26]) 
         ADD ,SUB , AND , OR , SLT , MUL : ID_EX_TYPE <= RR_ALU;
         ADDI , SUBI,SLTI : ID_EX_TYPE <= RM_ALU;
         BEQZ , BNEQZ : ID_EX_TYPE <= BRANCH;
         LD: ID_EX_TYPE <= LOAD;
         SD:ID_EX_TYPE <= STORE;
         HLT : ID_EX_TYPE <= hlt;
         default : ID_EX_TYPE <= hlt;
     endcase
end         
         
// EX stage wil start now
always @(posedge clk1) begin
     if (halted==0) begin
         EX_MEM_TYPE <= ID_EX_TYPE;
         EX_MEM_IR <= ID_EX_IR;
         taken_branch =0;
         case (ID_EX_TYPE)
              RR_ALU: begin
                         case (IF_ID_IR[31:26])
                             ADD : EX_MEM_ALUout <= ID_EX_A + ID_EX_B;
                             SUB : EX_MEM_ALUout <= ID_EX_A - ID_EX_B;
                             AND : EX_MEM_ALUout <= ID_EX_A & ID_EX_B;
                             OR : EX_MEM_ALUout <= ID_EX_A | ID_EX_B;
                             SLT : EX_MEM_ALUout <= ID_EX_A < ID_EX_B;
                             MUL : EX_MEM_ALUout <= ID_EX_A * ID_EX_B;
                             default: EX_MEM_ALUout <= 32'hXXXXXX;
                             
                         endcase
                    end        
              RM_ALU:begin
                         case (IF_ID_IR[31:26])
                             ADDI : EX_MEM_ALUout <= ID_EX_A + ID_EX_IMM;
                             SUBI : EX_MEM_ALUout <= ID_EX_A - ID_EX_IMM;
                             SLTI : EX_MEM_ALUout <= ID_EX_A < ID_EX_IMM;
                             default: EX_MEM_ALUout <= 32'hXXXXX;
                         endcase
                     end    
              LOAD ,STORE : begin
                               EX_MEM_ALUout <= ID_EX_A + ID_EX_IMM;
                               EX_MEM_ALUout <= ID_EX_B;
                            end
                            
                            BRANCH: begin
                                       EX_MEM_ALUout <= ID_EX_NPC + ID_EX_IMM;
                                       ex_mem_condition <= (ID_EX_A==0);
                                    end
         endcase
     end
end
                                       
// MEMORY ACCESS STAGE
always @(posedge clk2) begin
     if (halted==0) begin
         MEM_WB_TYPE <= EX_MEM_TYPE;
         MEM_WB_IR <=   EX_MEM_IR;
         taken_branch = 0;
         case (EX_MEM_TYPE)
              RM_ALU , RR_ALU : MEM_WB_ALUout <= EX_MEM_ALUout;
                         LOAD : MEM_WB_ALUout <= Mem[EX_MEM_ALUout];
                        STORE : if (taken_branch ==0) begin
                                    Mem[EX_MEM_ALUout] <= EX_MEM_B;
                                end
         endcase
     end
end
                                    
always @(posedge clk1) begin
     if (taken_branch==0) begin
         case (MEM_WB_TYPE)
             RR_ALU : Reg[MEM_WB_IR[15:1]] <= MEM_WB_ALUout; //rs
             RM_ALU : Reg[MEM_WB_IR[20:16]] <= MEM_WB_ALUout; //rt
             LOAD   : Reg[MEM_WB_IR[20:16]] <= MEM_WB_LMD; //rt
             hlt   : halted = 1'b1;
         endcase
     end
end
endmodule

               
          
                               
                                              
                                                           
                                          
                             
                                    
                                              
                           
              
         
              
            
         
                   
                         
     
                   

          

