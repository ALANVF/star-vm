unit Star.Bytecode.Builder;

{$modeSwitch ARRAYOPERATORS}
{$modeSwitch ADVANCEDRECORDS}

interface

uses
	Star.Bytecode.Index,
	Star.Bytecode.Opcode,
	Star.Bytecode.Op,
	Star.Bytecode.Selector,
	Star.Bytecode.Member,
	Star.Bytecode.CodeSection,
	Star.Bytecode.Method,
	Star.Bytecode.&Type;

type
	TMethodBuilder = class;

	TPushTrapNBuilder = record
		_builder: TMethodBuilder;
		_trySec: TCodeSectionIndex;
		_cases: TTrapCases;
	
		procedure catch(reg: TRegisterIndex; sec: TCodeSectionIndex);

		procedure done;
	end;

	TMethodBuilder = class
	private
		procedure emptyOp(opcode: TOpcode);

		procedure op_reg(opcode: TOpcode; v1: TRegisterIndex);

		procedure op_member(opcode: TOpcode; v1: TMemberIndex);

		procedure op_staticMember(opcode: TOpcode; v1: TTypeIndex; v2: TMemberIndex);

		procedure op_step(opcode: TOpcode; v1: TRegisterIndex);

		procedure op_sec(opcode: TOpcode; v1: TCodeSectionIndex);

		procedure op_sec_either(opcode: TOpcode; v1, v2: TCodeSectionIndex);

		procedure op_type(opcode: TOpcode; v1: TTypeIndex);

	public
		method: TMethod;
		secIndex, opIndex: word;

		constructor create(const method_: TMethod);

		procedure insertOp(const op: TOp);

		{ OPS }
		
		procedure retain;
		
		procedure release;

		procedure pushConst(index: TConstantIndex);
		
		procedure pushReg(index: TRegisterIndex);
		
		procedure pushMember(index: TMemberIndex);
		
		procedure pushStaticMember(&type: TTypeIndex; index: TMemberIndex);

		procedure setReg(index: TRegisterIndex);
		
		procedure setMember(index: TMemberIndex);
		
		procedure setStaticMember(&type: TTypeIndex; index: TMemberIndex);

		procedure swapReg(index1, index2: TRegisterIndex);

		procedure pop;
		
		procedure popN(count: word);
		
		procedure clear;
		
		procedure swap;
		
		procedure add;
		
		procedure sub;
		
		procedure mult;
		
		procedure pow;
		
		procedure &div;
		
		procedure idiv;
		
		procedure &mod;
		
		procedure mod0;
		
		procedure &and;
		
		procedure &or;
		
		procedure &xor;
		
		procedure &shl;
		
		procedure &shr;
		
		procedure eq;
		
		procedure ne;
		
		procedure gt;
		
		procedure ge;
		
		procedure lt;
		
		procedure le;

		procedure neg;
		
		procedure &not;
		
		procedure compl;
		
		procedure truthy;
		
		procedure incr(index: TRegisterIndex);
		
		procedure decr(index: TRegisterIndex);

		procedure consecutive(kind: TConsecutiveKind; sections: TCodeSectionIndexArray);

		procedure give;

		procedure pushSec(sec: TCodeSectionIndex);
		
		procedure pushSec_if(sec: TCodeSectionIndex);
		
		procedure pushSec_either(trueSec, falseSec: TCodeSectionIndex);
		
		procedure pushSec_table(sections: TCodeSectionIndexArray);

		{TODO}
		//procedure pushSec_lazyTable
		
		procedure changeSec(sec: TCodeSectionIndex);
		
		procedure changeSec_if(sec: TCodeSectionIndex);
		
		procedure changeSec_either(trueSec, falseSec: TCodeSectionIndex);
		
		procedure popSec;
		
		procedure popNSec(depth: word);
		
		procedure popSecAndChange(sec: TCodeSectionIndex);
		
		procedure popNSecAndChange(depth: word; sec: TCodeSectionIndex);
		
		procedure unreachable;

		procedure ret;
		
		procedure retVoid;

		procedure pushTrap(trySec: TCodeSectionIndex; dest: TRegisterIndex; catchSec: TCodeSectionIndex);
		
		procedure pushTrapN(trySec: TCodeSectionIndex; tcases: TTrapCases); overload;
		function pushTrapN(trySec: TCodeSectionIndex): TPushTrapNBuilder; overload;
		
		procedure popTrap;
		
		procedure panic;

		procedure staticSend(&type: TTypeIndex; sel: TSelectorIndex);
		
		procedure objSend(sel: TSelectorIndex);

		procedure cast(&type: TTypeIndex);

		procedure isa(&type: TTypeIndex);

		procedure getKindID;
		
		procedure getKindSlot(slot: byte);
		
		procedure getKindValue;

		procedure inspectEverything;
		
		procedure inspectRegs;
		
		procedure inspectStack;
		
		procedure inspectCallStack;
		
		procedure inspectCodeSectionStack;
		
		procedure inspectReg(index: TRegisterIndex);
		
		procedure inspectConst(index: TConstantIndex);
		
		procedure inspectType(index: TTypeIndex);
	end;

