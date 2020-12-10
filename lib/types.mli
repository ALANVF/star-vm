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
        | TImport of {name: string; circular: string list option}
        | TExpand of {index: type_index; args: type_index list}
        | TModule of Module.t
        | TMultiModule of Module.t list
        | TErased
        | TParam of {unique_id: int; parents: type_index list; params: type_index list}
        | TLazy of (unit -> t)
        | TThis

    module Table: sig
        type t = (type_index, Type.t) Hashtbl.t

        val create: unit -> t
    end
end

and Module: sig
    type k =
        | KClass of Class.t
        | KProtocol of Protocol.t
        | KValueKind of ValueKind.t
        | KTaggedKind of TaggedKind.t
        | KNative of Native.t

    type t = {
        m_name: string;
        mutable m_params: type_index list;
        mutable m_types: Type.Table.t;
        mutable m_sels: tsel list;
        mutable m_consts: Constant.t list;
        m_type: k
    }

    val resolve_type: t -> type_index -> Type.t option

    val get_type: t -> type_index -> Type.t

    (*val most_specific_module: modules: t list -> args: Type.t list -> t option*)
end

and Class: sig
    type t = {
        mutable t_parents: type_index list;
    
        mutable t_static_members: tmember list;
        mutable t_members: tmember list;
    
        mutable t_default_init: Methods.base_method option;
        mutable t_static_init: Methods.base_method option;
        
        mutable t_inits: Methods.method_table;
        
        mutable t_static_methods: Methods.method_table;
        mutable t_methods: Methods.method_table;
        
        mutable t_casts: Methods.cast_table;
    
        mutable t_operators: Methods.operator_table;
    
        mutable t_deinit: Methods.base_method option;
        mutable t_static_deinit: Methods.base_method option
    }

    val create:
        ?parents: type_index list ->
        ?static_members: tmember list ->
        ?members: tmember list ->
        ?default_init: Methods.base_method option ->
        ?static_init: Methods.base_method option ->
        ?inits: Methods.method_table ->
        ?static_methods: Methods.method_table ->
        ?methods: Methods.method_table ->
        ?casts: Methods.cast_table ->
        ?operators: Methods.operator_table ->
        ?deinit: Methods.base_method option ->
        ?static_deinit: Methods.base_method option ->
        unit -> t
end

and Protocol: sig
    type t = {
        mutable t_parents: type_index list;

        mutable t_static_members: tmember list;
        mutable t_members: tmember list;
        
        mutable t_static_methods: Methods.method_table;
        mutable t_methods: Methods.method_table;
        
        mutable t_casts: Methods.cast_table;

        mutable t_operators: Methods.operator_table
    }
end

and ValueKind: sig
    type case =
        | CConst of const_index
    
    type t = {
        k_is_flags: bool;
        
        vk_repr: type_index;
        mutable vk_cases: case list;

        mutable t_static_methods: Methods.method_table;
        mutable t_methods: Methods.method_table;
        
        mutable t_casts: Methods.cast_table;

        mutable t_operators: Methods.operator_table
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

        mutable t_default_init: Methods.base_method option;
        
        mutable t_static_methods: Methods.method_table;
        mutable t_methods: Methods.method_table;
        
        mutable t_casts: Methods.cast_table;

        mutable t_operators: Methods.operator_table
    }
end

and Native: sig
    type k =
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
        | NInt128
        | NUInt128
        | NDec
        | NPtr of type_index
        | NOpaque
    
    type t = {
        n_kind: k;

        mutable t_static_methods: Methods.method_table;
        mutable t_methods: Methods.method_table;
        
        mutable t_casts: Methods.cast_table;

        mutable t_operators: Methods.operator_table
    }
end

and Methods: sig
    type method_attrs = {
        is_hidden: bool
    }

    type section = {
        s_index: section_index;
        mutable s_opcodes: Opcode.t list
    }

    type dispatch_kind = [
        | `Normal
        | `Generic of Type.Table.t
    ]

    type unary_op =
        | UNeg
        | UNot
        | UCompl
        | UTruthy
    
    type binary_op =
        | BAdd
        | BSub
        | BMult
        | BPow
        | BDiv
        | BIDiv
        | BMod
        | BIsMod
        | BAnd
        | BOr
        | BXor
        | BShl
        | BShr
        | BEq
        | BNe
        | BGt
        | BGe
        | BLt
        | BLe



        class base_method:
        attrs: method_attrs ->
        registers: type_index list ->
        sections: section list ->
    object
        method attrs: method_attrs
        method registers: type_index list
        method sections: section list
    end

    class tmethod:
        attrs: method_attrs ->
        registers: type_index list ->
        sections: section list ->
        sel: tsel ->
        params: type_index list ->
        return: type_index ->
    object
        inherit base_method
        
        method sel: tsel
        method params: type_index list
        method return: type_index
    end

    class cast_method:
        attrs: method_attrs ->
        registers: type_index list ->
        sections: section list ->
        kind: dispatch_kind ->
        ret: type_index ->
    object
        inherit base_method
        
        method kind: dispatch_kind
        method ret: type_index
    end

    class unary_op_method:
        attrs: method_attrs ->
        registers: type_index list ->
        sections: section list ->
        op: unary_op ->
        ret: type_index ->
    object
        inherit base_method
        
        method op: unary_op
        method ret: type_index
    end

    class binary_op_method:
        attrs: method_attrs ->
        registers: type_index list ->
        sections: section list ->
        op: binary_op ->
        ret: type_index ->
    object inherit base_method
        method op: binary_op
        method ret: type_index
    end

    
    type 't dispatch = [
        | `Single of dispatch_kind * 't
        | `Multi of (dispatch_kind * 't) list
    ] constraint 't = #base_method


    type method_table = (sel_index, tmethod dispatch) Hashtbl.t

    type cast_table = (type_index, cast_method dispatch) Hashtbl.t

    type operator_table = {
        o_unary: (unary_op, unary_op_method) Hashtbl.t;
        o_binary: (binary_op, binary_op_method dispatch) Hashtbl.t
    }

    (*type method_kind =
        | KDefaultInit
        | KStaticInit
        | KDeinit
        | KStaticDeinit
        | KInit
        | KStatic
        | KInstance
        | KCast
        | KOperator*)
end