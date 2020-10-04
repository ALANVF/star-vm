unit StarBytecodeType;

{$SCOPEDENUMS+}
{$MINENUMSIZE 1}

interface

uses
	StarBytecodeIndex,
	StarBytecodeMember,
	StarBytecodeMethod,
	StarBytecodeSelector,
	SysUtils,
	FileUtils;

type
	TTypeID = (param, erased, module, &class, protocol, valueKind, taggedKind, native);
	
	TTypeAttr = (hidden, uncounted, strong, native);
	TTypeAttrs = set of TTypeAttr;

	TType = class abstract
	public
		index: TTypeIndex;
		attrs: TTypeAttrs;
		typeParams: TTypeIndexArray;

		constructor create(index_: TTypeIndex; attrs_: TTypeAttrs; typeParams_: TTypeIndexArray);

		procedure write(handle: THandle); virtual;
	end;

	TTypeParam = class(TType, IBinaryIOWrite)
	public
		parents: TTypeIndexArray;
		{hasCond: boolean;
		cond: ...}

		constructor create(index_: TTypeIndex; attrs_: TTypeAttrs; typeParams_, parents_: TTypeIndexArray);

		procedure write(handle: THandle); override;

		procedure writeToBinary(const bf: TBinaryFile); // override
	end;

	TTypeErased = class(TType)
	public
		procedure write(handle: THandle); override;
	end;

	TTypeNamespace = class abstract(TType)
	public
		nestedTypes: TTypeIndexArray;
		staticInit, staticDeinit: TMethod; {NULLABLE}
		staticMembers: TMemberArray;
		staticSelectors: TSelectorArray;
		staticMethods: TMethodArray;
		
		constructor create(
			index_: TTypeIndex;
			attrs_: TTypeAttrs;
			typeParams_, nestedTypes_: TTypeIndexArray;

			staticInit_, staticDeinit_: TMethod;
			staticMembers_: TMemberArray;
			staticSelectors_: TSelectorArray;
			staticMethods_: TMethodArray);
		destructor destroy; override;

		procedure write(handle: THandle); override;
	end;

	TTypeDispatchable = class abstract(TTypeNamespace)
	public
		instanceMembers: TMemberArray;
		instanceSelectors: TSelectorArray;
		instanceMethods: TMethodArray;

		constructor create(
			index_: TTypeIndex;
			attrs_: TTypeAttrs;
			typeParams_, nestedTypes_: TTypeIndexArray;

			staticInit_, staticDeinit_: TMethod;
			staticMembers_: TMemberArray;
			staticSelectors_: TSelectorArray;
			staticMethods_: TMethodArray;
			
			instanceMembers_: TMemberArray;
			instanceSelectors_: TSelectorArray;
			instanceMethods_: TMethodArray);
		destructor destroy; override;

		procedure write(handle: THandle); override;
	end;
	
	TTypeClassLike = class abstract(TTypeDispatchable)
	public
		defaultInit, instanceDeinit: TMethod; {NULLABLE}
		parents: TTypeIndexArray;

		constructor create(
			index_: TTypeIndex;
			attrs_: TTypeAttrs;
			typeParams_, nestedTypes_: TTypeIndexArray;

			staticInit_, staticDeinit_: TMethod;
			staticMembers_: TMemberArray;
			staticSelectors_: TSelectorArray;
			staticMethods_: TMethodArray;
			
			instanceMembers_: TMemberArray;
			instanceSelectors_: TSelectorArray;
			instanceMethods_: TMethodArray;
			defaultInit_, instanceDeinit_: TMethod;
			parents_: TTypeIndexArray);
		destructor destroy; override;

		procedure write(handle: THandle); override;
	end;

	TTypeClass = class(TTypeClassLike)
	public
		initSelectors: TSelectorArray;
		initMethods: TMethodArray;

		constructor create(
			index_: TTypeIndex;
			attrs_: TTypeAttrs;
			typeParams_, nestedTypes_: TTypeIndexArray;

			staticInit_, staticDeinit_: TMethod;
			staticMembers_: TMemberArray;
			staticSelectors_: TSelectorArray;
			staticMethods_: TMethodArray;
			
			instanceMembers_: TMemberArray;
			instanceSelectors_: TSelectorArray;
			instanceMethods_: TMethodArray;
			defaultInit_, instanceDeinit_: TMethod;
			parents_: TTypeIndexArray;

			initSelectors_: TSelectorArray;
			initMethods_: TMethodArray);
		destructor destroy; override;

		procedure write(handle: THandle); override;
	end;

	TTypeProtocol = class(TTypeClassLike)
	public
		procedure write(handle: THandle); override;
	end;

	TTypeKind = class abstract(TTypeClassLike)
	public
		isFlags: boolean;
	end;

	TTypeValueKind = class(TTypeKind)
	public
		type
			TCase = class
			public
				constant: TConstantIndex;
				defaultInit: TMethod; {NULLABLE}

				constructor create(constant_: TConstantIndex; defaultInit_: TMethod);
				// read
				destructor destroy; override;

				procedure write(handle: THandle);
			end;
			TCaseArray = array of TCase;
		
		var
			baseType: TTypeIndex;
			cases: TCaseArray;
		
		constructor create(
			index_: TTypeIndex;
			attrs_: TTypeAttrs;
			typeParams_, nestedTypes_: TTypeIndexArray;

			staticInit_, staticDeinit_: TMethod;
			staticMembers_: TMemberArray;
			staticSelectors_: TSelectorArray;
			staticMethods_: TMethodArray;
			
			instanceMembers_: TMemberArray;
			instanceSelectors_: TSelectorArray;
			instanceMethods_: TMethodArray;
			defaultInit_, instanceDeinit_: TMethod;
			parents_: TTypeIndexArray;
			
			isFlags_: boolean;
			baseType_: TTypeIndex;
			cases_: TCaseArray);
		destructor destroy; override;

		procedure write(handle: THandle); override;
	end;

	TTypeTaggedKind = class(TTypeKind)
	public
		type
			TCase = class
			public
				selector: TSelectorIndex;
				slots: TTypeIndexArray;
				defaultInit: TMethod; {NULLABLE}

				constructor create(selector_: TSelectorIndex; slots_: TTypeIndexArray; defaultInit_: TMethod);
				// read
				destructor destroy; override;

				procedure write(handle: THandle);
			end;
			TCaseArray = array of TCase;
		
		var
			cases: TCaseArray;
		
		constructor create(
			index_: TTypeIndex;
			attrs_: TTypeAttrs;
			typeParams_, nestedTypes_: TTypeIndexArray;

			staticInit_, staticDeinit_: TMethod;
			staticMembers_: TMemberArray;
			staticSelectors_: TSelectorArray;
			staticMethods_: TMethodArray;
			
			instanceMembers_: TMemberArray;
			instanceSelectors_: TSelectorArray;
			instanceMethods_: TMethodArray;
			defaultInit_, instanceDeinit_: TMethod;
			parents_: TTypeIndexArray;
			
			isFlags_: boolean;
			cases_: TCaseArray);
		destructor destroy; override;

		procedure write(handle: THandle); override;
	end;

	TTypeNative = class(TTypeDispatchable)
	public
		type
			TRepr = (
				{ basic types }
				void,
				int1, uint1, bool,
				uint8, int8, char,
				uint16, int16,
				uint32, int32,
				uint64, int64,
				//uint128, int128,          { UNUSED }
				//dec16,                    { UNUSED }
				dec32,
				dec64,
				//dec128,                   { UNUSED }
				
				{ compound types }
				ptr,
				voidptr,
				funcptr,
				//struct,                   { UNUSED }
				
				{ pascal-specific types }
				pascalStringPtr,
				pascalArrayPtr
			);

	end;

