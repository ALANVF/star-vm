open Base
open Base.Either.Export
open Types
open Index
open Util

type t = {
    mutable modules: (string, Module.t list) Hashtbl.t
}


let todo () = failwith "NYI"

let create () =
    {
        modules = Hashtbl.Poly.create()
    }

let lookup_module {modules; _} name = Hashtbl.find_multi modules name

let add_module {modules; _} m =
    Hashtbl.add_multi modules
        ~key: m#name
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
    | TExpand _ -> todo()
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
    | TExpand _ -> todo()
    | TLazy f -> simplify_type vm this (f ())
    | TThis -> TModule this
    | _ -> t

let get_simplified_type vm this index =
    index
    |> this#get_type
    |> simplify_type vm this

(* Uh... might wanna revisit this at some point *)
module Checks = struct
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

    let rec match_type ?(strict=true) vm this ~target ~parent =
        let open Type in
        
        let match_type' target' parent' =
            match target', parent' with
            | (TImport _ | TExpand _ | TLazy _ | TThis), _ | _, (TImport _ | TExpand _ | TLazy _ | TThis) -> invalid_arg "Unexpected complex type!"
            | TErased, _ | _, TErased -> `IsErased

            | TParam {parents = []; params = []; _}, TParam {parents = []; params = []; _} -> `IsExact
            (*| _, TParam {parents = []; params = []; _} -> `IsErased*)
            | TParam {parents = []; params = []; _}, _ -> `Failed
            | TParam {parents; params; _}, TParam {parents = parents'; params = params'; _} -> begin
                match params, params' with
                | _, [] -> begin
                    match match_parents ~strict: false vm this ~target ~parents: parents' with
                    | Some [] -> `IsSame
                    | Some parent_results -> `IsParent (List.zip_exn parents' parent_results)
                    | None -> `Failed
                end
                | [], _ -> `Failed
                | _, _ -> (* HKT *)
                    let rec loop acc tpl =
                        match tpl with
                        | [] -> Some acc
                        | tp :: tpl' ->
                            let tp' = get_simplified_type vm this tp in
                            match match_parents ~strict: false vm this ~target: tp' ~parents: parents' with
                            | Some rl' -> loop (rl' :: acc) tpl'
                            | None -> None
                    in
                    let map_parents =
                        loop [] >> Option.map ~f: (function
                            | [] -> `IsSame
                            | res -> `IsComplexParam res)
                    in
                    match match_types ~strict: false vm this ~targets: params ~parents: params' with
                    | Some [] ->
                        parents
                        |> map_parents
                        |> Option.value ~default: `Failed
                    | Some param_results ->
                        parents
                        |> map_parents
                        |> Option.map ~f: (fun f -> `IsParametric(f, param_results))
                        |> Option.value ~default: `Failed
                    | None -> `Failed
            end
            
            | TModule m, TParam {parents; params; _} -> begin
                match m#params, params with
                | _, [] -> begin
                    match match_parents ~strict: false vm this ~target: target' ~parents with
                    | Some parent_results -> `IsParent (List.zip_exn parents parent_results)
                    | None -> `Failed
                end
                | [], _ -> `Failed
                | _, _ -> todo() (* HKT *)
            end
            | TModule tm, TModule pm -> match_module ~strict vm this ~target: tm ~parent: pm
            
            | TMultiModule _, _ | _, TMultiModule _ -> todo()

            | _, _ -> `Failed
        in

        match_type' target parent
    
    and match_types ?(strict=true) vm this ~targets ~parents =
        let rec loop acc pl =
            match pl with
            | [] -> Some acc
            | (t, p) :: rest ->
                let t' = get_simplified_type vm this t in
                let p' = get_simplified_type vm this p in
                match match_type ~strict vm this ~target: t' ~parent: p' with
                | `Failed -> None
                | #tmatch_type as m -> loop (m :: acc) rest
        in
        match targets, parents with
        | [], [] -> Some []
        | _, _ -> loop [] (List.zip_exn targets parents)

    and try_match_types ?(strict=true) vm this ~targets ~parents =
        if List.(length targets = length parents) then
            match_types ~strict vm this ~targets ~parents
        else
            None
    
    (* rename this...? *)
    and match_parents ?(strict=true) vm this ~target ~parents =
        let rec loop acc pl =
            match pl with
            | [] -> Some acc
            | p :: pl' ->
                let p' = get_simplified_type vm this p in
                match match_type ~strict vm this ~target ~parent: p' with
                | `Failed -> None
                | #tmatch_type as m -> loop (m :: acc) pl'
        in
        loop [] parents
    
    and match_module ?(strict=true) vm this ~(target: tmodule) ~(parent: tmodule) =
        let open Poly in

        let match_some_parents target' parents' =
            let rec loop acc pl =
                match pl with
                | [] -> (match acc with [] -> None | _ -> Some acc)
                | p :: pl' ->
                    let p' = get_simplified_type vm this p in
                    match match_type ~strict vm this ~target: target' ~parent: p' with
                    | `Failed -> loop acc pl'
                    | #tmatch_type as m -> loop ((p, m) :: acc) pl'
            in
            loop [] parents'
        in

        match (target#name, target#params), (parent#name, parent#params) with
        | (n, []), (n', []) when n = n' -> `IsExact
        | (n, g), (n', g') -> begin
            let same_name = n = n' in
            let exact_or =
                if same_name then (fun _ -> `IsExact)
                else (fun v -> v)
            in
            let exact_or_same = exact_or `IsSame in
            let exact_or_failed = exact_or `Failed in
            
            let match_params res =
                match try_match_types vm this ~targets: g ~parents: g' with
                | Some [] when same_name -> (res :> tmatch_type_result) (* wtf *)
                | Some results when same_name -> `IsParametric(res, results)
                | _ -> `Failed
            in

            match get_module_kind target, get_module_kind parent with
            (*
            class A {}
            class B of A {}

            ;-- my _ (Parent) = target

            my bad (B) = A[new]
            my good (A) = B[new] ;-- only without `strict`
            *)
            | KClass tc, KClass _ when tc#parents = [] -> match_params `IsExact
            | KClass _, KClass _ when strict -> match_params `IsExact
            | KClass tc, (KClass _ | KProtocol _) -> begin
                match match_some_parents (TModule parent) tc#parents with
                | Some results -> `IsParent results
                | None -> `Failed
            end

            (* I think this is how it works? idk
            protocol Positional {}
            protocol Sequential of Positional {}

            ;-- my _ (Parent) = target

            my bad (Sequential) = Positional[new]
            my good (Positional) = Sequential[new]
            *)
            | KProtocol tp, KProtocol _ when tp#parents = [] -> match_params `IsExact
            | KProtocol tp, KProtocol _ -> begin
                match match_some_parents (TModule parent) tp#parents with
                | Some results -> `IsParent results
                | None -> `Failed
            end

            | KValueKind _, KValueKind _ -> match_params `IsExact

            (*
            kind A {has a}
            kind B of A {has b}

            ;-- my _ (Target) = parent

            my good (B) = A[a]
            my bad (A) = B[b]
            *)
            | KTaggedKind tt, KTaggedKind pt when tt#is_flags <> pt#is_flags -> `Failed
            | KTaggedKind _, KTaggedKind pt when pt#parents = [] -> match_params `IsExact
            | KTaggedKind _, KTaggedKind pt -> begin
                match match_some_parents (TModule target) pt#parents with
                | Some results -> `IsDerived results
                | None -> `Failed
            end
            | KTaggedKind tt, KProtocol _ -> begin
                match match_some_parents (TModule parent) tt#parents with
                | Some results -> `IsParent results
                | None -> `Failed
            end

            | KNative tn, KNative pn -> begin
                let match_ptrs i i' = (* TODO: respect void pointers here *)
                    let e = get_simplified_type vm target i in
                    let e' = get_simplified_type vm parent i' in
                    match match_type vm this ~target: e ~parent: e' with
                    | `Failed -> `Failed
                    | #tmatch_type as m -> `IsParametric(exact_or_same, [m])
                in

                match g, g' with
                | [], [] -> begin
                    match tn#kind, pn#kind with
                    | NVoid, NVoid
                    | NBool, NBool
                    | NInt8, NInt8
                    | NUInt8, NUInt8
                    | NInt16, NInt16
                    | NUInt16, NUInt16
                    | NInt32, NInt32
                    | NUInt32, NUInt32
                    | NInt64, NInt64
                    | NUInt64, NUInt64 -> exact_or_same
                    | NPtr i, NPtr i' -> match_ptrs i i'
                    | NOpaque, NOpaque -> exact_or_failed
                    | _, _ -> `Failed
                end
                | _, _ ->
                    match tn#kind, pn#kind with
                    | NPtr i, NPtr i' -> match_ptrs i i'
                    | _, _ -> `Failed
            end

            | _, _ -> `Failed
        end
    
    let get_better_match m1 m2 =
        let rec is_exact (inner, params) =
            if inner != `IsExact then
                false
            else
                let check = function
                    | `IsExact -> true
                    | `IsParametric p -> is_exact p
                    | _ -> false
                in
                params
                |> List.for_all ~f: check
        in
        let indeterminable () = failwith "Indeterminable!" in
        match m1, m2 with
        | `IsExact, `IsExact
        | `IsSame, `IsSame
        | `IsErased, `IsErased -> indeterminable()
        
        | `IsExact, `IsParametric p when is_exact p -> indeterminable()
        | `IsExact, _ -> `Left m1
        
        | `IsSame, (`IsExact | `IsParametric(`IsExact, _)) -> `Right m2
        | `IsSame, `IsParametric(`IsSame, _) -> indeterminable()
        | `IsSame, _ -> `Left m1

        | `IsParent _, `IsParent _ -> todo()

        | `IsDerived _, `IsDerived _ -> todo()

        | `IsComplexParam _, `IsComplexParam _ -> todo()

        | `IsErased, _ -> `Right m2

        | _, `IsErased -> `Left m1
        | _, _ -> todo()
end