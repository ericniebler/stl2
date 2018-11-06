#### [allocator.requirements]
MC: Proposed change is to strike the word valid [from "...when `a` and `(a + n)` are
valid dereferenceable pointer values..."]. [struck]

#### [concept.swappable]
STL: Does the self-swap case [in p1] deserve a note? [noted]

STL: What if someone expects to find enum through ADL? [added "or enumeration"]

JW: Should that be rewritten "expression-equivalent to an expression that exchanges the values". I'm not sure what it as written means. [changed to "Otherwise, if ...., *an expression that* exchanges the denoted values.]

TK: Could we add [the "SFINAE" note] to expression-equivalent instead of everywhere? [Action item to make this in a followup editorial change.]

STL: I'm uncomfortable with "function templates" that aren't actually function templates [in p4.1]. CC: Could be "entities"? [Changed to "entities", here and in [algorithms.requirements]]

STL: 4.3 has a typo: "explicitly template arguments". JW: Should be "explicitly-specified template argument lists". [Changed here, and note duplicated for the identical requirement in [algorithms.requirements]]
