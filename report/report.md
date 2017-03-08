---
pagetitle: Editor's Report for the Ranges TS
title: Editor's Report for the Ranges TS
...

# New Papers

* N4651 is the prospective working draft of the Ranges TS. It is intended to replace N4620.
* N4652 is this Editor's Report.

# Changes since N4620

## Motions incorprated into the working draft in Kona:
### LWG Motion 23: P0621R0 "Ready Ranges TS Issues"
* [189](https://github.com/ericniebler/stl2/issues/189) concept `Callable` should perfectly forward its function to `invoke`

    Applied in [ea4bd6e6](https://github.com/ericniebler/stl2/commit/ea4bd6e63f12a0a24e61f889bcca1ee6a79c8652).

* [236](https://github.com/ericniebler/stl2/issues/236) `projected<I>::value_type` incorrectly decays arrays to pointers

    Applied in [66cb441a](https://github.com/ericniebler/stl2/commit/66cb441a80e489f436b5141ba04962e79ded6e55).

* [237](https://github.com/ericniebler/stl2/issues/237) `IndirectCallable` should use `value_type_t<I>&` instead of `value_type_t<I>`

    Applied in [ea4bd6e6](https://github.com/ericniebler/stl2/commit/ea4bd6e63f12a0a24e61f889bcca1ee6a79c8652).

* [238](https://github.com/ericniebler/stl2/issues/238) P0022 broke `indirect_result_of`

    Applied in [f75c16db](https://github.com/ericniebler/stl2/commit/f75c16db5b09a33016b6fe3112a0270a2dec16c9).

* [239](https://github.com/ericniebler/stl2/issues/239) Remove the "Experimental additional constraints" from `Readable`

    Applied in [822e3d65](https://github.com/ericniebler/stl2/commit/822e3d65b31ef8a97fe14892ceff8950310508df).

* [240](https://github.com/ericniebler/stl2/issues/240) Should `Writable` require `Semiregular`, or "Move-Defaultable"

    Applied in [916be231](https://github.com/ericniebler/stl2/commit/916be231250e8a7e1a7db7c59e8074237176fddf).

* [241](https://github.com/ericniebler/stl2/issues/241) `IndirectlySwappable` is broken

    Applied in [54457f93](https://github.com/ericniebler/stl2/commit/54457f93b929e82c8f223f441a966d8d18e41662).

* [242](https://github.com/ericniebler/stl2/issues/242) Customizing `iter_move` and `iter_swap` is needlessly complicated

    Applied in [f016416f](https://github.com/ericniebler/stl2/commit/f016416f8f81e2e2389338f018d401828a9eaf22).

* [243](https://github.com/ericniebler/stl2/issues/243) `difference_type` of arrays

    Applied in [8c035d37](https://github.com/ericniebler/stl2/commit/8c035d377f73e2e7ea8f1717ccfd37d0444b934a).

* [244](https://github.com/ericniebler/stl2/issues/244) `move_iterator::operator*` should be defined in terms of `iter_move`

    Applied in [ff2a878e](https://github.com/ericniebler/stl2/commit/ff2a878e1003e4035cefc434f637a921ec0438bf), with an editorial correction of the wording for [move.iter.op.star] from "Equivalent to: `return iter_move(i + n);`" to "Equivalent to: `return iter_move(current + n);`".

* [258](https://github.com/ericniebler/stl2/issues/258): Remove subsection "C library algorithms" from `<experimental/ranges/algorithm>`

    Applied in [c9e4cc8d](https://github.com/ericniebler/stl2/commit/c9e4cc8db9faf83012f47026ee0fb2ae3739036d).

## Notable editorial changes:

  * [e15540b1](https://github.com/ericniebler/stl2/commit/e15540b17427724af926455e951b0cf53f4594cc) major reorg of `<iterator>`; add concepts to the synopsis

    Cleanup of the `<experimental/ranges/iterator>` header, most significantly including the iterator concepts in the header synposis. (Partially addresses [issue 11](https://github.com/ericniebler/stl2/issues/11).)

  * [1862bd89](https://github.com/ericniebler/stl2/commit/1862bd89cda5bde44993c0e8c4b6c0103825d594) add `<experimental/ranges/concepts>` synopsis

    Adds the missing synopsis of the `<experimental/ranges/concepts>` header. (Partially addresses [issue 11](https://github.com/ericniebler/stl2/issues/11); directly addresses [NB comment US-6 / issue 349](https://github.com/ericniebler/stl2/issues/349).)

  * [aced8dc9](https://github.com/ericniebler/stl2/commit/aced8dc9a1b82d224460750c1c4c0bbd8e8e7127) Relocate deprecated algorithm overloads completely to Annex A

    As requested by [NB US-8 / issue 359](https://github.com/ericniebler/stl2/issues/359), move the deprecated overloads of `equal`, `is_permutation`, `mismatch`, `swap_ranges`, and `transform` completely into the Annex.

  * [a8f86656](https://github.com/ericniebler/stl2/commit/a8f86656bfa047f5e327166cf7201d8f19d309f6) Replace `distance(f, l)` with `l - f` in [alg.is_permutation]/3

    As requested by [NB JP-2 / issue 356](https://github.com/ericniebler/stl2/issues/356).

  * [ade5d7a0](https://github.com/ericniebler/stl2/commit/ade5d7a0abc19d7b645a1c70abc58691c97a96c1) Relocate header table; macros are not entities

    As requested by [NB US-4 / issue 347](https://github.com/ericniebler/stl2/issues/347), clarify that macros are not entities.

  * [85b59183](https://github.com/ericniebler/stl2/commit/85b5918362094e59529adbd6e7c1e7737c5e1775) "equal" for customization point objects means [concepts.lib.general.equality]

    As requested by [NB US-3 / issue 346](https://github.com/ericniebler/stl2/issues/346), clarify the meaning of "equal" as used in the definition of *customization point object*.

  * [99da7818](https://github.com/ericniebler/stl2/commit/99da7818db38773fac5e95ab665715cc85161a10) Directory? What's a directory?

    As requested by [NB US-1 / issue 344](https://github.com/ericniebler/stl2/issues/344), don't use the term "directory" to describe the new headers.

  * [3bcd694f](https://github.com/ericniebler/stl2/commit/3bcd694f1d23486c9943cbec9feb1ec02dd5e0e4) Setup clauses 1-3 per ISO/IEC directives part 2

    ISO/IEC directives part 2 demands that clauses 1-3 are exactly "Scope," "References," and "Terms and Definitions." This pushes the pre-existing section numbers up by three relative to their numbering in N4620. This change was also requested by [NB CA-1 / issue 341](https://github.com/ericniebler/stl2/issues/341).

  * [6d2ff48e](https://github.com/ericniebler/stl2/commit/6d2ff48e4acfe1bda3444cce5c6a24320d550dc1) argument expressions to `ranges::swap` reference, rather than denote, objects

    Clarification confusion caused by the specifications of `ranges::swap` and `ranges::iter_swap` both using the term "denote" but with differing meanings, per [issue 306](https://github.com/ericniebler/stl2/issues/306).

  * [283fa47b](https://github.com/ericniebler/stl2/commit/283fa47b088d23f9a535dc8e8dfba616d05b9151) Clarify iterators.bidi/3.3

    Clarify [iterators.bidirectional]/3.3 "If `bool(a == b)`, then `bool((a--, a) == --b)`.", as requested during LWG review in Issaquah recorded in [issue 292](https://github.com/ericniebler/stl2/issues/292).

  * [9f81821b](https://github.com/ericniebler/stl2/commit/9f81821b1018ef19e04d76520a43d16d7aa377e6) Reorganize iterator.requirements.general to clarify presentation

    As requested by [NB GB-3 / issue 352](https://github.com/ericniebler/stl2/issues/352).

  * [484b24a2](https://github.com/ericniebler/stl2/commit/484b24a2624a89fd35208b6d43fe5cba2388d35b) Define "projection"; Fixes #221.

    As requested by LWG during the third Ranges review telecon, recorded in [issue 221](https://github.com/ericniebler/stl2/issues/221).

  * [f191094b](https://github.com/ericniebler/stl2/commit/f191094bb9c10d3ad0970ce44f8a4f4f7fb457cf) Patch for #353 (#376)

    Clarify the `&i == &++i` semantic requirement for `WeaklyIncrementable`, as requested by [NB GB-4 / issue 353](https://github.com/ericniebler/stl2/issues/353).

## Less notable editorial changes

Several less significant editorial changes occurred between publishing N4620 and N4651 (See the git revision history at [`https://github.com/ericniebler/stl2/compare/N4620...N4651`](https://github.com/ericniebler/stl2/compare/N4620...N4651)) with git log entries:

<pre>
commit c4ab9e9dde3cf7705ed7ea2d422fc6c66cbec19d
Author: Casey Carter &lt;Casey@Carter.net>
Date:   Wed Mar 15 13:28:54 2017 -0700

    [EDITORIAL] Clarify the specification of some of the comparison concepts

    per LWG Kona direction.

commit d966cba02986d7154ac3c2346653afcb4fb566ae
Author: Casey Carter &lt;Casey@Carter.net>
Date:   Mon Mar 13 17:53:51 2017 -0700

    [EDITORIAL] Remove unneeded std:: qualifications

    per LWG Kona direction.

commit 28572c54e719038531afe04248da1a58ec846950
Author: Casey Carter &lt;Casey@Carter.net>
Date:   Thu Mar 9 18:13:49 2017 -0800

    [EDITORIAL] swap u and v in CopyConstructible's "v is equal to u"

    per LWG Kona direction

commit caa3aa7e7f4baf0dbffb10552358a2b81f4c28a4
Author: Casey Carter &lt;Casey@Carter.net>
Date:   Thu Mar 9 18:07:40 2017 -0800

    [EDITORIAL] Note that Destructible forbids noexcept(false) destructors
    per LWG Kona direction

commit 206705564f3ef9928ef70f82a1e2bb801149a647
Author: Casey Carter &lt;Casey@Carter.net>
Date:   Thu Mar 9 17:52:38 2017 -0800

    [EDITORIAL] Rename Readable's parameter to In per LWG Kona direction

    Also correct the declaration of Writable in the &lt;iterator> synopsis.

commit c684161853eedf56952a4a416624ac57e2742f27
Author: Casey Carter &lt;Casey@Carter.net>
Date:   Thu Mar 9 17:47:38 2017 -0800

    [EDITORIAL] Don't qualify addressof per LWG Kona review

commit d4354511ef0f4197b28ba01a951afa24b39cdd7d
Author: Casey Carter &lt;Casey@Carter.net>
Date:   Thu Mar 9 17:44:40 2017 -0800

    [EDITORIAL] Clarify Assignable per LWG Kona review

commit f04054827b39ee5e8a8bac48c7c36255feccbe98
Author: Casey Carter &lt;Casey@Carter.net>
Date:   Thu Mar 9 17:04:33 2017 -0800

    [EDITORIAL] Replace "valid but unspecified" notes with references to lib.types.movedfrom

    Per LWG Kona instructions.

commit 04a5b098c050759486c982c8fcc65d00e73db7f7
Author: Casey Carter &lt;Casey@Carter.net>
Date:   Thu Mar 9 16:53:30 2017 -0800

    Cleanup "previous value" language in Swappable and MoveConstructible

    Addresses #293.

commit 9ad5341e9dd7e476e27fb647ae2cf3ba07f99c29
Author: Christopher Di Bella &lt;cjdb.ns@gmail.com>
Date:   Sat Feb 18 15:42:03 2017 +1100

    Patched #297 (#333)

    Annex C is not normative, so this change is editorial.

commit 923b7b5552db8cb0f850accd66b5ebec3f1c94f5
Author: Casey Carter &lt;Casey@Carter.net>
Date:   Wed Mar 8 14:02:07 2017 -0800

    [EDITORIAL] Remove redundant redefinition of indirect_result_of in [indirectcallable.indirectinvocable]

commit 01d47a592bb6ba8d3c16626816dc6252412c3d9a
Author: Eric Niebler &lt;eniebler@boost.org>
Date:   Wed Feb 15 09:49:16 2017 -0800

    [EDITORIAL] correct template parameter order for generate and generate_n

commit d4283046c1ae548131050b60722efc56f2f8acc1
Author: Eric Niebler &lt;eniebler@boost.org>
Date:   Mon Jan 30 15:04:45 2017 -0800

    [EDITORIAL] s/equivalent the/equivalent to the/

commit 1836cccdca8af0f81004f7eccc0ccb0633238147
Merge: 8532228 98f5cc6
Author: Casey Carter &lt;Casey@Carter.net>
Date:   Tue Feb 14 17:12:37 2017 -0800

    Minor editorial fixes to [iterator].

commit 98f5cc643e922a03f2934930b99848bb161aae33
Author: Casey Carter &lt;Casey@Carter.net>
Date:   Tue Feb 14 16:59:33 2017 -0800

    Minor cleanup

commit db3b675cfed327c6c5215f1a5118e5aa5d58b2aa
Author: Eric Niebler &lt;eniebler@boost.org>
Date:   Tue Feb 14 10:25:19 2017 -0800

    [EDITORIAL] Fix cross-reference to CommonReference concept

commit a0bd2cc2aa0babe0c6553a7a21ae4533938ec610
Author: Eric Niebler &lt;eniebler@boost.org>
Date:   Tue Jan 31 16:29:15 2017 -0800

    [EDITORIAL] give common_iterator::operator-> its own subsection and stable name, refs #318

commit 64a074e839a1ba38453ddb185d7f5a5659032e07
Author: Eric Niebler &lt;eniebler@boost.org>
Date:   Mon Jan 23 11:41:37 2017 -0800

    [Editorial] Table 5 has separate rows for iterator, indirect callable, and common algorithm requirements; fixes #308

commit a5c611a4a8137c86387e014085d5cdd13a14db82
Author: Casey Carter &lt;Casey@Carter.net>
Date:   Mon Jan 23 07:59:19 2017 -0800

    [Editorial] The concepts TS was not published in 2105.

commit 7cb4787b1a0039da157eefd61c9997b80b8a67a2
Author: Casey Carter &lt;Casey@Carter.net>
Date:   Tue Jan 17 14:23:13 2017 -0800

    [Editorial] "This paper" => "This document"

    Fixes #303.

commit 63921fc7c061de93f758dab593f58cb05287547e
Author: Casey Carter &lt;Casey@Carter.net>
Date:   Mon Nov 28 04:56:36 2016 -0800

    Editorial fixes I forgot to checkin for DTS
    [concepts.lib.compare.boolean]: Don't \tcode the entirety of 2.5 and 2.6.
    [iterator.stdtraits] and &lt;iterator> synopsis: qualify "experimental::ranges::Sentinel" when used in namespace std.
</pre>
