* [ ] `-> auto&&` is broken in C++20
* [ ] Cleanup the excess `static_cast`s in the CPO wording, now that we can rely on guaranteed elision
* [X] More `constexpr` for `move_sentinel`
* [X] `constexpr` the algorithms that are `constexpr` in the IS
* [ ] Respecify `common_iterator` in terms of `variant`
* [X] Remove `ranges::exchange` (Verify it's unused)
* [X] Specify CPO definitions in an inline namespace with an \unspec name
* [X] Steal `Swappable` and `std2::swap` from P0898R0.
* [ ] Reorder IS [iterator] sections (as in the TS) so the synopsis precedes the iterator requirements.
* [ ] https://github.com/ericniebler/stl2/issues/554
* [ ] https://github.com/ericniebler/stl2/issues/553
* [X] Relocate `dangling` to `<range>` as in P0896R0
* [X] Replace `typedef` with `using`
* [X] Move `tag` namespace into `std`
* [X] Make `WeaklyEqualityComparableWith` exposition-only
* [X] Put the `dangling` declaration in `<range>`
* [ ] Use expression-equivalent in [range.iterators.forward]
* [ ] Reformulate `noexcept(E1) && noexcept(E2)` as `noexcept(E1, E2)`
* [ ] Cleanup the subclause-per-operation garbage in the iterator adaptors
* [X] https://github.com/ericniebler/stl2/issues/502
* [X] `projection` definition from [intro.defs] in 898
* [X] Consider making `advance`, `next`, `prev`, and `distance` *implicit* CPOs like the algorithms

Document-wide changes to make:
* [X] Remove "std2." from stable names or replace with "range."
* [ ] Ensure references to old requirements tables agree with P0898
* [X] Reformulate concepts AND REQUIRES CLAUSES to use C++20
* [ ] Replace `{ E } -> Concept<Args...>&&;` with `E; requires Concept<decltype((E)), Args...>;`
* [X] Use `_v` traits everywhere
* [X] Use `remove_cvref_t` to replace `remove_ref_t<remove_cv_t<foo>>` and (where appropriate) `decay_t`
* [X] Reformulate `result_of` (`indirect_result_of`) uses in terms of `invoke_result` (`indirect_invoke_result`)
* [X] Define *explicit* CPOs as inline constexpr objects
* [ ] Add an "Open Issues" subclause to the design discussion
* [ ] Replace `\xname`s with new-style `\placeholder` exposition-only names