implementation

procedure TPushTrapNBuilder.catch(reg: TRegisterIndex; sec: TCodeSectionIndex);
var
	&case: TTrapCase;
begin
	with &case do begin
		destReg := reg;
		section := sec;
	end;

	_cases += [&case];
end;


procedure TPushTrapNBuilder.done;
var
	op: TOp;
begin
	with op do begin
		opcode := TOpcode.pushTrapN;
		with pushTrapN do begin
			trySection := _trySec;
			new(cases);
			cases^ := _cases;
		end;
	end;

	_builder.insertOp(op);
end;


constructor TMethodBuilder.create(const method_: TMethod);
begin
	method := method_;
	secIndex := 0;
	opIndex := 0;

	if method.sections = nil then
		method.sections := [TCodeSection.create()]
	else if length(method.sections) = 0 then
		method.sections += [TCodeSection.create()];
end;


procedure TMethodBuilder.emptyOp(opcode: TOpcode);
var
	op: TOp;
begin
	op.opcode := opcode;

	insertOp(op);
end;


procedure TMethodBuilder.op_reg(opcode: TOpcode; v1: TRegisterIndex);
var
	op: TOp;
begin
	op.opcode := opcode;
	op.reg := v1;
	
	insertOp(op);
end;


procedure TMethodBuilder.op_member(opcode: TOpcode; v1: TMemberIndex);
var
	op: TOp;
begin
	op.opcode := opcode;
	op.member := v1;
	
	insertOp(op);
end;


procedure TMethodBuilder.op_staticMember(opcode: TOpcode; v1: TTypeIndex; v2: TMemberIndex);
var
	op: TOp;
begin
	op.opcode := opcode;
	op.staticMember.&type := v1;
	op.staticMember.member := v2;

	insertOp(op);
end;


procedure TMethodBuilder.op_step(opcode: TOpcode; v1: TRegisterIndex);
var
	op: TOp;
begin
	op.opcode := opcode;
	op.step := v1;
	
	insertOp(op);
end;


procedure TMethodBuilder.op_sec(opcode: TOpcode; v1: TCodeSectionIndex);
var
	op: TOp;
begin
	op.opcode := opcode;
	op.sec := v1;
	
	insertOp(op);
end;


procedure TMethodBuilder.op_sec_either(opcode: TOpcode; v1, v2: TCodeSectionIndex);
var
	op: TOp;
begin
	op.opcode := opcode;
	with op.sec_either do begin
		trueSection := v1;
		falseSection := v2;
	end;
	
	insertOp(op);
end;


procedure TMethodBuilder.op_type(opcode: TOpcode; v1: TTypeIndex);
var
	op: TOp;
begin
	op.opcode := opcode;
	op.&type := v1;

	insertOp(op);
end;


procedure TMethodBuilder.insertOp(const op: TOp);
begin
	insert({source}op, {target}method.sections[secIndex].ops, {index}opIndex);
	inc(opIndex);
