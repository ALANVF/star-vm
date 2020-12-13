val (<<): ('b -> 'c) -> ('a -> 'b) -> 'a -> 'c

val (>>): ('a -> 'b) -> ('b -> 'c) -> 'a -> 'c

val (<|): ('a -> 'b) -> 'a -> 'b

val (==): 'a -> 'a -> bool

val (!=): 'a -> 'a -> bool

val poly_hash: ('a * 'b) list -> ('a, 'b) Base.Hashtbl.t


(* A large amount of this is taken from Stdint *)
module BetterStdint: sig
    type int8 = Stdint.int8
    type int16 = Stdint.int16
    type int24 = Stdint.int24
    type int32 = Stdint.int32
    type int40 = Stdint.int40
    type int48 = Stdint.int48
    type int56 = Stdint.int56
    type int64 = Stdint.int64
    type int128 = Stdint.int128
    type uint8 = Stdint.uint8
    type uint16 = Stdint.uint16
    type uint24 = Stdint.uint24
    type uint32 = Stdint.uint32
    type uint40 = Stdint.uint40
    type uint48 = Stdint.uint48
    type uint56 = Stdint.uint56
    type uint64 = Stdint.uint64
    type uint128 = Stdint.uint128

    module type Int = sig
        type t
        
        val zero: t
        val one: t
        val max_int: t
        val min_int: t
        val bits: int
        val add: t -> t -> t
        val sub: t -> t -> t
        val mul: t -> t -> t
        val div: t -> t -> t
        val succ: t -> t
        val pred: t -> t
        val neg: t -> t
        val abs: t -> t
        val of_int: int -> t
        val to_int: t -> int
        val of_float: float -> t
        val to_float: t -> float
        val of_nativeint: nativeint -> t
        val to_nativeint: t -> nativeint
        val of_int8: int8 -> t
        val to_int8: t -> int8
        val of_int16: int16 -> t
        val to_int16: t -> int16
        val of_int24: int24 -> t
        val to_int24: t -> int24
        val of_int32: int32 -> t
        val to_int32: t -> int32
        val of_int40: int40 -> t
        val to_int40: t -> int40
        val of_int48: int48 -> t
        val to_int48: t -> int48
        val of_int56: int56 -> t
        val to_int56: t -> int56
        val of_int64: int64 -> t
        val to_int64: t -> int64
        val of_int128: int128 -> t
        val to_int128: t -> int128
        val of_uint8: uint8 -> t
        val to_uint8: t -> uint8
        val of_uint16: uint16 -> t
        val to_uint16: t -> uint16
        val of_uint24: uint24 -> t
        val to_uint24: t -> uint24
        val of_uint32: uint32 -> t
        val to_uint32: t -> uint32
        val of_uint40: uint40 -> t
        val to_uint40: t -> uint40
        val of_uint48: uint48 -> t
        val to_uint48: t -> uint48
        val of_uint56: uint56 -> t
        val to_uint56: t -> uint56
        val of_uint64: uint64 -> t
        val to_uint64: t -> uint64
        val of_uint128: uint128 -> t
        val to_uint128: t -> uint128
        val of_substring: string -> pos:int -> (t * int)
        val of_string: string -> t
        val to_string: t -> string
        val to_string_bin: t -> string
        val to_string_oct: t -> string
        val to_string_hex: t -> string
        val printer: Format.formatter -> t -> unit
        val printer_bin: Format.formatter -> t -> unit
        val printer_oct: Format.formatter -> t -> unit
        val printer_hex: Format.formatter -> t -> unit
        val of_bytes_big_endian: Bytes.t -> int -> t
        val of_bytes_little_endian: Bytes.t -> int -> t
        val to_bytes_big_endian: t -> Bytes.t -> int -> unit
        val to_bytes_little_endian: t -> Bytes.t -> int -> unit
        val compare: t -> t -> int
        
        
        val (+): t -> t -> t
        val (-): t -> t -> t
        val ( * ): t -> t -> t
        val (/): t -> t -> t
        val (mod): t -> t -> t

        val pow: t -> t -> t
        val ( ** ): t -> t -> t
        
        val (~-): t -> t
        
        val (land): t -> t -> t
        val (lor): t -> t -> t
        val (lxor): t -> t -> t
        val (lsl): t -> int -> t
        val (lsr): t -> int -> t
        val (asr): t -> int -> t

        val lnot: t -> t
        val (~~): t -> t
    end
    
    module Int8: Int with type t = int8
    module Int16: Int with type t = int16
    module Int24: Int with type t = int24
    module Int32: Int with type t = int32
    module Int40: Int with type t = int40
    module Int48: Int with type t = int48
    module Int56: Int with type t = int56
    module Int64: Int with type t = int64
    module Int128: Int with type t = int128
    module Uint8: Int with type t = uint8
    module Uint16: Int with type t = uint16
    module Uint24: Int with type t = uint24
    module Uint32: Int with type t = uint32
    module Uint40: Int with type t = uint40
    module Uint48: Int with type t = uint48
    module Uint56: Int with type t = uint56
    module Uint64: Int with type t = uint64
    module Uint128: Int with type t = uint128
end

(*module Ring_buffer: functor(E: sig type t end) -> CCRingBuffer.S with type Array.t = E.t array and type Array.elt = E.t*)