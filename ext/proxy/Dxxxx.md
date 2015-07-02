---
pagetitle: Proxy Iterators for STL.Next
title: Proxy Iterators for STL.Next
...

Introduction
=====

This paper presents an extension to the Ranges TS [@n4328] that makes *proxy iterators* full-fledged members of the STL iterator hierarchy. This solves the "`vector<bool>`" problem along with several other problems that become apparent when working with range adaptors. It achieves this without fracturing the `Iterator` concept hierarchy[][9][@new-iter-concepts] and without breaking iterators apart into separate traversal and access pieces[][11][@n1873].

The design is presented as a series of diffs to the latest draft of the Ranges and Concepts TSs; however, everything suggested here has been implemented in C++11, where Concepts Lite has been simulated with the help of generalized SFINAE for expressions.

Motivation and Scope
=====

The proxy iterator problem has been known since at least 1999 when Herb Sutter wrote his article ["When is a container not a container?"][22][@sutter-99] about the problems with `vector<bool>`. Because `vector<bool>` stores the `bool`s as bits in packed integers rather than as actual `bool`s, its iterators cannot return a real `bool&` when they are dereferenced; rather, they must return proxy objects that merely behave like `bool&`. That would be fine except that:

1. According to the iterator requirements tables, every iterator category stronger than InputIterator is required to return a real reference from its dereference operator (`vector` is required to have random-access iterators), and
2. Algorithms that move and swap elements often do not work with proxy references.

Looking forward to a constrained version of the STL, there is one additional problem: the algorithm constraints must accommodate iterators with proxy reference types. This is particularly vexing for the higher-order algorithms that accept functions that are callable with objects of the iterator's value type.

<!--
A *proxy* is a stand-in for another object. It is important to note that not all iterators that return rvalues are proxy iterators. If the rvalue does not stand in for another object, it is not a proxy. For instance, an iterator that adapts another by multiplying each element by 2 is not a proxy iterator. This is an important distinction. Previous
-->

## Proxy Iterator problems

For all its problems, `vector<bool>` works surprisingly well in practice, despite the fact that fairly trivial code such as below is not portable.

```c++
std::vector<bool> v{true,false,true};
auto i = v.begin();
bool b = false;
using std::swap;
swap(* i, b);
```

Because of the fact that this code is underspecified, it is impossible to say with certainty which algorithms work with `vector<bool>`. That fact that many do is due largely to the efforts of implementors and to the fact that `bool` is a trivial, copyable type that hides many of the nastier problems with proxy references. For more interesting proxy reference types, the problems are impossible to hide.

A more interesting proxy reference type is that of a `zip` range view from the [range-v3][7][@range-v3] library. The `zip` view adapts two underlying sequences by building pairs of elements on the fly as the `zip` view is iterated.

```c++
vector<int> vi {1,2,3};
vector<string> vs {"a","b","c"};

auto zip = ranges::view::zip(vi, vs);
auto x = * zip.begin();
static_assert(is_same<decltype(x), pair<int&,string&>>{}, "");
assert(&x.first == &vi[0]);
assert(&x.second == &vs[0]);
```

The `zip` view's iterator's reference type is an rvalue `pair` object, but the `pair` holds lvalue references to the elements of the underlying sequences. This proxy reference type exposes more of the fundamental problems with proxies than does `vector<bool>`, so it will be used in the proceeding discussion.

### Permutable proxy iterators

Many algorithms such as `partition` and `sort` must permute elements. The Palo Alto report [cite] uses a `Permutable` concept to group the constraints of these algorithms. `Permutable` is expressed in terms of an `IndirectlyMovable` concept, which is described as follows:

> The `IndirectlyMovable` and `IndirectlyCopyable` concepts describe copy and move relationships
> between the values of an input iterator, `I`, and an output iterator `Out`. For an output iterator
> `out` and an input iterator `in`, their syntactic requirements expand to:
>
> - `IndirectlyMovable` requires ``*out = move(*in)``

The iterators into a non-const `vector` are `Permutable`. If we `zip` the two `vector`s together, is the resulting `zip` iterator also `Permutable`? The answer is: maybe, but not with the desired semantics. Given the `zip` view defined above, consider the following code:

```c++
auto i = zip.begin();
auto j = next(i);
* i = move(* j);
```

Since `*j` returns an rvalue `pair`, the `move` has no effect. The assignment then copies elements instead of moving them. Had one of the underlying sequences been of a move-only type like `unique_ptr`, the code would fail to compile.

The fundamental problem is that with proxies, the expression `move(*j)` is moving the *proxy*, not the element being proxied. Patching this up in the current system would involve returning some special pair-like type from `*j` and overloading `move` for it such that it returns a different pair-like type that stores rvalue references. However, `move` is not a customization point so the algorithms will not use it. Making `move` a customization point is one possible fix, but the effects on user code of breaking the assumption that `move(t)` returns a `T&&` are unknown and unknowable.

### Iterator associated types

The value and reference associated types must be related to each other in a way that can be relied upon by the algorithms. The Palo Alto report defines a `Readable` concept that expresses this relationship as follows (updated for the new Concepts Lite syntax):

