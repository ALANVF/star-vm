open Base
open Base.Either.Export
open Types

type t = {
    mutable modules: (string, Module.t list) Hashtbl.t
}


let lookup_module {modules; _} name = Hashtbl.find_multi modules name

let add_module {modules; _} m = let open Module in
    Hashtbl.add_multi modules
        ~key: m.m_name
        ~data: m

let rec resolve_module vm this t = let open Type in
    match t with
    | TImport {name; _} -> begin
        match lookup_module vm name with
        | [] -> None
        | [m] -> Some (First m)
        | ml -> Some (Second ml)
    end
    | TExpand _ -> failwith "NYI"
    | TModule m -> Some (First m)
    | TMultiModule ml -> Some (Second ml)
    | TErased -> invalid_arg "Cannot resolve an erased type"
    | TParam _ -> invalid_arg "Cannot resolve a generic parameter type"
    | TLazy f -> resolve_module vm this (f ())
    | TThis -> Some (First this)

let get_module vm this t =
    Option.value_exn (resolve_module vm this t)