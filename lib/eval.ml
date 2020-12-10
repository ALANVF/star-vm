open! Caml
open! Base
open Index
(*open Util.BetterStdint*)
open Types
open Types.Methods
open Values
(*module Vector = Containers.Vector*)


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

module VStack = struct
    type node =
        | Head
        | Node of {prev: node; value: tvalue}
        | Pin of {prev: node ref; value: tvalue}
    
    type t = {tail: node ref}


    let empty_exn () =
        failwith "Stack error: Stack was empty"

    let create () =
        {tail = ref Head}
    
    let push v {tail} =
        tail := Node {prev = !tail; value = v}
    
    let push_all vl t =
        List.iter vl ~f: (Fn.flip push t)
    
    let pop {tail} =
        match !tail with
        | Head -> empty_exn()
        | Node {prev; value} -> begin
            tail := prev;
            value
        end
        | Pin {value; _} -> value
    
    let pop_n n {tail} =
        let rec loop node acc prev_ref i =
            if i = 0 then begin
                prev_ref := node;
                acc
            end else
                match node with
                | Head -> empty_exn()
                | Node {prev; value} -> loop prev (value :: acc) prev_ref (i - 1)
                | Pin {prev; value} ->
                    prev_ref := node;
                    loop !prev (value :: acc) prev_ref (i - 1)
        in
        loop !tail [] tail n

    let remove {tail} =
        match !tail with
        | Head -> empty_exn()
        | Node {prev; _} -> tail := prev
        | Pin _ -> ()

    let remove_n n {tail} =
        let rec loop node prev_ref i =
            if i = 0 then
                prev_ref := node
            else
                match node with
                | Head -> empty_exn()
                | Node {prev; _} -> loop prev prev_ref (i - 1)
                | Pin {prev; _} ->
                    prev_ref := node;
                    loop !prev prev_ref (i - 1)
        in
        loop !tail tail n
    
    let clear {tail} =
        tail := Head

    let pin {tail} =
        match !tail with
        | Head -> empty_exn()
        | Node {prev; value} -> tail := Pin {prev = ref prev; value}
        | Pin _ -> Caml.prerr_endline "Warning: Attempted to pin a pinned value"

    let unpin {tail} =
        match !tail with
        | Head -> empty_exn()
        | Node _ -> failwith "Stack error: Cannot unpin an unpinned value"
        | Pin {prev; value} -> tail := Node {prev = !prev; value}

    let swap {tail} =
        match !tail with
        | Head
        | Node {prev = Head; _} -> empty_exn()
        | Pin _
        | Node {prev = Pin _; _} -> failwith "Stack error: Cannot swap a pinned value"
        | Node {prev = Node {prev; value = v2}; value = v1} ->
            tail := Node {prev = Node {prev; value = v1}; value = v2}

    let is_empty {tail} =
        match !tail with
        | Head -> true
        | _ -> false
end


type context = {
    vm: Vm.t;
    this: Module.t;
    routine: base_method;
    caller: tvalue option;
    regs: tvalue Uniform_array.t;
    vstack: VStack.t
}


let create_eval_context vm this routine caller args =
    let regs_spec = routine#registers
    in

    let regs = Uniform_array.unsafe_create_uninitialized ~len: (List.length regs_spec) in
    args |> List.iteri ~f: (Uniform_array.set regs);
    {
        vm;
        this;
        routine;
        caller;
        regs;
        vstack = VStack.create()
    }