end;


procedure TMethodBuilder.retain;
begin
	emptyOp(TOpcode.retain);
end;


procedure TMethodBuilder.release;
begin
	emptyOp(TOpcode.release);
end;


procedure TMethodBuilder.pushConst(index: TConstantIndex);
var
	op: TOp;
begin
	with op do begin
		opcode := TOpcode.pushConst;
		pushConst := index;
	end;

	insertOp(op);
end;


procedure TMethodBuilder.pushReg(index: TRegisterIndex);
begin
	op_reg(TOpcode.pushReg, index);
end;


procedure TMethodBuilder.pushMember(index: TMemberIndex);
begin
	op_member(TOpcode.pushMember, index);
end;


procedure TMethodBuilder.pushStaticMember(&type: TTypeIndex; index: TMemberIndex);
begin
	op_staticMember(TOpcode.pushStaticMember, &type, index);
end;


procedure TMethodBuilder.setReg(index: TRegisterIndex);
begin
	op_reg(TOpcode.setReg, index);
end;

procedure TMethodBuilder.setMember(index: TMemberIndex);
begin
	op_member(TOpcode.setMember, index);
end;


procedure TMethodBuilder.setStaticMember(&type: TTypeIndex; index: TMemberIndex);
begin
	op_staticMember(TOpcode.setStaticMember, &type, index);
end;


procedure TMethodBuilder.swapReg(index1, index2: TRegisterIndex);
var
	op: TOp;
begin
	with op do begin
		opcode := TOpcode.swapReg;
		swapReg.reg1 := index1;
		swapReg.reg2 := index2;
	end;

	insertOp(op);
end;


procedure TMethodBuilder.pop;
begin
	emptyOp(TOpcode.pop);
end;


procedure TMethodBuilder.popN(count: word);
var
	op: TOp;
begin
	op.opcode := TOpcode.popN;
	op.popN := count;

	insertOp(op);
end;


procedure TMethodBuilder.clear;
begin
	emptyOp(TOpcode.clear);
end;


procedure TMethodBuilder.swap;
begin
	emptyOp(TOpcode.swap);
end;


procedure TMethodBuilder.add;
begin
	emptyOp(TOpcode.add);
end;


procedure TMethodBuilder.sub;
begin
	emptyOp(TOpcode.sub);
end;


procedure TMethodBuilder.mult;
begin
	emptyOp(TOpcode.mult);
end;


procedure TMethodBuilder.pow;
begin
	emptyOp(TOpcode.pow);
end;


procedure TMethodBuilder.&div;
begin
	emptyOp(TOpcode.&div);
end;


procedure TMethodBuilder.idiv;
begin
	emptyOp(TOpcode.idiv);
end;


procedure TMethodBuilder.&mod;
begin
	emptyOp(TOpcode.&mod);
end;


procedure TMethodBuilder.mod0;
begin
	emptyOp(TOpcode.mod0);
end;


procedure TMethodBuilder.&and;
begin
	emptyOp(TOpcode.&and);
end;


procedure TMethodBuilder.&or;
begin
	emptyOp(TOpcode.&or);
end;


procedure TMethodBuilder.&xor;
begin
	emptyOp(TOpcode.&xor);
end;


procedure TMethodBuilder.&shl;
begin
	emptyOp(TOpcode.&shl);
end;


procedure TMethodBuilder.&shr;
begin
	emptyOp(TOpcode.&shr);
end;


procedure TMethodBuilder.eq;
begin
	emptyOp(TOpcode.eq);
end;


procedure TMethodBuilder.ne;
begin
	emptyOp(TOpcode.ne);
end;


procedure TMethodBuilder.gt;
begin
	emptyOp(TOpcode.gt);
end;


procedure TMethodBuilder.ge;
begin
	emptyOp(TOpcode.ge);
end;


procedure TMethodBuilder.lt;
begin
	emptyOp(TOpcode.lt);
end;


procedure TMethodBuilder.le;
begin
	emptyOp(TOpcode.le);
