# StarVM

StarVM is a portable virtual machine for the [Star programming language](https://github.com/ALANVF/Star-lang-specification).

Things to note:
- This is not at all finished
- This is most likely only going to be used for bootstrapping, although I may keep it around afterwards if it's good
- I like bulleted lists


## Building and running StarVM locally

Requirements:
- Free Pascal 3.2.0 (or later).

### Linux/MacOS

Use the `run` script in the main directory to compile and run the program

### Windows

Yell at me for not using fpcmake because I'm lazy


## So... what happened to using LLVM?

LLVM is a royal pain to work with if you're not using C++ (which is also a pain to work with). Every other API is either incomplete, old as hell, or has no docs, and it's really just a mess.


## Why Pascal?

~~That's *Object* Pascal tyvm~~

I chose Object Pascal because it's honestly just better than using C or C++.

Object Pascal > C/C++ (non-exhaustive):
- (Very) cross-platform
- Fast to compile
- Generally more optimized and efficient
- Good standard library
- Strongly-typed
- No headers / Modular
- Native set and range types
- Unions (variant records) are always checked
- Range checks
- Less pointers

Object Pascal > C++ (non-exhaustive):
- Language and standard library are not bloated with useless crap
- Generics are way less finicky
- Better RTTI