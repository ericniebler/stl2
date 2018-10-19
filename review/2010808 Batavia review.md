AM: Alisdair Meredith

BB: Billy Baker

CC: Casey Carter

DS: Dan S

MH: Mark Hoemmen

RD: Rob Douglas

TS: Tim Song

WB: Walter Brown

WB: [allocator.requirements] "the additional requirement that, when..." [so reworded]

CC: [concept.swappable] `ranges::swap` customization point needs to move into `<concepts>` [so moved]

CC: [concept.swappable] [The example is] user-code, but `ranges` name qualification is busted [`ranges::` fixed]

TS/CC: [concept.swappable] "swappable with" and "swappable" are terms of art but should be struck [struck]

AM: [memory.syn] I think that these concepts should be named [question to LWG]

CC: [memory.syn] Lack of [`noexcept`] requirement is to support older code. We could add requirement to be marked `noexcept` [question to LWG]

DS: [memory.syn] `uninitialized_copy_n_result` is redundant with `<algorithm>`'s `copy_result` [reuse `copy_result`]

AM: [memory.syn] would like copy result [et al] to be deducible [Mike is proposing CTAD for aggregates]

TS: [memory.syn] Look at `insert_return_type` to get wording to ensure structured binding works and prevent private members [done for all `_result` types]

AM: [memory.syn] Why not `Range` instead of `Rng` [for template parameter names]? ... Rename [everywhere] to `R` [Rename `([Rr])ng` to `$1`. Rename "Relation" template parameters from `R` to `C`. (no change marks)]

WB: [specialized.algorithms] "In this subclause, the names of template parameters are used to express type requirements for those algorithms defined directly in namespace std." [Rephrased]

CC: [specialized.algorithms] Last sentence of P1 needs to be a separate paragraph [separated]

TS: [specialized.algorithms] `advance` and `distance` are they always `std::`? [Neither `std::` nor `ranges::` will work in all cases.] [Reworded to remove uses of `+` and define semantics for `-` without using `distance`.]

WB: [specialized.algorithms] Would like to reorder p3 first sentence like we did for p1. [so reordered: note this is now p4]

WB: [specialized.algorithms] Suggest a note like "This means that these algorithms may not be called with explicit template arguments" [added a note]

WB: [specialized.algorithms] "When invoked on ranges of potentially overlapped subobjects, the algorithms specified in this subclause result in undefined behavior." [so rephrased]

AM: [special.mem.concepts] When talking about an assignment not throwing, do you mean any assignment? ... spell it out entirely [spammed out]

TS (offline): [special.mem.concepts] `begin`/`end` need `ranges::` qualification. Also, should *`no-throw-sentinel`*
require non-throwing SMFs as do the *`no-throw-XXX`* iterator concepts? [Yes: we want implementations to be able to
use `std::ranges::destroy` for cleanup.]

AM: [uninitialized.construct.default] Would suggest a function like `voidify` to replace the `static_cast` and `const_cast`s [added `voidify`]

CC: [uninitialized.fill] I'd like to change all the `_n` algorithms to use CTAD for `counted_iterator` rather than `make_counted_iterator` [especially since we struck `make_counted_iterator`!]. [Replaced throughout]

TS: [specialized.destroy] `destroy_at` needs to correctly handle a pointer to array [done]

AM: [range.comparisons] why follow idiom of templatizing on type? [Proposed redesign in P1252R0]

TS: [string.view.iterators] Suggest changing all usages of "contiguous iterator" to the concept version. [So changed]

TS (offline): [iterators.general] It's weird to have subclauses in Table 73 [struck]

ALL: [iterator.synopsis] `-> auto&&` is a bogus deduction constraint. [Replaced with a valid constraint]

AM: [iterator.synopsis] Recommend putting Permutable, Mergeable, and Sortable into Algorithms header [not changing at this time, rationale on the reflectors.]

TS: [iterator.requirements.general]/12 & /14 "Up to but not including the element pointed to by the…" -> "Up to but not including the element, if any, pointed to by the…" [so changed]

TS: [iterator.requirements.general] last sentence of p13 duplicates first sentence of p15.

TS: last sentence of p13 duplicates first sentence of p15. [fixed]

WB: Would like to strike first sentence [struck]

CC: We need the phrase "a range is valid". can put this in p13 [done]

TS: move second sentence to p14. [so rearranged]

WB: [iterator.requirements.general] "Functions in the library" -> "library functions" [so changed]

TS: [iterator.requirements.general] We dont have a definition of "weaker" [removed uses of "weaker" in reference to iterator categories; also in [iterator.concept.forward].]

AM: `WeaklyIncrementable` and `Incrementable` sound far more primitive than to just being tied to iterators. Would like to see them move down into `<concepts>`. [So would I - but this design change needs investigation to determine how to extract `iter_difference_t` from `iterator_traits`; this needs a paper.]