end;


procedure TMethodBuilder.neg;
begin
	emptyOp(TOpcode.neg);
end;


procedure TMethodBuilder.&not;
begin
	emptyOp(TOpcode.&not);
end;


procedure TMethodBuilder.compl;
begin
	emptyOp(TOpcode.compl);
end;


procedure TMethodBuilder.truthy;
begin
	emptyOp(TOpcode.truthy);
end;


procedure TMethodBuilder.incr(index: TRegisterIndex);
begin
	op_step(TOpcode.incr, index);
end;


procedure TMethodBuilder.decr(index: TRegisterIndex);
begin
	op_step(TOpcode.decr, index);
end;


procedure TMethodBuilder.consecutive(kind: TConsecutiveKind; sections: TCodeSectionIndexArray);
var
	op: TOp;
begin
	with op do begin
		opcode := TOpcode.consecutive;
		consecutive.kind := kind;
		new(consecutive.sections);
		consecutive.sections^ := sections;
	end;

	insertOp(op);
end;


procedure TMethodBuilder.give;
begin
	emptyOp(TOpcode.give);
end;


procedure TMethodBuilder.pushSec(sec: TCodeSectionIndex);
begin
	op_sec(TOpcode.pushSec, sec);
end;


procedure TMethodBuilder.pushSec_if(sec: TCodeSectionIndex);
begin
	op_sec(TOpcode.pushSec_if, sec);
end;


procedure TMethodBuilder.pushSec_either(trueSec, falseSec: TCodeSectionIndex);
begin
	op_sec_either(TOpcode.pushSec_either, trueSec, falseSec);
end;


procedure TMethodBuilder.pushSec_table(sections: TCodeSectionIndexArray);
var
	op: TOp;
begin
	with op do begin
		opcode := TOpcode.pushSec_table;
		new(pushSec_table);
		pushSec_table^ := sections;
	end;

	insertOp(op);
end;

procedure TMethodBuilder.changeSec(sec: TCodeSectionIndex);
begin
	op_sec(TOpcode.changeSec, sec);
end;


procedure TMethodBuilder.changeSec_if(sec: TCodeSectionIndex);
begin
	op_sec(TOpcode.changeSec_if, sec);
end;


procedure TMethodBuilder.changeSec_either(trueSec, falseSec: TCodeSectionIndex);
begin
	op_sec_either(TOpcode.changeSec_either, trueSec, falseSec);
end;


procedure TMethodBuilder.popSec;
begin
	emptyOp(TOpcode.popSec);
end;


procedure TMethodBuilder.popNSec(depth: word);
var
	op: TOp;
begin
	op.opcode := TOpcode.popNSec;
	op.popNSec := depth;

	insertOp(op);
end;


procedure TMethodBuilder.popSecAndChange(sec: TCodeSectionIndex);
begin
	op_sec(TOpcode.popSecAndChange, sec);
end;


procedure TMethodBuilder.popNSecAndChange(depth: word; sec: TCodeSectionIndex);
var
	op: TOp;
begin
	with op do begin
		opcode := TOpcode.popNSecAndChange;
		popNSecAndChange.depth := depth;
		popNSecAndChange.section := sec;
	end;

	insertOp(op);
end;


procedure TMethodBuilder.unreachable;
begin
	emptyOp(TOpcode.unreachable);
end;


procedure TMethodBuilder.ret;
begin
	emptyOp(TOpcode.ret);
end;


procedure TMethodBuilder.retVoid;
begin
	emptyOp(TOpcode.retVoid);
end;


procedure TMethodBuilder.pushTrap(trySec: TCodeSectionIndex; dest: TRegisterIndex; catchSec: TCodeSectionIndex);
var
	op: TOp;
begin
	with op do begin
		opcode := TOpcode.pushTrap;
		with pushTrap do begin
			trySection := trySec;
			catchDest := dest;
			catchSection := catchSec;
		end;
	end;

	insertOp(op);
end;

		
procedure TMethodBuilder.pushTrapN(trySec: TCodeSectionIndex; tcases: TTrapCases); overload;
var
	op: TOp;
