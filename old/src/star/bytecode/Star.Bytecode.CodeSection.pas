unit Star.Bytecode.CodeSection;

interface

uses
	Star.Bytecode.Index,
	Star.Bytecode.Op,
	SysUtils,
	FileUtils;

type
	TCodeSection = class(IBinaryIOWrite)
	public
		ops: TOpArray;

		constructor create;
		constructor create(const ops_: TOpArray);

		constructor read(handle: THandle);
		
		destructor destroy; override;

		procedure writeToBinary(const bf: TBinaryFile);

		function dump: string;
	end;

type
	TCodeSectionArray = array of TCodeSection;

implementation

constructor TCodeSection.create;
begin
	ops := [];
end;

constructor TCodeSection.create(const ops_: TOpArray);
begin
	ops := ops_;
end;


constructor TCodeSection.read(handle: THandle);
var
	len, i: longint;
begin
	fileRead(handle, len, sizeof(len));
	setLength(ops, len);
	for i := 0 to len do ops[i] := readOp(handle);
end;


destructor TCodeSection.destroy;
var
	i: integer;
begin
	for i := low(ops) to high(ops) do disposeOp(ops[i]);
	inherited destroy();
end;


procedure TCodeSection.writeToBinary(const bf: TBinaryFile);
begin
	bf.specialize writeAll<TOp>(ops, @writeOp);
end;


function TCodeSection.dump: string;
const
	sep = string(lineEnding) + #9 + #9 + #9;
var
	op: TOp;
begin
	result := '';

	for op in ops do begin
		result += sep;
		result += dumpOp(op);
	end;
end;

end.