module Hashtbl = Base.Hashtbl
open Starvm
open Starvm.Types

let load_natives vm =
    let basic name repr =
        ((new tnative
            ~name: name
            ~params: []
            ~types: (Type.Table.create())
            ~sels: []
            ~consts: []
            ~kind: repr
            ~static_methods: (Hashtbl.Poly.create())
            ~methods: (Hashtbl.Poly.create())
            ~casts: (Hashtbl.Poly.create())
            ~operators: {
                o_unary = Hashtbl.Poly.create();
                o_binary = Hashtbl.Poly.create()
            }) :> tmodule)
    in
    
    let modules = [
        basic "Star.Void" NVoid;
        ((new tclass
            ~name: "Star.Native"
            ~params: []
            ~types: (Type.Table.create())
            ~sels: []
            ~consts: []
            ~parents: []
            ~static_members: []
            ~members: []
            ~default_init: None
            ~static_init: None
            ~inits: (Hashtbl.Poly.create())
            ~static_methods: (Hashtbl.Poly.create())
            ~methods: (Hashtbl.Poly.create())
            ~casts: (Hashtbl.Poly.create())
            ~operators: {
                o_unary = Hashtbl.Poly.create();
                o_binary = Hashtbl.Poly.create()
            }
            ~deinit: None
            ~static_deinit: None) :> tmodule)
        ;
        basic "Star.Native.Bool" NBool;
        basic "Star.Native.Int8" NInt8;
        basic "Star.Native.UInt8" NUInt8;
        basic "Star.Native.Int16" NInt16;
        basic "Star.Native.UInt16" NUInt16;
        basic "Star.Native.Int32" NInt32;
        basic "Star.Native.UInt32" NUInt32;
        basic "Star.Native.Int64" NInt64;
        basic "Star.Native.UInt64" NUInt64;
        ((new tnative
            ~name: "Star.Native.Ptr"
            ~params: [1]
            ~types: (Hashtbl.Poly.of_alist_exn [1, Type.TImport {name = "Star.Void"; circular = None}])
            ~sels: []
            ~consts: []
            ~kind: (NPtr 1)
            ~static_methods: (Hashtbl.Poly.create())
            ~methods: (Hashtbl.Poly.create())
            ~casts: (Hashtbl.Poly.create())
            ~operators: {
                o_unary = Hashtbl.Poly.create();
                o_binary = Hashtbl.Poly.create()
            }) :> tmodule)
        ;
        basic "Star.Native.Opaque" NOpaque
    ] in
    
    modules
    |> List.iter (Vm.add_module vm)

let () =
    print_endline (Opcode.dump (Opcode.OPushSecJumpTable([1; 2; 3], Some 4)));
    
    let vm = Vm.create() in
    
    load_natives vm;
    
    print_endline (Hashtbl.find_multi vm.modules "Star.Void" |> List.hd)#name;
    print_endline (Hashtbl.find_multi vm.modules "Star.Native" |> List.hd)#name;

    let ptr = (Hashtbl.find_multi vm.modules "Star.Native.Ptr" |> List.hd) in
    let ptr' = ptr#try_cast(To Native_t) in
    match ptr' with
    | Some ptr'' when (match ptr''#kind with NPtr _ -> true | _ -> false) -> print_endline "yay"
    | _ -> print_endline "nope"