open Base
open Util.BetterStdint
open Types

[@@@warning "-30"]

type tvalue = {
    t: Type.t;
    kind: kvalue
}

and kvalue =
    | VClass of class_value
    | VValueKind of uint8
    | VMultiValueKind of uint64
    | VTaggedKind of tagged_kind_value
    | VMultiTaggedKind of multi_tagged_kind_value
    | VNative of native_value
    | VMasked of tvalue

and class_value = tvalue Option_array.t

and tagged_kind_value = {
    tag: uint8;
    values: tvalue list;
    members: tvalue Option_array.t
}

(* Behavior for tagged multi kinds with members does not currently exist *)
and multi_tagged_kind_value = (uint8, tvalue list) Hashtbl.t

and native_value =
    | VBool of bool
    | VInt8 of int8
    | VUInt8 of uint8
    | VInt16 of int16
    | VUInt16 of uint16
    | VInt32 of int32
    | VUInt32 of uint32
    | VInt64 of int64
    | VUInt64 of uint64
    | VPtr of tvalue Option_array.t
    | VOpaque of Caml.Obj.t


(*let get_type = function
    | VClass(t, _) -> TClass t
    | VValueKind(t, _) -> TValueKind t
    | VTaggedKind(t, _) -> TTaggedKind t
    | VNative(t, _) -> TNative t
    | VMasked(t, _) -> t

let rec get_full_type = function
    | VMasked(_, v) -> get_full_type v
    | t -> get_type t*)