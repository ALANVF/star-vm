unit Star.Bytecode.ConstantsTable;

{$scopedEnums+}
{$minEnumSize 1}

interface

uses
	ContainerUtils;

type
	TConstantKind = (
		bool,
		u8, i8, char,
		u16, i16,
		u32, i32,
		u64, i64,
		f32,
		f64,
		str
	);

	TConstantKinds = set of TConstantKind;

	{TConstant = record
		case kind: TConstantKind of
			TConstantKind.bool: (bool: boolean);
			TConstantKind.u8: (u8: byte);
			TConstantKind.i8: (i8: shortint);
			TConstantKind.char: (ch: ansichar);
			TConstantKind.u16: (u16: word);
			TConstantKind.i16: (i16: smallint);
			TConstantKind.u32: (u32: longword);
			TConstantKind.i32: (i32: longint);
			TConstantKind.u64: (u64: qword);
			TConstantKind.i64: (i64: int64);
			TConstantKind.f32: (f32: single);
			TConstantKind.f64: (f64: double);
			TConstantKind.str: (str: ^ansistring);
	end;}
	TConstantsTable = class
	public
		type
			TBool = boolean;
			TU8 = byte;
			TI8 = shortint;
			TChar = ansichar;
			TU16 = word;
			TI16 = smallint;
			TU32 = longword;
			TI32 = longint;
			TU64 = qword;
			TI64 = int64;
			TF32 = single;
			TF64 = double;
			TStr = ansistring;
			TKindPair = specialize TPair<TConstantKind, word>;

			TBoolArray = array of TBool;
			TU8Array = array of TU8;
			TI8Array = array of TI8;
			TCharArray = array of TChar;
			TU16Array = array of TU16;
			TI16Array = array of TI16;
			TU32Array = array of TU32;
			TI32Array = array of TI32;
			TU64Array = array of TU64;
			TI64Array = array of TI64;
			TF32Array = array of TF32;
			TF64Array = array of TF64;
			TStrArray = array of TStr;
			TConstantKindArray = array of TConstantKind;
			TKindPairArray = array of TKindPair;

		var
			bools: TBoolArray;
			u8s: TU8Array;
			i8s: TI8Array;
			chars: TCharArray;
			u16s: TU16Array;
			i16s: TI16Array;
			u32s: TU32Array;
			i32s: TI32Array;
			u64s: TU64Array;
			i64s: TI64Array;
			f32s: TF32Array;
			f64s: TF64Array;
			strs: TStrArray;
			pairs: TConstantKindPairArray;

		constructor create;
		constructor create(
			bools_: TBoolArray;
			u8s_: TU8Array;
			i8s_: TI8Array;
			chars_: TCharArray;
			u16s_: TU16Array;
			i16s_: TI16Array;
			u32s_: TU32Array;
			i32s_: TI32Array;
			u64s_: TU64Array;
			i64s_: TI64Array;
			f32s_: TF32Array;
			f64s_: TF64Array;
			strs_: TStrArray;
			kinds: TConstantKindArray);
		constructor create(
			bools_: TBoolArray;
			u8s_: TU8Array;
			i8s_: TI8Array;
			chars_: TCharArray;
			u16s_: TU16Array;
			i16s_: TI16Array;
			u32s_: TU32Array;
			i32s_: TI32Array;
			u64s_: TU64Array;
			i64s_: TI64Array;
			f32s_: TF32Array;
			f64s_: TF64Array;
			strs_: TStrArray;
			pairs_: TKindPairArray);

		{function kindAt(index: longint): TConstantKind;
		
		function offsetOfKindAt(index: longint): longint;

		procedure addBool(value: TBool);
		
		procedure addU8(value: TU8);
		
		procedure addI8(value: TI8);
		
		procedure addChar(value: TChar);
		
		procedure addU16(value: TU16);
		
		procedure addI16(value: TI16);
		
		procedure addU32(value: TU32);
		
		procedure addI32(value: TI32);
		
		procedure addU64(value: TU64);
		
		procedure addI64(value: TI64);
		
		procedure addF32(value: TF32);
		
		procedure addF64(value: TF64);
		
		procedure addStr(value: TStr);

		procedure addConstant(value: TBool); overload;
		procedure addConstant(value: TU8); overload;
		procedure addConstant(value: TI8); overload;
		procedure addConstant(value: TChar); overload;
		procedure addConstant(value: TU16); overload;
		procedure addConstant(value: TI16); overload;
		procedure addConstant(value: TU32); overload;
		procedure addConstant(value: TI32); overload;
		procedure addConstant(value: TU64); overload;
		procedure addConstant(value: TI64); overload;
		procedure addConstant(value: TF32); overload;
		procedure addConstant(value: TF64); overload;
		procedure addConstant(value: TStr); overload;

		function getBool(index: longint): TBool;
		
		function getU8(index: longint): TU8;
		
		function getI8(index: longint): TI8;
		
		function getChar(index: longint): TChar;
		
		function getU16(index: longint): TU16;
		
		function getI16(index: longint): TI16;
		
		function getU32(index: longint): TU32;
		
		function getI32(index: longint): TI32;
		
		function getU64(index: longint): TU64;
		
		function getI64(index: longint): TI64;
		
		function getF32(index: longint): TF32;
		
		function getF64(index: longint): TF64;
		
		function getStr(index: longint): TStr;

		function getAsBool(index: longint): TBool;
		
		function getAsU8(index: longint): TU8;
		
		function getAsI8(index: longint): TI8;
		
		function getAsChar(index: longint): TChar;
		
		function getAsU16(index: longint): TU16;
		
		function getAsI16(index: longint): TI16;
		
		function getAsU32(index: longint): TU32;
		
		function getAsI32(index: longint): TI32;
		
		function getAsU64(index: longint): TU64;
		
		function getAsI64(index: longint): TI64;
		
		function getAsF32(index: longint): TF32;
		
		function getAsF64(index: longint): TF64;
		
		function getAsStr(index: longint): TStr;}
	end;

