open Base
open Index

[@@@warning "-30"]

type tsel =
    | SSingle of string
    | SMulti of string list

type tmember = {
    mb_type: type_index;
    mb_getter: tsel option;
    mb_setter: tsel option
}

module rec Type: sig
    type t =
        | TImport of {name: string; is_circular: string list option}
        | TExpand of {index: type_index; args: type_index list}
        | TModule of Module.t
        | TErased
        | TParam of {unique_id: int; params: type_index list}
        | TLazy of (unit -> t)
        | TThis

    type k =
        | KClass of Class.t
        | KProtocol of Protocol.t
        | KValueKind of ValueKind.t
        | KTaggedKind of TaggedKind.t
        | KNative of Native.t
end = struct
    type t =
        | TImport of {name: string; is_circular: string list option}
        | TExpand of {index: type_index; args: type_index list}
        | TModule of Module.t
        | TErased
        | TParam of {unique_id: int; params: type_index list}
        | TLazy of (unit -> t)
        | TThis
    
    type k =
        | KClass of Class.t
        | KProtocol of Protocol.t
        | KValueKind of ValueKind.t
        | KTaggedKind of TaggedKind.t
        | KNative of Native.t
end

and Module: sig
    type t = {
        m_name: string;
        mutable m_params: type_index list option;
        mutable m_types: (type_index, Type.t) Hashtbl.t;
        mutable m_sels: tsel list;
        mutable m_consts: Constant.t list;
        m_type: Type.k
    }
end = struct
    type t = {
        m_name: string;
        mutable m_params: type_index list option;
        mutable m_types: (type_index, Type.t) Hashtbl.t;
        mutable m_sels: tsel list;
        mutable m_consts: Constant.t list;
        m_type: Type.k
    }
end

and Class: sig
    type t = {
        mutable t_parents: type_index list;

        mutable t_static_members: tmember list;
        mutable t_members: tmember list;

        mutable t_default_init: Methods.tmethod_body option;
        mutable t_static_init: Methods.tmethod_body option;
        
        mutable t_inits: Methods.tmethod_table;
        
        mutable t_static_methods: Methods.tmethod_table;
        mutable t_methods: Methods.tmethod_table;
        
        mutable t_casts: Methods.tcast_table;

        mutable t_operators: Methods.toperator_table;

        mutable t_deinit: Methods.tmethod_body option;
        mutable t_static_deinit: Methods.tmethod_body option
    }
end = struct
    type t = {
        mutable t_parents: type_index list;
    
        mutable t_static_members: tmember list;
        mutable t_members: tmember list;
    
        mutable t_default_init: Methods.tmethod_body option;
        mutable t_static_init: Methods.tmethod_body option;
        
        mutable t_inits: Methods.tmethod_table;
        
        mutable t_static_methods: Methods.tmethod_table;
        mutable t_methods: Methods.tmethod_table;
        
        mutable t_casts: Methods.tcast_table;
    
        mutable t_operators: Methods.toperator_table;
    
        mutable t_deinit: Methods.tmethod_body option;
        mutable t_static_deinit: Methods.tmethod_body option
    }
end

and Protocol: sig
    type t = {
        mutable t_parents: type_index list;

        mutable t_static_members: tmember list;
        mutable t_members: tmember list;
        
        mutable t_static_methods: Methods.tmethod_table;
        mutable t_methods: Methods.tmethod_table;
        
        mutable t_casts: Methods.tcast_table;

        mutable t_operators: Methods.toperator_table
    }
end = struct
    type t = {
        mutable t_parents: type_index list;

        mutable t_static_members: tmember list;
        mutable t_members: tmember list;
        
        mutable t_static_methods: Methods.tmethod_table;
        mutable t_methods: Methods.tmethod_table;
        
        mutable t_casts: Methods.tcast_table;

        mutable t_operators: Methods.toperator_table
    }
end

and ValueKind: sig
    type case =
        | CConst of const_index
    
    type t = {
        k_is_flags: bool;
        
        vk_repr: type_index;
        mutable vk_cases: case list;

        mutable t_static_methods: Methods.tmethod_table;
        mutable t_methods: Methods.tmethod_table;
        
        mutable t_casts: Methods.tcast_table;

        mutable t_operators: Methods.toperator_table
    }
