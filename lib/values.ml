open Base
open Stdint
open Types

[@@@warning "-30"]

type tvalue = {
    t: Type.t;
    kind: kvalue
}

and kvalue =
    | VClass of class_value
    | VValueKind of value_kind_value
    | VTaggedKind of tagged_kind_value
    | VNative of native_value
    | VMasked of tvalue


and class_value = tvalue Option_array.t

and value_kind_value = {
    tag: int;
    value: tvalue
}

and tagged_kind_value = {
    tag: int;
    values: tvalue list;
    members: tvalue Option_array.t
}

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
    (*| VFunc of (tvalue list -> tvalue option)*)
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