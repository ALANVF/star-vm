open Base
open Index

[@@@warning "-30"]

type ttype =
    | LImport of {name: string; is_circular: string list option}
    | LExpand of {index: type_index; args: type_index list}
    | LModule of tmodule
    | LErased
    | LParam of {unique_id: int; params: type_index list}
    | LLazy of (unit -> ttype)
    | LThis

and tlocal_types = (type_index, ttype) Hashtbl.t

and tmodule = {
    m_name: string;
    mutable m_params: type_index list option;
    mutable m_types: tlocal_types;
    mutable m_sels: tsel list;
    mutable m_consts: Constant.t list;
    m_type: ktype
}

and ktype =
    | TClass of tclass
    | TProtocol of tprotocol
    | TValueKind of tvalue_kind
    | TTaggedKind of ttagged_kind
    | TNative of tnative

and tclass = {
    mutable t_parents: type_index list;

    mutable t_static_members: tmember list;
    mutable t_members: tmember list;

    mutable t_default_init: tmethod_body option;
    mutable t_static_init: tmethod_body option;
    
    mutable t_inits: tmethod_table;
    
    mutable t_static_methods: tmethod_table;
    mutable t_methods: tmethod_table;
    
    mutable t_casts: tcast_table;

    mutable t_operators: toperator_table;

    mutable t_deinit: tmethod_body option;
    mutable t_static_deinit: tmethod_body option
}

and tprotocol = {
    mutable t_parents: type_index list;

    mutable t_static_members: tmember list;
    mutable t_members: tmember list;
    
    mutable t_static_methods: tmethod_table;
    mutable t_methods: tmethod_table;
    
    mutable t_casts: tcast_table;

    mutable t_operators: toperator_table
}

and tvalue_kind = {
    k_is_flags: bool;
    
    vk_repr: type_index;
    mutable vk_cases: tvalue_case list;

    mutable t_static_methods: tmethod_table;
    mutable t_methods: tmethod_table;
    
    mutable t_casts: tcast_table;

    mutable t_operators: toperator_table
}

and ttagged_kind = {
    k_is_flags: bool;

    mutable tk_cases: ttagged_case list;

    mutable t_parents: type_index list;

    mutable t_static_members: tmember list;
    mutable t_members: tmember list;

    mutable t_default_init: tmethod_body option;
    
    mutable t_static_methods: tmethod_table;
    mutable t_methods: tmethod_table;
    
    mutable t_casts: tcast_table;

    mutable t_operators: toperator_table
}

and tnative =
    | NVoid
    | NBool
    | NInt8
    | NUInt8
    | NInt16
    | NUInt16
    | NInt32
    | NUInt32
    | NInt64
    | NUInt64
    | NPtr of type_index
    | NFunc of {params: type_index list; return: type_index}
    | NOpaque


and tmember = {
    mb_type: type_index;
    mb_getter: tsel option;
    mb_setter: tsel option
}


and tvalue_case =
    | VCConst of const_index


and ttagged_case = {
    mutable tc_slots: type_index list
}


and tmethod_table = (sel_index, tmethod) Hashtbl.t

and tcast_table = (type_index, tcast) Hashtbl.t

and toperator_table = (kmethod_op_opcode, toperator) Hashtbl.t


and tsel =
    | SSingle of string
    | SMulti of string list


and tsection = {
    s_index: section_index;
    mutable s_opcodes: Opcode.t list
}


and tmethod = tdefault_method tmethod_of

and tcast = tmethod_cast tmethod_of

and toperator = tmethod_op tmethod_of

and 't tmethod_of = {
    mt_attrs: tmethod_attrs;
    mt_method: 't
}

and tmethod_attrs = {
    is_hidden: bool;
    is_no_inherit: bool;
    is_native: string option
}

and tmethod_body = {
    mutable b_registers: type_index list;
    mutable b_sections: tsection list
}

and tany_method =
    | AMDefaultInit of tmethod_body
    | AMStaticInit of tmethod_body
    | AMInit of tdefault_method
    | AMStatic of tdefault_method
    | AMInstance of tdefault_method
    | AMCast of tmethod_cast
    | AMOperator of tmethod_op
    | AMDeinit of tmethod_body
    | AMStaticDeinit of tmethod_body

and tdefault_method = {
    dm_sel: tsel;
    mutable dm_kind: kdefault_method;
    dm_return: type_index;
    dm_body: tmethod_body
}

and kdefault_method =
    | MNEmpty
    | MNMulti of kdefault_method_multi

and kdefault_method_multi =
    | MMSingle of kdefault_method_dispatch
    | MMMulti of kdefault_method_dispatch list

and kdefault_method_dispatch =
    | MDNormal of type_index list
    | MDGeneric of {locals: tlocal_types; params: type_index list}

and tmethod_cast = {
    mc_kind: kmethod_cast;
    mc_type: type_index;
    mc_body: tmethod_body
}

and kmethod_cast =
    | MCNormal
    | MCGeneric of tlocal_types

and tmethod_op = {
    mo_kind: kmethod_op;
    mo_body: tmethod_body
}

and kmethod_op =
    | MOUnary
    | MOBinary of kmethod_op_multi

and kmethod_op_multi =
    | MOMSingle of kmethod_op_dispatch
    | MOMMulti of kmethod_op_dispatch list

and kmethod_op_dispatch =
    | MODNormal of type_index
    | MODGeneric of {locals: tlocal_types; param: type_index}

and kmethod_op_opcode =
    | MOONeg
    | MOONot
    | MOOCompl
    | MOOTruthy
    | MOOAdd
    | MOOSub
    | MOOMult
    | MOOPow
    | MOODiv
    | MOOIDiv
    | MOOMod
    | MOOIsMod
    | MOOAnd
    | MOOOr
    | MOOXor
    | MOOShl
    | MOOShr
    | MOOEq
    | MOONe
    | MOOGt
    | MOOGe
    | MOOLt
    | MOOLe


module Vm = struct
    type t = {
        mutable modules: (string, tmodule) Hashtbl.t
    }

    let lookup_module {modules; _} name = Hashtbl.find modules name

    let rec resolve_module vm this t =
        match t with
        | LImport {name; is_circular = _} -> lookup_module vm name
        | LExpand _ -> raise (Failure "NYI")
        | LModule m -> Some m
        | LErased -> raise (Invalid_argument "Cannot resolve an erased type")
        | LParam _ -> raise (Invalid_argument "Cannot resolve a generic parameter type")
        | LLazy f -> resolve_module vm this (f ())
        | LThis -> Some this
    
    let get_module vm this t =
        Option.value_exn (resolve_module vm this t)
end


let resolve_local_type m i =
    if i = 0 then Some LThis
    else Hashtbl.find m.m_types i

let get_local_type m i =
    Option.value_exn (resolve_local_type m i)