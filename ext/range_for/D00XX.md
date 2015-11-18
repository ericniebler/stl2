---
pagetitle: Generalizing the Range-Based For Loop
title: Generalizing the Range-Based For Loop
...

Introduction
=====

The current draft of the [Ranges TS][1][@n4560] loosens the requirements on the objects used to denote
a range. Today, two iterators of the same type are used to denote a range. In the Ranges TS,
a *sentinel* may be used to denote the end of a range, where the type of the sentinel may be
different from the type of the range's iterator. The motivation for the loosening of this
requirement is given in section 3.3.5 of [Ranges for the Standard Library, Revision 1][3][@n4128],
but in short it is to facilitate better code generation for many interesting kinds of ranges, such
as a range denoted by an iterator and a predicate.

Allowing the type of a range's end to differ from that of its begin causes problems when the user
tries to use such a range with the built-in range-based `for` loop, which requires a range's begin
and end to have the same type. This paper proposes to lift that restriction for C++17, thereby
giving users of the Ranges TS the best possible experience.

Implementation Experience
=============

The author has implemented the described resolution in the clang compiler. The implementation was
as simple as removing the code that checks that `begin()` and `end()` return objects of the same
type. After this change was made, non-bounded ranges (those for which `end()` returns a sentinel
that is not an iterator) work with the built-in range-based `for` loop.

Motivation and Scope
=====

The motivation is simple enough: to give the users of the Ranges TS the best possible experience.
If the ranges they create with the Ranges TS are not usable with the built-in range-based `for`
loop, it will reflect poorly both on the Ranges TS and on the range-based `for` loop. In all
likelihood, a macro-based solution like [`BOOST_FOREACH`][2][@boost-foreach] will be invented to
fill the gap.

Also, it can be argued that the existing range-based `for` loop is over-constrained. The end
iterator is never incremented, decremented, or dereferenced. Requiring it to be an iterator serves
no practical purpose.

Technical Specifications
=====

**6.5.4  The range-based `for` statement [stmt.ranges]**

1\. A range-based `for` statement is equivalent to

<blockquote><code><del>{
  auto && __range = <em>for-range-initializer</em>;
  for ( auto __begin = begin-expr,
             __end = end-expr;
        __begin != __end;
        ++__begin ) {
    <em>for-range-declaration</em> = *__begin;
    <em>statement</em>
  }
}</del></code></blockquote>

<blockquote><code><ins>{
  auto && __range = <em>for-range-initializer</em>;
  auto __begin = begin-expr;
  auto __end = end-expr;
  for ( ; __begin != __end; ++__begin ) {
    <em>for-range-declaration</em> = *__begin;
    <em>statement</em>
  }
}</ins></code></blockquote>

where [...] <ednote>[*Editorial note:* -- ... as in the current Working Draft. --*end note*]</ednote>

Acknowledgements
=====

I would also like to thank Herb Sutter and the Standard C++ Foundation, without whose generous
financial support the Ranges TS would not be possible.

References
=====

---
references:
- id: n4560
  title: 'N4560: Working Draft, C++ Extensions for Ranges'
  type: article
  author:
  - family: Niebler
    given: Eric
  - family: Carter
    given: Casey
  issued:
    year: 2015
    month: 11
  URL: 'http://www.open-std.org/jtc1/sc22/wg21/docs/papers/2015/n4560.pdf'
- id: n4128
  title: 'N4128: Ranges for the Standard Library, Revision 1'
  type: article
  author:
  - family: Niebler
    given: Eric
  - family: Parent
    given: Sean
  - family: Sutton
    given: Andrew
  issued:
    year: 2014
    month: 10
  URL: 'http://www.open-std.org/jtc1/sc22/wg21/docs/papers/2014/n4128.html'
- id: boost-foreach
  title: Boost.Foreach
  URL: 'http://boost.org/libs/foreach'
  type: webpage
  accessed:
    year: 2015
    month: 11
    day: 18
...

[1]: http://www.open-std.org/jtc1/sc22/wg21/docs/papers/2015/n4560.pdf "Working Draft: C++ Extensions for Ranges"
[2]: http://boost.org/libs/foreach "Boost.Foreach"
[3]: http://www.open-std.org/jtc1/sc22/wg21/docs/papers/2014/n4128.html "Ranges for the Standard Library, Revision 1"
