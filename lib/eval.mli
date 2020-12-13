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

module VStack: sig
    type t

    val create: unit -> t
    val push: tvalue -> t -> unit
    val push_all: tvalue list -> t -> unit
    val pop: t -> tvalue
    val pop_n: int -> t -> tvalue list
    val remove: t -> unit
    val remove_n: int -> t -> unit
    val clear: t -> unit
    val pin: t -> unit
    val unpin: t -> unit
    val swap: t -> unit
    val is_empty: t -> bool
end


type context = {
    vm: Vm.t;
    this: tmodule;
    routine: base_method;
    caller: tvalue option;
    regs: tvalue Uniform_array.t;
    vstack: VStack.t
}


val create_eval_context: Vm.t -> tmodule -> base_method -> tvalue option -> tvalue list -> context