unit StarBytecodeIndex;

interface

uses
	SysUtils;

type
	TSelectorIndex = cardinal;
	TConstantIndex = word; // might need to be cardinal idk
	TRegisterIndex = word;
	TMemberIndex = word;
	TTypeIndex = cardinal;
	TCodeSectionIndex = word;

type
	TConstantIndexArray = array of TConstantIndex;
	TRegisterIndexArray = array of TRegisterIndex;
	TTypeIndexArray = specialize TArray<TTypeIndex>;//array of TTypeIndex;
	TCodeSectionIndexArray = array of TCodeSectionIndex;

type
	PConstantIndexArray = ^TConstantIndexArray;
	PRegisterIndexArray = ^TRegisterIndexArray;
	PTypeIndexArray = ^TTypeIndexArray;
	PCodeSectionIndexArray = ^TCodeSectionIndexArray;

function dumpSelectorIndex(index: TSelectorIndex): string;
function dumpConstantIndex(index: TConstantIndex): string;
function dumpRegisterIndex(index: TRegisterIndex): string;
function dumpMemberIndex(index: TMemberIndex): string;
function dumpTypeIndex(index: TTypeIndex): string;
function dumpCodeSectionIndex(index: TCodeSectionIndex): string;

function readRegisterIndexArray(handle: THandle): TRegisterIndexArray;
function readTypeIndexArray(handle: THandle): TTypeIndexArray; overload;
procedure readTypeIndexArray(handle: THandle; out arr: TTypeIndexArray); overload;

implementation

function dumpSelectorIndex(index: TSelectorIndex): string;
begin
	result := format('#%d', [index]);
end;

function dumpConstantIndex(index: TConstantIndex): string;
begin
	result := format('&%d', [index]);
end;

function dumpRegisterIndex(index: TRegisterIndex): string;
begin
	result := format('$%d', [index]);
end;

function dumpMemberIndex(index: TMemberIndex): string;
begin
	result := format('.%d', [index]);
end;

function dumpTypeIndex(index: TTypeIndex): string;
begin
	result := format('%%%d', [index]);
end;

function dumpCodeSectionIndex(index: TCodeSectionIndex): string;
begin
	result := format('@%d', [index]);
end;


function readRegisterIndexArray(handle: THandle): TRegisterIndexArray;
var
	len, i: longint;
begin
	result := [];
	fileRead(handle, len, sizeof(len));
	setLength(result, len);
	for i := 0 to len do
		fileRead(handle, result[i], sizeof(result[i]));
end;

function readTypeIndexArray(handle: THandle): TTypeIndexArray;
var
	len, i: longint;
begin
	result := [];
	fileRead(handle, len, sizeof(len));
	setLength(result, len);
	for i := 0 to len do
		fileRead(handle, result[i], sizeof(result[i]));
end;

procedure readTypeIndexArray(handle: THandle; out arr: TTypeIndexArray); overload;
var
	len, i: longint;
begin
	arr := [];
	fileRead(handle, len, sizeof(len));
	setLength(arr, len);
	for i := 0 to len do
		fileRead(handle, arr[i], sizeof(arr[i]));
end;

end.