begin
	with op do begin
		opcode := TOpcode.pushTrapN;
		with pushTrapN do begin
			trySection := trySec;
			new(cases);
			cases^ := tcases;
		end;
	end;

	insertOp(op);
end;

function TMethodBuilder.pushTrapN(trySec: TCodeSectionIndex): TPushTrapNBuilder; overload;
begin
	result._builder := self;
	result._trySec := trySec;
	result._cases := [];
end;


procedure TMethodBuilder.popTrap;
begin
	emptyOp(TOpcode.popTrap);
end;


procedure TMethodBuilder.panic;
begin
	emptyOp(TOpcode.panic);
end;


procedure TMethodBuilder.staticSend(&type: TTypeIndex; sel: TSelectorIndex);
var
	op: TOp;
begin
	with op do begin
		opcode := TOpcode.staticSend;
		staticSend.&type := &type;
		staticSend.selector := sel;
	end;

	insertOp(op);
end;


procedure TMethodBuilder.objSend(sel: TSelectorIndex);
var
	op: TOp;
begin
	op.opcode := TOpcode.objSend;
	op.objSend := sel;

	insertOp(op);
end;


procedure TMethodBuilder.cast(&type: TTypeIndex);
begin
	op_type(TOpcode.cast, &type);
end;


procedure TMethodBuilder.isa(&type: TTypeIndex);
begin
	op_type(TOpcode.isa, &type);
end;


procedure TMethodBuilder.getKindID;
begin
	emptyOp(TOpcode.getKindID);
end;


procedure TMethodBuilder.getKindSlot(slot: byte);
var
	op: TOp;
begin
	with op do begin
		opcode := TOpcode.getKindSlot;
		getKindSlot := slot;
	end;

	insertOp(op);
end;


procedure TMethodBuilder.getKindValue;
begin
	emptyOp(TOpcode.getKindValue);
end;


procedure TMethodBuilder.inspectEverything;
var
	op: TOp;
begin
	with op do begin
		opcode := TOpcode.debug;
		debug.kind := TDebugKind.inspectEverything;
	end;

	insertOp(op);
end;


procedure TMethodBuilder.inspectRegs;
var
	op: TOp;
begin
	with op do begin
		opcode := TOpcode.debug;
		debug.kind := TDebugKind.inspectRegs;
	end;

	insertOp(op);
end;


procedure TMethodBuilder.inspectStack;
var
	op: TOp;
begin
	with op do begin
		opcode := TOpcode.debug;
		debug.kind := TDebugKind.inspectStack;
	end;

	insertOp(op);
end;


procedure TMethodBuilder.inspectCallStack;
var
	op: TOp;
begin
	with op do begin
		opcode := TOpcode.debug;
		debug.kind := TDebugKind.inspectCallStack;
	end;

	insertOp(op);
end;


procedure TMethodBuilder.inspectCodeSectionStack;
var
	op: TOp;
begin
	with op do begin
		opcode := TOpcode.debug;
		debug.kind := TDebugKind.inspectCodeSectionStack;
	end;

	insertOp(op);
end;


procedure TMethodBuilder.inspectReg(index: TRegisterIndex);
var
	op: TOp;
begin
	with op do begin
		opcode := TOpcode.debug;
		with debug do begin
			kind := TDebugKind.inspectReg;
			r := index;
		end;
	end;

	insertOp(op);
end;


procedure TMethodBuilder.inspectConst(index: TConstantIndex);
var
	op: TOp;
begin
	with op do begin
		opcode := TOpcode.debug;
		with debug do begin
			kind := TDebugKind.inspectConst;
			c := index;
		end;
	end;

	insertOp(op);
end;


procedure TMethodBuilder.inspectType(index: TTypeIndex);
var
	op: TOp;
begin
	with op do begin
		opcode := TOpcode.debug;
		with debug do begin
			kind := TDebugKind.inspectType;
			t := index;
		end;
	end;

	insertOp(op);
end;

end.