implementation

constructor TConstantsTable.create;
begin
	bools := [];
	u8s := [];
	i8s := [];
	chars := [];
	u16s := [];
	i16s := [];
	u32s := [];
	i32s := [];
	u64s := [];
	i64s := [];
	f32s := [];
	f64s := [];
	strs := [];
	pairs := [];
end;

constructor TConstantsTable.create(
	bools_: TBoolArray;
	u8s_: TU8Array;
	i8s_: TI8Array;
	chars_: TCharArray;
	u16s_: TU16Array;
	i16s_: TI16Array;
	u32s_: TU32Array;
	i32s_: TI32Array;
	u64s_: TU64Array;
	i64s_: TI64Array;
	f32s_: TF32Array;
	f64s_: TF64Array;
	strs_: TStrArray;
	kinds: TConstantKindArray);
var
	i, numBools, numU8s, numI8s, numChars, numU16s, numI16s, numU32s, numI32s, numU64s, numI64s, numF32s, numF64s, numStrs: longint;
begin
	bools := bools_;
	u8s := u8s_;
	i8s := i8s_;
	chars := chars_;
	u16s := u16s_;
	i16s := i16s_;
	u32s := u32s_;
	i32s := i32s_;
	u64s := u64s_;
	i64s := i64s_;
	f32s := f32s_;
	f64s := f64s_;
	strs := strs_;
	
	setLength()
end;

constructor TConstantsTable.create(
	bools_: TBoolArray;
	u8s_: TU8Array;
	i8s_: TI8Array;
	chars_: TCharArray;
	u16s_: TU16Array;
	i16s_: TI16Array;
	u32s_: TU32Array;
	i32s_: TI32Array;
	u64s_: TU64Array;
	i64s_: TI64Array;
	f32s_: TF32Array;
	f64s_: TF64Array;
	strs_: TStrArray;
	pairs_: TKindPairArray);
begin
	bools := bools_;
	u8s := u8s_;
	i8s := i8s_;
	chars := chars_;
	u16s := u16s_;
	i16s := i16s_;
	u32s := u32s_;
	i32s := i32s_;
	u64s := u64s_;
	i64s := i64s_;
	f32s := f32s_;
	f64s := f64s_;
	strs := strs_;
	pairs := pairs_;
end;


end.