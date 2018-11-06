#### [allocator.requirements]
MC: Proposed change is to strike the word valid [from "...when `a` and `(a + n)` are
valid dereferenceable pointer values..."]. [struck]

#### [concept.swappable]
STL: Does the self-swap case [in p1] deserve a note? [noted]

STL: What if someone expects to find enum through ADL? [added "or enumeration"]

JW: Should that be rewritten "expression-equivalent to an expression that exchanges the values". I'm not sure what it as written means. [changed to "Otherwise, if ...., *an expression that* exchanges the denoted values.]
