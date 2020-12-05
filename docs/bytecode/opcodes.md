[The code](../../lib/opcode.ml) should be helpful enough, but here's this anyways


### retain
```
retain
```

Increases the reference count of a value.

Does not have an effect on constants or uncounted values.


### release
```
release
```

Decreases the reference count of a value. If the reference count becomes 0, the object is destroyed (more on that later).

Does not have an effect on constants or uncounted values.


### deinit
```
deinit
```

Calls the deinitializer of a value.


### push
```
push &<const>
push $<reg>
push .<member>
push %.<member>
```

1) Pushes the constant `const` onto the stack.
2) Pushes the register `reg` onto the stack.
3) Pushes the member `member` of a value onto the stack.
4) Pushes the static member `member` onto the stack.


### set
```
set $<reg>
set .<member>
set %.<member>
```

1) Assigns a value to the register `reg`.
2) Assigns a value to the member `member` of a value.
3) Assigns a value to the static member `member`.


### swap_reg
```
swap_reg $<reg-1>, $<reg-2>
```

Swaps the value of `reg-1` with the value of `reg-2`


### pop
```
pop
pop <depth>
```

1) Pops a value from the stack.
2) Pops `depth` values from the stack.


### clear
```
clear
```

Clears the stack.


### swap
```
swap
```

Swaps the last 2 values on the stack. This will fail if the stack has less than 2 values.


### pin
```
pin
```

Pins the last value onto the stack. This means that any operations that would usually remove
it from the stack do not actually remove it. This is particularly helpful for cascades.


### unpin
```
unpin
```

Unpins the last value from the stack.


### add
```
add
```

Adds 2 values.


### sub
```
sub
```

Subtracts 2 values.


### mult
```
mult
```

Multiplies 2 values.


### pow
```
pow
```

Exponentiates 2 values. (is that a real word?)


### div
```
div
```

Divides 2 values.


### idiv
```
idiv
```

Performs integer division on 2 values.


### mod
```
mod
```

Gets the remainder of dividing 2 values.


### mod0
```
mod0
```

Determines if `A` can be divided equally by `B`.


### and
```
and
```

Bitwise AND.


### or
```
or
```

Bitwise OR.


### xor
```
xor
```

Bitwise exclusive-OR.


### shl
```
shl
```

Left-shift.


### shr
```
shr
```

Right-shift.


### eq
```
eq
```

Determines if 2 values are equal.


### ne
```
ne
```

Determines if 2 values are inequal.


### gt
```
gt
```

Determines if `A` is greater than `B`.


### ge
```
ge
```

Determines if `A` is greater than or equal to `B`.


### lt
```
lt
```

Determines if `A` is less than `B`.


### le
```
le
```

Determines if `A` is less than or equal to `B`.


### neg
```
neg
```

Negates a value.


### not
```
not
```

Only exists for operator overloading purposes.


### compl
```
compl
```

Bitwise NOT.


### truthy
```
truthy
```

Determines if a value is "truthy".


### incr
```
incr $<reg>
```

Increases the value of a register.


### decr
```
decr $<reg>
```

Decreases the value of a register.


### consecutive
```
consecutive (all | any | one | none) @<sec-1>, @<sec-2>, ...
```

Emulates the behavior of short-circuiting operators.

TODO: more docs here


### give
```
give
```

Sends a value to the current consecutive instruction, terminates the current code section, and restores the code section stack.

Terminator: consecutive choice terminator


### sec
```
sec @<sec>
```

Executes a code section.


### sec_if
```
sec_if @<sec>
```

Executes a code section if a condition is true.


### sec_either
```
sec_either @<true-sec>, @<false-sec>
```

Executes a code section depending on a condition.

### sec_table
```
sec_table @<sec-1>, ...
```

Switch/case thing.


### sec_jtable
```
sec_jtable @<sec-1>, ...
sec_jtable @<sec-1>, ..., else @<default-sec>
```

Jump-table thing


### sec_ltable
```
sec_ltable @<case-1> => @<dest-1>, ...
sec_ltable @<case-1> => @<dest-1>, ..., else @<default-dest>
```

Switch/case thing.


### csec
```
csec @<sec>
```

Switches execution to a new code section.

Terminator: section terminator


### csec_if
```
csec @<sec>
```

Well now that I'm writing the docs, this seems kinda dumb ngl.

Terminator: optional section terminator


### csec_either
```
csec_either @<true-sec>, @<false-sec>
```

Switches execution to a new code section depending on a condition.

Terminator: section terminator


### psec
```
psec
psec <depth>
```

Exits the current code section, or multiple code sections if `depth` is specified.

Terminator:
| instruction    | terminator               |
|----------------|--------------------------|
| `psec`         | section terminator       |
| `psec <depth>` | multi-section terminator |


### pcsec
```
pcsec <depth>, @<sec>
```

Exits `depth` number of code sections. Then, it switches the current execution to a new code section.

Terminator: multi-section terminator


### unreachable
```
unreachable
```

Terminator: global terminator


### return
```
return
```

Returns a value from a method. Note that `Void` values cannot be instantiated, and therefore cannot be returned.

Terminator: method terminator


### return void
```
return void
```

Returns from a method

Terminator: method terminator.


### trap
```
trap @<try-sec>, $<catch-reg-1> => @<catch-sec-1>, ...
```

TODO


### ptrap
```
ptrap
```

Successfully exits a trap section.

Terminator: trap terminator


### throw
```
throw
```

Raises an error.

Terminator: multi-section terminator


### init
```
init %<type>, #<sel>
```

Creates an instance of `type`.

The arity of the call is determined by the selector.


### send
```
send %<type>, #<sel>
send #<sel>
```

1) Sends message `sel` to `type`
2) Sends message `sel` to a value

The arity of the call is determined by the selector.


### super
```
super %<type>, #<sel>
super %<type>
```

1) Sends message `sel` to superclass `type`
2) Resends the current message to superclass `type`

The arity of the call is determined by the selector.


### cast
```
cast %<type>
```

Casts a value to type `type`.


### isa
```
isa %<type>
```

Determines if a value is an instance of type `type`.


### kind
```
kind %<type>, <index>
```

Creates an instance of a kind value.

The arity of the opcode is determined by the index.


### kind_id
```
kind_id
```

Gets the ID of a kind value.


### kind_slot
```
kind_slot <slot>
```

Gets the value of a slot from a kind value. Only valid for tagged kinds.


### kind_value
```
kind_value
```

Gets the underlying value from a kind value. Only valid for enumerated kinds.


### debug
```
debug everything
debug regs
debug stack
debug callStack
debug codeSectionStack
debug reg $<reg>
debug const &<const>
debug type %<type>
```

Used for debugging purposes only.