WB: [incrementable.traits] & [readable.traits] do we have meaning for "implemented as if"? [These seem to be noise words; struck.]

TS (offline): [incrementable.traits] Do you need to `decay` [in the `const I` partial specialization of `incrementable_traits`]? [Not really; the intent was to reduce the number of specializations needed for `iter_difference_t<const int[42]>`, but that's such a weird corner that it's not worth complicating the spec. Changed to `remove_const_t`.]

AM: [iterator.traits] [p1 says] `iterator_traits<int*>::pointer` is `void` [since it does not support `operator->`]? [Clarified these statements apply only to iterators of class type. Drive-by: fix the prior sentence as well which was ~~a dumpster fire~~ not good.]

WB: [iterator.traits]/2 "Member types of specializations that are not program defined" [Fixed.]

RD: [iterator.traits]/2 Why arent you using kebab naming form? TS (offline): [iterator.traits]/2 Should we kebab the exposition-only names? [Fixed.]

Group: [iterator.traits]/2 is too long. Separate out exposition only concepts. [Fixed.]

DS: [iterator.traits]/2 first sentence of 2.1 needs a "then". [Fixed.]

WB: [iterator.traits]/2 Add "then"s to complement the "if"s? [Fixed.]

WB: [iterator.traits]/2 2.2 may be easier to have as sub-bulleted list. [Fixed.]

WB: [iterator.traits]/2 Don't like mixing of "names" and "is". [Fixed.]

TS (offline): `requires !C<T>` isn't a valid *requires-clause* in C++20's reduced grammar. [audited all *requires-clause*s]

