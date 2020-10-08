unit StarBytecodeType;

{$SCOPEDENUMS+}
{$MINENUMSIZE 1}
{$T+}

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
	
	TTypeAttr = (hidden, uncounted, strong, main);
	TTypeAttrs = set of TTypeAttr;

	TType = class abstract(IBinaryIOWrite)
	public
		index: TTypeIndex;
		name: shortstring;
		attrs: TTypeAttrs;
		typeParams: TTypeIndexArray;

		constructor create(index_: TTypeIndex; name_: shortstring; attrs_: TTypeAttrs; typeParams_: TTypeIndexArray);

		procedure writeToBinary(const bf: TBinaryFile); virtual;
	end;

	TTypeParam = class(TType)
	public
		parents: TTypeIndexArray;
		{hasCond: boolean;
		cond: ...}

		constructor create(index_: TTypeIndex; name_: shortstring; attrs_: TTypeAttrs; typeParams_, parents_: TTypeIndexArray);

		procedure writeToBinary(const bf: TBinaryFile); override;
	end;

	TTypeErased = class(TType)
	public
		procedure writeToBinary(const bf: TBinaryFile); override;
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
			name_: shortstring;
			attrs_: TTypeAttrs;
			typeParams_, nestedTypes_: TTypeIndexArray;

			staticInit_, staticDeinit_: TMethod;
			staticMembers_: TMemberArray;
			staticSelectors_: TSelectorArray;
			staticMethods_: TMethodArray);
		destructor destroy; override;

		procedure writeToBinary(const bf: TBinaryFile); override;
	end;

	TTypeModule = class(TTypeNamespace)
	public
		procedure writeToBinary(const bf: TBinaryFile); override;
	end;

	TTypeDispatchable = class abstract(TTypeNamespace)
	public
		instanceMembers: TMemberArray;
		instanceSelectors: TSelectorArray;
		instanceMethods: TMethodArray;

		constructor create(
			index_: TTypeIndex;
			name_: shortstring;
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

		procedure writeToBinary(const bf: TBinaryFile); override;
	end;
	
	TTypeClassLike = class abstract(TTypeDispatchable)
	public
		defaultInit, instanceDeinit: TMethod; {NULLABLE}
		parents: TTypeIndexArray;

		constructor create(
			index_: TTypeIndex;
			name_: shortstring;
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

		procedure writeToBinary(const bf: TBinaryFile); override;
	end;

	TTypeClass = class(TTypeClassLike)
	public
		initSelectors: TSelectorArray;
		initMethods: TMethodArray;

		constructor create(
			index_: TTypeIndex;
			name_: shortstring;
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

		procedure writeToBinary(const bf: TBinaryFile); override;
	end;

	TTypeProtocol = class(TTypeClassLike)
	public
		procedure writeToBinary(const bf: TBinaryFile); override;
	end;

	TTypeKind = class abstract(TTypeClassLike)
	public
		isFlags: boolean;
	end;

	TTypeValueKind = class(TTypeKind)
	public
		type
			TCase = class(IBinaryIOWrite)
			public
				constant: TConstantIndex;
				defaultInit: TMethod; {NULLABLE}

				constructor create(constant_: TConstantIndex; defaultInit_: TMethod);
				destructor destroy; override;

				procedure writeToBinary(const bf: TBinaryFile);
			end;
			TCaseArray = array of TCase;
		
		var
			baseType: TTypeIndex;
			cases: TCaseArray;
		
		constructor create(
			index_: TTypeIndex;
			name_: shortstring;
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

		procedure writeToBinary(const bf: TBinaryFile); override;
	end;

	TTypeTaggedKind = class(TTypeKind)
	public
		type
			TCase = class(IBinaryIOWrite)
			public
				selector: TSelectorIndex;
				slots: TTypeIndexArray;
				defaultInit: TMethod; {NULLABLE}

				constructor create(selector_: TSelectorIndex; slots_: TTypeIndexArray; defaultInit_: TMethod);
				destructor destroy; override;

				procedure writeToBinary(const bf: TBinaryFile);
			end;
			TCaseArray = array of TCase;
		
		var
			cases: TCaseArray;
		
		constructor create(
			index_: TTypeIndex;
			name_: shortstring;
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

		procedure writeToBinary(const bf: TBinaryFile); override;
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

constructor TType.create(index_: TTypeIndex; name_: shortstring; attrs_: TTypeAttrs; typeParams_: TTypeIndexArray);
begin
	index := index_;
	name := name_;
	attrs := attrs_;
	typeParams := typeParams_;
end;

procedure TType.writeToBinary(const bf: TBinaryFile);
begin
	bf.write(index);
	bf.write(name);
	bf.writeOnly(attrs, sizeof(attrs));
	bf.writeAll(typeParams);
end;


constructor TTypeParam.create(index_: TTypeIndex; name_: shortstring; attrs_: TTypeAttrs; typeParams_, parents_: TTypeIndexArray);
begin
	inherited create(index_, name_, attrs_, typeParams_);

	parents := parents_;
end;


procedure TTypeParam.writeToBinary(const bf: TBinaryFile);
begin
	bf.specialize write<TTypeID>(TTypeID.param);
	
	inherited writeToBinary(bf);
	
	bf.writeAll(parents);
end;


procedure TTypeErased.writeToBinary(const bf: TBinaryFile);
begin
	bf.specialize write<TTypeID>(TTypeID.erased);

	inherited writeToBinary(bf);
end;


constructor TTypeNamespace.create(
	index_: TTypeIndex;
	name_: shortstring;
	attrs_: TTypeAttrs;
	typeParams_, nestedTypes_: TTypeIndexArray;

	staticInit_, staticDeinit_: TMethod;
	staticMembers_: TMemberArray;
	staticSelectors_: TSelectorArray;
	staticMethods_: TMethodArray);
begin
	inherited create(index_, name_, attrs_, typeParams_);

	nestedTypes := nestedTypes_;
	staticInit := staticInit_;
	staticDeinit := staticDeinit_;
	staticMembers := staticMembers_;
	staticSelectors := staticSelectors_;
	staticMethods := staticMethods_;
end;

destructor TTypeNamespace.destroy;
var
	i: longint;
begin
	if staticInit <> nil then freeAndNil(staticInit);
	if staticDeinit <> nil then freeAndNil(staticDeinit);
	for i := low(staticMembers) to high(staticMembers) do freeAndNil(staticMembers[i]);
	for i := low(staticMethods) to high(staticMethods) do freeAndNil(staticMethods[i]);

	inherited destroy();
end;

procedure TTypeNamespace.writeToBinary(const bf: TBinaryFile);
var
	hasStaticInit, hasStaticDeinit: boolean;
begin
	inherited writeToBinary(bf);
	
	bf.writeAll(nestedTypes);
	
	hasStaticInit := staticInit <> nil;
	bf.write(hasStaticInit);
	if hasStaticInit then
		bf.specialize writeIO<TMethod>(staticInit);

	hasStaticDeinit := staticDeinit <> nil;
	bf.write(hasStaticDeinit);
	if hasStaticDeinit then
		bf.specialize writeIO<TMethod>(staticDeinit);
	
	bf.specialize writeAllIO<TMember>(staticMembers);
	bf.writeAll(staticSelectors);
	bf.specialize writeAllIO<TMethod>(staticMethods);
end;


procedure TTypeModule.writeToBinary(const bf: TBinaryFile);
begin
	bf.specialize write<TTypeID>(TTypeID.module);

	inherited writeToBinary(bf);
end;


constructor TTypeDispatchable.create(
	index_: TTypeIndex;
	name_: shortstring;
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
	inherited create(
		index_, name_, attrs_, typeParams_,
		nestedTypes_, staticInit_, staticDeinit_, staticMembers_, staticSelectors_, staticMethods_
	);

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

procedure TTypeDispatchable.writeToBinary(const bf: TBinaryFile);
begin
	inherited writeToBinary(bf);
	
	bf.specialize writeAllIO<TMember>(instanceMembers);
	bf.writeAll(instanceSelectors);
	bf.specialize writeAllIO<TMethod>(instanceMethods);
end;


constructor TTypeClassLike.create(
	index_: TTypeIndex;
	name_: shortstring;
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
	inherited create(
		index_, name_, attrs_, typeParams_,
		nestedTypes_, staticInit_, staticDeinit_, staticMembers_, staticSelectors_, staticMethods_,
		instanceMembers_, instanceSelectors_, instanceMethods_
	);

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

procedure TTypeClassLike.writeToBinary(const bf: TBinaryFile);
var
	hasDefaultInit, hasInstanceDeinit: boolean;
begin
	inherited writeToBinary(bf);

	hasDefaultInit := defaultInit <> nil;
	bf.write(hasDefaultInit);
	if hasDefaultInit then
		bf.specialize writeIO<TMethod>(defaultInit);

	hasInstanceDeinit := instanceDeinit <> nil;
	bf.write(hasInstanceDeinit);
	if hasInstanceDeinit then
		bf.specialize writeIO<TMethod>(instanceDeinit);
end;


constructor TTypeClass.create(
	index_: TTypeIndex;
	name_: shortstring;
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
		index_, name_, attrs_, typeParams_,
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

procedure TTypeClass.writeToBinary(const bf: TBinaryFile);
begin
	bf.specialize write<TTypeID>(TTypeID.&class);

	inherited writeToBinary(bf);

	bf.writeAll(initSelectors);
	bf.specialize writeAllIO<TMethod>(initMethods);
end;


procedure TTypeProtocol.writeToBinary(const bf: TBinaryFile);
begin
	bf.specialize write<TTypeID>(TTypeID.protocol);

	inherited writeToBinary(bf);
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

procedure TTypeValueKind.TCase.writeToBinary(const bf: TBinaryFile);
var
	hasDefaultInit: boolean;
begin
	bf.write(constant);
	
	hasDefaultInit := defaultInit <> nil;
	bf.write(hasDefaultInit);
	if hasDefaultInit then
		bf.specialize writeIO<TMethod>(defaultInit);
end;


constructor TTypeValueKind.create(
	index_: TTypeIndex;
	name_: shortstring;
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
		index_, name_, attrs_, typeParams_,
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

procedure TTypeValueKind.writeToBinary(const bf: TBinaryFile);
begin
	bf.specialize write<TTypeID>(TTypeID.valueKind);

	inherited writeToBinary(bf);
	
	bf.write(isFlags);
	bf.write(baseType);
	bf.specialize writeAllIO<TTypeValueKind.TCase>(cases);
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

procedure TTypeTaggedKind.TCase.writeToBinary(const bf: TBinaryFile);
var
	hasDefaultInit: boolean;
begin
	bf.write(selector);
	
	bf.writeAll(slots);

	hasDefaultInit := defaultInit <> nil;
	bf.write(hasDefaultInit);
	if hasDefaultInit then
		bf.specialize writeIO<TMethod>(defaultInit);
end;


constructor TTypeTaggedKind.create(
	index_: TTypeIndex;
	name_: shortstring;
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
		index_, name_, attrs_, typeParams_,
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

procedure TTypeTaggedKind.writeToBinary(const bf: TBinaryFile);
begin
	bf.specialize write<TTypeID>(TTypeID.taggedKind);

	inherited writeToBinary(bf);
	
	bf.write(isFlags);
	bf.specialize writeAllIO<TTypeTaggedKind.TCase>(cases);
end;

end.