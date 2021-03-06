AM: Alisdair Meredith

BB: Billy Baker

CC: Casey Carter

DS: Dan S

MC: Marshall Clow

MH: Mark Hoemmen

MW: Michael Wong

RD: Rob Douglas

TS: Tim Song

VV: Ville Voutilainen

WB: Walter Brown

#### [allocator.requirements]
WB: "the additional requirement that, when..." [so reworded]

#### [concept.swappable]
CC: `ranges::swap` customization point needs to move into `<concepts>` [so moved]

CC: [The example is] user-code, but `ranges` name qualification is busted [`ranges::` fixed]

TS/CC: "swappable with" and "swappable" are terms of art but should be struck [struck]

#### [memory.syn]
AM: I think that these concepts should be named [question to LWG]

CC: Lack of [`noexcept`] requirement is to support older code. We could add requirement to be marked `noexcept` [question to LWG]

DS: `uninitialized_copy_n_result` is redundant with `<algorithm>`'s `copy_result` [reuse `copy_result`]

AM: would like copy result [et al] to be deducible [Mike is proposing CTAD for aggregates]

TS: Look at `insert_return_type` to get wording to ensure structured binding works and prevent private members [done for all `_result` types]

AM: Why not `Range` instead of `Rng` [for template parameter names]? ... Rename [everywhere] to `R` [Rename `([Rr])ng` to `$1`. Rename "Relation" template parameters from `R` to `C`. (no change marks)]

#### [specialized.algorithms]
WB: "In this subclause, the names of template parameters are used to express type requirements for those algorithms defined directly in namespace std." [Rephrased]

CC: Last sentence of P1 needs to be a separate paragraph [separated]

TS: `advance` and `distance` are they always `std::`? [Neither `std::` nor `ranges::` will work in all cases.] [Reworded to remove uses of `+` and define semantics for `-` without using `distance`.]

WB: Would like to reorder p3 first sentence like we did for p1. [so reordered: note this is now p4]

WB: Suggest a note like "This means that these algorithms may not be called with explicit template arguments" [added a note]

WB: "When invoked on ranges of potentially overlapped subobjects, the algorithms specified in this subclause result in undefined behavior." [so rephrased]

#### [special.mem.concepts]
AM: When talking about an assignment not throwing, do you mean any assignment? ... spell it out entirely [spammed out]

TS (offline): `begin`/`end` need `ranges::` qualification. Also, should *`no-throw-sentinel`*
require non-throwing SMFs as do the *`no-throw-XXX`* iterator concepts? [Yes: we want implementations to be able to
use `std::ranges::destroy` for cleanup.]

#### [uninitialized.construct.default]
AM: Would suggest a function like `voidify` to replace the `static_cast` and `const_cast`s [added `voidify`]

#### [uninitialized.fill]
CC: I'd like to change all the `_n` algorithms to use CTAD for `counted_iterator` rather than `make_counted_iterator` [especially since we struck `make_counted_iterator`!]. [Replaced throughout]

#### [specialized.destroy]
TS: `destroy_at` needs to correctly handle a pointer to array [done]

#### [range.comparisons]
AM: why follow idiom of templatizing on type? [Proposed redesign in P1252R0]

#### [string.view.iterators]
TS: Suggest changing all usages of "contiguous iterator" to the concept version. [So changed]

#### [iterators.general]
TS (offline): It's weird to have subclauses in Table 73 [struck]

#### [iterator.synopsis]
ALL: `-> auto&&` is a bogus deduction constraint. [Replaced with a valid constraint]

AM: Recommend putting Permutable, Mergeable, and Sortable into Algorithms header [not changing at this time, rationale on the reflectors.]

#### [iterator.requirements.general]
TS: P12 & P14 "Up to but not including the element pointed to by the..." -> "Up to but not including the element, if any, pointed to by the..." [so changed]

TS: last sentence of p13 duplicates first sentence of p15. [fixed]

WB: Would like to strike first sentence [struck]

CC: We need the phrase "a range is valid". can put this in p13 [done]

TS: move second sentence to p14. [so rearranged]

WB: "Functions in the library" -> "library functions" [so changed]

TS: We dont have a definition of "weaker" [removed uses of "weaker" in reference to iterator categories; also in [iterator.concept.forward].]

AM: `WeaklyIncrementable` and `Incrementable` sound far more primitive than to just being tied to iterators. Would like to see them move down into `<concepts>`. [So would I - but this design change needs investigation to determine how to extract `iter_difference_t` from `iterator_traits`; this needs a paper.]

#### [incrementable.traits]
WB: Do we have meaning for "implemented as if"? [These seem to be noise words; struck. Also in [readable.traits].]

TS (offline): Do you need to `decay` [in the `const I` partial specialization of `incrementable_traits`]? [Not really; the intent was to reduce the number of specializations needed for `iter_difference_t<const int[42]>`, but that's such a weird corner that it's not worth complicating the spec. Changed to `remove_const_t`.]

#### [iterator.traits]
AM: [p1 says] `iterator_traits<int*>::pointer` is `void` [since it does not support `operator->`]? [Clarified these statements apply only to iterators of class type. Drive-by: fix the prior sentence as well which was ~~a dumpster fire~~ not good.]

WB: P2 "Member types of specializations that are not program defined" [Fixed.]

RD: P2 Why arent you using kebab naming form? TS (offline): [iterator.traits]/2 Should we kebab the exposition-only names? [Fixed.]

Group: P2 is too long. Separate out exposition only concepts. [Fixed.]

DS: P2 first sentence of 2.1 needs a "then". [Fixed.]

WB: P2 Add "then"s to complement the "if"s? [Fixed.]

WB: P2.2 may be easier to have as sub-bulleted list. [Fixed.]

WB: P2 Don't like mixing of "names" and "is". [Fixed.]

