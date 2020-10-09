StarVM's value stack works nearly identically to Forth.

Forth:
```fth
1 2 - 3 +   ( => 2 )
```

StarVM:
```
&1 = Int 1
&2 = Int 2
&3 = Int 3

...

push &1
push &2
sub
push &3
add
debug inspectStack   ;=> [ Int 2 ]
```

TODO: explain this in more detail