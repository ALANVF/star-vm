open Base
open Util.BetterStdint
open Types

type tvalue =
    | VClass of tclass * class_value
    | VValueKind of tvalue_kind * uint8
    | VMultiValueKind of tvalue_kind * uint64
    | VTaggedKind of ttagged_kind * tagged_kind_value
    | VMultiTaggedKind of ttagged_kind * multi_tagged_kind_value
    | VNative of tnative * native_value
    | VMasked of tmodule * tvalue

and class_value = tvalue Uniform_array.t

and tagged_kind_value = {
    tag: uint8;
    values: tvalue list;
    members: tvalue Uniform_array.t
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
    | VInt128 of int128
    | VUInt128 of uint128
    | VDec of float
    | VPtr of int * tvalue Uniform_array.t
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