TS (offline): `requires !C<T>` isn't a valid *requires-clause* in C++20's reduced grammar. [audited all *requires-clause*s]

WB: p3 second sentence "if specified" -> "is present" CC: [iterator.traits]/3 "should" is also problematic. This is meant to put requirements on users, but I dont think we need to impose these requirements. Group: [iterator.traits]/3 "should" -> "shall" [Sentence struck: There's no reason to require that program-defined `iterator_concept` has any relation to a `std` type, or that it has SMFs for tag dispatch.]

TS: P5 Can we rename the template parameter [`BidirectionalIterator`] in this example [to avoid confusion with the concept of the same name]? [Renamed to `BI`]

#### [iterator.custpoints.iter_move]
WB & TS (offline): Don't italicize "customization point object" - this isn't a definition. [fixed here and in [iterator.custpoints.iter_swap]]

TS (offline): We should harmonize [the wording in 1.1] with `ranges::swap`... "with overload resolution performed in a context..." [adjusted `iter_move` and `iter_swap` to agree with the style of the other CPOs]

#### [iterator.custpoints.iter_swap]
??: P1.2 "both" -> "each" [Fixed. Drive-by: clarify by referring to `SwappableWith` directly.]

CC: P1.3 Add a "then" before `(void)` [to clearly delimit the conditions from the equivalent expression]. [Fixed]

CC: P2 "does not swap" -> "does not exchange the values" with cross reference [to [concept.swappable]].

#### [iterator.concepts.general]
WB: What's a "type function"? Do we need p1? Strike p1. [struck]

CC: phrasing of "primary template" is wrong [should be "not program-defined"]. [Nope. "primary template" was, in fact, correct - restore the "instantiation of the primary template" wording throughout.]

TS (offline): Missing "the *qualified-id*" in 2.2 [fixed]

AM: Why not just always use `iterator_traits<I>`? Suggest a note. [added a note]

#### [iterator.concept.writable]
WB: Why italics in note in p5? CC: Because it came from the IS, of course. [Italics removed; and in the IS]

AM: Why `const_cast` statements in p1? Please add a note. [Added a note]

#### [iterator.concept.iterator]
RD: P2 note needs to update for change in syntax to `{...} -> auto&&`. [Note has been struck.]

#### [iterator.concept.sentinel]
TS (offline):  "over time" seems like the wrong description. It doesn't change spontaneously; only as a result of other evaluations. [change "can change over time" to "is not static".]

AM: When I increment an iterator, all *other* iterators are invalidated. Suggest: "Any *other* iterator" [changed]

#### [iterator.concept.sizedsentinel]
RD: Missing semicolon in `SizeSentinel` definition. [fixed]

WB: p3 first sentence "mechanism to enable library use"? [Reworded]

CC: Can strike [second] sentence [of p3, it's not actually normative]. [struck]

WB: [p4] Strikes more as example than note [changed to example]

#### [iterator.concept.input]
AM: Loses equality comparison requirement. Because `Sentinel`? Please include in note. [so included]

CC: Blech, strike "The XXX concept is a refinement of YYY."; it's redundant with the concept definitions. WB: Agreed, do it in all these subclauses. [struck]

WB: In p1 note "Unlike the Cpp17InputIterator (22.3.5.2)" [so rephrased]

#### [iterator.concept.output]
AM: Don't want a term of art [*single pass*] defined in note [italics removed]

CC (drive-by): The sentence "However, output iterators are not required to satisfy `EqualityComparable`." is normative duplication. Also, "however" seems out of place here. [Strike "however", turn into a note.]

#### [iterator.concept.forward]
WB: Would it be possible to have a diagram of the relationships of these concepts? [Such a diagram would be large and verges on tutorial - I think it would be out of place in the IS.]

Group: 4.2 needs to be `((void)[](X x){++x;}(a), *a)` [i.e., add a cast to `(void)` to avoid `,` hijacking via ADL]. [added.]

#### [iterator.concept.random.access]
CC: "refines `BidirectionalIterator` with support for ..., as well as the computation..." [So changed.]

#### [iterator.concept.contiguous]
WB: consult project editor regarding "`expression == expression` is `true`" vs "`expression` is equal to `expression`" [Unilaterally changed to the second form.]

#### [projected]
WB: "is intended for use" -> "is used to constrain" [so changed.]

CC: Delete the note [Replaced by `// not defined` comment.]

#### [common.alg.req.general]
WB: "on their arguments" -> "on its arguments". [This is correct, but unclear: replaced "their" with its antecedent "the concepts'". Also strike the noise word "explicitly".]

#### [common.alg.req.indirectlymovable]
TS (offline): Presumably we need a similar rule [specifying that an rvalue RHS is valid-but-unspecified] for the `Assignable` part as well? [Nope: `Assignable` already has that semantic.]

#### [common.alg.req.indirectlyswappable]
RD: p2 here differs from previous subclauses with usage of "only". [Rephrased.]

TS (offline): It looks like `I1` and `I2` can't be reference types, so why are we forwarding? [The requires-expression paramers are references [to avoid decay](https://github.com/ericniebler/stl2/issues/241). We went too far making them *rvalue* references, however. Changed to lvalue reference types.]

TS (offline): vice-versa here appears to fail to cover `iter_swap(i2, i1)` [Fixed.].

#### [std.iterator.tags]
RD: Get an Oxford comma from core. [fixed]

WB: strike "and optionally" [struck]

RD: strike "defined in" [struck]

#### [range.iterator.operations]
AM: I could have a type that has `operator+` but isn't a `RandomAccessIterator`. [rewrite this horrible paragraph comepletely]

CC: Missing the "you may not specify explicit template arguments" requirement [copy from [algorithms.requirements] and tailor]

#### [range.iterator.operations.advance]
TS (offline): `n` -> `|n|`. Group: Wording without absval will be left alone as it's based on existing wording. [fixed here and in the IS. ]

AM: Strike p4 up to comma. [struck]

CC (Drive-by): Clarify uses of "for foo iterators" with "If `I` models `FooIterator`". [fixed]

CC (Drive-by): "until `i == bound`" is not well-defined for `Boolean` expression `i == bound`. [fixed]

MH: P8 uses "distance" rather than "difference". TS (offline): Should we have a note that `M` can be negative? [Rephrase: "`M` is the difference between the ending and starting positions of `i`"]

#### [range.iterator.operations.distance]
WB: either _ shall denote a range or else _ shall denote a range. [Rephrased for clarity, but without "either...else": the preconditions are not mutually exclusive.]

#### [reverse.iterator]
WB: order [the iterator traits] aliases consistently. [Changed consistently throughout to `iterator_concept` (if present), `iterator_category`, `value_type`, `difference_type`, `pointer`, `reference`. Since this is a simple permutation, I put diff markings in the IS text but not in the new text.]

WB: p1 line break please. [broke]

DS: Please rename template parameter `Iterator` to `I`. TS (offline): Can we rename
the template parameter to avoid confusion with the Iterator concept? [I've made a note to submit this change as a post-merge editorial issue; I'd rather not bloat the proposal with *all* the wording for `reverse_iterator` and `move_iterator` simply so I can markup this change.]

#### [reverse.iter.requirements]
CC: "satisfy" -> "meet". [fixed]

WB: This is a mess. If you can clean it up, I'd be very happy. [Improved (happiness not guaranteed)]

#### [reverse.iter.cmp]
WB: would rather phrase p1 as ... [p1 struck]

CC: "subsection" should be removed. [p1 struck]

Group: would like this wording applied throughout. [done]

#### [reverse.iter.nonmember]
CC: [The conditional `noexcept`s] could be simplified [by using `current` instead of `declval`]. [so simplified]

TS (offline): [several comments about the conditional `noexcept`s indicating that the intended implementation is too subtle]. [clarified effects]

RD: right-most paren [in p4] needs to be moved toward noexcept and not include `is_nothrow_copy_constructible_v` [fixed]

MH: `Iterator2` needs to be in `noexcept` clause [in p4]. TS (offline): [ditto]. [fixed.]

TS (offline): Do we want to include [`iter_`-]swapping in either order? [Sort of, but not enough to want to pay the compile time cost.]

#### [move.iterator]
TS (offline): Can we rename the template parameter to avoid confusion with the `Iterator` concept? [Same response as for `reverse_iterator`: I'll do this in a
a follow-up editorial issue.]

#### [move.iter.requirements]
WB: "If any of the _ functions *is* instantiated" ["any" can be either singular or plural, and I think the plural reads better here. COME AT ME, Walter!]

#### [move.iter.nav]
CC: use `auto` rather than `decltype(auto)` [fixed]

TS (offline): Can we have a note that the return type is `void` in [the "otherwise"] case? [There are no `return`s from which to deduce a return type, how is this not clear?]

#### [move.iter.op.comp]
CC (Drive-by): Explode p1 into constraints elements as for [reverse.iter.comp]. [fixed]

#### [move.iter.nonmember]
CC (Drive-by): Explode p1 into constraints elements as for [move.iter.op.comp]. [fixed]

#### [move.sent.op.const]
TS (offline): [The converting constructor template] is mis-constrained: `ConvertibleTo` examines the convertiblity of non-`const` rvalue `S2`, but we are initializing from a `const` lvalue. [audited all uses of `ConvertibleTo`]

#### [iterators.common]
CC (Drive-by): Hanging paragraphs. [Push down into [common.iterator]]

#### [common.iterator.traits]
WB: p2-p4 should be bullets under p1. [fixed]

TS (offline): Where do we require `I` to be at least input? [The `iterator_traits` specialization is constrained to require `InputIterator`.]

CC (Drive-by): The specialization of `readable_traits` is unnecessary given that `common_iterator` specializes `iterator_traits`. [struck]

#### [common.iterator.const]
WB: Do we need separate subclauses for each operator? [Coalesce tiny subclauses]

#### [common.iter.access]
Group: Move [conditional `noexcept` paragraph] P4 to P1. [moved]

#### [common.iter.cmp]
RD: `I1` -> `I`, `S1` -> `S`. [fixed]

#### [common.iter.cust]
TS (offline): [`y.v_` has no alternative `I`, it has `I2`]. [fixed]

#### [default.sent]
WB: Merge into [default.sentinels]. [fixed]

#### [counted.iterator]
CC: "distance from its starting position" is just wrong. [fixed]

WB: Why "possibly differing" rather than "possibly identical"? [struck - it's immaterial.]

DS: `cnt` -> `n` or something else, but not `count` as that is a function name. [change to `length`]

CC (Drive-by): The specialization of `readable_traits` is unnecessary given the specialization of `iterator_traits`. [struck]

Group: Squash all [counted.iterator.ops] subclauses to one ginormous section. [Rearrange subclauses in the style of the working draft.]

#### [counted.iter.const]
WB: "and conversions" but conversion are elsewhere. [Merge [counted.iter.op.conv]]

CC: Strike p1 and declaration that precedes it [replace with DMIs and defaulted constructor]. [fixed]

CC: Strike "Constructs a `counted_iterator`," [struck]

#### [counted.iter.access]
RD: `noexcept` on `count()`. [`noexcept`ed]

#### [counted.iter.nav]
RD: ["Expects" element for `operator++()`] needs a period. [Audited all "Expects"]

DS: [The "Returns" element for `operator++()`] could be moved into "Effects". TS (offline): Why not put this into the codeblock? [Merge all "Returns" elements into "Effects"]

TS (offline): [The "Expects" element on `operator++(int) requires ForwardIterator`, `operator+`, and `operator-`] are implied by the equivalent-to. [struck]

BB: Now that `operator+` is a `friend`, can use `difference_type` rather than `iter_difference_t<I>`. [`difference_type` is a relic of the TS design. Current design intent is that people use the traits, and that iterators/ranges don't have nested types. `difference_type` here - and in `common_iterator` - should be a specialization of `incrementable_traits`.]

#### [unreachable.sentinel]
RD: "placeholder type" not what you want. [strike "is a placeholder type that"]

WB: I'd like to just strike p1 final sentence. [struck]

CC: p2 Example is broken in being unreachable. Group: p1 could use note about utility with single-pass iterators. [Deferred for now: I have design concerns about `unreachable` that need investigation.]

#### [ranges.syn]
AM: Should `transform_view` use something other than `Invocable`? CC: Suspect we might want to use `IndirectUnaryInvocable`. [No: `IndirectUnaryInvocable` is overconstraining here.]

AM: Suggest putting all ranges [declarations] in `namespace std::ranges {...}` and all things in `std` namespace afterward in `namespace std {...}` [done]

AM: Suggest to move contents of [range.access] and [range.primitives] to `<iterator>` [to break apparent cycle]. [Not making this change: These are range-specific machinery, not iterator-specific, and they belong in `<range>` despite the historical accident of declaring them in `<iterator>`. Implementers will have no trouble breaking the cycle.]

TS (offline): [Many "link" comments lack textual descriptions]. [added]

TS (offline): [Missing declarations of `take_view` and `view::take`]. [added]

#### [range.access.end]
CC: strike cross reference in p1.2. [No, this is fine. One cross-reference per subclause is reasonable ;)]

TS (offline): [This definition] permits a member `begin` to be paired with a non-member `end`. Do we care or is the concept checks enough? [*I* don't care about member vs. non-member if they satisfy the concepts.]

AM: [Question on whether final bullet in each customization-point disables SFINAE]. [The words "Otherwise `ranges::cpo(E)` is ill-formed." necessarily produce SFINAE when the expression is in the immediate context and substitution into `E` results in `ranges::cpo(E)` being ill-formed.] [added notes]

AM: update notes [here and in `cend`, `rend`, and `crend`] to clarify `Sentinel` usage of both types. [fixed]

#### [range.access.rbegin]
AM: remove `make_reverse_iterator` to use CTAD. [This would break `ranges::rbegin(x)` when `x` is a range of `reverse_iterator`s; CTAD is dangerous in generic code.]

#### [range.primitives.size]
TS (offline): [The type `T` of an expression is never a reference type; `remove_cvref_t<T>` here could be `remove_cv_t`]. [fixed]

TS (offline): Extract `disable_sized_range` from 1.2 and 1.3 and turn them into sub-bullets. [fixed]

WB/CC: Otherwise, let `RANGE_DIFF` be `DECAY_COPY(ranges::cend(E) - ranges::cbegin(E))` with `E` evaluated exactly once, if `RANGE_DIFF` is a valid expression and the types `I` and `S` of `ranges::cbegin(E)` and `ranges::cend(E)` model `SizedSentinel<S, I>` and `ForwardIterator<I>`. [fixed]

#### [range.primitives.empty]
RD: p1.2 could be read to dictate that size must be `0`? Suggest adding `()` [done]

AM: 1.3 fix as above [for `ranges::size`]. [done]

#### [range.primitives.data]
AM: Delete p1.3 as p1.4 subsumes it?
CC: for an empty range 1.3 returns a pointer. p1.4 always returns nullptr for an empty range.
AM: So whether vector hits 1.3 depends on whether it uses pointers or fancy iterators?
CC: yes. This helps it match the result of calling `begin()`.
AM: I read this to say the opposite. Having iterators as pointers would ensure that I get something different.
Group: Strike p1.3 [struck what is now p1.2]

#### [range.requirements.general]
AM: Strike "of containers". Sentence 2 should be like "Calling begin on a range object produces an iterator. Calling end on a range object produces a sentinel." Sentence 3 "The library formalizes the interfaces, semantics, and complexity of ranges to enable algorithm and range adaptors that work efficiently on different types of sequences." [so changed]

Group: Strike p2 [and Table 76]. [struck]

WB: p3 sentence append ", respectively." [appended]

WB: "In addition, several refinements of `Range` group requirements that arise frequently." [rephrased]

CC: Get rid of italics. Strike "range categories" from last sentence. [fixed]

TS (offline): Missing mentions of `ContiguousRange` and `ViewableRange`. [mentioned]

#### [range.range]
AM: strike note. [struck]

WB: Comment in synopsis says "equality preserving"; I confused this to talk about the note in p4.
CC: Applies to p2.3.
WB: change "see below" to "see below for clarifications". [Changed to "sometimes equality preserving"]

DS: Add "and" to the end of the bullets
WB: Instead, change "only if" to "only [if] each of the following is true:" [clarified]

TS (offline): [`begin` and `end` don't require implicit expression variations] even when `T` is a `const &`? We really need to get the implicit-variation rules clear. [Ugh, this normative non-requirement cannot be a note.]

CC (Drive-by): `ranges::begin(static_cast<T&>(E))` is ill-formed when `E` is an rvalue; *`forwarding-range`* is broken. [fixed]

AM: Would be good to have a note following p4 to describe the purpose of *`forwarding-range`*. [add a note *and* an example]

#### [range.sized]
CC: Strike deduction constraint in requires expression. TS (offline): Is this `ConvertibleTo` requirement useful? [struck]

DS: add ", and" to end of p2.1. [added]

RD: p2.2 in note, "*to* be". [added]

WB: Please move "for example" to start of the sentence. [moved]

CC: p3 needs same cleanup just like `disable_sized_sentinel`. [so cleaned]

#### [range.view]
RD: Ask Core for another Oxford comma. [Got one: ,]

AM: "A container" to "Most containers". [changed]

AM: Reword to "Program-defined specializations of `enable_view` shall have a base characteristic of either `true_type` or `false_type`." [Bah - let's merge `enable_view` and *`view_predicate`*.]

RD: "shall be" -> "is". [fixed]

RD: Change line ending ";"s to "."s [in p4]. [fixed]

#### [range.refinements]
RD: Please qualify `begin` and `end` with `range::` [audited all these subclauses]

TS (offline): [Tiny subclauses, merge them]. [`ranges::merge`d]

AM: Is `ranges::data(t);` [requirement of `ContiguousRange`] redundant with `ContiguousIterator`? [`data` is certainly very convenient.]

#### [view.interface]
CC: missing requirements on `D`; must be publicly and unambiguously derived from `view_interface`. [fixed]

AM: I don't like forward-declared autos. [Inline all the things.]

TS: Can we require [`D` to be] a *cv-unqualified* class type? [fixed]

Group: Strike "container" conversion operator for now. [struck]

#### [range.subrange]
CC (Drive-by): Reorganize and retitle subclauses. [done]

CC: Change `namespace std { namespace ranges {` to `namespace std::ranges {`. [fixed]

CC: In *`pair-like`*, the `-> Integral` should be changed to make the constraint correct. TS: `requires DerivedFrom<tuple_size<T>, integral_constant<size_t, 2>>`. [changed; also added a `typename tuple_size<T>::type` requirement to guard against incomplete `tuple_size<T>`.]

TS: `remove_reference_t` [in *`pair-like-convertible-to`*]? CC: Yes; I think that's sufficient. [fixed]

TS: Deduction constraints [in *`pair-like-convertible-to`*] should not decay. [Break up compound requirements `{ E } -> ConvertibleTo<T>;` into simple requirement `E;` and nested requirement `requires ConvertibleTo<decltype(E), T>;`.]

CC: Replace `Same<T, decay_t<T>>` with `!is_reference_v<T>`, in *`iterator-sentinel-pair`* and *`pair-like-convertible-from`*. [replaced, and moved this requirement into the definition of *`pair-like`*]

TS: There is an extra angle bracket after `unsized` [in the template-head for `subrange]. The requires stuff needs parens. [fixed]

TS (offline): The pervasive use of `{}`-initializers here and elsewhere suggests that we need to make `DefaultConstructible` check it, as does *`Cpp17DefaultConstructible`*. [I've [submitted a PR](https://github.com/cplusplus/LWG/pull/251) to add this requirement to `DefaultConstructible` in the [LWG 3149 P/R](https://wg21.link/lwg3149). Also, I've changed all `T foo {};` member declarations to `T foo = T();` in the meantime.]

#### [range.subrange.ctor]
AM: Should we add a note to the ctor described in paras 2 and 3, explaining what the `n` is for? MC: I would be happy with it. [added note]

CC: Would we rather depict para 7 as a delegating ctor? [group agrees] CC: OK; I will do that with all of these. [Change 3 detailed constructor specifications into delegation declarations.]

TS (offline): Perhaps make [the conversion operator] conditionally explicit? [Not touching this for now: I have no idea how explicit-specifiers interact with associated constraints. LWG: File an issue?]

#### [range.subrange.access]
TS: [Use of "satisfy" instead of "model" in P5]. [Fixed, along with several other occurrences in the proposal.]

#### [range.adaptor.object]
TS: Para 1: Expressions don't "return" things -- "yield"/"produce". ["yield"]

AM,CC: Para 3 and 4 "if the adaptor" -> "If a range adaptor object". [fixed]

#### [range.semi.wrap]
TS: Shorten the stable name, please. [fixed]

TS: Para 1.2: broken markup. [fixed]

AM: Para 1: Helper class, helper ...? TS: "helper class template". CC: "helper" seems redundant with "exposition only". [Change "helper called *`semiregular`*" to "class template *`semiregular`*".]

CC: Para 1: "This type" -> "semiregular". [fixed]

AM: "exceptions" or "differences"? ["differences"]

#### [range.all]
AM,CC: Would be useful to specify in the Note that `view::all(E)` is a `View` of all the elements of `E`. [That's literally what p1 already says. Striking the note as useless.]

MC: `DECAY_COPY` is not my favorite thing, but I'm not going to object at this moment. (In the Std, we say it's equivalent to a chunk of code...). CC: We say it's equivalent to a different chunk of code. I plan to harmonize this. [Add conditional `noexcept` and `constexpr` to `decay_copy` in [thread.decaycopy].]

#### [range.view.ref]
TS: *`ref_view`* should be *`ref-view`*. [fixed]

CC: Strike the conditional `noexcept` if I can't find a good reason for it to be there. [struck]

AM: `ref-view<const X>` is unfortunately constructible from `X&&`. [Give *`ref-view`* the LWG 2993 treatment.]

AM: For `size` and `data`, can we say what return type is? [Let's just merge these one-line "Effects: equivalent to" specs into the class body, so it's clear that `ref-view::foo` returns whatever `ranges::foo` returns for the underlying range.]

TS: Why are [the parameters to *`ref-view`*'s non-member `begin` and `end` overloads] rvalue references? CC: No good reason. I will change to by-value. [fixed]

CC: Para 3 bad formatting; I will split them. Ditto for para 4. [struck instead of split]

#### [range.filter.view]
AM: Why is `base_` value-initialized and `pred_` default-initialized? [Like `optional`, default and value init are equivalent for *`semiregular`*s.]

AM: `iterator` and `sentinel` are exposition-only but appear in the public interface [followed by inconclusive discussion]. [No change?]

AM: We probably want them to be public names. Do I have to use `auto` in expressions? [No, use `iterator_t` and `sentinel_t`.]

AM: Can `pred_` be empty [when calling `begin`]? CC: No; I will call out the precondition in *Expects*. [fixed]

MH: We're fusing the two `end`s, right? CC: Yes, so we get public names for `iterator` and `sentinel`, and the two `end` functions fuse into one. [Despite that I've broken the premise by *not* naming `iterator` and `sentinel`, this is still a righteous change.]

#### [range.filter.iterator]
MH: [In `operator--`], should negate the [result of the] predicate. [fixed]

CC: We need global wording saying that "modifications to the values of the elements that would observably alter the value that the predicate would return for those" result in UB. This would go somewhere high up in `filter_view`. [Added new para here.]

#### [range.transform.view]
CC (Drive-by): Rearrange subclauses. [fixed]

TS (offline): We are - presumably intentionally - allowing non-regular invocables here, but I'm not sure why. [You presume too much sir! This is simply a mistake. fixed.]

DS: Example directly runs into synopsis? [split subclause before synopsis]

### [range.transform.iterator]
MH & TS (offline): `Base` typedef is broken syntax. [fixed]

DS: Make [`void operator++(int)`'s] "Equivalent to" a one-liner [instead of a codeblock]. [fixed]

#### [range.iota.view]
TS (offline): [In the semantic requirements for `Decrementable`, the expression `bool((a--, a) == --b)` is subject to `,`-hijacking]. DS: [same comment]. [`(void)`ed]

TS (offline): [The `iter_difference_t` typename requirement in `Advanceable`] is implied by `WeaklyIncrementable`. [struck]

TS (offline): I think we only defined reachable for iterator/sentinel pairs. [I'd prefer to file a post-merge issue for this: it needs a short paper. We need to define "reachable" as a property of two values `i` and `b` of types `I` and `B` that model `WeaklyIncrementable<I>` and `weakly-equality-comparable-with<I, B>` such that for some non-negative integer `N`, `N` applications of `++` make `bool(i == b)` be `true`. We can than use that property uniformly in the `Sentinel` relationship, here in *`Advanceable`*, and in the definitions of the `iota` classes.]

TS (offline): What are the types of `x`, `y`, and `x + y`? `(n - one)` may not be of the difference type. [fixed to convert all integer expressions to the difference type.]

TS (offline): We didn't do the `zero` / `one` dance for `RandomAccessIterator`; seems like we should do both or neither. [harmonized]

CC (Drive-by): `a <= b` here should be "`bool(a <= b)` is `true`". [fixed]

TS (offline): Maybe we can define [`RandomAccessIterator`] using *`Advanceable`* and reduce the duplication. [and `Bidi`/*`Decrementable`. This looks large enough to be followup work.]

DS,CC: Change from `Bound{}` to `Bound()` [in the `iota_view` constructor]. [fixed]

#### [range.iota.iterator]
DS: Suggest changing `I` to `W` for `WeaklyIncrementable`. [changed (with no diff markup)]

AM: Why use `+ -n`? Aren't the requirements strict enough that we could use `- n`? [style preference: encode operations in terms of other operations when possible, (e.g., `return !(x == y);`) for consistency between types.]

CC: `operator-` uses `*x` instead of `x.value_`, which is inconsistent with others. [change all friends to use `.value_`]

#### [range.iota.adaptor]
DS,CC: "For some subexpressions `E` and `F`, the expressions...." [changed. And everywhere else.]

#### [range.take.overview]
DS: Add to description in para 1, that it takes at most N elements. [fixed]

CC: If we're using the letter `R` everywhere for `Range` parameters, it's weird to use `R` [in the adaptors] for something that models `View`. Should I change `R`'s to `V`'s? Group: Yes. [changed; also s/O/R/g for `Range` parameters that previously would have conflicted. (NO DIFF MARKS)]

#### [range.take.view]
CC (Drive-by): Inline bodies of functions with deduced return types. [fixed]

#### [range.join.view]
CC (Drive-by): Inline bodies of functions with deduced return types. [fixed]

CC: Merge two overloads of `end` and `end const`. [merged]

MH,DS: In [`begin`'s "Effects"], should specify `C` by its conditions rather than by the order of overloads. CC: I would like to specify this like in `take_view`. DS: Please make them look similarly. [obviated by inlining into class body.]

#### [range.join.iterator]
CC (Drive-by): Inline bodies of functions with deduced return types. [fixed]

EN ([stl2/#574](https://github.com/ericniebler/stl2/issues/574)): [`operator++` incorrectly passes `*outer_` - which may be an xvalue - to `ranges::begin` instead of passing an lvalue denoting the same object]. [fixed]

TS (offline): [`reference_t` in `satisfy` should be `iter_reference_t`]. [fixed]

MW,CC: [In the converting constructor], "`parent_`-" is a LaTeX bug. [This disappeared after another fix changed line breaking.]

#### [range.join.adaptor]
MH: See above: Put "for some subexpression `E`" at beginning of sentence. [changed all occurrences]

#### [range.single.view]
CC: I need to fix [*`tiny-range`* to ensure that `remove_reference_t<R>::size()`] is a compile-time expression [as in [LWG 3150](https://cplusplus.github.io/LWG/issue3150)]. [fixed]

TS (offline): Why not just `explicit single_view(T) -> single_view<T>;`? [Why not simply strike the guide?]

#### [range.split.view]
CC (Drive-by): Inline bodies of functions with deduced return types. [fixed]

MW,CC: Paras 5 and 7, p. 124, has another hyphenation bug. [no longer an issue after inlining.]

#### [range.split.outer]
CC (Drive-by): Inline bodies of functions with deduced return types. [fixed]

MH,CC: I'll add a forward reference to the section that explains where `value_type` is defined. [Added `// See [range.split.outer.value]` to declaration.]

#### [range.split.inner]
CC (Drive-by): Inline bodies of functions with deduced return types. [fixed]

DS,MW: Variable name `zero_` [for a `bool`]? It could be equal to one at some point. [Rename to `incremented_`.]

CC: ["Effects" on `iter_move` doesn't `return` anything]. [fixed]

CC: [`iter_swap`] incorrectly uses *`current`* as a function instead of a member variable.

#### [range.split.adaptor]
MH: See above: "for some subexpressions `E` and `F`" should go to beginning of that sentence. [Yes, seriously - I changed them all.]

#### [range.counted]
TS (offline): Should we do the `ConvertibleTo` check on the decayed type rather than the real type/value cat of `F`? [We are incorrectly checking the decayed type of `F`, when we should be checking that `F` converts to `iter_difference_t<T>`.]

CC: I am almost convinced that the `static_cast` of `F` is unnecessary. [True for 1.1.2, but 1.1.1 *does* need an explicit conversion.]

#### [range.common.view]
CC (Drive-by): Inline bodies of functions with deduced return types. [fixed]

#### [range.common.adaptor]
CC: Rewrite 1.1: "`view::all(E)`, if `decltype((EE))` models...". [fixed]

#### [range.reverse.view]
CC (Drive-by): Inline body of size, specify return types of other functions with deduced return types. [fixed]

TS (offline): The `reverse_iterator` CTAD below will break if the range's iterator type is a `reverse_iterator` itself.

#### [range.reverse.adaptor]
DS,CC: Change "for some subexpression `E`" everywhere. [I get it already.]

#### [algorithms.requirements]
AM: Could we use an existing function that does the same thing as [the code sequence in p12]? [Yes, use `ranges::next`]

AM,CC: To para 13, add "...dispatching to the overload *in namespace `ranges`* that takes...". [fixed]

CC: We need Annex C wording for para 14, because this is a breaking change. [added]

#### [alg.all_of]
AM,CC: "and any projection" (no projection for the old non-ranges versions). [fixed]

TS (offline): Maybe explicitly parameterize as `E(i)` rather than relying on a macro-like expansion? [I don't think this improves readability; feel free to propose a separate change.]

#### [alg.any_of]
AM,CC: "and any projection". [fixed]

#### [alg.none_of]
TS (offline):  Why is this one `P` and not `E`? [I wanted LWG's opinion on `E` for "expression" vs. `P` for "predicate". Also the inconsistency shows if people are actually paying attention ;)]

AM,CC: Change `P` to `E`. [See? Lots of people noticed and preferred `E`. Fixed.]

AM,CC: "and any projection" (Change this generally where appropriate). [fixed - think I got all of them.]

#### [alg.for_each]
MW,CC: Change "nonconstant" in the Note in para 11 to be hyphenated. [fixed]

TS (offline): This requires `CopyConstructible<Fun>`, unlike the unconstrained overload which just requires *`Cpp17MoveConstructible`*. [Added a note]

#### [alg.find]
DS: Group the non-`ranges` and `ranges` versions of `find`, `find_if`, and `find_if_not` together? [I think repeatedly opening and closing `ranges` in the declarations would obfuscate this.]

Group: [Discussion about the value of `std` predicates being required to be contextually convertible to `bool`, culminating in "Casey should forcibly convert everything to `bool` in the algorithms"]. [I did this with many of the algorithms in the post-Batavia work that was reviewed on the reflector, but I don't think it's worth doing with the remainder now since (a) it will add a great many changes to review, and (b) I don't have *every* standard algorithm in the proposal to fix. I'd prefer to do this in a followup issue ]

#### [alg.find_end]
CC: Change `P` to `E`. [This was the last `P` occurence in [algorithms].]

TS (offline): "and each projection" is used below. Harmonize? [These are all "and any projection(s)" now.]

#### [alg.find.first.of]
AM,CC: Change "`E` holds" to "`E` is `true`" for consistency. [Ditto, this should be an IS-wide followup.]

#### [alg.copy]
TS (offline): `last + M` should be `first + M` [for `copy_n`'s "Returns"].

#### [partial.sort.copy]
TS (offline): There are two projections here. [fixed]

#### [equal.range]
TS (offline): ["`bool(invoke(comp, invoke(proj, e), value))` shall imply `!invoke(comp, value, invoke(proj, e))` for the overloads in namespace `ranges`." is implied by the `IndirectStrictWeakOrder` requirement]. [struck]

#### [alg.partitions]
TS (offline): ["The relative order of the elements in both groups is preserved." is an effect, not a returned value]. [fixed]

## Newly-addressed
#### [alg.find_end]
TS (offline): What if [`[first1, last1 - (last2 - first2))`] isn't a valid range, i.e., `last1 - first1 < last2 - first2`? [fixed]

#### [alg.count]
AM: Why not collapse overloads via equal predicate? [Because we have all permutations of "call with `value`" and "call `invoke`"; there's no way to compress these 4 unique]

#### [alg.mismatch]
AM: Should we fully qualify `min` (here and in general)? CC: change to math font? CC: Should I do that [and for `max`, as well] only to the algorithms I'm touching, or to all complexity statements in the standard library? AM: Ask LWG. [I so no need for a general qualification: both `std::min` and `std::ranges::min` are equivalent for integral arguments, which we're talking about here, so there's no potential for confusion. File editorial issue to ask about changing uniformly to math-mode https://github.com/cplusplus/draft/issues/2385.]

#### [alg.is_permutation]
CC: `range` version is in terms of range-and-a-half `equal`, which isn't being proposed. [fixed]

TS (offline): `first2 + (last1 - first1)` should be `last2`. [Equivalent, but clearer - changed.]

#### [alg.search]
TS (offline): Do we really need [bullet 5.1] or is the next bullet OK for this case too (the condition is vacuously true)? [struck]

#### [alg.copy]
TS (offline):  Instead of `WeaklyIncrementable O` and `requires IndirectlyCopyable<I, O>`, consider `OutputIterator<iter_reference_t<I>> O`. Also in [alg.move]. [Considered; don't care.]

#### [alg.move]
TS (offline): ["move assignments" is redundant]. [struck]

TS (offline): "starting from first and proceeding to last" is missing code font. [fixed; and in [alg.move]/12, and the `copy_backward` and `move_backward` footnotes.]

#### [alg.transform]
TS (offline): `OutputIterator<indirect_result_t<F&, ...> O`; have to move `O` to the end though so that the other parameters are in scope. Alternatively, s/`Writable`/`OutputIterator`/ and s/`WeaklyIncrementable`/`class`/. [Not changed: I prefer that implementations aren't allowed to use post-increment. Feel free to send a proposal to LEWG to change these.]

#### [alg.replace]
TS (offline): [For `replace_copy_if`]  Instead of `IndirectlyCopyable<I, O>`, we should perhaps use `OutputIterator<O, iter_reference_t<I>>` to codify that you can assign both `*first` and `new_value` to `*r++`. Or perhaps this is an indication that we should reconsider `IndirectlyCopyable`? [Ditto "post-increment"]

#### [alg.find_end]
TS (offline): `IndirectRelation<Pred, projected<I1, Proj1>, projected<I2, Proj2>>` is just an-
other way to spell `IndirectlyComparable<I1, I2, Pred, Proj1, Proj2>`. We should probably pick one
and consistently use it rather than using the former for e.g. `find_first_of` and `mismatch`, and the latter
for e.g. `find_end` and `equal`.

#### [alg.generate]
TS (offline): [For `generate_n`] s/`Writable`/`OutputIterator`/ and remove the `Iterator`. [Ditto "post-increment"]

#### [alg.remove]
TS (offline): [For `remove_copy_if`] `OutputIterator<iter_reference_t<I>> O` and drop the `IndirectlyCopyable`. [Ditto "post-increment"]

#### [alg.unique_copy]
TS (offline): `OutputIterator<iter_reference_t<I>> O` and drop the `IndirectlyCopyable`. Also maybe add `OutputIterator<O, const iter_value_t<I>&>` to the `IndirectlyCopyableStorable` clause. [Ditto "post-increment"]

#### [alg.reverse]
TS (offline): `OutputIterator<iter_reference_t<I>> O` and drop the `IndirectlyCopyable`. [Ditto "post-increment"]

#### [alg.rotate]
TS (offline): ["Complexity" says "swaps", but] `Permutable` grants permission to use moves instead of swaps. Do we care? [...and create **temporaries**, ick. I don't care now, but I may soon. This is captured in https://github.com/ericniebler/stl2/issues/577.]

TS (offline): [For `rotate_copy`] `OutputIterator<iter_reference_t<I>> O` and drop the `IndirectlyCopyable`. [Ditto "post-increment"]

#### [alg.random.shuffle]
TS (offline): The `ConvertibleTo` is implied. [Yes - blind carryover from conversion requirements on `std` algorithms. Struck. (WTF? I *already* struck the requirement for the `std` algorithms.)]

TS (offline): What if `remove_reference_t<Gen>` does not meet the uniform random bit generator requirements? [LWG opinion is that implementors make it work.]

#### [sort]
TS (offline): We are missing "with respect to `comp` (and any `proj`)" [in "*Effects:* Sorts the elements in the range `[first, last)`."] here and elsewhere. [fixed in [sort],[stable.sort],[partial.sort],[partial.sort.copy],[is.sorted], and [alg.nth.element]]

#### [alg.partial_sort_copy]
TS (offline): The project part is mind-bending. We copy from input to output, with a possible conversion, then you separately project the input and output ranges. But is the copying required to preserve the ordering? Which projection are we sorting with respect to? [clarified]

#### [alg.partitions]
TS (offline): [For `partition_copy`] `OutputIterator<iter_reference_t<I>> O1` and ditto for `O2`. [Ditto "post-increment"]

TS (offline): [For `partition_point`] Can we use this phrasing for `partition` and `stable_partition`? [Not anymore with the merged wording.]

#### [alg.merge]
TS (offline): We should require `OutputIterator` here, but we can change `Mergeable` maybe? Also in [set.union], [set.intersection], [set.difference], and [set.symmetric_difference]. [Ditto "post-increment"]

TS (offline): [For `inplace_merge`'s "Effects", isn't this simply] "sorted with respect to `comp` (and any `proj`)"? [Yip - replaced]

#### [alg.min.max]
TS (offline): `Copyable` isn't enough, right? You need to be able to construct `iter_value_t<iterator_t<Rng>>` from its reference type and have it preserve the value, and ditto for assignment from reference. [yes, this is very wrong - we need the parts of `IndirectlyCopyableStorable` that don't involve the output iterator. fixed]

TS (offline): ["leftmost argument" and "rightmost argument" makes no sense for a range]. [fixed]

#### [alg.lex.comparison]
TS (offline): "prefix" [pre-existing in remarks should be] "proper prefix". [fixed]

#### [alg.permutation.generators]
TS (offline): [Pre-existing "Otherwise, it transforms the sequence" in both algorithms] isn't really a Returns [it's an effect]. [fixed]

## Unaddressed Comments
#### [alg.set.operations]
TS (offline): I think we need to define "equivalent elements" better now that we have projections in the picture.

TS (offline): [None of these make any sense with projections.]

TS (offline): The sorted-output business is rather silly with projections and unreadable output. CC: Arguably this wording is no more broken than it was before.

TS (offline): [Pre-existing: Several "Effects" clauses say "The elements in the constructed range are sorted." and not "sorted with respect to XXX"].

#### [includes]
CC (Drive-by): "shall be sorted with respect to `comp`, and `proj`" - what's `proj`?

TS (offline): [The "subsequence" notion in Returns is completely broken by projections].

#### [set.union]
TS (offline): We should fix the pre-existing "shall" in the Remarks.

#### [heap.operations]
TS (offline): The definition of "heap" needs to be updated for projections.
