unit FileUtils;

//{$modeswitch ARRAYOPERATORS}
{$macro ON}
{$typedAddress ON}
{$modeSwitch ADVANCEDRECORDS}

{$define M_FOR_ALL_TYPES :=
	M_BEGIN shortint M_END
	M_BEGIN smallint M_END
	M_BEGIN longint  M_END
	M_BEGIN longword M_END
	M_BEGIN int64    M_END
	M_BEGIN byte     M_END
	M_BEGIN word     M_END
	M_BEGIN qword    M_END
	M_BEGIN boolean  M_END
	M_BEGIN ansichar M_END
	M_BEGIN widechar M_END
	M_BEGIN real     M_END
	M_BEGIN single   M_END
	M_BEGIN double   M_END
	M_BEGIN extended M_END
	M_BEGIN comp     M_END
	M_BEGIN currency M_END
}

{$define M_FOR_ALL_READ_TYPES :=
	M_FOR_ALL_TYPES
	M_BEGIN IBinaryIORead M_END
	M_BEGIN ansistring    M_END
	M_BEGIN widestring    M_END
}

{$define M_FOR_ALL_WRITE_TYPES :=
	M_FOR_ALL_TYPES
	M_BEGIN IBinaryIOWrite M_END
	M_BEGIN ansistring     M_END
	M_BEGIN widestring     M_END
}

interface

uses
	SysUtils;

type
	TBinaryFile = class;
	
	{$push}
	{$interfaces CORBA} // We don't need these to be RCed, but rather just exist as type constraints
	IBinaryIORead = interface
		procedure readFromBinary(const bf: TBinaryFile);
	end;

	IBinaryIOWrite = interface
		procedure writeToBinary(const bf: TBinaryFile);
	end;
	{$pop}

	IBinaryIOWriteArray = array of IBinaryIOWrite;

type
	//generic TBinaryCustomReadProc<T> = procedure(const bf: TBinaryFile; out value: T);
	generic TBinaryCustomReadFunc<T> = function(const bf: TBinaryFile): T;
	generic TBinaryCustomWriteProc<T> = procedure(const bf: TBinaryFile; const value: T);

	TBinaryFile = class
	private
		isClosed: boolean;
	public
		handle: THandle;

		constructor fromHandle(handle_: THandle);
		constructor create(const fileName: unicodestring); overload;
		constructor create(const fileName: unicodestring; rights: integer); overload;
		constructor create(const fileName: unicodestring; shareMode: integer; Rights: integer); overload;
		constructor create(const fileName: RawByteString); overload;
		constructor create(const fileName: RawByteString; rights: integer); overload;
		constructor create(const fileName: RawByteString; shareMode: integer; rights: integer); overload;
		constructor open(const fileName: unicodestring; mode: integer); overload;
		constructor open(const fileName: RawByteString; mode: integer); overload;
		
		destructor destroy; override;

		procedure close;

		function flush: boolean;

		procedure read(var buffer: IBinaryIORead); overload;
		procedure read(out buffer: ansistring); overload;
		procedure read(out buffer: widestring); overload;
		{$define M_BEGIN :=  procedure read(out buffer:  }
		{$define M_END   :=  ); overload;                }
			M_FOR_ALL_TYPES
		generic procedure read<T>(out buffer: T); overload;

		procedure readOnly(out buffer; count: longint);

		{$define M_BEGIN :=   procedure readAll(out buffer: specialize TArray<  }
		{$define M_END   :=   >); overload;                                     }
			M_FOR_ALL_READ_TYPES
		generic procedure readAll<T>(out buffer: specialize TArray<T>); overload;
		//generic procedure readAll<T>(out buffer: specialize TArray<T>; size: longint); overload;
		generic procedure readAll<T>(out buffer: specialize TArray<T>; const func: specialize TBinaryCustomReadFunc<T>); overload;

		function seek(foffset, origin: longint): longint; overload;
		function seek(foffset: int64; origin: longint): int64; overload;

		function truncate(size: int64): boolean;

		procedure write(const buffer: IBinaryIOWrite); overload;
		procedure write(const buffer: ansistring); overload;
		procedure write(const buffer: widestring); overload;
		{$define M_BEGIN :=  procedure write(buffer:  }
		{$define M_END   :=  ); overload;             }
			M_FOR_ALL_TYPES
		generic procedure write<T>(const buffer: T); overload;

		procedure writeOnly(const buffer; count: longint);

		{$define M_BEGIN :=   procedure writeAll(const buffer: specialize TArray<  }
		{$define M_END   :=   >); overload;                                        }
			M_FOR_ALL_WRITE_TYPES
		generic procedure writeAll<T>(const buffer: specialize TArray<T>); overload;
		//generic procedure writeAll<T>(const buffer: specialize TArray<T>; size: longint); overload;
		generic procedure writeAll<T>(const buffer: specialize TArray<T>; const proc: specialize TBinaryCustomWriteProc<T>); overload;
	end;

