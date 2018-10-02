Mon PM

DS: Dan S
TS: Tim S
AM: Alisdair Meredith
WB: Walter Brown
CC: Casey Carter
RD: Rob Douglas

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
