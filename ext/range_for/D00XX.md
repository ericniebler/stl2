---
pagetitle: Generalizing the Range-Based For Loop
title: Generalizing the Range-Based For Loop
...

Introduction
=====

The current draft of the Ranges TS (CITE) loosens the requirements on the objects
used to denote a range. Today, two iterators of the same type are used to denote
a range. In the Ranges TS, a *sentinel* may be used to denote the end of a
range, where the type of the sentinel may be different from the type of the range's
iterator. The motivation for the loosening of this requirement is given in section
3.3.5 of [Ranges for the Standard Library, Revision 1][10][@n4128], but in short
it is to facilitate better code generation for many interesting kinds of ranges,
such as a range denoted by an iterator and a predicate.

Allowing the type of a range's end to differ from that of its begin causes problems
when the user tries to use such a range with the built-in range-based `for` loop,
which requires a range's begin and end to have the same type. This paper proposes
to lift that restriction for C++17, thereby giving users of the Ranges TS the best
possible experience.

Implementation Experience
=============

The author has implemented the described resolution in the clang compiler. The
implementation was as simple as removing the code that checks that `begin()` and
`end()` return objects of the same type. After this change was made, non-bounded
ranges (those for which `end()` returns a sentinel that is not an iterator) work
with the built-in range-based `for` loop.

Motivation and Scope
=====

The motivation is simple enough: to give the users of the Ranges TS the best
possible experience. If the ranges they create with the Ranges TS are not usable
with the built-in range-based `for` loop, it will reflect poorly both on the
Ranges TS and on the range-based `for` loop. In all likelihood, a macro-based
solution like [`BOOST_FOREACH`][][] will be invented to fill the gap.

The existing range-based `for` loop is over-constrained. The end iterator is never
incremented, decremented, or dereferenced. Requiring it to be an iterator serves
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

I would also like to thank Herb Sutter and the Standard C++ Foundation, without
whose generous financial support The Ranges TS would not be possible.

References
=====

---
references:
- id: stepanov09
  title: Elements of Programming
  type: book
  author:
  - family: Stepanov
    given: Alexander
  - family: McJones
    given: Paul
  edition: 1
  isbn: 032163537X, 9780321635372
  issued:
    year: 2009
  publisher: Addison-Wesley Professional
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
- id: n3351
  title: 'N3351: A Concept Design for the STL'
  type: article
  author:
  - family: Stroustrup
    given: Bjarne
  - family: Sutton
    given: Andrew
  issued:
    year: 2012
    month: 1
  URL: 'http://www.open-std.org/jtc1/sc22/wg21/docs/papers/2012/n3351.pdf'
- id: n1873
  title: 'N1873: The Cursor/Property Map Abstraction'
  type: article
  author:
  - family: Dietmar
    given: Kühl
  - family: Abrahams
    given: David
  issued:
    year: 2005
    month: 8
    day: 26
  URL: 'http://www.open-std.org/jtc1/sc22/wg21/docs/papers/2005/n1873.html'
- id: new-iter-concepts
  title: 'N1640: New Iterator Concepts'
  URL: 'http://www.open-std.org/jtc1/sc22/wg21/docs/papers/2004/n1640.html'
  type: article
  author:
  - family: Abrahams
    given: David
  - family: Siek
    given: Jeremy
  - family: Witt
    given: Thomas
  issued:
    year: 2004
    month: 4
    day: 10
- id: sutter-99
  title: When is a container not a container?
  type: article-journal
  author:
  - family: Sutter
    given: Herb
  issued:
    date-parts:
      - - 1999
        - 5
  container-title:
    C++ Report
  volume:
    11
  issue:
    5
  accessed:
    year: 2015
    month: 7
    day: 1
  URL: 'http://www.gotw.ca/publications/mill09.htm'
- id: range-v3
  title: Range v3
  URL: 'http://www.github.com/ericniebler/range-v3'
  type: webpage
  accessed:
    year: 2014
    month: 10
    day: 8
- id: cmcstl2
  title: CMCSTL2
  URL: 'https://github.com/CaseyCarter/cmcstl2'
  type: webpage
  accessed:
    year: 2015
    month: 9
    day: 9
- id: n4382
  title: 'N4382: Working Draft: C++ Extensions for Ranges'
  type: article
  author:
  - family: Niebler
    given: Eric
  issued:
    year: 2015
    month: 4
    day: 12
  URL: http://www.open-std.org/jtc1/sc22/wg21/docs/papers/2015/n4382.pdf
- id: sgi-stl
  title: 'SGI Standard Template Library Programmer''s Guide'
  type: webpage
  source: https://www.sgi.com/tech/stl/
  URL: https://www.sgi.com/tech/stl/
  accessed:
    year: 2015
    month: 8
    day: 12
- id: custpoints
  title: 'Suggested Design for Customization Points'
  type: article
  author:
  - family: Niebler
    given: Eric
  issued:
    year: 2015
    month: 3
    day: 11
...

[1]: http://www.open-std.org/jtc1/sc22/wg21/docs/papers/2015/n4382.pdf "Working Draft: C++ Extensions for Ranges"
[2]: http://www.open-std.org/jtc1/sc22/wg21/docs/papers/2004/n1640.html "New Iterator Concepts"
[3]: http://www.open-std.org/jtc1/sc22/wg21/docs/papers/2005/n1873.html "The Cursor/Property Map Abstraction"
[4]: http://www.gotw.ca/publications/mill09.htm "When is a container not a container?"
[5]: http://www.github.com/ericniebler/range-v3 "Range v3"
[6]: http://www.open-std.org/jtc1/sc22/wg21/docs/papers/2012/n3351.pdf "A Concept Design for the STL"
[7]: https://www.sgi.com/tech/stl/ "SGI Standard Template Library Programmer's Guide"
[8]: http://www.open-std.org/jtc1/sc22/wg21/docs/papers/2015/n4381.html "Suggested Design for Customization Points"
[9]: https://github.com/CaseyCarter/cmcstl2 "CMCSLT2: Casey Carter's reference implementation of STL2"
[10]: http://www.open-std.org/jtc1/sc22/wg21/docs/papers/2014/n4128.html "Ranges for the Standard Library, Revision 1"