end = struct
    type case =
        | CConst of const_index
    
    type t = {
        k_is_flags: bool;
        
        vk_repr: type_index;
        mutable vk_cases: case list;

        mutable t_static_methods: Methods.tmethod_table;
        mutable t_methods: Methods.tmethod_table;
        
        mutable t_casts: Methods.tcast_table;

        mutable t_operators: Methods.toperator_table
    }
end

and TaggedKind: sig
    type case = {
        mutable slots: type_index list
    }

    type t = {
        k_is_flags: bool;

        mutable tk_cases: case list;

        mutable t_parents: type_index list;

        mutable t_static_members: tmember list;
        mutable t_members: tmember list;

        mutable t_default_init: Methods.tmethod_body option;
        
        mutable t_static_methods: Methods.tmethod_table;
        mutable t_methods: Methods.tmethod_table;
        
        mutable t_casts: Methods.tcast_table;

        mutable t_operators: Methods.toperator_table
    }
end = struct
    type case = {
        mutable slots: type_index list
    }

    type t = {
        k_is_flags: bool;

        mutable tk_cases: case list;

        mutable t_parents: type_index list;

        mutable t_static_members: tmember list;
        mutable t_members: tmember list;

        mutable t_default_init: Methods.tmethod_body option;
        
        mutable t_static_methods: Methods.tmethod_table;
        mutable t_methods: Methods.tmethod_table;
        
        mutable t_casts: Methods.tcast_table;

        mutable t_operators: Methods.toperator_table
    }
end

and Native: sig
    type t =
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
end = struct
    type t =
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
end

and Methods: sig
    type tmethod_table = (sel_index, tmethod) Hashtbl.t

    and tcast_table = (type_index, tcast) Hashtbl.t

    and toperator_table = (kmethod_op_opcode, toperator) Hashtbl.t


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
        | MDGeneric of {locals: (type_index, Type.t) Hashtbl.t; params: type_index list}

    and tmethod_cast = {
        mc_kind: kmethod_cast;
        mc_type: type_index;
        mc_body: tmethod_body
    }

    and kmethod_cast =
        | MCNormal
        | MCGeneric of (type_index, Type.t) Hashtbl.t

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
        | MODGeneric of {locals: (type_index, Type.t) Hashtbl.t; param: type_index}

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
end = struct
    type tmethod_table = (sel_index, tmethod) Hashtbl.t

    and tcast_table = (type_index, tcast) Hashtbl.t

    and toperator_table = (kmethod_op_opcode, toperator) Hashtbl.t


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
        | MDGeneric of {locals: (type_index, Type.t) Hashtbl.t; params: type_index list}

    and tmethod_cast = {
        mc_kind: kmethod_cast;
        mc_type: type_index;
        mc_body: tmethod_body
    }

    and kmethod_cast =
        | MCNormal
        | MCGeneric of (type_index, Type.t) Hashtbl.t

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
        | MODGeneric of {locals: (type_index, Type.t) Hashtbl.t; param: type_index}

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
end


module Vm = struct
    type t = {
        mutable modules: (string, Module.t) Hashtbl.t
    }

    let lookup_module {modules; _} name = Hashtbl.find modules name

    let rec resolve_module vm this t = Type.(
        match t with
        | TImport {name; is_circular = _} -> lookup_module vm name
        | TExpand _ -> raise (Failure "NYI")
        | TModule m -> Some m
        | TErased -> raise (Invalid_argument "Cannot resolve an erased type")
        | TParam _ -> raise (Invalid_argument "Cannot resolve a generic parameter type")
        | TLazy f -> resolve_module vm this (f ())
        | TThis -> Some this
    )
    
    let get_module vm this t =
        Option.value_exn (resolve_module vm this t)
end


let resolve_local_type m i = Type.(Module.(
    if i = 0 then Some TThis
    else Hashtbl.find m.m_types i
))

let get_local_type m i =
    Option.value_exn (resolve_local_type m i)