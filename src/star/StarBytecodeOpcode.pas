unit StarBytecodeOpcode;

{$SCOPEDENUMS+}
{$MINENUMSIZE 1}

interface

type
	TOpcode = (
		retain,                { ... }
		release,               { ... }
		
		pushConst,             { const }
		pushReg,               { reg }
		pushMember,            { value.member }
		pushStaticMember,      { Type.member }

		setReg,                { dest = value }
		setMember,             { dest.member = value }
		setStaticMember,       { Type.member = value }

		swapReg,               { TBD }

		pop,                   { ... }
		popN,                  { ... }
		clear,                 { ... }
		swap,                  { ... }
		
		add,                   { dest = value1 + value2 }
		sub,                   { dest = value1 - value2 }
		mult,                  { dest = value1 * value2 }
		pow,                   { dest = value1 ** value2 }
		&div,                  { dest = value1 / value2 }
		idiv,                  { dest = value1 // value2 }
		&mod,                  { dest = value1 % value2 }
		mod0,                  { dest = value1 %% value2 }
		&and,                  { dest = value1 & value2 }
		&or,                   { dest = value1 | value2 }
		&xor,                  { dest = value1 ^ value2 }
		&shl,                  { dest = value1 << value2 }
		&shr,                  { dest = value1 >> value2 }
		eq,                    { dest = value1 ?= value2 }
		ne,                    { dest = value1 != value2 }
		gt,                    { dest = value1 > value2 }
		ge,                    { dest = value1 >= value2 }
		lt,                    { dest = value1 < value2 }
		le,                    { dest = value1 <= value2 }

		neg,                   { dest = -value }
		&not,                  { dest = !value }
		compl,                 { dest = ~value }
		truthy,                { dest = value? }
		incr,                  { dest++ }
		decr,                  { dest-- }

		consecutive,           { dest = value1 <op> value2 <op> value3 <op> ... valueN  WHERE  op = && OR || OR ^^ }
		give,                  { ... }                                                                               // consecutive CHOICE TERMINATOR

		pushSec,               { ... }
		pushSec_if,            { if cond ... }
		pushSec_either,        { if cond ... else ... }
		pushSec_table,         { match ... at ... else ... }
		
		changeSec,             { ... }                                                                               // SECTION TERMINATOR
		changeSec_if,          { ... }                                                                               // SECTION TERMINATOR
		changeSec_either,      { ... }                                                                               // SECTION TERMINATOR
		
		popSec,                { ... }                                                                               // SECTION TERMINATOR
		popNSec,               { ... }                                                                               // MULTI-SECTION TERMINATOR
		popSecAndChange,       { ... }                                                                               // MULTI-SECTION TERMINATOR
		popNSecAndChange,      { ... }                                                                               // MULTI-SECTION TERMINATOR
		
		unreachable,           { ... }                                                                               // GLOBAL TERMINATOR

		ret,                   { return value }                                                                      // METHOD TERMINATOR
		retVoid,               { return }                                                                            // METHOD TERMINATOR

		pushTrap,              { try ... catch ... }
		popTrap,               { ... }                                                                               // TRAP TERMINATOR
		panic,                 { panic value }                                                                       // MULTI-SECTION TERMINATOR

		staticSend,            { dest = Type[msg...] }
		objSend,               { dest = value[msg...] }

		cast,                  { dest = value[Type] }
		isa,                   { dest = value of Type }

		getKindID,             { ... }
		getKindSlot,           { ... }
		getKindValue,          { ... }

		debug                  { ... }
	);

function dumpOpcodeName(opcode: TOpcode): string;

implementation

function dumpOpcodeName(opcode: TOpcode): string;
begin
	case opcode of
		TOpcode.retain: result := 'retain';
		TOpcode.release: result := 'release';
		TOpcode.pushConst..TOpcode.pushStaticMember: result := 'push';
		TOpcode.setReg..TOpcode.setStaticMember: result := 'set';
		TOpcode.swapReg: result := 'swap_reg';
		TOpcode.pop, TOpcode.popN: result := 'pop';
		TOpcode.clear: result := 'clear';
		TOpcode.swap: result := 'swap';
		TOpcode.add: result := 'add';
		TOpcode.sub: result := 'sub';
		TOpcode.mult: result := 'mult';
		TOpcode.pow: result := 'pow';
		TOpcode.&div: result := 'div';
		TOpcode.idiv: result := 'idiv';
		TOpcode.&mod: result := 'mod';
		TOpcode.mod0: result := 'mod0';
		TOpcode.&and: result := 'and';
		TOpcode.&or: result := 'or';
		TOpcode.&xor: result := 'xor';
		TOpcode.&shl: result := 'shl';
		TOpcode.&shr: result := 'shr';
		TOpcode.eq: result := 'eq';
		TOpcode.ne: result := 'ne';
		TOpcode.gt: result := 'gt';
		TOpcode.ge: result := 'ge';
		TOpcode.lt: result := 'lt';
		TOpcode.le: result := 'le';
		TOpcode.neg: result := 'neg';
		TOpcode.&not: result := 'not';
		TOpcode.compl: result := 'compl';
		TOpcode.truthy: result := 'truthy';
		TOpcode.incr: result := 'incr';
		TOpcode.decr: result := 'decr';
		TOpcode.consecutive: result := 'consecutive';
		TOpcode.give: result := 'give';
		TOpcode.pushSec: result := 'sec';
		TOpcode.pushSec_if: result := 'sec_if';
		TOpcode.pushSec_either: result := 'sec_either';
		TOpcode.pushSec_table: result := 'sec_table';
		TOpcode.changeSec: result := 'csec';
		TOpcode.changeSec_if: result := 'csec_if';
		TOpcode.changeSec_either: result := 'csec_either';
		TOpcode.popSec, TOpcode.popNSec: result := 'psec';
		TOpcode.popSecAndChange, TOpcode.popNSecAndChange: result := 'pcsec';
		TOpcode.unreachable: result := 'unreachable';
		TOpcode.ret: result := 'return';
		TOpcode.retVoid: result := 'return void';
		TOpcode.pushTrap: result := 'trap';
		TOpcode.popTrap: result := 'ptrap';
		TOpcode.panic: result := 'panic';
		TOpcode.staticSend, TOpcode.objSend: result := 'send';
		TOpcode.cast: result := 'cast';
		TOpcode.isa: result := 'isa';
		TOpcode.getKindID: result := 'kind_id';
		TOpcode.getKindSlot: result := 'kind_slot';
		TOpcode.getKindValue: result := 'kind_value';
		TOpcode.debug: result := 'debug';
	else
		result := '???';
	end;
end;

end.