implementation

constructor TBinaryFile.fromHandle(handle_: THandle);
begin
	isClosed := false;
	handle := handle_;
end;


constructor TBinaryFile.create(const fileName: unicodestring); overload;
begin
	isClosed := false;
	handle := fileCreate(fileName);
end;

constructor TBinaryFile.create(const fileName: unicodestring; rights: integer); overload;
begin
	isClosed := false;
	handle := fileCreate(fileName, rights);
end;

constructor TBinaryFile.create(const fileName: unicodestring; shareMode: integer; Rights: integer); overload;
begin
	isClosed := false;
	handle := fileCreate(fileName, shareMode, rights);
end;

constructor TBinaryFile.create(const fileName: RawByteString); overload;
begin
	isClosed := false;
	handle := fileCreate(fileName);
end;

constructor TBinaryFile.create(const fileName: RawByteString; rights: integer); overload;
begin
	isClosed := false;
	handle := fileCreate(fileName, rights);
end;

constructor TBinaryFile.create(const fileName: RawByteString; shareMode: integer; rights: integer); overload;
begin
	isClosed := false;
	handle := fileCreate(fileName, shareMode, rights);
end;


constructor TBinaryFile.open(const fileName: unicodestring; mode: integer); overload;
begin
	isClosed := false;
	handle := fileOpen(fileName, mode);
end;

constructor TBinaryFile.open(const fileName: RawByteString; mode: integer); overload;
begin
	isClosed := false;
	handle := fileOpen(fileName, mode);
end;


destructor TBinaryFile.destroy;
begin
	if not isClosed then fileClose(handle);
	inherited destroy();
end;


procedure TBinaryFile.close;
begin
	if not isClosed then begin
		isClosed := true;
		fileClose(handle);
	end;
end;


function TBinaryFile.flush: boolean;
begin
	result := fileFlush(handle);
end;


procedure TBinaryFile.read(var buffer: IBinaryIORead); overload;
begin
	assert(buffer <> nil);
	buffer.readFromBinary(self);
end;

procedure TBinaryFile.read(out buffer: ansistring); overload;
var
	len: longint;
begin
	fileRead(handle, len, sizeof(len));
	setLength(buffer, len);
	fileRead(handle, buffer, len * sizeof(ansichar));
end;

procedure TBinaryFile.read(out buffer: widestring); overload;
var
	len: longint;
begin
	fileRead(handle, len, sizeof(len));
	setLength(buffer, len);
	fileRead(handle, buffer, len * sizeof(widechar));
end;

{$define M_BEGIN :=  procedure TBinaryFile.read(out buffer:                             }
{$define M_END   :=  ); overload; begin fileRead(handle, buffer, sizeof(buffer)); end;  }
	M_FOR_ALL_TYPES

generic procedure TBinaryFile.read<T>(out buffer: T);
begin
	fileRead(handle, buffer, sizeof(buffer));
end;


procedure TBinaryFile.readOnly(out buffer; count: longint);
begin
	fileRead(handle, buffer, count);
end;


// TODO: optimize this for numeric types
{$define M_BEGIN :=   procedure TBinaryFile.readAll(out buffer: specialize TArray<  }
{$define M_END   :=
	>); overload;
	var
		i, len: longint;
	begin
		buffer := [];
	
		fileRead(handle, len, sizeof(len));
		setLength(buffer, len);
		
		for i := 0 to len do
			self.read(buffer[i]);
	end;
}
	M_FOR_ALL_READ_TYPES

