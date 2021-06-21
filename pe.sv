`timescale 1ns/100ps
import SystemVerilogCSP::*;

module mem(interface datain, interface addrin, interface dataout, interface addrout);

	parameter WIDTH = 8, DP = 5, ADDR_WIDTH = 3, FL = 4, BL = 2;

	logic [ADDR_WIDTH-1:0] addr_in;
	logic [ADDR_WIDTH-1:0] addr_out;

	logic [WIDTH-1:0] data_in;
	logic [WIDTH-1:0] data_out;
	reg [WIDTH-1:0]mem[DP - 1 : 0];

	integer i;
	initial begin
	    for(i=0; i < DP; i = i + 1) begin
	        mem[i] = 8'h00;
	    end
	end

    always begin
        fork
        	datain.Receive(data_in);
        	addrin.Receive(addr_in);
        join
        # FL;
        mem[addr_in] = data_in;
    end
  
    always begin
        addrout.Receive(addr_out);
        # FL;
        dataout.Send(mem[addr_out]);
        # BL;
    end
endmodule

module multipler
	#(parameter BL = 2,
	  parameter FL = 4,
	  parameter WIDTH = 8)

	( interface input1,
	  interface input2,
	  interface output_data);

    logic [WIDTH-1:0] data1;
    logic [WIDTH-1:0] data2;

    always begin
    	fork 
    		input1.Receive(data1);
    		input2.Receive(data2);
    	join
    	# FL;
    	output_data.Send(data1 * data2);
	    # BL;
    end
endmodule

module adder
	#(parameter BL = 2,
	  parameter FL = 4,
	  parameter WIDTH = 8)

	( interface inputFromMul,
	  interface inputFromAc,
	  interface inputFromPsum,
	  interface control,
	  interface output_data);

    logic [WIDTH-1:0] data1;
    logic [WIDTH-1:0] data2;
    logic [WIDTH-1:0] data3 = 8'b00000000;
    logic [WIDTH-1:0] contralData;

    always begin
    	fork
            control.Receive(contralData);
        	inputFromMul.Receive(data1);
	        inputFromAc.Receive(data2);
	        inputFromPsum.Receive(data3);
        join
    	# FL;
    	if(contralData == 1) begin
	    	output_data.Send(data1 + data2);
        end
        else begin
	    	output_data.Send(data3 + data2);
        end        	
	    # BL;
    end
endmodule

module split
	#(parameter BL = 2,
	  parameter FL = 4,
	  parameter WIDTH = 8)

	( interface inputFromAd,
	  interface control,
	  interface outputToPsm,
	  interface outputToAc);

    logic [WIDTH-1:0] data1;
    logic [WIDTH-1:0] contralData;

    always begin
    	fork 
    		inputFromAd.Receive(data1);
            control.Receive(contralData);
    	join
    	# FL;
    	if(contralData == 0) begin
	    	outputToAc.Send(data1);
        end
        else begin
	    	outputToPsm.Send(data1);
	    	outputToAc.Send(data1);
	    	$display("current result is %d", data1);
        end        	
	    # BL;
    end
endmodule

module accumulator
	#(parameter BL = 2,
	  parameter FL = 4,
	  parameter WIDTH = 8)

	( interface inputFromSp,
	  interface control,
	  interface outputToAd);

    logic [WIDTH-1:0] data1;
    logic [WIDTH-1:0] contralData;
    logic [WIDTH-1:0] data2 = 8'b00000000;

    always begin
    	control.Receive(contralData);
    	# FL;
    	if(contralData == 0) begin
    		fork
	            inputFromSp.Receive(data1);
		    	outputToAd.Send(data2);
	        join
	        data2 = data1;
        end
        else begin
	    	data2 = 8'b00000000;
        end        	
	    # BL;
    end
endmodule

module control
	#(parameter BL = 2,
	  parameter FL = 4,
	  parameter WIDTH = 8)

	( interface filteraddr,
	  interface ifmapaddr,
	  interface add_sel,
	  interface acc_clear,
	  interface split_sel,
	  interface start,
	  interface done );

    int i, j;
    logic [WIDTH-1:0] flag = 8'b00000001;
    logic [WIDTH-1:0] high = 8'b00000001;
    logic [WIDTH-1:0] low =  8'b00000000;

    always begin
    	wait(flag == 0);
	    for(i = 0; i < 3; i = i + 1) 
	    begin
			acc_clear.Send(high); 
            for(j = 0; j < 3; j = j + 1) 
            begin
            	fork
	                split_sel.Send(low);
	                add_sel.Send(high);
	                filteraddr.Send(j);
	                ifmapaddr.Send(i + j);
	                acc_clear.Send(low);  
	            join
	            #BL;
            end
            fork
               filteraddr.Send(0);
	           ifmapaddr.Send(0);
	           acc_clear.Send(low);
	           add_sel.Send(low);
	           split_sel.Send(high); 
            join
	    end
	    flag = 1;
	    done.Send(high);
    end

    always begin
        start.Receive(flag);
        # 2;
    end

    initial begin
      i = 0;
      j = 0;
    end
endmodule

module pe(interface filter_in, filter_addr, ifmap_in, ifmap_addr, psum_in, start, done, psum_out);

 parameter WIDTH = 8;
 parameter DEPTH_I = 5;
 parameter ADDR_I = 3; 
 parameter DEPTH_F = 3;
 parameter ADDR_F = 2;

 Channel #(.hsProtocol(P4PhaseBD), .WIDTH(10)) memToMult [2:0] (); 
 Channel #(.hsProtocol(P4PhaseBD), .WIDTH(10)) MultToAdd [2:0] (); 
 Channel #(.hsProtocol(P4PhaseBD), .WIDTH(10)) AcToAdd [2:0] ();
 Channel #(.hsProtocol(P4PhaseBD), .WIDTH(10)) SplitToAc [2:0] ();  
 Channel #(.hsProtocol(P4PhaseBD), .WIDTH(10)) ControlToAdd [2:0] (); 
 Channel #(.hsProtocol(P4PhaseBD), .WIDTH(10)) ControlToSp [2:0] (); 
 Channel #(.hsProtocol(P4PhaseBD), .WIDTH(10)) ControlToAc [2:0] ();
 Channel #(.hsProtocol(P4PhaseBD), .WIDTH(10)) ControlToFilter [2:0] ();
 Channel #(.hsProtocol(P4PhaseBD), .WIDTH(10)) ControlToMapper [2:0] (); 
 Channel #(.hsProtocol(P4PhaseBD), .WIDTH(10)) AddToSplit [2:0] (); 

 mem  #(.WIDTH(WIDTH), .DP(DEPTH_F), .ADDR_WIDTH(ADDR_F), .FL(4), .BL(2))
 filterMemory(.datain (filter_in), .addrin (filter_addr), .dataout(memToMult[0]), .addrout(ControlToFilter[0]));

 mem  #(.WIDTH(WIDTH), .DP(DEPTH_I), .ADDR_WIDTH(ADDR_I), .FL(4), .BL(2))
 ifmapMemory(.datain (ifmap_in), .addrin (ifmap_addr), .dataout(memToMult[1]), .addrout(ControlToMapper[0]));

 multipler #(.WIDTH(WIDTH), .FL(4), .BL(2))
 mp(.input1(memToMult[0]), .input2(memToMult[1]), .output_data(MultToAdd[0]));

 adder #(.WIDTH(WIDTH), .FL(4), .BL(2))
 ad(.inputFromMul (MultToAdd[0]), .inputFromAc  (AcToAdd[0]), .inputFromPsum(psum_in), .control (ControlToAdd[0]), .output_data (AddToSplit[0]));

 split #(.WIDTH(WIDTH), .FL(4), .BL(2))
 sp(.inputFromAd(AddToSplit[0]), .control (ControlToSp[0]), .outputToPsm(psum_out), .outputToAc (SplitToAc[0]));

 accumulator #(.WIDTH(WIDTH), .FL(4), .BL(2))
 ac(.inputFromSp(SplitToAc[0]), .control (ControlToAc[0]), .outputToAd (AcToAdd[0]));

 control #(.WIDTH(WIDTH), .FL(4), .BL(2))
 cl(.filteraddr(ControlToFilter[0]), .ifmapaddr (ControlToMapper[0]), .add_sel (ControlToAdd[0]), .acc_clear (ControlToAc[0]), .split_sel (ControlToSp[0]), .start (start), .done (done));
endmodule