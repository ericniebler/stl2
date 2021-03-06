Followup:
* [ ] Fix `bool` conversions in algorithms IS-wide. Also change "`E` holds" to "`E` is `true`".
* [ ] Add something about potential SFINAE to the definition of expression-equivalent, and remove the notes from the CPOs.
* [ ] Editorial issue: Consider using mathmode `\max` and `\min` uniformly in the algorithm specifications.
* [ ] LWG issue: `copy_backward` and `move_backward` are "range-and-a-half" algorithms; we should add two range versions (and possibly drop the range-and-a-half versions in `std::ranges` before C++20).
* [ ] LWG issue: Add set algorithms to [algorithm.stable].
* [ ] Editorial issue: audit algorithms for more cases where "Let $N$ be `last - first`" could cleanup wording.
* [ ] MC: We have concerns about the words of `is_permutation`. AM: There is an issue with the created iterator interacting with the projection.
* [ ] Should `<numeric>` export `__cpp_lib_concepts` since it defines `UniformRandomNumberGenerator`?

P0896:
* [ ] The new "no explicitly specified template parameters" policy applies to both `std` and `std::ranges` `<algorithms>`, but inconsistently only to [specialized.algorithms] in `std::ranges`.
* [ ] Make `iota` helper concepts public, and factor out commonality with the iterator concepts
* [ ] `reverse_iterator` needs to use `ranges::prev` and not `std::prev`. I *think* this is valid, but need to verify that *`Cpp17BidirectionalIterator`*s model `BidirectionalIterator`. Fully audit `reverse_iterator` and `move_iterator` for similar SNAFUs.
* [ ] If we require that contiguous allocator-aware containers have contiguous iterators without requiring that Allocator pointers are contiguous iterators, we effectively forbid such a container from using the pointer type directly as an iterator.
* [ ] The magic for returning sentinels needs to be expanded to include arithmetic, and possibly copied to [specialized.algorithms]. Also `i - n` needs to make sense, or I need to eradicate it.
* [ ] Audit the view adaptors for overconstraint requiring `InputRange` when they could require vanilla `Range`.
* [ ] When a view adaptor uses the iterators/sentinel of the underlying range directly, it should be "rvalue range-able" iff the underlying range is "rvalue range-able".
* [ ] `operator->` for the view adaptors' iterators
  * [ ] `counted_iterator`
  * [ ] Reconcile the `common_iterator` and *has-arrow* `operator->` styles.
* [ ] Forbid explicit template arguments for quasi-CPOs (algorithms, iterator operations, specialized memory algorithms)
* [ ] Define "models", and use it throughout to replace both "`foo` satisfies `Concept`" and the "syntactic requirements...otherwise ill-formed NDR" dance.
* [ ] `split_view` on `ForwardRange`s has complexity problems
* [ ] `Decrementable` doesn't constrain the behavior of objects that aren't both *incrementable* and *decrementable*.
* [ ] Why are `single_view::begin`, `::end`, and `::data` declared `noexcept` when they have a precondition?
* [ ] Add `operator[]` (and other `view_interface` operations) to *ref-view*?
* [ ] Shorten new stable names.
* [ ] Consider constraining the template parameters of the "named tuples" returned by algorithms.
* [ ] https://github.com/ericniebler/stl2/issues/553
* [ ] Discussion with Alisdair in Batavia:
  > AM: `iota_view::operator[]` -- if not unbounded, don't I need constraint. I don't think that falls out of the Returns.
  >
  > CC: True. This may return a value that's outside of the range. Do we care, as long as the value is well-defined?
  >
  > AM: That feels to be the precondition of `operator[]` in general. I find it surprising that we define `operator[]` over a larger range than the view supports. Typically, when you do effects equivalent to, it would invoke UB in the places you would expect. This one would not do that. I would like an impl to be able to look for bugs.
  >
  > CC: Right. We can't do that here because it's defined. I would not object to making that change. Do we want something similar for everything else?
  >
  > AM: This is the first time I've found that.
  >
  > CC: Every operation on the iterator type could feasibly move outside of the range.
  >
  > AM: File it as an open question. It goes deeper than I had thought.
* [ ] Fix the intro - it hasn't been updated since P0!
* [X] Remove conditional `noexcept` from *`ref-view`*'s constructor, and require `ConvertibleTo`.
* [X] Consider merging the view and corresponding range adaptor into a single subclause: "view::common is ... common_view is..."
* [X] Feature test macro `__cpp_lib_ranges` defined in `<algorithm>`, `<functional>`, `<iterator>`, `<memory>`, and `<ranges>`
* [X] Audit all concepts for P0717
* [X] Update concept stable names as in the P0898 merge.
* [X] Use the P0788 terminology in function specifications
  * [X] utilities.tex
  * [X] iterators.tex
  * [X] ranges.tex