implementation

constructor TType.create(index_: TTypeIndex; attrs_: TTypeAttrs; typeParams_: TTypeIndexArray);
begin
	index := index_;
	attrs := attrs_;
	typeParams := typeParams_;
end;

procedure TType.write(handle: THandle);
begin
	fileWrite(handle, index, sizeof(index));
	fileWrite(handle, attrs, sizeof(attrs));
	writeTypeIndexArray(handle, typeParams);
end;


constructor TTypeParam.create(index_: TTypeIndex; attrs_: TTypeAttrs; typeParams_, parents_: TTypeIndexArray);
begin
	inherited create(index_, attrs_, typeParams_);

	parents := parents_;
end;

procedure TTypeParam.write(handle: THandle);
const
	id: TTypeID = TTypeID.param;
begin
	fileWrite(handle, id, sizeof(id));
	
	inherited write(handle);

	writeTypeIndexArray(handle, parents);
end;

procedure TTypeParam.writeToBinary(const bf: TBinaryFile);
begin
	bf.specialize write<TTypeID>(TTypeID.param);
	
	//inherited writeToBinary(bf);
	
	bf.writeAll(parents);
end;


procedure TTypeErased.write(handle: THandle);
const
	id: TTypeID = TTypeID.erased;
begin
	fileWrite(handle, id, sizeof(id));

	inherited write(handle);
