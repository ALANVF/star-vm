unit StringUtils;

interface

function hash(s: string): qword;

implementation

function hash(s: string): qword; // djb2 algorithm
var
	c: char;
begin
	result := 5381;
	
	for c in s do
		result := (result shl 5) + result + ord(c); // result * 33 + ord(c)
end;

end.
