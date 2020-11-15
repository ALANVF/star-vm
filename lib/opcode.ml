open Index

type consecutive_kind =
    | CKAll
    | CKAny
    | CKOne
    | CKNone

type debug_kind =
    | DKEverything
    | DKRegs
    | DKStack
    | DKCallStack
    | DKCodeSectionStack
    | DKReg of reg_index
    | DKConst of const_index
    | DKType of type_index

type t =
    | ORetain
    | ORelease
    | ODeinit

    | OPushConst of const_index
    | OPushReg of reg_index
    | OPushMember of member_index
    | OPushStaticMember of member_index
    
    | OSetReg of reg_index
    | OSetMember of member_index
    | OSetStaticMember of member_index

    | OSwapReg of reg_index * reg_index 

    | OPop of int
    | OClear
    | OSwap
    | OPin
    | OUnpin

    | OAdd
    | OSub
    | OMult
    | OPow
    | ODiv
    | OIDiv
    | OMod
    | OIsMod
    | OAnd
    | OOr
    | OXor
    | OShl
    | OShr
    | OEq
    | ONe
    | OGt
    | OGe
    | OLt
    | OLe

    | ONeg
    | ONot
    | OCompl
    | OTruthy

    | OIncr of reg_index
    | ODecr of reg_index

    | OConsecutive of consecutive_kind * section_index list
    | OGive

    | OPushSec of section_index
    | OPushSecIf of section_index
    | OPushSecEither of section_index * section_index
    | OPushSecTable of section_index list * section_index option
    | OPushSecJumpTable of section_index list * section_index option
    | OPushSecLazyTable of (section_index * section_index) list * section_index option

    | OChangeSec of section_index
    | OChangeSecIf of section_index
    | OChangeSecEither of section_index * section_index
    
    | OPopSec of int
    | OPopAndChangeSec of int * section_index

    | OUnreachable

    | ORet
    | ORetVoid
    
    | OPushTrap of section_index * (reg_index * section_index) list
    | OPopTrap
    | OThrow
    
    | OSendInit of type_index * sel_index
    | OSendStatic of type_index * sel_index
    | OSendObj of sel_index
    | OSendSuper of type_index * sel_index option

    | OCast of type_index
    | OIsA of type_index

    | OInitKind of type_index * int
    | OGetKindID
    | OGetKindSlot of int
    | OGetKindValue

    | ODebug of debug_kind

let is_terminator = function
    | OGive
    | OChangeSec _ | OChangeSecEither _
    | OPopSec _ | OPopAndChangeSec _
    | OUnreachable
    | ORet | ORetVoid
    | OPopTrap | OThrow -> true
    | _ -> false

