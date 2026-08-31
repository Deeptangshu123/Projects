module seq_detect(
input clock, 
input reset, 
input sequence_in, 
output reg detector_out
); 
parameter  
  s0=3'b000,
  s1=3'b001,
  s2=3'b011,
  s3=3'b010,
  s4=3'b110;
 
reg [2:0] current_state, next_state;

always @(posedge clock, posedge reset)
begin
 if(reset==1) 
 current_state <= s0;
 else
 current_state <= next_state; 
end 
always @(current_state,sequence_in)
begin
 case(current_state) 
 s0:begin
  if(sequence_in==1)
   next_state = s1;
  else
   next_state = s0;
 end
 s1:begin
  if(sequence_in==0)
   next_state = s2;
  else
   next_state = s1;
 end
 s2:begin
  if(sequence_in==0)
   next_state = s0;
  else
   next_state = s3;
 end 
 s3:begin
  if(sequence_in==0)
   next_state = s2;
  else
   next_state = s4;
 end
 s4:begin
  if(sequence_in==0)
   next_state = s2;
  else
   next_state = s1;
 end
 default:next_state = s0;
 endcase
end

always @(current_state)
begin 
 case(current_state) 
 s0:  detector_out = 0;
 s1:  detector_out = 0;
 s2:  detector_out = 0;
 s3:  detector_out = 0;
 s4:  detector_out = 1;
 default:  detector_out = 0;
 endcase
end 
endmodule