end;


constructor TTypeNamespace.create(
	index_: TTypeIndex;
	attrs_: TTypeAttrs;
	typeParams_, nestedTypes_: TTypeIndexArray;

	staticInit_, staticDeinit_: TMethod;
	staticMembers_: TMemberArray;
	staticSelectors_: TSelectorArray;
	staticMethods_: TMethodArray);
begin
	inherited create(index_, attrs_, typeParams_);

	nestedTypes := nestedTypes_;
	staticInit := staticInit_;
	staticDeinit := staticDeinit_;
	staticMembers := staticMembers_;
	staticSelectors := staticSelectors_;
	staticMethods := staticMethods_;
end;

destructor TTypeNamespace.destroy;
var
	i: integer;
begin
	if staticInit <> nil then freeAndNil(staticInit);
	if staticDeinit <> nil then freeAndNil(staticDeinit);
	for i := low(staticMembers) to high(staticMembers) do freeAndNil(staticMembers[i]);
	for i := low(staticMethods) to high(staticMethods) do freeAndNil(staticMethods[i]);

	inherited destroy();
end;

procedure TTypeNamespace.write(handle: THandle);
var
	hasStaticInit, hasStaticDeinit: boolean;
begin
	inherited write(handle);
	
	writeTypeIndexArray(handle, nestedTypes);
	
	hasStaticInit := staticInit <> nil;
	fileWrite(handle, hasStaticInit, sizeof(boolean));
	if hasStaticInit then staticInit.write(handle);

	hasStaticDeinit := staticDeinit <> nil;
	fileWrite(handle, hasStaticDeinit, sizeof(boolean));
	if hasStaticDeinit then staticDeinit.write(handle);

	writeMemberArray(handle, staticMembers);
	writeSelectorArray(handle, staticSelectors);
	writeMethodArray(handle, staticMethods);
end;


constructor TTypeDispatchable.create(
	index_: TTypeIndex;
	attrs_: TTypeAttrs;
	typeParams_, nestedTypes_: TTypeIndexArray;

	staticInit_, staticDeinit_: TMethod;
	staticMembers_: TMemberArray;
	staticSelectors_: TSelectorArray;
	staticMethods_: TMethodArray;
	
	instanceMembers_: TMemberArray;
	instanceSelectors_: TSelectorArray;
	instanceMethods_: TMethodArray);
begin
	inherited create(index_, attrs_, typeParams_, nestedTypes_, staticInit_, staticDeinit_, staticMembers_, staticSelectors_, staticMethods_);

	instanceMembers := instanceMembers_;
	instanceSelectors := instanceSelectors_;
	instanceMethods := instanceMethods_;
end;

destructor TTypeDispatchable.destroy;
var
	i: integer;
begin
	for i := low(instanceMembers) to high(instanceMembers) do freeAndNil(instanceMembers[i]);
	for i := low(instanceMethods) to high(instanceMethods) do freeAndNil(instanceMethods[i]);

	inherited destroy();
end;

procedure TTypeDispatchable.write(handle: THandle);
begin
	inherited write(handle);
	
	writeMemberArray(handle, instanceMembers);
	writeSelectorArray(handle, instanceSelectors);
	writeMethodArray(handle, instanceMethods);
end;


