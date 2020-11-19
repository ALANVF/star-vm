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
end = struct
    type t =
        | TImport of {name: string; circular: string list option}
        | TExpand of {index: type_index; args: type_index list}
        | TModule of Module.t
        | TMultiModule of Module.t list
        | TErased
        | TParam of {unique_id: int; parents: type_index list; params: type_index list}
        | TLazy of (unit -> t)
        | TThis
    
    module Table = struct
        type t = (type_index, Type.t) Hashtbl.t
        
        let create () = Hashtbl.Poly.create()
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
end = struct
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

    let resolve_type m i = Type.(
        if i = 0 then Some TThis
        else Hashtbl.find m.m_types i
    )

    let get_type m i =
        Option.value_exn (resolve_type m i)
    
    (*let most_specific_module ~modules ~args =
        None*)
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

    val create:
        ?parents: type_index list ->
        ?static_members: tmember list ->
        ?members: tmember list ->
        ?default_init: Methods.tmethod_body option ->
        ?static_init: Methods.tmethod_body option ->
        ?inits: Methods.tmethod_table ->
        ?static_methods: Methods.tmethod_table ->
        ?methods: Methods.tmethod_table ->
        ?casts: Methods.tcast_table ->
        ?operators: Methods.toperator_table ->
        ?deinit: Methods.tmethod_body option ->
        ?static_deinit: Methods.tmethod_body option ->
        unit -> t
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

    let create
        ?(parents = [])
        ?(static_members = [])
        ?(members = [])
        ?(default_init = None)
        ?(static_init = None)
        ?(inits = Hashtbl.Poly.create())
        ?(static_methods = Hashtbl.Poly.create())
        ?(methods = Hashtbl.Poly.create())
        ?(casts = Hashtbl.Poly.create())
        ?(operators = Hashtbl.Poly.create())
        ?(deinit = None)
        ?(static_deinit = None)
    () =
        {
            t_parents = parents;
            t_static_members = static_members;
            t_members = members;
            t_default_init = default_init;
            t_static_init = static_init;
            t_inits = inits;
            t_static_methods = static_methods;
            t_methods = methods;
            t_casts = casts;
            t_operators = operators;
            t_deinit = deinit;
            t_static_deinit = static_deinit
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
        | NPtr of type_index
        | NOpaque
    
    type t = {
        n_kind: k;

        mutable t_static_methods: Methods.tmethod_table;
        mutable t_methods: Methods.tmethod_table;
        
        mutable t_casts: Methods.tcast_table;

        mutable t_operators: Methods.toperator_table
    }
end = struct
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
        | NPtr of type_index
        | NOpaque
    
    type t = {
        n_kind: k;

        mutable t_static_methods: Methods.tmethod_table;
        mutable t_methods: Methods.tmethod_table;
        
        mutable t_casts: Methods.tcast_table;

        mutable t_operators: Methods.toperator_table
    }
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
end = struct
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