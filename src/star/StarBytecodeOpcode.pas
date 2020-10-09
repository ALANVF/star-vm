unit StarBytecodeOpcode;

{$scopedEnums+}
{$minEnumSize 1}

interface

type
	{TODO:
	- lazy jumptable op
	- select op
	- remove changeSec_if op
	- maybe remove pushTrap op
	}
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

		consecutive,           { dest = value1 <op> value2 <op> value3 <op> ... valueN  WHERE  op = && OR || OR ^^ OR !! }
		give,                  { ... }                                                                                     // consecutive CHOICE TERMINATOR

		pushSec,               { ... }
		pushSec_if,            { if cond ... }
		pushSec_either,        { if cond ... else ... }
		pushSec_table,         { match ... at ... else ... }
		
		changeSec,             { ... }                                                                                     // SECTION TERMINATOR
		changeSec_if,          { ... }                                                                                     // SECTION TERMINATOR
		changeSec_either,      { ... }                                                                                     // SECTION TERMINATOR
		
		popSec,                { ... }                                                                                     // SECTION TERMINATOR
		popNSec,               { ... }                                                                                     // MULTI-SECTION TERMINATOR
		popSecAndChange,       { ... }                                                                                     // MULTI-SECTION TERMINATOR
		popNSecAndChange,      { ... }                                                                                     // MULTI-SECTION TERMINATOR
		
		unreachable,           { ... }                                                                                     // GLOBAL TERMINATOR

		ret,                   { return value }                                                                            // METHOD TERMINATOR
		retVoid,               { return }                                                                                  // METHOD TERMINATOR

		pushTrap,              { try ... catch ... }
		pushTrapN,             { try ... catch ... catch ... }
		popTrap,               { ... }                                                                                     // TRAP TERMINATOR
		panic,                 { panic value }                                                                             // MULTI-SECTION TERMINATOR

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
		TOpcode.pushConst..TOpcode.pushStaticMember: result := 'push';
		TOpcode.setReg..TOpcode.setStaticMember: result := 'set';
		TOpcode.swapReg: result := 'swap_reg';
		TOpcode.popN: result := 'pop';
		TOpcode.pushSec: result := 'sec';
		TOpcode.pushSec_if: result := 'sec_if';
		TOpcode.pushSec_either: result := 'sec_either';
		TOpcode.pushSec_table: result := 'sec_table';
		TOpcode.changeSec: result := 'csec';
		TOpcode.changeSec_if: result := 'csec_if';
		TOpcode.changeSec_either: result := 'csec_either';
		TOpcode.popSec, TOpcode.popNSec: result := 'psec';
		TOpcode.popSecAndChange, TOpcode.popNSecAndChange: result := 'pcsec';
		TOpcode.ret: result := 'return';
		TOpcode.retVoid: result := 'return void';
		TOpcode.pushTrap, TOpcode.pushTrapN: result := 'trap';
		TOpcode.popTrap: result := 'ptrap';
		TOpcode.staticSend, TOpcode.objSend: result := 'send';
		TOpcode.getKindID: result := 'kind_id';
		TOpcode.getKindSlot: result := 'kind_slot';
		TOpcode.getKindValue: result := 'kind_value';
	else
		str(opcode, result);
	end;
end;

end.