constructor TTypeClassLike.create(
	index_: TTypeIndex;
	attrs_: TTypeAttrs;
	typeParams_, nestedTypes_: TTypeIndexArray;

	staticInit_, staticDeinit_: TMethod;
	staticMembers_: TMemberArray;
	staticSelectors_: TSelectorArray;
	staticMethods_: TMethodArray;
	
	instanceMembers_: TMemberArray;
	instanceSelectors_: TSelectorArray;
	instanceMethods_: TMethodArray;
	defaultInit_, instanceDeinit_: TMethod;
	parents_: TTypeIndexArray);
begin
	inherited create(index_, attrs_, typeParams_, nestedTypes_, staticInit_, staticDeinit_, staticMembers_, staticSelectors_, staticMethods_, instanceMembers_, instanceSelectors_, instanceMethods_);

	defaultInit := defaultInit_;
	instanceDeinit := instanceDeinit_;
	parents := parents_;
end;

destructor TTypeClassLike.destroy;
begin
	if defaultInit <> nil then freeAndNil(defaultInit);
	if instanceDeinit <> nil then freeAndNil(instanceDeinit);

	inherited destroy();
end;

procedure TTypeClassLike.write(handle: THandle);
var
	hasDefaultInit, hasInstanceDeinit: boolean;
begin
	inherited write(handle);

	hasDefaultInit := defaultInit <> nil;
	fileWrite(handle, hasDefaultInit, sizeof(boolean));
	if hasDefaultInit then defaultInit.write(handle);

	hasInstanceDeinit := instanceDeinit <> nil;
	fileWrite(handle, hasInstanceDeinit, sizeof(boolean));
	if hasInstanceDeinit then instanceDeinit.write(handle);
end;


constructor TTypeClass.create(
	index_: TTypeIndex;
	attrs_: TTypeAttrs;
	typeParams_, nestedTypes_: TTypeIndexArray;

	staticInit_, staticDeinit_: TMethod;
	staticMembers_: TMemberArray;
	staticSelectors_: TSelectorArray;
	staticMethods_: TMethodArray;
	
	instanceMembers_: TMemberArray;
	instanceSelectors_: TSelectorArray;
	instanceMethods_: TMethodArray;
	defaultInit_, instanceDeinit_: TMethod;
	parents_: TTypeIndexArray;

	initSelectors_: TSelectorArray;
	initMethods_: TMethodArray);
begin
	inherited create(
		index_, attrs_, typeParams_,
		nestedTypes_, staticInit_, staticDeinit_, staticMembers_, staticSelectors_, staticMethods_,
		instanceMembers_, instanceSelectors_, instanceMethods_, defaultInit_, instanceDeinit_, parents_
	);

	initSelectors := initSelectors_;
	initMethods := initMethods_;
end;

destructor TTypeClass.destroy;
var
	i: integer;
begin
	for i := low(initMethods) to high(initMethods) do freeAndNil(initMethods[i]);

	inherited destroy();
end;

procedure TTypeClass.write(handle: THandle);
const
	id: TTypeID = TTypeID.&class;
begin
	fileWrite(handle, id, sizeof(id));

	inherited write(handle);

	writeSelectorArray(handle, initSelectors);
	writeMethodArray(handle, initMethods);
end;


procedure TTypeProtocol.write(handle: THandle);
const
	id: TTypeID = TTypeID.protocol;
begin
	fileWrite(handle, id, sizeof(id));

	inherited write(handle);
end;


constructor TTypeValueKind.TCase.create(constant_: TConstantIndex; defaultInit_: TMethod);
begin
	constant := constant_;
	defaultInit := defaultInit_;
end;

destructor TTypeValueKind.TCase.destroy;
begin
	if defaultInit <> nil then freeAndNil(defaultInit);

	inherited destroy();
end;

procedure TTypeValueKind.TCase.write(handle: THandle);
var
	hasDefaultInit: boolean;
begin
	fileWrite(handle, constant, sizeof(constant));
	hasDefaultInit := defaultInit <> nil;
	fileWrite(handle, hasDefaultInit, sizeof(hasDefaultInit));
	if hasDefaultInit then defaultInit.write(handle);
end;

