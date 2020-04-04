module branchctlunit (regData1, branchCtl, branch);
	// TODO: Need Optimization.
	input	[15:0]	regData1;
	input	[3:0]	branchCtl;
	output	reg		branch;
	always @(*) begin
		case (branchCtl)
			3'b000: branch <= 0;
			3'b001: branch <= 0;
			3'b010: branch <= 0;
			3'b011: branch <= 0;
			3'b100: branch <= (regData1 == 16'h0000)? 1:0;
			3'b101: branch <= (regData1 == 16'h0000)? 0:1;
			3'b110: branch <= regData1[15]? 1:0;
			3'b111: branch <= regData1[15]? 0:1;
		endcase // sel
	end
endmodule