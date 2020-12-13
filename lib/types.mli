open Base
open Index

(* TODO:
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


module Cast: sig
    type 'a class_name = ..
    constraint 'a = <cast: 'a. 'a name -> 'a; try_cast: 'a. 'a name -> 'a option; ..>

    and 'a name =
        To: 'a class_name -> (<cast: 'a. 'a name -> 'a; try_cast: 'a. 'a name -> 'a option; ..> as 'a) name
    [@@unboxed]

    exception Bad_cast

    class type t = object
        method cast: 'a. 'a name -> 'a
        method try_cast: 'a. 'a name -> 'a option
    end
end


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
    class type t = object
        inherit Cast.t

        method name: string
        method params: type_index list
        method types: Type.Table.t
        method sels: tsel list
        method consts: Constant.t list

        method resolve_type: type_index -> Type.t option

        method get_type: type_index -> Type.t

        (*method most_specific_module: modules: t list -> args: Type.t list -> t option*)
    end
end


module Methods: sig
    type method_attrs = {
        is_hidden: bool;
        is_no_inherit: bool;
        is_native: string option
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


type 'a Cast.class_name += Module_t: Module.t Cast.class_name

class virtual tmodule:
    name: string ->
    params: type_index list ->
    types: Type.Table.t ->
    sels: tsel list ->
    consts: Constant.t list ->
object
    inherit Module.t
end


module Class: sig
    class type t = object
        inherit tmodule

        method parents: type_index list
        method static_members: tmember list
        method members: tmember list
        method default_init: Methods.base_method option
        method static_init: Methods.base_method option
        method inits: Methods.method_table
        method static_methods: Methods.method_table
        method methods: Methods.method_table
        method casts: Methods.cast_table
        method operators: Methods.operator_table
        method deinit: Methods.base_method option
        method static_deinit: Methods.base_method option
    end
end

type 'a Cast.class_name += Class_t: Class.t Cast.class_name

class tclass:
    name: string ->
    params: type_index list ->
    types: Type.Table.t ->
    sels: tsel list ->
    consts: Constant.t list ->
    parents: type_index list ->
    static_members: tmember list ->
    members: tmember list ->
    default_init: Methods.base_method option ->
    static_init: Methods.base_method option ->
    inits: Methods.method_table ->
    static_methods: Methods.method_table ->
    methods: Methods.method_table ->
    casts: Methods.cast_table ->
    operators: Methods.operator_table ->
    deinit: Methods.base_method option ->
    static_deinit: Methods.base_method option ->
object
    inherit Class.t
end


module Protocol: sig
    class type t = object
        inherit tmodule

        method parents: type_index list
        method static_members: tmember list
        method members: tmember list
        method static_methods: Methods.method_table
        method methods: Methods.method_table
        method casts: Methods.cast_table
        method operators: Methods.operator_table
    end
end

type 'a Cast.class_name += Protocol_t: Protocol.t Cast.class_name

class tprotocol:
    name: string ->
    params: type_index list ->
    types: Type.Table.t ->
    sels: tsel list ->
    consts: Constant.t list ->
    parents: type_index list ->
    static_members: tmember list ->
    members: tmember list ->
    static_methods: Methods.method_table ->
    methods: Methods.method_table ->
    casts: Methods.cast_table ->
    operators: Methods.operator_table ->
object
    inherit Protocol.t
end


module ValueKind: sig
    class type t = object
        inherit tmodule

        method is_flags: bool
        method repr: type_index
        method cases: const_index list
        method static_methods: Methods.method_table
        method methods: Methods.method_table
        method casts: Methods.cast_table
        method operators: Methods.operator_table
    end
end

type 'a Cast.class_name += ValueKind_t: ValueKind.t Cast.class_name
    
class tvalue_kind:
    name: string ->
    params: type_index list ->
    types: Type.Table.t ->
    sels: tsel list ->
    consts: Constant.t list ->
    is_flags: bool ->
    repr: type_index ->
    cases: const_index list ->
    static_methods: Methods.method_table ->
    methods: Methods.method_table ->
    casts: Methods.cast_table ->
    operators: Methods.operator_table ->
object
    inherit ValueKind.t
end


module TaggedKind: sig
    class type t = object
        inherit tmodule

        method is_flags: bool
        method cases: type_index list list
        method parents: type_index list
        method static_members: tmember list
        method members: tmember list
        method default_init: Methods.base_method option
        method static_methods: Methods.method_table
        method methods: Methods.method_table
        method casts: Methods.cast_table
        method operators: Methods.operator_table
    end
end

type 'a Cast.class_name += TaggedKind_t: TaggedKind.t Cast.class_name

class ttagged_kind:
    name: string ->
    params: type_index list ->
    types: Type.Table.t ->
    sels: tsel list ->
    consts: Constant.t list ->
    is_flags: bool ->
    cases: type_index list list ->
    parents: type_index list ->
    static_members: tmember list ->
    members: tmember list ->
    default_init: Methods.base_method option ->
    static_methods: Methods.method_table ->
    methods: Methods.method_table ->
    casts: Methods.cast_table ->
    operators: Methods.operator_table ->
object
    inherit TaggedKind.t
end


type knative =
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

module Native: sig
    class type t = object
        inherit tmodule

        method kind: knative
        method static_methods: Methods.method_table
        method methods: Methods.method_table
        method casts: Methods.cast_table
        method operators: Methods.operator_table
    end
end

type 'a Cast.class_name += Native_t: Native.t Cast.class_name

class tnative:
    name: string ->
    params: type_index list ->
    types: Type.Table.t ->
    sels: tsel list ->
    consts: Constant.t list ->
    kind: knative ->
    static_methods: Methods.method_table ->
    methods: Methods.method_table ->
    casts: Methods.cast_table ->
    operators: Methods.operator_table ->
object
    inherit Native.t
end


type kmodule =
    | KClass of tclass
    | KProtocol of tprotocol
    | KValueKind of tvalue_kind
    | KTaggedKind of ttagged_kind
    | KNative of tnative

val get_module_kind: tmodule -> kmodule