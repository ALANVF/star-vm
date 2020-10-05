unit StarBytecodeOp;

{$scopedEnums+}
{$minEnumSize 1}
{$modeSwitch ADVANCEDRECORDS}

interface

uses
	StarBytecodeIndex,
	StarBytecodeOpcode,
	SysUtils,
	FileUtils;

type
	TOp = packed record
	public
		type
			TConsecutiveKind = (
				all,
				any,
				one,
				none
			);

			TTrapCase = record
				destReg: TRegisterIndex;
				section: TCodeSectionIndex;
			end;
			TTrapCases = array of TTrapCase;
			PTrapCases = ^TTrapCases;

			TDebugKind = (
				inspectEverything,
				inspectRegs,
				inspectStack,
				inspectCallStack,
				inspectCodeSectionStack,
				inspectReg,
				inspectConst,
				inspectType
			);	
	public
		case opcode: TOpcode of
			TOpcode.retain, TOpcode.release, TOpcode.pop, TOpcode.clear, TOpcode.swap, TOpcode.add..TOpcode.truthy,
			TOpcode.give, TOpcode.popSec, TOpcode.unreachable..TOpcode.retVoid, TOpcode.popTrap, TOpcode.panic,
			TOpcode.getKindID, TOpcode.getKindValue: ();

			TOpcode.pushConst: (pushConst: TConstantIndex);
			
			TOpcode.pushReg, TOpcode.setReg: (reg: TRegisterIndex);
			
			TOpcode.pushMember, TOpcode.setMember: (member: TMemberIndex);
			
			TOpcode.pushStaticMember, TOpcode.setStaticMember: (staticMember: record
				&type: TTypeIndex;
				member: TMemberIndex;
			end);
			
			TOpcode.swapReg: (swapReg: record
				reg1, reg2: TRegisterIndex;
			end);
			
			TOpcode.popN: (popN: word);
			
			TOpcode.incr, TOpcode.decr: (step: TRegisterIndex);
			
			TOpcode.consecutive: (consecutive: record
				kind: TConsecutiveKind;
				sections: PCodeSectionIndexArray;
			end);
			
			TOpcode.pushSec, TOpcode.pushSec_if,
			TOpcode.popSecAndChange,
			TOpcode.changeSec, TOpcode.changeSec_if: (sec: TCodeSectionIndex);

			TOpcode.pushSec_either, TOpcode.changeSec_either: (sec_either: record
				trueSection, falseSection: TCodeSectionIndex;
			end);
			
			TOpcode.pushSec_table: (pushSec_table: PCodeSectionIndexArray);
			
			TOpcode.popNSec: (popNSec: word);
			
			TOpcode.popNSecAndChange: (popNSecAndChange: record
				depth: word;
				section: TCodeSectionIndex;
			end);
			
			TOpcode.pushTrap: (pushTrap: record
				trySection: TCodeSectionIndex;
				catchDest: TRegisterIndex;
				catchSection: TCodeSectionIndex;
			end);

			TOpcode.pushTrapN: (pushTrapN: record
				trySection: TCodeSectionIndex;
				cases: PTrapCases;
			end);
			
			TOpcode.staticSend: (staticSend: record
				&type: TTypeIndex;
				selector: TSelectorIndex;
			end);
			
			TOpcode.objSend: (objSend: TSelectorIndex);

			TOpcode.cast, TOpcode.isa: (&type: TTypeIndex);

			TOpcode.getKindSlot: (getKindSlot: byte);
			
			TOpcode.debug: (debug: record
				case kind: TDebugKind of
					TDebugKind.inspectEverything..TDebugKind.inspectCodeSectionStack: ();
					TDebugKind.inspectReg: (r: TRegisterIndex);
					TDebugKind.inspectConst: (c: TConstantIndex);
					TDebugKind.inspectType: (t: TTypeIndex);
			end);
	end;

type
	TOpArray = array of TOp;


function dumpOp(op: TOp): string;

procedure disposeOp(var op: TOp);

procedure writeOp(const bf: TBinaryFile; const op: TOp);

function readOp(handle: THandle): TOp;

implementation

function dumpOp(op: TOp): string;
var
	opStr: string;
	i: integer;
