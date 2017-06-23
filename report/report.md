---
pagetitle: Editor's Report for the Ranges TS
title: Editor's Report for the Ranges TS
...

# New Papers

* N4671 is the prospective working draft of the Ranges TS. It is intended to replace N4651.
* N4672 is this Editor's Report.

# Changes since N4651

## Notable editorial changes:
  * [fca5c4d9](https://github.com/ericniebler/stl2/commit/fca5c4d98b3fe4f123934c4cb0daa56a6b3526bc) Revert "[EDITORIAL] Remove redundant redefinition of indirect_result_of in [indirectcallable.indirectinvocable]"

    Revert an earlier editorial error that removed the VERY MUCH NOT REDUNDANT definition of `indirect_result_of`.

  * [cca6fb00](https://github.com/ericniebler/stl2/commit/cca6fb0032eeacdd1e84e85a8c59a154450d312d) [EDITORIAL] LWG Kona changes:

    * Use `decltype(auto)` instead of "see below" in declarations

    * Insert missing semicolons in the specification of `counted_iterator::operator++`

    * Simplify `counted_iterator::operator++(int)` by using pre-increment in the effects-equivalent-to, which notably "inherits" the Requires element.

    All per LWG direction during Kona review.

## Less notable editorial changes

Several less significant editorial changes occurred between publishing N4651 and N4671 (See the git revision history at [`https://github.com/ericniebler/stl2/compare/N4651...N4671`](https://github.com/ericniebler/stl2/compare/N4651...N4671)) with git log entries:

<pre>
commit 51e87798d85491353ace2a1e39c70f50fbe2a590
Author: Casey Carter &lt;Casey@Carter.net>
Date:   Thu Jun 15 19:23:20 2017 -0700

    [EDITORIAL] clarify complexity elements for partition_point and lexicographical_compare

commit d1c84d792c28260278d2974717e1c74e3d51b308
Author: Casey Carter &lt;Casey@Carter.net>
Date:   Thu Jun 15 14:07:00 2017 -0700

    [EDITORIAL] Clarify that alg.foreach has stronger requirements than in C++14

    Fixes #401.

commit 8aee26ee5704ac910764974aaa093042a2561cf0
Author: Eric Niebler &lt;eniebler@boost.org>
Date:   Mon Jun 12 10:18:54 2017 -0700

    [EDITORIAL] fix forward-declaractions of std::iterator_traits in &lt;exper.../iterator> synopsis, fixes #392

commit 6c25afeacb3bb25c4844856feb7f7d294379d64d
Author: Eric Niebler &lt;eniebler@boost.org>
Date:   Sat Jun 10 10:40:14 2017 -0700

    [EDITORIAL] s/an Range/a Range/

commit 4748df73c0fcf0e19dcf341e5c920244989833f7
Author: Casey Carter &lt;Casey@Carter.net>
Date:   Fri Mar 31 11:03:05 2017 -0700

    [EDITORIAL] Update normative reference intro text
    ... per ISO/IEC directives part 2 15.5.1

commit ad4d8d21b52b4ddeadfa89d5ace6d9ddea336612
Author: timsong-cpp &lt;rs2740@gmail.com>
Date:   Sat May 20 01:22:23 2017 -0400

    Fix capitalization in clause titles

    Prevailing convention appears to be capitalizing only the first letter.

commit f1caf2b80c49c8f47c395c4968e669f34919de8d
Author: Casey Carter &lt;Casey@Carter.net>
Date:   Fri May 19 17:19:03 2017 -0700

    [EDITORIAL] Fix C++14 reference in [intro.compliance]

    Fixes #403.

commit 8b3ae787c8dd300a523c77628a2bea026ca9cfec
Author: Casey Carter &lt;Casey@Carter.net>
Date:   Fri May 19 17:15:03 2017 -0700

    [EDITORIAL] Replace \(begin|end){note} with \(enter|exit)note

    Fixes #402.
</pre>
