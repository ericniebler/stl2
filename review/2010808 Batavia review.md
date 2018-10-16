AM: Alisdair Meredith
CC: Casey Carter
DS: Dan S
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

WB: [specialized.algorithms] Suggest a note like “This means that these algorithms may not be called with explicit template arguments” [added a note]

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

TS: [iterator.requirements.general]/12 & /14 “Up to but not including the element pointed to by the…” -> “Up to but not including the element, if any, pointed to by the…” [so changed]

TS: [iterator.requirements.general] last sentence of p13 duplicates first sentence of p15.

TS: last sentence of p13 duplicates first sentence of p15.
WB: Would like to strike first sentence
CC: We need the phrase "a range is valid". can put this in p13
TS: move second sentence to p14. [so rearranged]

WB: [iterator.requirements.general] "Functions in the library" -> "library functions" [so changed]

TS: [iterator.requirements.general] We dont have a definition of "weaker" [removed uses of "weaker" in reference to iterator categories; also in [iterator.concept.forward].]

AM: `WeaklyIncrementable` and `Incrementable` sound far more primitive than to just being tied to iterators. Would like to see them move down into `<concepts>`. [So would I - but this design change needs investigation to determine if and how to extract `iter_difference_t` from `iterator_traits`; this needs a paper.]

WB: [incrementable.traits] & [readable.traits] do we have meaning for "implemented as if"? [These seem to be noise words; struck.]

TS (offline): [incrementable.traits] Do you need to `decay` [in the `const I` partial specialization of `incrementable_traits`]? [Not really; the intent was to reduce the number of specializations needed for `iter_difference_t<const int[42]>`, but that's such a weird corner that it's not worth complicating the spec. Changed to `remove_const_t`.]

AM: [iterator.traits] [p1 says] `iterator_traits<int*>::pointer` is `void` [since it does not support `operator->`]? [Clarified these statements apply only to iterators of class type. Drive-by: fix the prior sentence as well which was ~~a dumpster fire~~ not good.]

WB: [iterator.traits]/2 "Member types of specializations that are not program defined"
RD: [iterator.traits]/2 Why arent you using kebab naming form?
TS (offline): [iterator.traits]/2 Should we kebab the exposition-only names?
Group: [iterator.traits]/2 is too long. Separate out exposition only concepts.
DS: [iterator.traits]/2 first sentence of 2.1 needs a "then"
WB: [iterator.traits]/2 Add "then"s to complement the "if"s?
WB: [iterator.traits]/2 2.2 may be easier to have as sub-bulleted list
WB: [iterator.traits]/2 Don’t like mixing of "names" and "is" [All changes applied]

TS (offline): `requires !C<T>` isn't a valid *requires-clause* in C++20's reduced grammar. [audited all *requires-clause*s]

WB: [iterator.traits]/3 second sentence "if specified" -> "is present"
CC: [iterator.traits]/3 "should" is also problematic. This is meant to put requirements on users, but I dont think we need to impose these requirements.
Group: [iterator.traits]/3 "should" -> "shall" [Sentence struck: There's no reason to require that program-defined `iterator_concept` has any relation to a `std` type, or that it has SMFs for tag dispatch.]

TS: [iterator.traits]/5 Can we rename the template parameter [BidirectionalIterator]in this example [to avoid confusion with the concept of the same name]? [Renamed to `BI`]
