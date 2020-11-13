open Base
open Types

type t = {
    mutable modules: (string, Module.t) Hashtbl.t
}

let lookup_module {modules; _} name = Hashtbl.find modules name

let rec resolve_module vm this t = Type.(
    match t with
    | TImport {name; is_circular = _} -> lookup_module vm name
    | TExpand _ -> raise (Failure "NYI")
    | TModule m -> Some m
    | TErased -> raise (Invalid_argument "Cannot resolve an erased type")
    | TParam _ -> raise (Invalid_argument "Cannot resolve a generic parameter type")
    | TLazy f -> resolve_module vm this (f ())
    | TThis -> Some this
)

let get_module vm this t =
    Option.value_exn (resolve_module vm this t)