begin
	result := dumpOpcodeName(op.opcode);

	if op.opcode in [
		TOpcode.pushConst..TOpcode.swapReg,
		TOpcode.popN,
		TOpcode.incr, TOpcode.decr,
		TOpcode.consecutive,
		TOpcode.pushSec..TOpcode.changeSec_either,
		TOpcode.popNSec..TOpcode.popNSecAndChange,
		TOpcode.ret,
		TOpcode.pushTrap,
		TOpcode.staticSend..TOpcode.isa,
		TOpcode.getKindSlot,
		TOpcode.debug
	] then with op do begin
		result += ' ';

		case opcode of
			TOpcode.pushConst: result += dumpConstantIndex(pushConst);
			
			TOpcode.pushReg, TOpcode.setReg: result += dumpRegisterIndex(sec);
			
			TOpcode.pushMember, TOpcode.setMember: result += dumpMemberIndex(member);
			
			TOpcode.pushStaticMember, TOpcode.setStaticMember: with staticMember do
				result += dumpTypeIndex(&type) + dumpMemberIndex(member);
			
			TOpcode.swapReg: with swapReg do
				result += dumpRegisterIndex(reg1) + ', ' + dumpRegisterIndex(reg2);
			
			TOpcode.popN: result += intToStr(popN);
			
			TOpcode.incr, TOpcode.decr: result += dumpRegisterIndex(step);
			
			TOpcode.consecutive: begin
				assert(length(consecutive.sections^) > 1, 'Invalid consecutive op!');
				
				opStr := '';
				str(consecutive.kind, opStr);
				result += opStr + ' ';
				result += dumpCodeSectionIndex(consecutive.sections^[0]);
				for i := 1 to high(consecutive.sections^) do
					result += ', ' + dumpCodeSectionIndex(consecutive.sections^[i]);
			end;

			TOpcode.pushSec, TOpcode.pushSec_if,
			TOpcode.popSecAndChange,
			TOpcode.changeSec, TOpcode.changeSec_if: result += dumpCodeSectionIndex(sec);

			TOpcode.pushSec_either, TOpcode.changeSec_either: with sec_either do begin
				result += dumpCodeSectionIndex(trueSection);
				result += ', ';
				result += dumpCodeSectionIndex(falseSection);
			end;
			
			TOpcode.pushSec_table: begin
				result += dumpCodeSectionIndex(pushSec_table^[0]);
				for i := 1 to high(pushSec_table^) do
					result += ', ' + dumpCodeSectionIndex(pushSec_table^[i]);
			end;

			TOpcode.popNSec: result += intToStr(popNSec);
			
			TOpcode.popNSecAndChange: with popNSecAndChange do begin
				result += intToStr(depth);
				result += ', ';
				result += dumpCodeSectionIndex(section);
			end;

			TOpcode.pushTrap: with pushTrap do begin
				result += dumpCodeSectionIndex(trySection);
				result += ', ';
				result += dumpRegisterIndex(catchDest);
				result += ', ';
				result += dumpCodeSectionIndex(catchSection);
			end;

			TOpcode.pushTrapN: with pushTrapN do begin
				result += dumpCodeSectionIndex(trySection);
				for i := 0 to high(cases^) do begin
					result += ', ';
					result += dumpRegisterIndex(cases^[i].destReg);
					result += ' sec ';
					result += dumpCodeSectionIndex(cases^[i].section);
				end;
			end;

			TOpcode.staticSend: with staticSend do begin
				result += dumpTypeIndex(&type);
				result += ', ';
				result += dumpSelectorIndex(selector);
			end;

			TOpcode.objSend: result += dumpSelectorIndex(objSend);

			TOpcode.cast, TOpcode.isa: result += dumpTypeIndex(&type);

			TOpcode.getKindSlot: result += intToStr(getKindSlot);

			TOpcode.debug: begin
				opStr := '';
				str(debug.kind, opStr);
				result += opStr;

				case debug.kind of
					TOp.TDebugKind.inspectReg: result += ' ' + dumpRegisterIndex(debug.r);
					TOp.TDebugKind.inspectConst: result += ' ' + dumpConstantIndex(debug.c);
					TOp.TDebugKind.inspectType: result += ' ' + dumpTypeIndex(debug.t);
				end;
			end;
		end;
	end;

end;

procedure disposeOp(var op: TOp);
begin
	with op do
		case opcode of
			TOpcode.consecutive: freeMemAndNil(consecutive.sections);
			TOpcode.pushSec_table: freeMemAndNil(pushSec_table);
			TOpcode.pushTrapN: freeMemAndNil(pushTrapN.cases);
		end;
end;

procedure writeOp(const bf: TBinaryFile; const op: TOp);
begin
	if op.opcode in [TOpcode.consecutive, TOpcode.pushSec_table] then begin
		bf.specialize write<TOpcode>(op.opcode);

		case op.opcode of
			TOpcode.consecutive: with op.consecutive do begin
				bf.specialize write<TOp.TConsecutiveKind>(kind);
				
				bf.writeAll(sections^);
			end;

			TOpcode.pushSec_table: with op do
				bf.writeAll(pushSec_table^);
			
			TOpcode.pushTrapN: with op.pushTrapN do begin
				bf.write(trySection);

				bf.specialize writeAll<TOp.TTrapCase>(cases^);
			end;
		end;
	end else
		bf.specialize write<TOp>(op);
end;

function readOp(handle: THandle): TOp;
var
	len: word;
	i: integer;
begin
	fileRead(handle, result.opcode, sizeof(TOpcode));

	if result.opcode in [TOpcode.consecutive, TOpcode.pushSec_table] then with result do begin
		case opcode of
			TOpcode.consecutive: with consecutive do begin
				fileRead(handle, kind, sizeof(kind));
				
				fileRead(handle, len, sizeof(len));
				new(sections);
				setLength(sections^, len);
				for i := 0 to len-1 do
					fileRead(handle, sections^[i], sizeof(TCodeSectionIndex));
			end;

			TOpcode.pushSec_table: begin
				fileRead(handle, len, sizeof(len));
				new(pushSec_table);
				setLength(pushSec_table^, len);
				for i := 0 to len-1 do
					fileRead(handle, pushSec_table^[i], sizeof(TCodeSectionIndex));
			end;

			TOpcode.pushTrapN: with pushTrapN do begin
				fileRead(handle, trySection, sizeof(trySection));
				
				fileRead(handle, len, sizeof(len));
				new(cases);
				setLength(cases^, len);
				for i := 0 to len-1 do
					fileRead(handle, cases^[i], sizeof(TCodeSectionIndex));
			end;
		end;
	end else
		{$T+}
		// Well that seems kinda unsafe
		fileRead(handle, (@result + sizeof(TOpcode))^, sizeof(result) - sizeof(TOpcode));
end;

end.