#### [iterator.traits]/3
WB:  second sentence "if specified" -> "is present" CC: [iterator.traits]/3 "should" is also problematic. This is meant to put requirements on users, but I dont think we need to impose these requirements. Group: [iterator.traits]/3 "should" -> "shall" [Sentence struck: There's no reason to require that program-defined `iterator_concept` has any relation to a `std` type, or that it has SMFs for tag dispatch.]

#### [iterator.traits]/5
TS: Can we rename the template parameter [`BidirectionalIterator`] in this example [to avoid confusion with the concept of the same name]? [Renamed to `BI`]

#### [iterator.custpoints.iter_move]
WB & TS (offline): Don't italicize "customization point object" - this isn't a definition. [fixed here and in [iterator.custpoints.iter_swap]]

TS (offline): We should harmonize [the wording in 1.1] with `ranges::swap`... "with overload resolution performed in a context..." [adjusted `iter_move` and `iter_swap` to agree with the style of the other CPOs]

#### [iterator.custpoints.iter_swap]
??: /1.2 "both" -> "each" [Fixed. Drive-by: clarify by referring to `SwappableWith` directly.]

CC: /1.3 Add a "then" before `(void)` [to clearly delimit the conditions from the equivalent expression]. [Fixed]

CC: /2 "does not swap" -> "does not exchange the values" with cross reference [to [concept.swappable]].

#### [iterator.concepts.general]
WB: What's a "type function"? Do we need p1? Strike p1. [struck]

CC: phrasing of "primary template" is wrong [should be "not program-defined"]. [Nope. "primary template" was, in fact, correct - restore the "instantiation of the primary template" wording throughout.]

TS (offline): Missing "the *qualified-id*" in 2.2 [fixed]

AM: Why not just always use `iterator_traits<I>`? Suggest a note. [added a note]

#### [iterator.concept.writable]
WB: Why italics in note in p5? CC: Because it came from the IS, of course. [Italics removed; and in the IS]

AM: Why `const_cast` statements in p1? Please add a note. [Added a note]

#### [iterator.concept.iterator]
RD: /2 note needs to update for change in syntax to `{...} -> auto&&`. [Note has been struck.]

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

#### [commonalgoreq.general]
WB: "on their arguments" -> "on its arguments". [This is correct, but unclear: replaced "their" with its antecedent "the concepts'". Also strike the noise word "explicitly".]

#### [commonalgoreq.indirectlymovable]
TS (offline): Presumably we need a similar rule [specifying that an rvalue RHS is valid-but-unspecified] for the `Assignable` part as well? [Nope: `Assignable` already has that semantic.]

#### [commonalgoreq.indirectlyswappable]
RD: p2 here differs from previous subclauses with usage of "only". [Rephrased.]

TS (offline): It looks like `I1` and `I2` can't be reference types, so why are we forwarding? [They are references [to avoid decay](https://github.com/ericniebler/stl2/issues/241). We went too far making them *rvalue* references, however. Changed to lvalue reference types.]

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

MH: /8 uses "distance" rather than "difference". TS (offline): Should we have a note that `M` can be negative? [Rephrase: "`M` is the difference between the ending and starting positions of `i`"]

[range.iterator.operations.distance]
WB: either _ shall denote a range or else _ shall denote a range. [Rephrased for clarity, but without "either...else": the preconditions are not mutually exclusive.]

[reverse.iterator]
WB: order [the iterator traits] aliases consistently. [Changed consistently throughout to `iterator_concept` (if present), `iterator_category`, `value_type`, `difference_type`, `pointer`, `reference`. Since this is a simple permutation, I put diff markings in the IS text but not in the new text.]

WB: p1 line break please. [broke]

DS: Please rename template parameter `Iterator` to `I`. TS (offline): Can we rename
the template parameter to avoid confusion with the Iterator concept? [I've made a note to submit this change as a post-merge editorial issue; I'd rather not bloat the proposal with *all* the wording for `reverse_iterator` and `move_iterator` simply so I can markup this change.]

[reverse.iter.requirements]
CC: "satisfy" -> "meet". [fixed]

WB: This is a mess. If you can clean it up, I'd be very happy. [Improved (happiness not guaranteed)]

[reverse.iter.cmp]
WB: would rather phrase p1 as ... [p1 struck]

CC: "subsection" should be removed. [p1 struck]

Group: would like this wording applied throughout. [done]

[reverse.iter.nonmember]
CC: [The conditional `noexcept`s] could be simplified [by using `current` instead of `declval`]. [so simplified]

TS (offline): [several comments about the conditional `noexcept`s indicating that the intended implementation is too subtle]. [clarified effects]

RD: right-most paren [in p4] needs to be moved toward noexcept and not include `is_nothrow_copy_constructible_v` [fixed]

MH: `Iterator2` needs to be in `noexcept` clause [in p4]. TS (offline): [ditto]. [fixed.]

TS (offline): Do we want to include [`iter_`-]swapping in either order? [Sort of, but not enough to want to pay the compile time cost.]

[move.iterator]
TS (offline): Can we rename the template parameter to avoid confusion with the `Iterator` concept? [Same response as for `reverse_iterator`: I'll do this in a
a follow-up editorial issue.]

[move.iter.requirements]
WB: "If any of the _ functions *is* instantiated" ["any" can be either singular or plural, and I think the plural reads better here. COME AT ME, Walter!]

[move.iter.nav]
CC: use `auto` rather than `decltype(auto)` [fixed]

TS (offline): Can we have a note that the return type is `void` in [the "otherwise"] case? [There are no `return`s from which to deduce a return type, how is this not clear?]

[move.iter.op.comp]
CC (Drive-by): Explode p1 into constraints elements as for [reverse.iter.comp]. [fixed]

[move.iter.nonmember]
CC (Drive-by): Explode p1 into constraints elements as for [move.iter.op.comp]. [fixed]

[move.sent.op.const]
TS (offline): [The converting constructor template] is mis-constrained: `ConvertibleTo` examines the convertiblity of non-`const` rvalue `S2`, but we are initializing from a `const` lvalue. [audited all uses of `ConvertibleTo`]

[iterators.common]
CC (Drive-by): Hanging paragraphs. [Push down into [common.iterator]]

[common.iterator.traits]
WB: p2-p4 should be bullets under p1. [fixed]

TS (offline): Where do we require `I` to be at least input? [The `iterator_traits` specialization is constrained to require `InputIterator`.]

CC (Drive-by): The specialization of `readable_traits` is unnecessary given that `common_iterator` specializes `iterator_traits`. [struck]

[common.iterator.const]
WB: Do we need separate subclauses for each operator? [Coalesce tiny subclauses]

[common.iter.access]
Group: Move [conditional `noexcept` paragraph] P4 to P1. [moved]

[common.iter.cmp]
RD: `I1` -> `I`, `S1` -> `S`. [fixed]

[common.iter.cust]
TS (offline): [`y.v_` has no alternative `I`, it has `I2`]. [fixed]

[default.sent]
WB: Merge into [default.sentinels]. [fixed]

[counted.iterator]
CC: "distance from its starting position" is just wrong. [fixed]

WB: Why "possibly differing" rather than "possibly identical"? [struck - it's immaterial.]

DS: `cnt` -> `n` or something else, but not `count` as that is a function name. [change to `length`]

CC (Drive-by): The specialization of `readable_traits` is unnecessary given the specialization of `iterator_traits`. [struck]

[counted.iter.const]
WB: "and conversions" but conversion are elsewhere. [Merge [counted.iter.op.conv]]

CC: Strike p1 and declaration that precedes it [replace with DMIs and defaulted constructor]. [fixed]

CC: Strike "Constructs a `counted_iterator`," [struck]

[counted.iter.access]
RD: `noexcept` on `count()`. [`noexcept`ed]

[counted.iter.ops]
Group: Squash all subclauses to one ginormous section. [Rearrange subclauses in the style of the working draft.]

RD: ["Expects" element] needs a period. [Audited all "Expects"]

DS: [The "Returns" element for `operator++()`] could be moved into "Effects". TS (offline): Why not put this into the codeblock? [Merge all "Returns" elements into "Effects"]
