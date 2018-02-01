Document-wide changes to make:
* [X] IS-wide editorial instruction to rename old requirements tables whose names match concepts.
  * [ ] What to do about "swappable" and "swappable with" being EVERYWHERE?!?
* [X] Reformulate concepts AND REQUIRES CLAUSES to use C++20
* [X] Replace `{ E } -> Same<T>&&;` with `E; requires Same<decltype(E), T>;`
* [X] Use `_v` traits everywhere
* [X] Use `remove_cvref_t` to replace `remove_ref_t<remove_cv_t<foo>>` and (where appropriate) `decay_t`
* [X] Reformulate `result_of` uses in terms of `invocable`
* [ ] Clause numbers should agree with the target Clause numbers in the IS
* [X] Define CPOs as inline constexpr objects
* [ ] Add an "Open Issues" subclause to the design discussion
* [X] https://github.com/ericniebler/stl2/issues/506
* [X] https://github.com/ericniebler/stl2/issues/510
* [ ] https://github.com/ericniebler/stl2/issues/531
* [ ] https://github.com/ericniebler/stl2/issues/532
* [X] https://github.com/ericniebler/stl2/issues/538
* [ ] Implement and validate, especially common_XXX

Clause 1:
* [ ] Replace with design discussion. This can be as simple as pointers to relevant information from the Ranges TS design discussion, and some discussion/reference to the pertinent proposals for integrating concepts into the standard library:
  * [P0802 "Applying Concepts to the Standard Library"](http://www.open-std.org/jtc1/sc22/wg21/docs/papers/2017/p0802r0.html)
  * [P0830 "Using Concepts and `requires` in the C++ Standard Library"](http://www.open-std.org/jtc1/sc22/wg21/docs/papers/2017/p0830r0.pdf)
  * [P0872 "Discussion Summary: Applying Concepts to the Standard Library"](http://www.open-std.org/jtc1/sc22/wg21/prot/14882fdis/p0872r0.html)

Clause 2:
* [X] burninate

Clause 3:
* [X] `expression-equivalent` can use the "constant-subexpression" definition in 20.3.6. Put it in this paper because why not.
* `projection` is definitely library-only, and should go in Eric's paper.

Clause 4:
This all seems to be firewood as well. `std::experimental::ranges::v1` is no longer a thing. ~~Everything in this paper will be in namespace `std`~~, so the wording will be either (a) pure additions, or (b) modifications in-place (Very rarely). **I should use diff marks vs. C++20 for in-place modifications.**

Clause 5 is firewood - already applied to C++17.
* [X] burninate

Clause 6:
I'll need to decide subclause-by-subclause what info is duplicated in C++20 and what is new. This clause will also entail both in-place modifications and additions to existing wording.
* [X] 6.1: Para 4 (the concepts library blurb) needs to move verbatim into C++20's lib-intro. Remainder is trash.
* [X] 6.2.1.2: Add "concepts" to [structure.summary]
* [X] 6.2.1.3: Add "or satisfy a concept" (or replace "interface convention"?) to 1.3. Paras 3/6/7 are largely new.

* [ ] Do we need something in [conventions] to characterize what it means for a concept to be exposition-only?

* [X] 6.3.2: Add `<concepts>`
* [X] 6.3.4.3: "or evaluating a concept [with an incomplete type]"
* [X] 6.3.4.7: Totally new.
* [X] 6.3.5.1: [customization.point.object] needs to nest under [type.descriptions] §20.4.2.1 in the IS.
* [ ] Correct markup in here for newly-devised text that wasn't in the TS.

Clause 7:
* [X] This needs to be early in the library Clauses: probably between [language.support] and [diagnostics]. ([library] and [language.support] would not be insane, either.) (Queue whinging about changing the Clause numbering again.)
* [ ] 7.1.1: "Equality-Preservation" is more a general library-wide "Method of description" than something specific to this Clause. Think about locating it somewhere in 20.4.
* [X] 7.3.2/2: Now that `Same<T, U>` is defined to be equivalent to `is_same_v<T, U>`, this falls out of as-if.
* [ ] 7.3.7: Figure out how & if `Integral` should subsume `Regular` and `StrictTotallyOrdered`

* [X] Make `WeaklyEqualityComparableWith` exposition-only

Clause 8:
  * [X] `invoke` is already in C++17 - simply omit.
  * [X] `common_reference` into namespace `std`
  * [X] `common_type` into namespace `std`. CAREFULLY UNIFY THE TWO `common_type`S! (Be sure to \ednote a joke about this definition being the `common_type` of the definitions in C++20 and the Ranges TS.)
  * [X] `identity` may as well go into `std`
  * [X] `swap` and the related traits into `std2`
    * [X] Eric suggests that std2::swap needs to keep the poison pill since the constraints are different from those on std::swap.

Clause 12:
  * [X] Rename URNG to URBG

Compat Annex:
  * Say something about reusing the "old" requirement set names for concepts? No: it's a spec difference only, not a potential cause of source-level incompatibilities.
  * Talk about any differences vs. the Ranges TS? Yes, but not in the IS: in the design discussion.
