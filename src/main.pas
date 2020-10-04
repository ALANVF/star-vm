program star_pas_test;

{ $modeswitch TYPEHELPERS}
{ $SCOPEDENUMS+}

uses
	StringUtils,
	FileUtils,
	Star,
	StarBytecodeOp,
	StarBytecodeOpcode,
	StarBytecodeMember;

type
	TBuf = array[0..sizeof(TOp)] of byte;
	PBuf = ^TBuf;
	TArrOfInt = array of integer;
	P_ArrOfInt = array[0..(3 * sizeof(integer))] of byte;
	PArrOfInt = ^P_ArrOfInt;

var
	op: TOp;
	s: string;
	b: byte;
	a: TArrOfInt;

begin
	{writeln(sizeof(Star.TStarType));
	writeln('yay!');
	writeln(StringUtils.hash('yay!'));}

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
	
	{a := [5,10,15,20];
	for b in (PArrOfInt(a) - word(1))^ do writeln(b);}
end.