unit StarBytecodeCodeSection;

interface

uses
	StarBytecodeIndex,
	StarBytecodeOp,
	SysUtils;

type
	TCodeSection = class
	public
		ops: TOpArray;

		constructor create;
		constructor create(const ops_: TOpArray);
		constructor read(handle: THandle);
		destructor destroy; override;

		procedure write(handle: THandle);
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

procedure TCodeSection.write(handle: THandle);
var
	len: longint;
	op: TOp;
begin
	len := length(ops);
	fileWrite(handle, len, sizeof(len));
	for op in ops do writeOp(handle, op);
end;

end.