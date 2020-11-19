open Base

let (<<) f g = Fn.compose f g [@@inline always]

let (>>) f g = Fn.compose g f [@@inline always]

let (<|) = (@@)