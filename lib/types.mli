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
    
    module Table: sig
        type t = (type_index, Type.t) Hashtbl.t
    end
end

and Module: sig
    type t = {
        m_name: string;
        mutable m_params: type_index list option;
        mutable m_types: Type.Table.t;
        mutable m_sels: tsel list;
        mutable m_consts: Constant.t list;
        m_type: Type.k
    }

    val resolve_type: t -> type_index -> Type.t option

    val get_type: t -> type_index -> Type.t
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
    type kdispatch = [
        | `Normal
        | `Generic of Type.Table.t
    ]

    type tdispatch = [
        | `Single of kdispatch
        | `Multi of kdispatch list
    ]


    type tsection = {
        s_index: section_index;
        mutable s_opcodes: Opcode.t list
    }


    type tmethod_body = {
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
        dm_kind: kdefault_method;
        dm_return: type_index;
        dm_body: tmethod_body
    }

    and kdefault_method =
        | DMEmpty
        | DMMulti of {params: type_index list; dispatch: tdispatch}

    
    and tmethod_cast = {
        mc_kind: kdispatch;
        mc_type: type_index;
        mc_body: tmethod_body
    }

    
    and tmethod_op = {
        mo_kind: kmethod_op;
        mo_body: tmethod_body
    }

    and kmethod_op =
        | MOUnary
        | MOBinary of {param: type_index; dispatch: tdispatch}

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

    
    type tmethod_attrs = {
        is_hidden: bool;
        is_no_inherit: bool;
        is_native: string option
    }

    type 't tmethod_of = {
        mt_attrs: tmethod_attrs;
        mt_method: 't
    }

    type tmethod = tdefault_method tmethod_of

    type tcast = tmethod_cast tmethod_of

    type toperator = tmethod_op tmethod_of
    
    type tmethod_table = (sel_index, tmethod) Hashtbl.t

    type tcast_table = (type_index, tcast) Hashtbl.t

    type toperator_table = (kmethod_op_opcode, toperator) Hashtbl.t
end