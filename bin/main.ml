let () =
    print_endline (Starvm.Opcode.dump (Starvm.Opcode.OPushSecJumpTable([1; 2; 3], Some 4)))
