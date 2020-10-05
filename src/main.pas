program star_vm_test;

uses
	StringUtils,
	FileUtils,
	Star,
	StarBytecode,
	StarBytecodeCodeSection,
	StarBytecodeOp,
	StarBytecodeOpcode,
	StarBytecodeMember;

type
	TBuf = array[0..sizeof(TOp)] of byte;
	PBuf = ^TBuf;

var
	op: TOp;
	s: string;
	b: byte;

begin
	with op do begin
		opcode := TOpcode.pushConst;
		pushConst := 5;
	end;
	
	for b in PBuf(@op)^ do writeln(b);
	
	writeln(sizeof(op):10, sizeof(TOp):10);
	writeln(op.opcode, ' ', op.pushConst);
	s := '';
	str(op.opcode, s);
	writeln(s);
	writeln(dumpOp(op));
end.