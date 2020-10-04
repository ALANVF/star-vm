unit StarBytecodeMember;

{$SCOPEDENUMS+}
{$MINENUMSIZE 1}

interface

uses
	StarBytecodeIndex,
	SysUtils;

type
	TMemberAttr = (hidden, noinherit, readonly);
	TMemberAttrs = set of TMemberAttr;

	TMember = class
	public
		index: TMemberIndex;
		name: string;
		&type: TTypeIndex;
		attrs: TMemberAttrs;

		constructor create(index_: TMemberIndex; name_: string; type_: TTypeIndex; attrs_: TMemberAttrs);
		constructor read(handle: THandle);

		procedure write(handle: THandle);
	end;

type
	TMemberArray = array of TMember;

procedure readMemberArray(handle: THandle; out arr: TMemberArray); overload;
function readMemberArray(handle: THandle): TMemberArray; overload;

procedure writeMemberArray(handle: THandle; const arr: TMemberArray);

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

procedure TMember.write(handle: THandle);
begin
	fileWrite(handle, index, sizeof(index));
	fileWrite(handle, &type, sizeof(&type));
	fileWrite(handle, attrs, sizeof(attrs));
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


procedure writeMemberArray(handle: THandle; const arr: TMemberArray);
var
	len: longint;
	member: TMember;
begin
	len := length(arr);
	fileWrite(handle, len, sizeof(len));
	for member in arr do
		member.write(handle);
end;

end.