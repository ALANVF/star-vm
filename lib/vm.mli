open Base
open Types

type t = {
    mutable modules: (string, Module.t list) Hashtbl.t
}

val lookup_module: t -> string -> Module.t list

val add_module: t -> Module.t -> unit

val resolve_module: t -> Module.t -> Type.t -> (Module.t, Module.t list) Either.t option

val get_module: t -> Module.t -> Type.t -> (Module.t, Module.t list) Either.t