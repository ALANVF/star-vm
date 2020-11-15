open Base
open Base.Either.Export
open Types

type t = {
    mutable modules: (string, Module.t list) Hashtbl.t
}


let create () =
    {
        modules = Hashtbl.Poly.create()
    }

let lookup_module {modules; _} name = Hashtbl.find_multi modules name

let add_module {modules; _} m = let open Module in
    Hashtbl.add_multi modules
        ~key: m.m_name
        ~data: m

let rec resolve_module vm this t =
    let open Type in

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

let rec simplify_type vm this t =
    let open Type in

    match t with
    | TImport {name; _} -> begin
        match lookup_module vm name with
        | [] -> failwith ("Module `" ^ name ^ "` does not exist!")
        | [m] -> TModule m
        | ml -> TMultiModule ml
    end
    | TExpand _ -> failwith "NYI"
    | TLazy f -> simplify_type vm this (f ())
    | _ -> t

let get_simplified_type vm this index =
    index
    |> Module.get_type this
    |> simplify_type vm this

[@@@warning "-26-27"]
module Checks = struct
    type tmatch_type = [
        | `IsExact
        | `IsSame
        | `IsDerived of tmatch_type list
        | `IsDerivedParam of tmatch_type list list
        | `IsParametric of tmatch_type * tmatch_type list
        | `IsErased
    ]
    type tmatch_type_result = [ tmatch_type | `Failed ]

    let rec match_type vm this ~target ~parent =
        let open Type in
        
        let match_type' target' parent' =
            match target', parent' with
            | (TImport _ | TExpand _ | TLazy _ | TThis), _ | _, (TImport _ | TExpand _ | TLazy _ | TThis) -> invalid_arg "Unexpected complex type!"
            | TErased, _ | _, TErased -> `IsErased
            | TParam {parents = []; params = []; _}, TParam {parents = []; params = []; _} -> `IsExact
            | _, TParam {parents = []; params = []; _} -> `IsErased
            | TParam {parents = []; params = []; _}, _ -> `Failed
            | TParam {parents; params; _}, TParam {parents = parents'; params = params'; _} -> begin
                match params, params' with
                | _, [] -> begin
                    match match_parents vm this ~target ~parents: parents' with
                    | Some [] -> `IsSame
                    | Some parent_results -> `IsDerived parent_results
                    | None -> `Failed
                end
                | [], _ -> `Failed
                | _, _ ->
                    let rec loop acc tpl =
                        match tpl with
                        | [] -> Some acc
                        | tp :: tpl' ->
                            let tp' = get_simplified_type vm this tp in
                            match match_parents vm this ~target: tp' ~parents: parents' with
                            | Some rl' -> loop (rl' :: acc) tpl'
                            | None -> None
                    in
                    match match_types vm this ~targets: params ~parents: params' with
                    | Some param_results -> begin
                        match loop [] parents with
                        | Some [] -> `IsParametric(`IsSame, param_results)
                        | Some parent_results -> `IsParametric(`IsDerivedParam parent_results, param_results)
                        | None -> `Failed
                    end
                    | None -> `Failed
            end
            | TModule {m_params; _} as m, TParam {parents; params; _} -> begin
                match m_params, params with
                | _, [] -> begin
                    match match_parents vm this ~target: target' ~parents with
                    | Some parent_results -> `IsDerived parent_results
                    | None -> `Failed
                end
                | [], _ -> `Failed
                | _, _ -> failwith "NYI!"
            end
            | _, _ -> `Failed
        in

        match_type' target parent
    
    and match_types vm this ~targets ~parents =
        let rec loop acc pl =
            match pl with
            | [] -> Some acc
            | (t, p) :: rest ->
                let t' = get_simplified_type vm this t in
                let p' = get_simplified_type vm this p in
                match match_type vm this ~target: t' ~parent: p' with
                | `Failed -> None
                | #tmatch_type as m -> loop (m :: acc) rest
        in
        loop [] (List.zip_exn targets parents)
    
    and match_parents vm this ~target ~parents =
        let rec loop acc pl =
            match pl with
            | [] -> Some acc
            | p :: pl' ->
                let p' = get_simplified_type vm this p in
                match match_type vm this ~target ~parent: p' with
                | `Failed -> None
                | #tmatch_type as m -> loop (m :: acc) pl'
        in
        loop [] parents
end