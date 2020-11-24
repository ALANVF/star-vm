open Base
open Index
(*open Util.BetterStdint*)
open Types
open Types.Methods
open Values

module Flow = struct
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


let create_eval_context vm this routine caller args =
    let {b_registers = regs_spec; _} =
        match routine with
        | MDefaultInit b
        | MStaticInit b
        | MDeinit b
        | MStaticDeinit b -> b
        | MInit {dm_body; _}
        | MStatic {dm_body; _}
        | MInstance {dm_body; _} -> dm_body
        | MCast {mc_body; _} -> mc_body
        | MOperator {mo_body; _} -> mo_body
    in
    
    let regs = Option_array.create ~len: (List.length regs_spec) in
    args |> List.iteri ~f: (fun i v -> Option_array.set_some regs i (ref v));
    {
        vm;
        this;
        routine;
        caller;
        regs
    }