```c++
template< class I >
concept bool Readable =
    Semiregular<I> && requires (I i) {
        typename ValueType<I>;
        { * i } -> const ValueType<I>&;
    };
```

The result of the dereference operation must be convertible to a const reference of the iterator's value type. This works trivially for all iterators whose reference type is an lvalue reference, and it also works for some proxy iterator types. In the case of `vector<bool>`, the dereference operator returns an object that is implicitly convertible to `bool`, which can bind to `const bool&`.

But once again we are caught out by move-only types. A `zip` view that zips together a `vector<unique_ptr<int>>` and a `vector<int>` has the following associated types:

| Associtated type | Value                         |
|------------------|-------------------------------|
| `ValueType<I>`   | `pair<unique_ptr<int>, int>`  |
| `decltype(*i)`   | `pair<unique_ptr<int>&, int&>`|

To model `Readable`, the expression "`const ValueType<I>& tmp = *i`" must be valid. But trying to initialize a `const pair<unique_ptr<int>, int>&` with a `pair<unique_ptr<int>&, int&>` will fail. It tries to create a temporary `pair` that can be bound to the `const&`, which tries to copy from an lvalue `unique_ptr`. So we see that the `zip` view's iterators are not even `Readable` when one of the element types is move-only. That's unacceptable.

Although the Palo Alto report lifts the onerous restriction that `*i` must be an lvalue expression, we can see from the `Readable` concept that proxy reference types are still not adequately supported.

### Constraining higher-order algorithms

The Palo Alto report shows the constrained signature of the `for_each` algorithm as follows:

```c++
template<InputIterator I, Semiregular F>
    requires Function<F, ValueType<I>>
F for_each(I first, I last, F f);
```

Consider calling code

```c++
// As before, vi and vs are vectors
auto z = view::zip( vi, vs );
// Let Ref be the zip iterator's reference type:
using Ref = decltype(*z.begin());
// Use for_each to increment all the ints:
for_each( z.begin(), z.end(), [](Ref r) {
    ++r.first;
});
```

Without the constraint, this code compiles. With it, it doesn't. The constraint `Function<F, ValueType<I>>` checks to see if the lambda is callable with `pair<int,string>`. The lambda accepts `pair<int&,string&>`. There is no conversion that makes the call succeed.

Changing the lambda to accept either a `pair<int,string> [const &]` or a `pair<int const &, string const &> [const &]` would make the check succeed, but the body of the lambda would fail to compile or have the wrong semantics.


Proposed Design
=====


## Impact on the Standard



Technical Specifications
=====

This section is intentionally left blank.

Future Directions
=====



Acknowledgements
=====



References
=====

---
references:
- id: boostconceptcheck
  title: Boost Concept Check Library
  URL: 'http://boost.org/libs/concept_check'
  type: webpage
  accessed:
    year: 2014
    month: 10
    day: 8
- id: boostrange
  title: Boost.Range Library
  URL: 'http://boost.org/libs/range'
  type: webpage
  accessed:
    year: 2014
    month: 10
    day: 8
- id: asl
  title: Adobe Source Libraries
  URL: 'http://stlab.adobe.com'
  type: webpage
  accessed:
    year: 2014
    month: 10
    day: 8
- id: drange
  title: D Phobos std.range
  URL: 'http://dlang.org/phobos/std_range.html'
  type: webpage
  accessed:
    year: 2014
    month: 10
    day: 8
- id: bekennrange
  title: Position-Based Ranges
  URL: 'https://github.com/Bekenn/range'
  type: webpage
  accessed:
    year: 2014
    month: 10
    day: 8
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
- id: n3782
  title: 'N3782: Index-Based Ranges'
  type: article
  author:
  - family: Schödl
    given: Arno
  - family: Fracassi
    given: Fabio
  issued:
    year: 2013
    month: 9
    day: 24
  URL: 'http://www.open-std.org/jtc1/sc22/wg21/docs/papers/2013/n3782.pdf'
- id: clangmodernize
  title: Clang Modernize
  URL: 'http://clang.llvm.org/extra/clang-modernize.html'
  type: webpage
  accessed:
    year: 2014
    month: 10
    day: 8
- id: new-iter-concepts
  title: New Iterator Concepts
  URL: 'http://www.boost.org/libs/iterator/doc/new-iter-concepts.html'
  type: webpage
  accessed:
    year: 2014
    month: 10
    day: 8
- id: universal-references
  title: Universal References in C++11
  URL: 'http://isocpp.org/blog/2012/11/universal-references-in-c11-scott-meyers'
  type: webpage
  accessed:
    year: 2014
    month: 10
    day: 8
- id: range-comprehensions
  title: Range Comprehensions
  URL: 'http://ericniebler.com/2014/04/27/range-comprehensions/'
  type: webpage
  accessed:
    year: 2014
    month: 10
    day: 8
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
- id: n4132
  title: 'N4132: Contiguous Iterators'
  type: article
  author:
  - family: Maurer
    given: Jens
  issued:
    year: 2014
    month: 9
    day: 10
  accessed:
    year: 2014
    month: 10
    day: 8
  URL: 'https://isocpp.org/files/papers/n4132.html'
