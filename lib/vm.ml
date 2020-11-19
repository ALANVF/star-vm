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
    |> Module.get_type this
    |> simplify_type vm this

(* Uh... might wanna revisit this at some point *)
module Checks = struct
    type tmatch_type = [
        | `IsExact
        | `IsSame
        | `IsDerivedParent of (type_index * tmatch_type) list
        | `IsParent of (type_index * tmatch_type) list
        | `IsDerived of tmatch_type list
        | `IsDerivedParam of tmatch_type list list
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
                    | Some parent_results -> `IsDerived parent_results
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
                            | res -> `IsDerivedParam res)
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
            
            | TModule {m_params; _}, TParam {parents; params; _} -> begin
                match m_params, params with
                | _, [] -> begin
                    match match_parents ~strict: false vm this ~target: target' ~parents with
                    | Some parent_results -> `IsDerived parent_results
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
    
    and match_module ?(strict=true) vm this ~target ~parent =
        let open Poly in
        let open Module in
        let open Class in
        let open Protocol in
        let open TaggedKind in

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

        match target, parent with
        | {m_name=n; m_params=[]; _}, {m_name=n'; m_params=[]; _} when n = n' -> `IsExact
        | {m_name=n; m_params=g; m_type=t; _}, {m_name=n'; m_params=g'; m_type=t'; _} -> begin
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
            
            match t, t' with
            (*
            class A {}
            class B of A {}

            ;-- my _ (Parent) = target

            my bad (B) = A[new]
            my good (A) = B[new] ;-- only without `strict`
            *)
            | KClass {t_parents=[]; _}, KClass _ -> match_params `IsExact
            | KClass _, KClass _ when strict -> match_params `IsExact
            | KClass {t_parents=pl; _}, (KClass _ | KProtocol _) -> begin
                match match_some_parents (TModule parent) pl with
                | Some results -> `IsDerivedParent results
                | None -> `Failed
            end

            (* I think this is how it works? idk
            protocol Positional {}
            protocol Sequential of Positional {}

            ;-- my _ (Parent) = target

            my bad (Sequential) = Positional[new]
            my good (Positional) = Sequential[new]
            *)
            | KProtocol {t_parents=[]; _}, KProtocol _ -> match_params `IsExact
            | KProtocol {t_parents=pl; _}, KProtocol _ -> begin
                match match_some_parents (TModule parent) pl with
                | Some results -> `IsDerivedParent results
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
            | KTaggedKind {k_is_flags=f; _}, KTaggedKind {k_is_flags=f'; _} when f <> f' -> `Failed
            | KTaggedKind _, KTaggedKind {t_parents=[]; _} -> match_params `IsExact
            | KTaggedKind _, KTaggedKind {t_parents=pl; _} -> begin
                match match_some_parents (TModule target) pl with
                | Some results -> `IsParent results
                | None -> `Failed
            end
            | KTaggedKind {t_parents=pl; _}, KProtocol _ -> begin
                match match_some_parents (TModule parent) pl with
                | Some results -> `IsDerivedParent results
                | None -> `Failed
            end

            | KNative na, KNative na' -> begin
                let match_ptrs i i' = (* TODO: respect void pointers here *)
                    let e = get_simplified_type vm target i in
                    let e' = get_simplified_type vm parent i' in
                    match match_type vm this ~target: e ~parent: e' with
                    | `Failed -> `Failed
                    | #tmatch_type as m -> `IsParametric(exact_or_same, [m])
                in

                match g, g' with
                | [], [] -> begin
                    match na, na' with
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
                    match na, na' with
                    | NPtr i, NPtr i' -> match_ptrs i i'
                    | _, _ -> `Failed
            end

            | _, _ -> `Failed
        end
    
    (*let get_better_match m1 m2 =
        match m1 with*)
end