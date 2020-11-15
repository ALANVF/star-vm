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

val is_terminator: t -> bool

val dump: t -> string