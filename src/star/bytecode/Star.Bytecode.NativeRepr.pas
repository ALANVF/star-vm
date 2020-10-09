unit Star.Bytecode.NativeRepr;

interface

type
	TNativeRepr = (
		{ basic types }
		void,
		bool,
		uint8, int8,
		uint16, int16,
		uint32, int32,
		uint64, int64,
		dec32,
		dec64,
		
		{ compound types }
		ptr,
		voidPtr,
		funcPtr,
		//struct,
		
		{ pascal-specific types }
		pascalStringPtr,
		pascalArrayPtr,
		pascalTObject
	);

const
	NATIVE_VOID_GLOBAL_INDEX = 0;

implementation

end.