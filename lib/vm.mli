open Base
open Types
open Index

type t = {
    mutable modules: (string, tmodule list) Hashtbl.t
}

val create: unit -> t

val lookup_module: t -> string -> tmodule list

val add_module: t -> tmodule -> unit

val resolve_module: t -> tmodule -> Type.t -> (tmodule, tmodule list) Either.t option

val get_module: t -> tmodule -> Type.t -> (tmodule, tmodule list) Either.t

val simplify_type: t -> tmodule -> Type.t -> Type.t


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


    val match_type: ?strict: bool -> t -> tmodule -> target: Type.t -> parent: Type.t -> tmatch_type_result

    val match_types: ?strict: bool -> t -> tmodule -> targets: type_index list -> parents: type_index list -> tmatch_type list option

    val try_match_types: ?strict: bool -> t -> tmodule -> targets: type_index list -> parents: type_index list -> tmatch_type list option

    val match_parents: ?strict: bool -> t -> tmodule -> target: Type.t -> parents: type_index list -> tmatch_type list option

    val match_module: ?strict: bool -> t -> tmodule -> target: tmodule -> parent: tmodule -> tmatch_type_result

    val get_better_match: tmatch_type -> tmatch_type -> [ `Left of tmatch_type | `Right of tmatch_type ]

    (*val compare_match: tmatch_type -> tmatch_type -> int*)

    (*val get_best_matches: ('t * tmatch_type) list -> ('t * tmatch_type) list*)
end