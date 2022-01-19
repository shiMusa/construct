# construct

(Jai) `#insert #run construct(...)` allows to assign `struct`s as constants during compile time.

See `example.jai` on how to use.

Currently, pointers are not allowed as struct members!

But most basic types are:

- intrinsic data types (`s8`, `u8`, etc.) 
- strings
- arrays
- enums
- (polymorphic) structs
- nestings thereof