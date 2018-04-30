* Consider refining the `View` heuristic with `is_nothrow_copy_constructible`
* Concern about constraining `operator|` for range adaptors with the current minimal specification.
* Concern about the currying of arguments in range adaptor objects, and possible ambiguity for a range adaptor that accepts a variadic number of ranges.
* `iota_view` should allow asymmetric deduction unless the two types are integral types with differing "signed-ness"
* Paper should have a section on "surprising" design decisions.
* No one cares that adaptors are intermixed with factories in namespace `view`

Large group feedback:
* Don't bother with `view::remove_if`
* Don't provide `view::filter_out`
* `BoundedRange` bikeshed:
  * `ClassicRange` 13
  * `SameTypeRange` 6
  * `IteratorPairRange` 3
  * `BoundedRange` 3
  * `UniformRange` 2
  * `IteratorRange` 5
  * `IteratorBoundedRange` 12
  * `NonSentinelRange` 9
  * `HomogenousRange` 5
  * `ConsistentRange` 0
