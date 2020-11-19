open Base
open Types
open Index

type t = {
    mutable modules: (string, Module.t list) Hashtbl.t
}

val create: unit -> t

val lookup_module: t -> string -> Module.t list

val add_module: t -> Module.t -> unit

val resolve_module: t -> Module.t -> Type.t -> (Module.t, Module.t list) Either.t option

val get_module: t -> Module.t -> Type.t -> (Module.t, Module.t list) Either.t

val simplify_type: t -> Module.t -> Type.t -> Type.t


module Checks: sig
    type tmatch_type = [
        | `IsExact
        | `IsSame
        | `IsParent of (type_index * tmatch_type) list
        | `IsDerived of (type_index * tmatch_type) list
        | `IsComplexParam of tmatch_type list list
        | `IsParametric of tmatch_type * tmatch_type list
        | `IsErased
    ]
    type tmatch_type_result = [ tmatch_type | `Failed ]


    val match_type: ?strict: bool -> t -> Module.t -> target: Type.t -> parent: Type.t -> tmatch_type_result

    val match_types: ?strict: bool -> t -> Module.t -> targets: type_index list -> parents: type_index list -> tmatch_type list option

    val try_match_types: ?strict: bool -> t -> Module.t -> targets: type_index list -> parents: type_index list -> tmatch_type list option

    val match_parents: ?strict: bool -> t -> Module.t -> target: Type.t -> parents: type_index list -> tmatch_type list option

    val match_module: ?strict: bool -> t -> Module.t -> target: Module.t -> parent: Module.t -> tmatch_type_result

    (*val compare_match: tmatch_type -> tmatch_type -> int*)

    (*val get_best_matches: ('t * tmatch_type) list -> ('t * tmatch_type) list*)
end