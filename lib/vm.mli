open Base
open Types

type t = {
    mutable modules: (string, Module.t) Hashtbl.t
}

val lookup_module: t -> string -> Module.t option

val resolve_module: t -> Module.t -> Type.t -> Module.t option

val get_module: t -> Module.t -> Type.t -> Module.t