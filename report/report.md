---
pagetitle: Editor's Report for the Ranges TS
title: Editor's Report for the Ranges TS
...

# New Papers

* N4684 is the committee draft of the Ranges TS.
* N4685 is the prospective working draft of the Ranges TS. It is intended to replace N4671.
* N4686 is this Editor's Report.

# Changes since N4671
## Motions incorporated into the working draft and CD (from Toronto)
### LWG Motion 15: Apply the changes in [P0663R0 (Ranges TS "Ready" issues for the July 2017 (Toronto) Meeting)](http://wg21.link/P0663R0)
* [#155: : Comparison concepts and reference types](https://github.com/ericniebler/stl2/issues/155)
* [#172: : `tagged<Base...>` should be implicitly constructible from `Base`](https://github.com/ericniebler/stl2/issues/172)
* [#203: : Don’t slurp entities from `std` into `std::experimental::ranges::v1`](https://github.com/ericniebler/stl2/issues/203)
* [#232: : Kill the Readability requirement for `i++` for `InputIterators`](https://github.com/ericniebler/stl2/issues/232)
* [#235: : Trivial example breaks `common_type` from P0022](https://github.com/ericniebler/stl2/issues/235)
* [#245: : The iterator adaptors should customize `iter_move` and `iter_swap`](https://github.com/ericniebler/stl2/issues/245)
* [#251: : algorithms incorrectly specified in terms of `swap(*a,*b)` instead `iter_swap(a,b)`, and `move(*a)` instead of `iter_move(a)`](https://github.com/ericniebler/stl2/issues/251)
* [#259: : `is_swappable` type traits should not be in namespace `std`](https://github.com/ericniebler/stl2/issues/259)
* [#286: : Resolve inconsistency in `indirect_result_of`](https://github.com/ericniebler/stl2/issues/286)
* [#288: : “regular function” != `RegularInvocable`](https://github.com/ericniebler/stl2/issues/288)
* [#299: : `value_type` of classes with member `element_type`](https://github.com/ericniebler/stl2/issues/299)
* [#302: : `insert_iterator` and `ostreambuf_iterator` don’t properly support `*o++ = t;`](https://github.com/ericniebler/stl2/issues/302)
* [#307: : Incomplete edit to `InputIterator` to support proxy iterators](https://github.com/ericniebler/stl2/issues/307)
* [#309: : Missing “Returns:” clause of `sort`/`stable_sort`/`partial_sort`/`nth_element`](https://github.com/ericniebler/stl2/issues/309)
* [#311: : `Common` and `CommonReference` should use `ConvertibleTo` to test for implicit convertibility](https://github.com/ericniebler/stl2/issues/311)
* [#316: : `copy_if` “Returns” clause incorrect](https://github.com/ericniebler/stl2/issues/316)
* [#317: : `is_nothrow_indirectly_movable` could be true even when `iter_move` is `noexcept(false)`](https://github.com/ericniebler/stl2/issues/317)
* [#318: : `common_iterator::operator->` does not specify its return type](https://github.com/ericniebler/stl2/issues/318)
* [#321: : Concepts that use type traits are inadvertently subsuming them](https://github.com/ericniebler/stl2/issues/321)
* [#330: : Argument deduction constraints are specified incorrectly](https://github.com/ericniebler/stl2/issues/330)
* [#331: : Reorder requirements in concept `Iterator`](https://github.com/ericniebler/stl2/issues/331)
* [#345: : US 2 (006): 2.1.1: Update ranged-for-loop wording](https://github.com/ericniebler/stl2/issues/345)
* [#354: : JP 1 (015): 6.9.2.2/1: `Range` doesn’t require begin](https://github.com/ericniebler/stl2/issues/354)
* [#357: : JP 3 (018): 7.4.4/5: `transform` does not include projection calls in Complexity](https://github.com/ericniebler/stl2/issues/357)

### LWG Motion 16: Apply the changes in [P0740R0 (Ranges TS "Immediate" issues for the July 2017 (Toronto) Meeting)](http://wg21.link/P0740R0)
* [#61: : Review stated complexities of algorithms wrt the use of projections](https://github.com/ericniebler/stl2/issues/61)
* [#70: : Why do neither reference types nor array types satisfy `Destructible`?](https://github.com/ericniebler/stl2/issues/70)
* [#154: : Raw pointer does not satisfy the requirements of `RandomAccessIterator`](https://github.com/ericniebler/stl2/issues/154)
* [#156: : Validity of references obtained from out-of-lifetime iterators](https://github.com/ericniebler/stl2/issues/156)
* [#167: : `ConvertibleTo` should require both implicit and explicit conversion](https://github.com/ericniebler/stl2/issues/167)
* [#170: : `unique_copy` and LWG 2439](https://github.com/ericniebler/stl2/issues/170)
* [#174: : `Swappable` concept and P0185 swappable traits](https://github.com/ericniebler/stl2/issues/174)
* [#176: : Relax requirements on `replace` and `replace_if`](https://github.com/ericniebler/stl2/issues/176)
* [#211: : Add new header `<experimental/range/range>`](https://github.com/ericniebler/stl2/issues/211)
* [#229: : `Assignable` concept looks wrong](https://github.com/ericniebler/stl2/issues/229)
* [#250: : Do `common_iterator`’s copy/move ctors/operators need to be specified?](https://github.com/ericniebler/stl2/issues/250)
* [#255: : `DerivedFrom` should be “publicly and unambiguously”](https://github.com/ericniebler/stl2/issues/255)
* [#256: : Add `constexpr` to `advance`, `distance`, `next`, and `prev`](https://github.com/ericniebler/stl2/issues/256)
* [#261: : Restrict alg.general changes from P0370 to apply only to the range-and-a-half algorithms](https://github.com/ericniebler/stl2/issues/261)
* [#262: : Use "expression-equivalent" in definitions of CPOs](https://github.com/ericniebler/stl2/issues/262)
* [#284: : `iter_move` and `iter_swap` need to say when they are `noexcept` and `constexpr`](https://github.com/ericniebler/stl2/issues/284)
* [#289: : `[iterator, count)` ranges](https://github.com/ericniebler/stl2/issues/289)
* [#298: : `common_iterator::operator->` with xvalue `operator*`](https://github.com/ericniebler/stl2/issues/298)
* [#300: : Is it intended that an aggregate with a deleted or nonexistent default constructor satisfy `DefaultConstructible`?](https://github.com/ericniebler/stl2/issues/300)
* [#301: : Is it intended that `Constructible<int&, long&>()` is true?](https://github.com/ericniebler/stl2/issues/301)
* [#310: : `Movable<int&&>()` is true and it should probably be false](https://github.com/ericniebler/stl2/issues/310)
* [#313: : `MoveConstructible<T>() != std::is_move_constructible<T>()`](https://github.com/ericniebler/stl2/issues/313)
* [#314: : `ConvertibleTo<T&&, U>` should say something about the final state of the source object](https://github.com/ericniebler/stl2/issues/314)
* [#322: : `ranges::exchange` should be `constexpr` and conditionally `noexcept`](https://github.com/ericniebler/stl2/issues/322)
* [#338: : `common_reference` doesn’t work with some proxy references](https://github.com/ericniebler/stl2/issues/338)
* [#339: : After P0547R0, `const`-qualified iterator types are not `Readable` or `Writable`](https://github.com/ericniebler/stl2/issues/339)
* [#340: : GB 1 (001): Consider all outstanding issues before the final TS is produced](https://github.com/ericniebler/stl2/issues/340)
* [#361: : P0541 is missing semantics for `OutputIterator`’s writable post-increment result](https://github.com/ericniebler/stl2/issues/361)
* [#366: : `common_iterator::operator->` is underconstrained](https://github.com/ericniebler/stl2/issues/366)
* [#367: : `advance`, `distance`, `next`, and `prev` should be customization point objects](https://github.com/ericniebler/stl2/issues/367)
* [#368: : `common_iterator`’s and `counted_iterator`’s `const operator*` need to be constrained](https://github.com/ericniebler/stl2/issues/368)
* [#379: : Switch to variable concepts](https://github.com/ericniebler/stl2/issues/379)
* [#381: : `Readable` types with prvalue reference types erroneously model `Writable`](https://github.com/ericniebler/stl2/issues/381)
* [#382: : Don’t try to forbid overloaded `&` in `Destructible`](https://github.com/ericniebler/stl2/issues/382)
* [#386: : P0541: basic exception guarantee in `counted_iterator`’s postincrement](https://github.com/ericniebler/stl2/issues/386)
* [#387: : `Writable` should work with rvalues](https://github.com/ericniebler/stl2/issues/387)
* [#396: : `SizedRange` should not require `size()` to be callable on a `const` qualified object](https://github.com/ericniebler/stl2/issues/396)
* [#398: : `Assignable` semantic constraints contradict each other for self-assign](https://github.com/ericniebler/stl2/issues/398)
* [#399: : iterators that return move-only types by value do not satisfy `Readable`](https://github.com/ericniebler/stl2/issues/399)
* [#404: : Normative content in informative subclause](https://github.com/ericniebler/stl2/issues/404)
* [#407: : `istreambuf_iterator::operator->`](https://github.com/ericniebler/stl2/issues/407)
* [#411: : `find_first_of` and `mismatch` should use `IndirectRelation` instead of `Indirect(Binary)Predicate`](https://github.com/ericniebler/stl2/issues/411)
* [#414: : Remove `is_[nothrow]_indirectly_(movable|swappable)`](https://github.com/ericniebler/stl2/issues/414)
* [#420: : Harmonize `common_type` with C++17’s [meta.trans.other]/p4](https://github.com/ericniebler/stl2/issues/420)
* [#421: : With `common_type`, the Ranges TS requires vendors to break conformance](https://github.com/ericniebler/stl2/issues/421)
* [#424: : Constrain return types in `IndirectInvocable`](https://github.com/ericniebler/stl2/issues/424)
* [#436: : `common_iterator`’s destructor should not be specified in [common.iter.op=]](https://github.com/ericniebler/stl2/issues/436)

### LWG Motion 17: Apply the changes in [P0541R1 (Ranges TS: Post-increment on Input and Output iterators)](http://wg21.link/P0541R1)
### LWG Motion 18: Apply the changes in [P0547R2 (Ranges TS: Assorted Object Concept Fixes)](http://wg21.link/P0547R2)
### LWG Motion 19: Apply the changes in [P0579R1 (`constexpr` for `<experimental/ranges/iterator>`)](http://wg21.link/P0579R1)
### LWG Motion 20: Apply the changes in [P0651R1 (Switch the Ranges TS to Use Variable Concepts)](http://wg21.link/P0651R1)
### LWG Motion 21: Apply the changes in [P0662R0 (Wording for Ranges TS Issue 345 / US-2: Update ranged-for-loop wording)](http://wg21.link/P0662R0), resolving 1 NB comment:
* US 2: Update ranged-for-loop wording ([Issue #345](https://github.com/ericniebler/stl2/issues/345))

## Notable editorial changes:
  * [8fc2e509](https://github.com/ericniebler/stl2/commit/8fc2e50999da233246cd1a765007d0de4893fc91) [EDITORIAL] Correct mispellings of "only if" as "if and only if"

    LWG in Toronto pointed out that the concept definitions in P0547 were improperly using "if and only if" when the intent was "only if." This corrects similar improper uses of "if and only if" in the remainder if the TS concept definitions.

  * [d2a700e5](https://github.com/ericniebler/stl2/commit/d2a700e5da9870b70b437da0cea0d39f537c6b71) [EDITORIAL] Rename "implicit expression variants" to "implicit expression variations"

    As noted in [issue #384](https://github.com/ericniebler/stl2/issues/384), LWG in Kona requested a different name for the "implicit expression variant" term-of-art to avoid confusion with C++17 `std::variant`.

## Less notable editorial changes

Several less significant editorial changes occurred between publishing N4671 and N4684 (See the git revision history at [`https://github.com/ericniebler/stl2/compare/N4671...N4684`](https://github.com/ericniebler/stl2/compare/N4671...N4684)) with git log entries:

<pre>
commit 489196e0db10dce024706e7ac77a79705774b5a7
Author: Casey Carter <Casey@Carter.net>
Date:   Wed Jul 19 20:01:56 2017 -0700

    [EDITORIAL] manually wrap long lines

commit e251468bee213ed3dd0fad59ef058d2b7b758fc9
Author: Eric Niebler <eniebler@boost.org>
Date:   Thu Jul 20 09:10:27 2017 -0700

    [EDITORIAL] Add some missing periods.

commit f349b60364faae683e1ed36b2dc821c2f79453af
Author: Casey Carter <Casey@Carter.net>
Date:   Thu Jul 20 07:47:38 2017 -0700

    [EDITORIAL] Cleanup font usage in [stmt.ranged]

commit 6610d68fdeb0b71cc7b734cf8fc4fed1e574a6e4
Author: Casey Carter <Casey@Carter.net>
Date:   Tue Jul 18 17:41:01 2017 -0700

    [EDITORIAL] Cleanup "()" in SwappableWith

commit 00d9f8df6cba4bc239b30d2f5d19793ec1d9e162
Author: Casey Carter <Casey@Carter.net>
Date:   Fri Jul 7 06:00:47 2017 -0700

    [EDITORIAL] s/static_const/static_cast/g

commit eb024249c7985327fc4dd418a3e38e7f7ded4557
Author: Eric Niebler <eniebler@boost.org>
Date:   Mon Jun 19 15:48:25 2017 -0700

    [EDITORIAL] N3351 and N4128 are non-normative references, move to bib; fixes #391

commit c7f5bcdc0cb931e91aaa661fb59d166b1ca3707d
Author: Casey Carter <Casey@Carter.net>
Date:   Mon Jun 19 11:23:07 2017 -0700

    [EDITORIAL] Bring [intro.defs] into compliance with ISO/IEC directives part 2 section 16.5

    Fixes #405.
</pre>
