open Base
open Stdint

[@@@warning "-30"]

type tvalue =
    | VClass of Types.tclass * class_value
    | VProtocol of Types.tprotocol * tvalue
    | VValueKind of Types.tvalue_kind * value_kind_value
    | VTaggedKind of Types.ttagged_kind * tagged_kind_value
    | VNative of Types.tnative * native_value

and class_value = tvalue array

and value_kind_value = {
    tag: int;
    value: tvalue
}

and tagged_kind_value = {
    tag: int;
    values: tvalue list;
    members: tvalue array
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