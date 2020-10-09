unit Star.Bytecode.Method;

{$SCOPEDENUMS+}
{$MINENUMSIZE 1}

interface

uses
	Star.Bytecode.Index,
	Star.Bytecode.Op,
	Star.Bytecode.Selector,
	Star.Bytecode.CodeSection,
	SysUtils,
	FileUtils;

type
	// add attrs later
	TMethodAttr = (hidden, static, main, noinherit, unordered, native);
	TMethodAttrs = set of TMethodAttr;

	TMethod = class(IBinaryIOWrite)
	public
		selector: TSelectorIndex;
		attrs: TMethodAttrs;
		typeParams, paramTypes: TTypeIndexArray;
		returnType: TTypeIndex;
		registers: TTypeIndexArray;
		sections: TCodeSectionArray;

		constructor create(selector_: TSelectorIndex; attrs_: TMethodAttrs; typeParams_, paramTypes_: TTypeIndexArray; returnType_: TTypeIndex; registers_: TTypeIndexArray; sections_: TCodeSectionArray);
		
		constructor read(handle: THandle);

		destructor destroy; override;

		procedure writeToBinary(const bf: TBinaryFile);

		function dump: string;
	end;

type
	TMethodArray = array of TMethod;

procedure readMethodArray(handle: THandle; out arr: TMethodArray); overload;
function readMethodArray(handle: THandle): TMethodArray; overload;

implementation

constructor TMethod.create(selector_: TSelectorIndex; attrs_: TMethodAttrs; typeParams_, paramTypes_: TTypeIndexArray; returnType_: TTypeIndex; registers_: TTypeIndexArray; sections_: TCodeSectionArray);
begin
	selector := selector_;
	attrs := attrs_;
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
	//selector
	//attrs
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
	bf.write(selector);
	bf.writeOnly(attrs, sizeof(attrs));
	bf.writeAll(typeParams);
	bf.writeAll(paramTypes);
	bf.write(returnType);
	bf.writeAll(registers);
	bf.specialize writeAllIO<TCodeSection>(sections);
end;


function TMethod.dump: string;
const
	sep = string(lineEnding) + #9 + #9;
	sep2 = lineEnding + sep;
var
	i: longint;
	reg: TRegisterIndex = 0;
	attr: TMethodAttr;
	attrName: string;
begin
	//typeParams...
	
	result := #9'on ';
	result += dumpSelectorIndex(selector);
	result += ' [';
	
	if length(paramTypes) > 0 then begin
		result += dumpRegisterIndex(1);
		result += ' (';
		result += dumpTypeIndex(paramTypes[0]);
		result += ')';
		
		for reg := 1 to high(paramTypes) do begin
			result += ', ';
			result += dumpRegisterIndex(reg + 1);
			result += ' (';
			result += dumpTypeIndex(paramTypes[reg]);
			result += ')';
		end;
	end;
	
	result += '] (';
	result += dumpTypeIndex(returnType);
	result += ')';

	for attr in attrs do begin
		result += ' is ';
		str(attr, attrName);
		result += attrName;
	end;

	result += ' {';

	for i := 0 to high(registers) do begin
		result += sep;
		result += 'my ';
		result += dumpRegisterIndex(reg + i + 1);
		result += ' (';
		result += dumpTypeIndex(registers[i]);
		result += ')';
	end;

	if length(registers) <> 0 then
		result += lineEnding;
	
	for i := 0 to high(sections) do begin
		result += sep;
		result += dumpCodeSectionIndex(TCodeSectionIndex(i));
		result += ' {';
		result += sections[i].dump();
		result += sep;
		result += '}';
	end;

	result += lineEnding;
	result += #9'}';
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