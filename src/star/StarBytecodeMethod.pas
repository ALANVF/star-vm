unit StarBytecodeMethod;

{$SCOPEDENUMS+}
{$MINENUMSIZE 1}

interface

uses
	StarBytecodeIndex,
	StarBytecodeOp,
	StarBytecodeCodeSection,
	SysUtils,
	FileUtils;

type
	// add attrs later

	TMethod = class(IBinaryIOWrite)
	public
		typeParams, paramTypes: TTypeIndexArray;
		returnType: TTypeIndex;
		registers: TTypeIndexArray;
		sections: TCodeSectionArray;

		constructor create(typeParams_, paramTypes_: TTypeIndexArray; returnType_: TTypeIndex; registers_: TTypeIndexArray; sections_: TCodeSectionArray);
		
		constructor read(handle: THandle);

		destructor destroy; override;
		
		procedure writeToBinary(const bf: TBinaryFile);
	end;

type
	TMethodArray = array of TMethod;

procedure readMethodArray(handle: THandle; out arr: TMethodArray); overload;
function readMethodArray(handle: THandle): TMethodArray; overload;

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


procedure TMethod.writeToBinary(const bf: TBinaryFile);
begin
	bf.writeAll(typeParams);
	bf.writeAll(paramTypes);
	bf.write(returnType);
	bf.writeAll(registers);
	bf.writeAll(IBinaryIOWriteArray(sections));
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

end.