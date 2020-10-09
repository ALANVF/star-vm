program star_vm_test;

uses
	SysUtils,
	StringUtils,
	FileUtils,
	Star,
	Star.Bytecode,
	Star.Bytecode.CodeSection,
	Star.Bytecode.Op,
	Star.Bytecode.Opcode,
	Star.Bytecode.Member,
	Star.Bytecode.Method,
	Star.Bytecode.Builder,
	Star.Bytecode.&Type;

var
	bf: TBinaryFile;
	main: TTypeModule;
	method: TMethod;
	builder: TMethodBuilder;

begin
	{-----------------------------------------------}

	writeln('module Main is main {');

	method := TMethod.create(
		0,
		[TMethodAttr.static, TMethodAttr.main],
		[],
		[],
		1,
		[],
		[]
	);

	main := TTypeModule.create(
		3,
		'Main',
		[TTypeAttr.main],
		[],
		[],
		nil,
		nil,
		[],
		['main'],
		[method]
	);

	builder := TMethodBuilder.create(method);
	
	with builder do begin
		pushConst(1);
		pushConst(2);
		add();
		inspectStack();
		retVoid();
	end;

	writeln(method.dump());

	builder.destroy();

	writeln('}');

	bf := TBinaryFile.create('out.blh');
	bf.specialize writeIO<TTypeModule>(main);
	bf.close();
	bf.destroy();

	//method.destroy();
	main.destroy();
end.