- id: ntcts-iterator
  title: NTCTS Iterator
  URL: 'https://github.com/Beman/ntcts_iterator'
  type: webpage
  accessed:
    year: 2014
    month: 10
    day: 8
- id: range-v3
  title: Range v3
  URL: 'http://www.github.com/ericniebler/range-v3'
  type: webpage
  accessed:
    year: 2014
    month: 10
    day: 8
- id: llvm-sroa
  title: 'Debug info: Support fragmented variables'
  URL: 'http://reviews.llvm.org/D2680'
  type: webpage
  accessed:
    year: 2014
    month: 10
    day: 8
- id: libcxx
  title: 'libc++ C++ Standard Library'
  URL: 'http://libcxx.llvm.org/'
  type: webpage
  accessed:
    year: 2014
    month: 10
    day: 8
- id: austern98
  title: 'Segmented Iterators and Hierarchical Algorithms'
  URL: 'http://dl.acm.org/citation.cfm?id=647373.724070'
  author:
  - family: Austern
    given: Matthew
  type: paper-conference
  container-title: Selected Papers from the International Seminar on Generic Programming
  page: 80-90
  issued:
    year: 2000
- id: cpp-seasoning
  title: 'C++ Seasoning'
  author:
  - family: Parent
    given: Sean
  type: speech
  URL: 'https://github.com/sean-parent/sean-parent.github.com/wiki/presentations/2013-09-11-cpp-seasoning/cpp-seasoning.pdf'
  container-title: 'GoingNative 2013'
  issued:
    year: 2013
    month: 9
    day: 11
- id: muchnick97
  title: 'Advanced Compiler Design Implementation'
  author:
  - family: Muchnick
    given: Steven
  publisher: 'Morgan Kaufmann'
  issued:
    year: 1997
  isbn: '1558603204, 9781558603202'
- id: n4017
  title: 'N4017: Non-member size() and more'
  type: article
  author:
  - family: Marcangelo
    given: Riccardo
  issued:
    year: 2014
    month: 5
    day: 22
  accessed:
    year: 2014
    month: 10
    day: 10
  URL: 'http://www.open-std.org/jtc1/sc22/wg21/docs/papers/2014/n4017.htm'
- id: n3350
  title: 'N3350: A minimal std::range<Iter>'
  type: article
  author:
  - family: Yasskin
    given: Jeffrey
  issued:
    year: 2012
    month: 1
    day: 16
  accessed:
    year: 2014
    month: 10
    day: 10
    URL: 'http://www.open-std.org/Jtc1/sc22/wg21/docs/papers/2012/n3350.html'
...

[1]: http://boost.org/libs/concept_check "Boost Concept Check Library"
[2]: http://www.boost.org/libs/range "Boost.Range"
[3]: http://stlab.adobe.com/ "Adobe Source Libraries"
[4]: http://dlang.org/phobos/std_range.html "D Phobos std.range"
[5]: https://github.com/Bekenn/range "Position-Based Ranges"
[6]: https://github.com/sean-parent/sean-parent.github.com/wiki/presentations/2013-09-11-cpp-seasoning/cpp-seasoning.pdf "C++ Seasoning, Sean Parent"
[7]: http://www.github.com/ericniebler/range-v3 "Range v3"
[8]: http://www.open-std.org/jtc1/sc22/wg21/docs/papers/2012/n3351.pdf "A Concept Design for the STL"
[9]: http://www.boost.org/libs/iterator/doc/new-iter-concepts.html "New Iterator Concepts"
[10]: http://www.open-std.org/jtc1/sc22/wg21/docs/papers/2013/n3782.pdf "Indexed-Based Ranges"
[11]: http://www.open-std.org/jtc1/sc22/wg21/docs/papers/2005/n1873.html "The Cursor/Property Map Abstraction"
[12]: http://ericniebler.com/2014/04/27/range-comprehensions/ "Range Comprehensions"
[13]: http://isocpp.org/blog/2012/11/universal-references-in-c11-scott-meyers "Universal References in C++11"
[14]: http://lafstern.org/matt/segmented.pdf "Segmented Iterators and Hierarchical Algorithms"
[15]: http://reviews.llvm.org/D2680 "Debug info: Support fragmented variables."
[16]: http://clang.llvm.org/extra/clang-modernize.html "Clang Modernize"
[17]: http://libcxx.llvm.org/ "libc++ C++ Standard Library"
[18]: https://isocpp.org/files/papers/n4132.html "Contiguous Iterators"
[19]: https://github.com/Beman/ntcts_iterator "ntcts_iterator"
[20]: http://www.open-std.org/jtc1/sc22/wg21/docs/papers/2014/n4017.htm "Non-member size() and more"
[21]: http://www.open-std.org/Jtc1/sc22/wg21/docs/papers/2012/n3350.html "A minimal std::range<Iter>"
[22]: http://www.gotw.ca/publications/mill09.htm "When is a container not a container?"
