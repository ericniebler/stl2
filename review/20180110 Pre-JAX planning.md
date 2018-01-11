* Whither CPOs? Follow concepts? `swap` can't. CPOs default to `std2`.
  * Remove the deprecated rvalue behavior for the `c?r?begin`, `c?r?end`, and `c?data` CPO variants.
  * Do we want to propose `cdata` at all? Casey made it up for consistency, and was hoping to get user feedback to decide whether or not to standardize.
* Everything in `std2` should go into a `v1` inline namespace.
* Division into `std` and `std2`:
  * Clause 6 & 7 into namespace `std`
    * Make `WeaklyEqualityComparable` exposition-only
    * How to access `std` concepts from `std2`? pull in with `using`? Always qualify?
  * Clause 8:
    * `std`:
      * Constraining `std::exchange` is probably fine
      * `invoke` is already in C++17 - we can simply omit.
      * `common_type` and `common_reference` can merge into namespace `std`.
    * `std2`:
      * function objects *must* go into `std2`. What about ericniebler/stl2#21? No consensus for change for JAX.
      * swappable traits, although they are identical to those in std except for using the `std2` CPO.
      * `tagged`
  * Clause 9-11 Iterators/Ranges/Algorithms into `std2`
    * What about the fact that algs in `std` are more specialized since they take iterator pairs? (ericniebler/stl2#371)
  * Clause 12 into `std` (this is literally only the URNG concept, which should be renamed URBG)