constructor TTypeValueKind.create(
	index_: TTypeIndex;
	attrs_: TTypeAttrs;
	typeParams_, nestedTypes_: TTypeIndexArray;

	staticInit_, staticDeinit_: TMethod;
	staticMembers_: TMemberArray;
	staticSelectors_: TSelectorArray;
	staticMethods_: TMethodArray;
	
	instanceMembers_: TMemberArray;
	instanceSelectors_: TSelectorArray;
	instanceMethods_: TMethodArray;
	defaultInit_, instanceDeinit_: TMethod;
	parents_: TTypeIndexArray;
	
	isFlags_: boolean;
	baseType_: TTypeIndex;
	cases_: TTypeValueKind.TCaseArray);
begin
	inherited create(
		index_, attrs_, typeParams_,
		nestedTypes_, staticInit_, staticDeinit_, staticMembers_, staticSelectors_, staticMethods_,
		instanceMembers_, instanceSelectors_, instanceMethods_, defaultInit_, instanceDeinit_, parents_
	);

	isFlags := isFlags_;
	baseType := baseType_;
	cases := cases_;
end;

destructor TTypeValueKind.destroy;
var
	i: integer;
begin
	for i := low(cases) to high(cases) do
		freeAndNil(cases[i]);

	inherited destroy();
end;

procedure TTypeValueKind.write(handle: THandle);
const
	id: TTypeID = TTypeID.valueKind;
var
	len: longint;
	&case: TTypeValueKind.TCase;
begin
	fileWrite(handle, id, sizeof(id));

	inherited write(handle);
	
	fileWrite(handle, isFlags, sizeof(isFlags));
	fileWrite(handle, baseType, sizeof(baseType));

	len := length(cases);
	fileWrite(handle, len, sizeof(len));
	for &case in cases do &case.write(handle);
end;


constructor TTypeTaggedKind.TCase.create(selector_: TSelectorIndex; slots_: TTypeIndexArray; defaultInit_: TMethod);
begin
	selector := selector_;
	slots := slots_;
	defaultInit := defaultInit_;
end;

destructor TTypeTaggedKind.TCase.destroy;
begin
	if defaultInit <> nil then freeAndNil(defaultInit);

	inherited destroy();
end;

procedure TTypeTaggedKind.TCase.write(handle: THandle);
var
	hasDefaultInit: boolean;
begin
	fileWrite(handle, selector, sizeof(selector));
	writeTypeIndexArray(handle, slots);

	hasDefaultInit := defaultInit <> nil;
	fileWrite(handle, hasDefaultInit, sizeof(hasDefaultInit));
	if hasDefaultInit then defaultInit.write(handle);
end;


constructor TTypeTaggedKind.create(
	index_: TTypeIndex;
	attrs_: TTypeAttrs;
	typeParams_, nestedTypes_: TTypeIndexArray;

	staticInit_, staticDeinit_: TMethod;
	staticMembers_: TMemberArray;
	staticSelectors_: TSelectorArray;
	staticMethods_: TMethodArray;
	
	instanceMembers_: TMemberArray;
	instanceSelectors_: TSelectorArray;
	instanceMethods_: TMethodArray;
	defaultInit_, instanceDeinit_: TMethod;
	parents_: TTypeIndexArray;
	
	isFlags_: boolean;
	cases_: TTypeTaggedKind.TCaseArray);
begin
	inherited create(
		index_, attrs_, typeParams_,
		nestedTypes_, staticInit_, staticDeinit_, staticMembers_, staticSelectors_, staticMethods_,
		instanceMembers_, instanceSelectors_, instanceMethods_, defaultInit_, instanceDeinit_, parents_
	);

	isFlags := isFlags_;
	cases := cases_;
end;

destructor TTypeTaggedKind.destroy;
var
	i: integer;
begin
	for i := low(cases) to high(cases) do
		freeAndNil(cases[i]);

	inherited destroy();
end;

procedure TTypeTaggedKind.write(handle: THandle);
const
	id: TTypeID = TTypeID.taggedKind;
var
	len: longint;
	&case: TTypeTaggedKind.TCase;
begin
	fileWrite(handle, id, sizeof(id));

	inherited write(handle);
	
	fileWrite(handle, isFlags, sizeof(isFlags));

	len := length(cases);
	fileWrite(handle, len, sizeof(len));
	for &case in cases do &case.write(handle);
end;

end.