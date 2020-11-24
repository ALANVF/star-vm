open Base
open Index
(*open Util.BetterStdint*)
open Types
open Types.Methods
open Values

module Flow: sig
    exception Pop_sec of int
    exception Change_sec of int * section_index
    exception Pop_trap
    exception Give
    exception Return
    exception Return_void
    exception Throw
    exception Unreachable
end


type context = {
    vm: Vm.t;
    this: Module.t;
    routine: tany_method;
    caller: tvalue option;
    regs: tvalue ref Option_array.t;
}


val create_eval_context: Vm.t -> Module.t -> tany_method -> tvalue option -> tvalue list -> context