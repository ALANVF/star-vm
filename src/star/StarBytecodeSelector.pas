unit StarBytecodeSelector;

interface

uses
	StarBytecodeIndex,
	SysUtils;

type
	TSelector = type word;

type
	TSelectorArray = array of TSelector;

function readSelectorArray(handle: THandle): TSelectorArray;
procedure readSelectorArray(handle: THandle; out arr: TSelectorArray); overload;

procedure writeSelectorArray(handle: THandle; const arr: TSelectorArray);

implementation

function readSelectorArray(handle: THandle): TSelectorArray;
var
	len, i: longint;
begin
	result := [];
	fileRead(handle, len, sizeof(len));
	setLength(result, len);
	for i := 0 to len do
		fileRead(handle, result[i], sizeof(result[i]));
end;

procedure readSelectorArray(handle: THandle; out arr: TSelectorArray); overload;
var
	len, i: longint;
begin
	arr := [];
	fileRead(handle, len, sizeof(len));
	setLength(arr, len);
	for i := 0 to len do
		fileRead(handle, arr[i], sizeof(arr[i]));
end;


procedure writeSelectorArray(handle: THandle; const arr: TSelectorArray);
var
	len: longint;
	index: TSelector;
begin
	len := length(arr);
	fileWrite(handle, len, sizeof(len));
	for index in arr do
		fileWrite(handle, index, sizeof(index));
end;

end.