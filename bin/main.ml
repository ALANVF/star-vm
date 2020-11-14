module Hashtbl = Base.Hashtbl
open Starvm
open Starvm.Types

let load_natives vm =
    let basic name repr =
        Module.{
            m_name = name;
            m_params = None;
            m_types = Type.Table.create();
            m_sels = [];
            m_consts = [];
            m_type = KNative repr
        }
    in

    let modules = Module.[
        basic "Star.Void" NVoid;
        {
            m_name = "Star.Native";
            m_params = None;
            m_types = Type.Table.create();
            m_sels = [];
            m_consts = [];
            m_type = KClass (Class.create())
        };
        basic "Star.Native.Bool" NBool;
        basic "Star.Native.Int8" NInt8;
        basic "Star.Native.UInt8" NUInt8;
        basic "Star.Native.Int16" NInt16;
        basic "Star.Native.UInt16" NUInt16;
        basic "Star.Native.Int32" NInt32;
        basic "Star.Native.UInt32" NUInt32;
        basic "Star.Native.Int64" NInt64;
        basic "Star.Native.UInt64" NUInt64;
        {
            m_name = "Star.Native.Ptr";
            m_params = Some [1];
            m_types = Hashtbl.Poly.of_alist_exn [1, Type.TImport {name = "Star.Void"; circular = None}];
            m_sels = [];
            m_consts = [];
            m_type = KNative (NPtr 1)
        };
        basic "Star.Native.Opaque" NOpaque
    ] in
    
    modules
    |> List.iter (Vm.add_module vm)

let () =
    print_endline (Opcode.dump (Opcode.OPushSecJumpTable([1; 2; 3], Some 4)));
    
    let vm = Vm.create() in
    
    load_natives vm;
    
    print_endline (Hashtbl.find_multi vm.modules "Star.Void" |> List.hd).m_name;
    print_endline (Hashtbl.find_multi vm.modules "Star.Native" |> List.hd).m_name