* [X] `-> auto&&` is broken in C++20 (Don't miss `\tcode{auto\&\&}`)
* [X] `ranges::destroy_at` needs to handle arrays properly.
* [X] Update the Swappable text from the P0898 merge.
* [X] `ranges::swap` of pointer-to-uninstantiated should avoid instantiation
* [X] `view_interface::data` needs to return a pointer
* [X] Mark *all* private members `\expos`
* [X] Audit the specifications of `iterator_category` for `forward`s that don't have reference reference types.
* [X] Detailed review of `split_view`
  * [X] What happens if `const Rng` models `ForwardRange` and `Rng` only models `InputRange`?
  * [X] `iterator_category`/`_concept`
* [X] Add mutable `single_view` access.
* [X] Why doesn't `split_view` inherit from `view_interface`?
* [X] Respecify `common_iterator` in terms of `variant`; fix the mess I made by making the operators members.
* [X] Turn all of the `\xname{iterator}` and `\xname{sentinel}` into non-`\xname` expo-`private`
* [X] Make `filter_view::iterator` and `::sentinel` expo
* [X] Add `ref_view` as exposition-only, propose to LEWG for SD.
* [X] Index Range concepts.
* [X] https://github.com/ericniebler/stl2/issues/554
* [X] "Hidden friend" all the things
* [X] Cleanup the excess `static_cast`s in the CPO wording, now that we can rely on guaranteed elision
* [X] https://github.com/ericniebler/stl2/issues/526 (algorithms should return subrange.)
* [X] Oops: `Cpp17Allocator` can't require `ContiguousIterator`
* [X] `s/template </template</`
* [X] s/equality preserving/equality-preserving
* [X] Replace `{ E } -> Concept<Args...>&&;` with `E; requires Concept<decltype((E)), Args...>;`
* [X] LEWG: Drop `tagged`, return named structs with named fields instead
* [X] LEWG: Harmonize names of `<range>` header and `std::ranges` namespace.
* [X] `constexpr` things that require `swap` as in the WP at Rapperswil
* [X] More `constexpr` for `move_sentinel`
* [X] `constexpr` the algorithms that are `constexpr` in the IS
* [X] Remove `ranges::exchange` (Verify it's unused)
* [X] Specify CPO definitions in an inline namespace with an \unspec name
* [X] Steal `Swappable` and `std2::swap` from P0898R0.
* [X] Relocate `dangling` to `<range>` as in P0896R0
* [X] Replace `typedef` with `using`
* [X] Move `tag` namespace into `std`
* [X] Make `WeaklyEqualityComparableWith` exposition-only
* [X] Put the `dangling` declaration in `<range>`
* [X] https://github.com/ericniebler/stl2/issues/502
* [X] `projection` definition from [intro.defs] in 898
* [X] Consider making `advance`, `next`, `prev`, and `distance` *implicit* CPOs like the algorithms

Post-merge:
* [ ] Rename the template parameter for the pre-existing iterator adaptors from `Iterator` to `I`
* [ ] Sweep the IS for "foo iterators" and replace with appropriate named requirements.

Document-wide changes to make:
* [X] Remove "std2." from stable names or replace with "range."
* [X] Reformulate concepts AND REQUIRES CLAUSES to use C++20
* [X] Use `_v` traits everywhere
* [X] Use `remove_cvref_t` to replace `remove_ref_t<remove_cv_t<foo>>` and (where appropriate) `decay_t`
* [X] Reformulate `result_of` (`indirect_result_of`) uses in terms of `invoke_result` (`indirect_invoke_result`)
* [X] Define *explicit* CPOs as inline constexpr objects
* [ ] Add an "Open Issues" subclause to the design discussion
* [X] Replace `\xname`s with new-style `\placeholder` exposition-only names

P0789:
* [X] Merge
* [X] Fixup view_interface::data for contiguous iterators.
* [X] Merge P0970 *again*

P1033:
* [X] Merge

P1037:
* [X] Merge
* [X] Search and replace:
  * [X] `difference_type` with `incrementable_traits`
  * [X] `difference_type_t` with `\newtxt{iter_}difference\oldtxt{_type}_t`
  * [X] `value_type` with `readable_traits`
  * [X] `value_type_t` with `\newtxt{iter_}value\oldtxt{_type}_t`
  * [X] `reference_t` with `\newtxt{iter_}reference_t`
  * [X] `rvalue_reference_t` with `\newtxt{iter_}rvalue_reference_t`
  * [X] In [algorithms]: `equal_to` with `ranges::equal_to`, `less` with `ranges::less`

P0970:
* [X] Merge to P896.
* [X] `span`
* [X] LEWG: Drop `dangling`, make calls that would dangle ill-formed

P0944:
* [X] Merge
* Specify `ranges::iterator_category` is `ranges::contiguous_iterator_tag` for:
  * [X] `basic_string` (contiguous container)
  * [X] `basic_string_view`
  * [X] `array` (contiguous container)
  * [X] `vector` (contiguous container)
  * [X] `valarray`
  * [X] `span`
