unit Star.Bytecode.Member;

{$scopedEnums+}
{$minEnumSize 1}

interface

uses
	Star.Bytecode.Index,
	SysUtils,
	FileUtils;

type
	TMemberAttr = (hidden, noinherit, readonly);
	TMemberAttrs = set of TMemberAttr;

	TMember = class(IBinaryIOWrite)
	public
		index: TMemberIndex;
		name: string;
		&type: TTypeIndex;
		attrs: TMemberAttrs;

		constructor create(index_: TMemberIndex; name_: string; type_: TTypeIndex; attrs_: TMemberAttrs);
		
		constructor read(handle: THandle);

		procedure writeToBinary(const bf: TBinaryFile);
	end;

type
	TMemberArray = array of TMember;

procedure readMemberArray(handle: THandle; out arr: TMemberArray); overload;
function readMemberArray(handle: THandle): TMemberArray; overload;

implementation

constructor TMember.create(index_: TMemberIndex; name_: string; type_: TTypeIndex; attrs_: TMemberAttrs);
begin
	index := index_;
	name := name_;
	&type := type_;
	attrs := attrs_;
end;


constructor TMember.read(handle: THandle);
begin
	fileRead(handle, index, sizeof(index));
	fileRead(handle, name, sizeof(name));
	fileRead(handle, &type, sizeof(&type));
	fileRead(handle, attrs, sizeof(attrs));
end;


procedure TMember.writeToBinary(const bf: TBinaryFile);
begin
	bf.write(index);
	bf.write(name);
	bf.write(&type);
	bf.writeOnly(attrs, sizeof(attrs));
end;


procedure readMemberArray(handle: THandle; out arr: TMemberArray); overload;
var
	len, i: longint;
begin
	arr := [];
	fileRead(handle, len, sizeof(len));
	setLength(arr, len);
	for i := 0 to len do
		arr[i] := TMember.read(handle);
end;

function readMemberArray(handle: THandle): TMemberArray; overload;
var
	len, i: longint;
begin
	result := [];
	fileRead(handle, len, sizeof(len));
	setLength(result, len);
	for i := 0 to len do
		result[i] := TMember.read(handle);
end;

end.