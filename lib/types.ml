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

module Cast = struct
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
end = struct
    class type t = object
        inherit Cast.t

        method name: string
        method params: type_index list
        method types: Type.Table.t
        method sels: tsel list
        method consts: Constant.t list

        method resolve_type: type_index -> Type.t option

        method get_type: type_index -> Type.t
    end
end


module Methods = struct
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


    class base_method ~attrs ~registers ~sections = object
        method attrs: method_attrs = attrs
        method registers: type_index list = registers
        method sections: section list = sections
    end

    class tmethod ~attrs ~registers ~sections ~sel ~params ~return = object
        inherit base_method ~attrs ~registers ~sections

        method sel: tsel = sel
        method params: type_index list = params
        method return: type_index = return
    end

    class cast_method ~attrs ~registers ~sections ~kind ~ret = object
        inherit base_method ~attrs ~registers ~sections
        
        method kind: dispatch_kind = kind
        method ret: type_index = ret
    end

    class unary_op_method ~attrs ~registers ~sections ~op ~ret = object
        inherit base_method ~attrs ~registers ~sections
        
        method op: unary_op = op
        method ret: type_index = ret
    end

    class binary_op_method ~attrs ~registers ~sections ~op ~ret = object
        inherit base_method ~attrs ~registers ~sections
        
        method op: binary_op = op
        method ret: type_index = ret
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
end


type 'a Cast.class_name += Module_t: Module.t Cast.class_name

class virtual tmodule ~name ~params ~types ~sels ~consts = object(this)
    method cast: type a. a Cast.name -> a = fun cls ->
        match this#try_cast cls with
        | Some this' -> this'
        | None -> raise Cast.Bad_cast
    
    method virtual try_cast: 'a. 'a Cast.name -> 'a option
    method try_cast: type a. a Cast.name -> a option = function
        | To Module_t -> Some(this :> Module.t)
        | _ -> None


    method name = name
    method params = params
    method types = types
    method sels = sels
    method consts = consts

    method resolve_type i =
        if i = 0 then Some Type.TThis
        else Hashtbl.find types i
    
    method get_type i =
        Option.value_exn (this#resolve_type i)
end


module Class = struct
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

class tclass ~name ~params ~types ~sels ~consts ~parents ~static_members ~members ~default_init ~static_init ~inits ~static_methods ~methods ~casts ~operators ~deinit ~static_deinit : Class.t = object(this)
    inherit tmodule ~name ~params ~types ~sels ~consts as super
    method! try_cast: type a. a Cast.name -> a option = function
        | To Class_t -> Some(this :> Class.t)
        | other -> super#try_cast other

    method parents = parents
    method static_members = static_members
    method members = members
    method default_init = default_init
    method static_init = static_init
    method inits = inits
    method static_methods = static_methods
    method methods = methods
    method casts = casts
    method operators = operators
    method deinit = deinit
    method static_deinit = static_deinit
end


module Protocol = struct
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

class tprotocol ~name ~params ~types ~sels ~consts ~parents ~static_members ~members ~static_methods ~methods ~casts ~operators : Protocol.t = object(this)
    inherit tmodule ~name ~params ~types ~sels ~consts as super
    method! try_cast: type a. a Cast.name -> a option = function
        | To Protocol_t -> Some(this :> Protocol.t)
        | other -> super#try_cast other

    method parents = parents
    method static_members = static_members
    method members = members
    method static_methods = static_methods
    method methods = methods
    method casts = casts
    method operators = operators
end


module ValueKind = struct
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

class tvalue_kind ~name ~params ~types ~sels ~consts ~is_flags ~repr ~cases ~static_methods ~methods ~casts ~operators : ValueKind.t = object(this)
    inherit tmodule ~name ~params ~types ~sels ~consts as super
    method! try_cast: type a. a Cast.name -> a option = function
        | To ValueKind_t -> Some(this :> ValueKind.t)
        | other -> super#try_cast other

    method is_flags = is_flags
    method repr = repr
    method cases = cases
    method static_methods = static_methods
    method methods = methods
    method casts = casts
    method operators = operators
end


module TaggedKind = struct
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

class ttagged_kind ~name ~params ~types ~sels ~consts ~is_flags ~cases ~parents ~static_members ~members ~default_init ~static_methods ~methods ~casts ~operators : TaggedKind.t = object(this)
    inherit tmodule ~name ~params ~types ~sels ~consts as super
    method! try_cast: type a. a Cast.name -> a option = function
        | To TaggedKind_t -> Some(this :> TaggedKind.t)
        | other -> super#try_cast other

    method is_flags = is_flags
    method cases = cases
    method parents = parents
    method static_members = static_members
    method members = members
    method default_init = default_init
    method static_methods = static_methods
    method methods = methods
    method casts = casts
    method operators = operators
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

module Native = struct
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

class tnative ~name ~params ~types ~sels ~consts ~kind ~static_methods ~methods ~casts ~operators : Native.t = object(this)
    inherit tmodule ~name ~params ~types ~sels ~consts as super
    method! try_cast: type a. a Cast.name -> a option = function
        | To Native_t -> Some(this :> Native.t)
        | other -> super#try_cast other

    method kind = kind
    method static_methods = static_methods
    method methods = methods
    method casts = casts
    method operators = operators
end


type kmodule =
    | KClass of tclass
    | KProtocol of tprotocol
    | KValueKind of tvalue_kind
    | KTaggedKind of ttagged_kind
    | KNative of tnative

let get_module_kind (m: tmodule) =
    match m#try_cast(To Class_t) with
    | Some c -> KClass c
    | None ->
        match m#try_cast(To Protocol_t) with
        | Some p -> KProtocol p
        | None ->
            match m#try_cast(To ValueKind_t) with
            | Some v -> KValueKind v
            | None ->
                match m#try_cast(To TaggedKind_t) with
                | Some p -> KTaggedKind p
                | None ->
                    match m#try_cast(To Native_t) with
                    | Some p -> KNative p
                    | None -> raise Cast.Bad_cast