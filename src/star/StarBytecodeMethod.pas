unit StarBytecodeMethod;

{$SCOPEDENUMS+}
{$MINENUMSIZE 1}

interface

uses
	StarBytecodeIndex,
	StarBytecodeOp,
	StarBytecodeCodeSection,
	SysUtils;

type
	// add attrs later

	TMethod = class
	public
		typeParams, paramTypes: TTypeIndexArray;
		returnType: TTypeIndex;
		registers: TTypeIndexArray;
		sections: TCodeSectionArray;

		constructor create(typeParams_, paramTypes_: TTypeIndexArray; returnType_: TTypeIndex; registers_: TTypeIndexArray; sections_: TCodeSectionArray);
		
		constructor read(handle: THandle);

		destructor destroy; override;
		
		procedure write(handle: THandle);
	end;

type
	TMethodArray = array of TMethod;

procedure readMethodArray(handle: THandle; out arr: TMethodArray); overload;
function readMethodArray(handle: THandle): TMethodArray; overload;

procedure writeMethodArray(handle: THandle; const arr: TMethodArray);

implementation

constructor TMethod.create(typeParams_, paramTypes_: TTypeIndexArray; returnType_: TTypeIndex; registers_: TTypeIndexArray; sections_: TCodeSectionArray);
begin
	typeParams := typeParams_;
	paramTypes := paramTypes_;
	returnType := returnType_;
	registers := registers_;
	sections := sections_;
end;


constructor TMethod.read(handle: THandle);
var
	len, i: longint;
begin
	readTypeIndexArray(handle, typeParams);
	readTypeIndexArray(handle, paramTypes);
	fileRead(handle, returnType, sizeof(returnType));
	readTypeIndexArray(handle, registers);
	fileRead(handle, len, sizeof(len));
	setLength(sections, len);
	for i := 0 to len do
		sections[i] := TCodeSection.read(handle);
end;


destructor TMethod.destroy;
var
	i: integer;
begin
	for i := low(sections) to high(sections) do
		freeAndNil(sections[i]);
	
	inherited destroy();
end;


procedure TMethod.write(handle: THandle);
var
	len: longint;
	sec: TCodeSection;
begin
	writeTypeIndexArray(handle, typeParams);
	writeTypeIndexArray(handle, paramTypes);
	fileWrite(handle, returnType, sizeof(returnType));
	writeTypeIndexArray(handle, registers);
	len := length(sections);
	fileWrite(handle, len, sizeof(len));
	for sec in sections do sec.write(handle);
end;


procedure readMethodArray(handle: THandle; out arr: TMethodArray); overload;
var
	len, i: longint;
begin
	arr := [];
	fileRead(handle, len, sizeof(len));
	setLength(arr, len);
	for i := 0 to len do
		arr[i] := TMethod.read(handle);
end;

function readMethodArray(handle: THandle): TMethodArray; overload;
var
	len, i: longint;
begin
	result := [];
	fileRead(handle, len, sizeof(len));
	setLength(result, len);
	for i := 0 to len do
		result[i] := TMethod.read(handle);
end;


procedure writeMethodArray(handle: THandle; const arr: TMethodArray);
var
	len: longint;
	method: TMethod;
begin
	len := length(arr);
	fileWrite(handle, len, sizeof(len));
	for method in arr do
		method.write(handle);
end;

end.