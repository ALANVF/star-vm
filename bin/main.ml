open Starvm
open Starvm.Types

let () =
    print_endline (Opcode.dump (Opcode.OPushSecJumpTable([1; 2; 3], Some 4)));

    let vm = Vm.create() in
    
    Vm.add_module vm Module.{
        m_name = "Star.Void";
        m_params = [];
        m_types = Type.Table.create();
        m_sels = [];
        m_consts = [];
        m_type = KNative NVoid
    };

    print_endline (Base.Hashtbl.find_multi vm.modules "Star.Void" |> List.hd).m_name