generic procedure TBinaryFile.readAll<T>(out buffer: specialize TArray<T>); overload;
type
	TElems = specialize TArray<T>;
var
	i, len: longint;
	_buffer: TElems;
begin
	_buffer := [];
	
	fileRead(handle, len, sizeof(len));
	setLength(_buffer, len);
	
	for i := 0 to len do
		self.specialize read<T>(_buffer[i]);

	buffer := _buffer;
end;

{generic procedure TBinaryFile.readAll<T>(out buffer: specialize TArray<T>; size: longint); overload;
var
	i, len: longint;
begin
	buffer := [];
	
	fileRead(handle, len, sizeof(len));
	setLength(buffer, len);
	
	for i := 0 to len do
		self.readOnly(buffer[i], size);
end;}

generic procedure TBinaryFile.readAll<T>(out buffer: specialize TArray<T>; const func: specialize TBinaryCustomReadFunc<T>); overload;
var
	i, len: longint;
begin
	buffer := [];
	
	fileRead(handle, len, sizeof(len));
	setLength(buffer, len);
	
	for i := 0 to len do
		buffer[i] := func(self);
end;


function TBinaryFile.seek(foffset, origin: longint): longint; overload;
begin
	result := fileSeek(handle, foffset, origin);
end;

function TBinaryFile.seek(foffset: int64; origin: longint): int64; overload;
begin
	result := fileSeek(handle, foffset, origin);
end;


function TBinaryFile.truncate(size: int64): boolean;
begin
	result := fileTruncate(handle, size);
end;


procedure TBinaryFile.write(const buffer: IBinaryIOWrite); overload;
begin
	assert(buffer <> nil);
	buffer.writeToBinary(self);
end;

procedure TBinaryFile.write(const buffer: ansistring); overload;
var
	len: longint;
begin
	len := length(buffer);
	fileWrite(handle, len, sizeof(len));
	fileWrite(handle, buffer, len * sizeof(ansichar));
end;

procedure TBinaryFile.write(const buffer: widestring); overload;
var
	len: longint;
begin
	len := length(buffer);
	fileWrite(handle, len, sizeof(len));
	fileWrite(handle, buffer, len * sizeof(widechar));
end;

{$define M_BEGIN :=  procedure TBinaryFile.write(buffer:                                 }
{$define M_END   :=  ); overload; begin fileWrite(handle, buffer, sizeof(buffer)); end;  }
	M_FOR_ALL_TYPES

generic procedure TBinaryFile.write<T>(const buffer: T); overload;
begin
	fileWrite(handle, buffer, sizeof(buffer));
end;


procedure TBinaryFile.writeOnly(const buffer; count: longint);
begin
	fileWrite(handle, buffer, count);
end;


// TODO: optimize this for numeric types
{$define M_BEGIN :=   procedure TBinaryFile.writeAll(const buffer: specialize TArray<  }
{$define M_END   :=
	>); overload;
	var
		i, len: longint;
	begin
		len := length(buffer);
		fileWrite(handle, len, sizeof(len));
		
		for i := 0 to len do
			self.write(buffer[i]);
	end;
}
	M_FOR_ALL_WRITE_TYPES

generic procedure TBinaryFile.writeAll<T>(const buffer: specialize TArray<T>); overload;
var
	i, len: longint;
begin
	len := length(buffer);
	fileWrite(handle, len, sizeof(len));
	
	for i := 0 to len do
		self.specialize write<T>(buffer[i]);
end;

{generic procedure TBinaryFile.writeAll<T>(const buffer: specialize TArray<T>; size: longint); overload;
var
	i, len: longint;
begin
	len := length(buffer);
	fileWrite(handle, len, sizeof(len));
	
	for i := 0 to len do
		self.write(buffer[i], size);
end;}

generic procedure TBinaryFile.writeAll<T>(const buffer: specialize TArray<T>; const proc: specialize TBinaryCustomWriteProc<T>); overload;
var
	i, len: longint;
begin
	len := length(buffer);
	fileWrite(handle, len, sizeof(len));
	
	for i := 0 to len do
		proc(self, buffer[i]);
end;

end.