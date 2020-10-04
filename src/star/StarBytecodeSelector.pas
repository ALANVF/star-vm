unit StarBytecodeSelector;

interface

uses
	StarBytecodeIndex,
	SysUtils;

type
	TSelector = ansistring;{class(IBinaryIOWrite)
		..
	end;}

type
	TSelectorArray = array of TSelector;

function readSelectorArray(handle: THandle): TSelectorArray;
procedure readSelectorArray(handle: THandle; out arr: TSelectorArray); overload;

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

end.