let dump op =
    let open Printf in

    let fsec s = sprintf "@%i" s in

    let ftype t = sprintf "%%%i" t in

    let fsendt t s = sprintf " %%%i, #%i" t s in

    let fconsec = function
        | CKAll -> "all"
        | CKAny -> "any"
        | CKOne -> "one"
        | CKNone -> "none"
    in

    let fsecl sl =
        sl
        |> List.map(fsec)
        |> String.concat ", "
    in
    
    match op with
    | ORetain -> "retain"
    | ORelease -> "release"
    | ODeinit -> "deinit"
    | OPushConst c -> sprintf "push &%i" c
    | OPushReg r -> sprintf "push $%i" r
    | OPushMember m -> sprintf "push .%i" m
    | OPushStaticMember m -> sprintf "push %%.%i" m
    | OSetReg r -> sprintf "set $%i" r
    | OSetMember m ->  sprintf "set .%i" m
    | OSetStaticMember m -> sprintf "set %%.%i" m
    | OSwapReg(r1, r2) -> sprintf "swap_reg $%i, $%i" r1 r2
    | OPop 0 -> "pop INVALID"
    | OPop 1 -> "pop"
    | OPop n -> sprintf "pop %i" n
    | OClear -> "clear"
    | OSwap -> "swap"
    | OPin -> "pin"
    | OUnpin -> "unpin"
    | OAdd -> "add"
    | OSub -> "sub"
    | OMult -> "mult"
    | OPow -> "pow"
    | ODiv -> "div"
    | OIDiv -> "idiv"
    | OMod -> "mod"
    | OIsMod -> "mod0"
    | OAnd -> "and"
    | OOr -> "or"
    | OXor -> "xor"
    | OShl -> "shl"
    | OShr -> "shr"
    | OEq -> "eq"
    | ONe -> "ne"
    | OGt -> "gt"
    | OGe -> "ge"
    | OLt -> "lt"
    | OLe -> "le"
    | ONeg -> "neg"
    | ONot -> "not"
    | OCompl -> "compl"
    | OTruthy -> "truthy"
    | OIncr r -> sprintf "incr $%i" r
    | ODecr r -> sprintf "decr $%i" r
    | OConsecutive(k, ([] | [_])) -> "consecutive " ^ fconsec k ^ " INVALID"
    | OConsecutive(k, sl) -> "consecutive " ^ fconsec k ^ " " ^ fsecl sl
    | OGive -> "give"
    | OPushSec s -> "sec " ^ fsec s
    | OPushSecIf s -> "sec_if " ^ fsec s
    | OPushSecEither(s1, s2) -> "sec_either " ^ fsec s1 ^ ", " ^ fsec s2
    | OPushSecTable(sl, d) | OPushSecJumpTable(sl, d) ->
        (
            match op with
            | OPushSecJumpTable _ -> "sec_jtable "
            | _ -> "sec_table "
        ) ^ fsecl sl ^ (
            match d with
            | Some s -> ", else " ^ fsec s
            | None -> ""
        )
    | OPushSecLazyTable(sl, d) ->
        "sec_ltable " ^ (
            sl
            |> List.map(fun (c, s) -> sprintf "@%i => @%i" c s)
            |> String.concat ", "
        ) ^ (
            match d with
            | Some s -> ", else " ^ fsec s
            | None -> ""
        )
    | OChangeSec s -> "csec " ^ fsec s
    | OChangeSecIf s -> "csec_if " ^ fsec s
    | OChangeSecEither(s1, s2) -> "csec_either " ^ fsec s1 ^ ", " ^ fsec s2
    | OPopSec 0 -> "psec INVALID"
    | OPopSec 1 -> "psec"
    | OPopSec n -> sprintf "psec %i" n
    | OPopAndChangeSec(0, _) -> "pcsec INVALID"
    | OPopAndChangeSec(n, s) -> sprintf "pcsec %i, @%i" n s
    | OUnreachable -> "unreachable"
    | ORet -> "return"
    | ORetVoid -> "return void"
    | OPushTrap(ts, []) -> "trap " ^ fsec ts
    | OPushTrap(ts, hl) ->
        "trap " ^ fsec ts ^ ", " ^ (
            hl
            |> List.map(fun (r, s) -> sprintf "$%i => @%i" r s)
            |> String.concat ", "
        )
    | OPopTrap -> "ptrap"
    | OThrow -> "throw"
    | OSendInit(t, s) -> "init" ^ fsendt t s
    | OSendStatic(t, s) -> "send" ^ fsendt t s
    | OSendObj s -> sprintf "send #%i" s
    | OSendSuper(st, None) -> "super " ^ ftype st
    | OSendSuper(st, Some s) -> "super" ^ fsendt st s
    | OCast t -> "cast " ^ ftype t
    | OIsA t -> "isa " ^ ftype t
    | OInitKind(t, i) -> sprintf "kind %%%i, %i" t i
    | OGetKindID -> "kind_id"
    | OGetKindSlot s -> sprintf "kind_slot %i" s
    | OGetKindValue -> "kind_value"
    | ODebug DKEverything -> "debug everything"
    | ODebug DKRegs -> "debug regs"
    | ODebug DKStack -> "debug stack"
    | ODebug DKCallStack -> "debug callStack"
    | ODebug DKCodeSectionStack -> "debug codeSectionStack"
    | ODebug DKReg r -> sprintf "debug reg $%i" r
    | ODebug DKConst c -> sprintf "debug const &%i" c
    | ODebug DKType t -> "debug type %%%i" ^ ftype t
