program star_vm_test;

uses
	SysUtils,
	StringUtils,
	FileUtils,
	Star,
	StarBytecode,
	StarBytecodeCodeSection,
	StarBytecodeOp,
	StarBytecodeOpcode,
	StarBytecodeMember,
	StarBytecodeMethod,
	StarBytecodeBuilder,
	StarBytecodeType;

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

	bf := TBinaryFile.create('out.starbm'{, fmOpenWrite});
	bf.specialize writeIO<TTypeModule>(main);
	bf.close();
	bf.destroy();

	//method.destroy();
	main.destroy();
end.