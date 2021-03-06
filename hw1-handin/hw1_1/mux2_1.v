   /*
    CS/ECE 552 Spring '20
    Homework #1, Problem 1

    2-1 mux template
*/
module mux2_1(InA, InB, S, Out);
	input   InA, InB;
	input   S;
	output  Out;
	
	// Use only NAND, NOR and NOT
    // YOUR CODE HERE
	 
	wire Not_S, Nand_A, Nand_B;
	not1 not_1(.in1(S), .out(Not_S));
	nand2 nand2_1(.in1(InA), .in2(Not_S), .out(Nand_A));
	nand2 nand2_2(.in1(S), .in2(InB), .out(Nand_B));
	nand2 nand2_3(.in1(Nand_A), .in2(Nand_B), .out(Out));

	
endmodule
