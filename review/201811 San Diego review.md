#### [allocator.requirements]
MC: Proposed change is to strike the word valid [from "...when `a` and `(a + n)` are
valid dereferenceable pointer values..."]. [struck]

#### [concept.swappable]
STL: Does the self-swap case [in p1] deserve a note? [noted]

STL: What if someone expects to find enum through ADL? [added "or enumeration"]

JW: Should that be rewritten "expression-equivalent to an expression that exchanges the values". I'm not sure what it as written means. [changed to "Otherwise, if ...., *an expression that* exchanges the denoted values.]

TK: Could we add [the "SFINAE" note] to expression-equivalent instead of everywhere? [Action item to make this in a followup editorial change.]

#### [specialized.algorithms]
STL: I'm uncomfortable with "function templates" that aren't actually function templates [in p4.1]. CC: Could be "entities"? [Changed to "entities", here and in [algorithms.requirements]]

STL: 4.3 has a typo: "explicitly template arguments". JW: Should be "explicitly-specified template argument lists". [Changed here, and note duplicated for the identical requirement in [algorithms.requirements]]

STL: We are using `addressof` then `static_cast` to `void*` in algorithms [in namespace `std`]. Should those algorithms also use `voidify`? [changed]

#### [special.mem.concepts]
STL: A note mentioning we don't cover all the possible operations with nothrow. [added notes]

#### [iterator.synopsis]
STL: In the synopsis, we lost the template header before `iter_rvalue_reference_t`. CC: It's correct but the formatting is unfortunate. [altered formatting]

#### [iterator.requirements.general]
Marshall: [In p14] incrementing "`i` `n` times" is odd typographically. [Rephrase "the result of `n` applications of `++i`"]

#### [iterator.traits]
STL: Should ["instantiation of the primary template"] be "specialization"? MC: Core uses "[specialization/instantiation] generated from template" [for example, in [temp.class.spec.match]/1]. [Changed to "names a specialization generated from the primary template" in [incrementable.traits]/2, [readable.traits]/2, [iterator.traits]/3, [iterator.traits]/4, [iterator.concepts.general]/1 (two places)]

MC: Is there supposed to be a definition of `value_type`? It is only mentioned it could be `void`. [The `difference_type`/"difference type" and `value_type`/"value type" associations are established in [incrementable.traits] and [readable.traits] for `WeaklyIncrementable` and `Readable` types.]

JW: [In p3.3] why is it "if `incrementable_traits<I>::difference_type` is well-formed" [which is nonsense], rather than "If the *qualified-id* ... is valid and denotes a type"? [fixed]

STL: P4, "opt in or out of conformance." [changed to "indicate conformance"]

JW: In P4, we can reduce words by using "explicit specializations or partial specializations may have members". [changed]

#### [iterator.cust]
CC: [Stable names are weird and long]. [iterator.custpoints.iter_move] should be [iter.move] (iterator.custpoints). [Simplify stable names]

#### [iterator.concept.writable]
JW: Use of "requires" in a note would be a problem [for ISO]. [change to "has"]

#### [iterator.concept.sentinel]
STL: Can we say "[`disable_sized_sentinel`] allows" instead of "enables"? [fixed; also in [range.sized]]

#### [iterator.concept.input]
JW: "need not require" could be a problem [for ISO]. [change to "does not need"]

#### [iterator.concept.bidirectional]
STL: In P2, can you choose a different letter besides `s`, such as `q`? `s` usually means sentinel. [fixed]

STL: In P3 is there a hole in the requirements. 3.4 talks abouts going forward and going back. It should possibly be split out. You've excluded the very beginning. [fixed]

#### [projected]
JW: "bundles"? CC: "Combines" is fine, if Stephan doesn't like "aggregates". [fixed; also in [range.subrange]]

Jeff: There's another requires [in a note] here. [fixed; also in [special.mem.concepts],[iterator.concept.incrementable]. I'm not going to audit all 952 occurrences of "require" here in SD - I'll do so when ISO complains.]
