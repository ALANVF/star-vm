open Base
open Index

(* TODO:
 * - less redundancy
 * - change index types to something stronger
 *)

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
end

and Methods: sig
    type tmethod_table = (sel_index, tmethod) Hashtbl.t

    and tcast_table = (type_index, tcast) Hashtbl.t

    and toperator_table = (kmethod_op_opcode, toperator) Hashtbl.t


    and tsection = {
        s_index: section_index;
        mutable s_opcodes: Opcode.t list
    }


    and tmethod = tdefault_method Methods.tmethod_of

    and tcast = Methods.tmethod_cast Methods.tmethod_of

    and toperator = Methods.tmethod_op Methods.tmethod_of

    and 't tmethod_of = {
        mt_attrs: Methods.tmethod_attrs;
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
        | AMDefaultInit of Methods.tmethod_body
        | AMStaticInit of Methods.tmethod_body
        | AMInit of tdefault_method
        | AMStatic of tdefault_method
        | AMInstance of tdefault_method
        | AMCast of Methods.tmethod_cast
        | AMOperator of Methods.tmethod_op
        | AMDeinit of Methods.tmethod_body
        | AMStaticDeinit of Methods.tmethod_body

    and tdefault_method = {
        dm_sel: tsel;
        mutable dm_kind: kdefault_method;
        dm_return: type_index;
        dm_body: Methods.tmethod_body
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
        mc_body: Methods.tmethod_body
    }

    and kmethod_cast =
        | MCNormal
        | MCGeneric of (type_index, Type.t) Hashtbl.t

    and tmethod_op = {
        mo_kind: kmethod_op;
        mo_body: Methods.tmethod_body
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


module Vm: sig
    type t = {
        mutable modules: (string, Module.t) Hashtbl.t
    }

    val lookup_module: t -> string -> Module.t option

    val resolve_module: t -> Module.t -> Type.t -> Module.t option

    val get_module: t -> Module.t -> Type.t -> Module.t
end


val resolve_local_type: Module.t -> type_index -> Type.t option

val get_local_type: Module.t -> type_index -> Type.t