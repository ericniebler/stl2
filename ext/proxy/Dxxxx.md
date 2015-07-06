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

Changing the lambda to accept either a "`pair<int,string> [const &]`" or a "`pair<int const &, string const &> [const &]`" would make the check succeed, but the body of the lambda would fail to compile or have the wrong semantics.

Proposed Design
=====

The design suggested here makes heavier use of an existing API, `iter_swap(I,I)`, promoting it to the status of customization point, thereby giving proxy iterators a way to control how elements are swapped. In addition, it suggests a new customization point: `iter_move(I)`, which can be used for moving an element at a certain position out of sequence, leaving a "hole". The return type of `iter_move` is the iterator's *rvalue reference*, a new associated type. The `IndirectlySwappable` and `IndirectlyMovable` concepts are re-expressed in terms of `iter_swap` and `iter_move`, respectively.

The relationships between an iterator's associated types, currently expressed in terms of convertability, are re-expressed in terms of a shared *common reference* type. A *common reference* is much like the familiar `common_type` trait, except that instead of throwing away top-level cv and ref qualifiers, they are preserved. Informally, the common reference of two reference types is the *minimally-qualified* reference type to which both types can bind. Like `common_type`, the new `common_reference` trait can be specialized.

## Impact on the Standard

The algorithms must be specified to use `iter_swap` and `iter_move` when swapping and moving elements. The concepts must be respecified in terms of the new customization points, and a new type trait, `common_reference`, must be specified and implemented. The known shortcomings of `common_type` (lack of SFINAE-friendliness, difficulty of specialization) must be addressed. Care must be taken in the algorithm implementations to hew to the valid expressions for the iterator concepts. The algorithm constraints must be respecified to accommodate proxy iterators.

For user code, the changes are minimal. No code that works today will stop working after adoping this resolution. When adapting generic code to work with proxy iterators, calls to `swap` and `move` should be replaced with `iter_swap` and `iter_move`, and for calls to higher-order algorithms, generic lambdas are the preferred solution. When that's not possible, functions can be changed to take arguments by the iterator's *common reference* type, which is the result of applying the `common_reference` trait to `Reference<I>&&` and `ValueType<I>&`. (A `CommonReference<I>` type alias is suggested to make this simpler.)

Alternate Designs
=====

## New iterator concepts

In [N1640][9][@new-iter-concepts], Abrahams et.al. describe a decomposition of the standard iterator concept hierarchy into access concepts: `Readable`, `Writable`, `Swappable`, and `Lvalue`; and traversal concepts: `SinglePass`, `Forward`, `Bidirectional`, and `RandomAccess`. Like the design suggested in this paper, the `Swappable` concept from N1640 is specified in terms of `iter_swap`. Since N1640 was written before move semantics, it does not have anything like `iter_move`, but it's reasonable to assume that it would have invented something similar.

Like the Palo Alto report, the `Readable` concept from N1640 requires a convertibility constraint between an iterator's reference and value associated types. As a result, N1640 does not adequately address the proxy reference problem as presented in this paper. In particular, it is incapable of correctly expressing the relationship between a move-only value type and its proxy reference type. Also, the somewhat complicated iterator tag composition suggested by N1640 is not necessary in a world with concept-based overloading.

In other respect, N1640 agrees with the STL design suggested by the Palo Alto report and the Ranges TS, which also has concepts for `Readable`, `Writable`. In the Palo Alto design, these "access" concepts are not purely orthogonal to the "traversal" concepts of `InputIterator`, `ForwardIterator`, however, since the latter are not pure traversal concepts; rather, these iterators are all `Readable`. The standard algorithms have little need for writable-but-not-readable random access iterators, for instance, so a purely orthogonal design does not accurately capture the requirements clusters that appear in the algorithm constraints. The binary concepts `IndirectlyMovable<I,O>`, `IndirectlyCopyable<I,O>`, and `IndirectlySwappable<I1,I2>` from the Palo Alto report do a better job of grouping common requirements and reducing verbosity in the algorithm constraints.

## Cursor/Property Map

[N1873][11][@n1873], the "Cursor/Property Map Abstraction" BUGBUG TODO

## Language support

In private exchange, Sean Parent suggested a more radical fix for the proxy reference problem: change the language. With his suggestion, it would be possible to specify that a type is a proxy reference with a syntax such as:

```c++
struct bool_reference : bool& {
    // ...
}
```

Notice the "inheritance" from `bool&`. When doing template type deduction, a `bool_reference` can bind to a `T&`, with `T` deduced to `bool`. This solution has not been explored in depth. It is unclear how to control which operations are to be performed on the proxy itself and which on the object being proxied, or under which circumstances, if any, that is desirable. The impact of changing template type deduction and possibly overload resolution to natively support proxy references is unknown.


Technical Specifications
=====

This section is written as a set of diffs against N4382, "C++ Extensions for Ranges" and N4141 (C++14), except where otherwise noted.

Add a section for diffs against 20.10 "Metaprogramming and type traits". To 20.10.2, add the following to the `<type_traits>` synopsis:

> ```c++
> // 20.10.7.6, other transformations:
> ...
> template <class T, class U, template <class> class TQual, template <class> class UQual>
> struct basic_common_reference { };
> template <class... T> struct common_reference;
> ```

Change Table 57 Other Transformations as follows:

> | Template | Condition | Comments |
> |----------|-----------|----------|
> | `template <class... T>` |  | [...] A program may specialize this trait |
> | `struct common_type;`   |  | if at least one template parameter in the  |
> | | | specialization is a user-defined type <span style="color:#009a9a">and</span> |
> | | | <span style="color:#009a9a">`sizeof...(T) == 2`</span>. [...] |
> | | | |
> | | | |
> | <span style="color:#009a9a">`template <class T, class U,`</span> |  | <span style="color:#009a9a">There shall be no member typedef `type`.</span> |
> | <span style="color:#009a9a">&nbsp;&nbsp;`template <class> class TQual,`</span> |  | <span style="color:#009a9a">A program may specialize this trait if at</span> |
> | <span style="color:#009a9a">&nbsp;&nbsp;`template <class> class UQual>`</span> |  | <span style="color:#009a9a">least one template parameter in the</span> |
> | <span style="color:#009a9a">`struct basic_common_reference;`</span> |  | <span style="color:#009a9a">specialization is a user-defined type.</span> |
> | | | <span style="color:#009a9a">&lbrack; *Note:* -- Such specializations may be</span> |
> | | | <span style="color:#009a9a">used to influence the result of</span>|
> | | | <span style="color:#009a9a">`common_reference` --*end note* ]</span>|
> | | | |
> | | | |
> | <span style="color:#009a9a">`template <class... T>`</span> |  | <span style="color:#009a9a">The member typedef type shall be</span> |
> | <span style="color:#009a9a">`struct common_reference;`</span> |  | <span style="color:#009a9a">defined or omitted as specified below.</span> |
> | | | <span style="color:#009a9a">If it is omitted, there shall be no</span> |
> | | | <span style="color:#009a9a">member type. All types in the</span> |
> | | | <span style="color:#009a9a">parameter pack T shall be complete or</span> |
> | | | <span style="color:#009a9a">(possibly cv) void. A program may</span> |
> | | | <span style="color:#009a9a">specialize this trait if at least one</span> |
> | | | <span style="color:#009a9a">template parameter in the</span> |
> | | | <span style="color:#009a9a">specialization is a user-defined type</span> |
> | | | <span style="color:#009a9a">and `sizeof...(T) == 2`. [ *Note:* Such</span> |
> | | | <span style="color:#009a9a">specializations are needed to properly</span> |
> | | | <span style="color:#009a9a">handle proxy reference types in generic</span> |
> | | | <span style="color:#009a9a">code. --*end note* \]</span> |



Delete [meta.trans.other]/p3 and replace it with the following:

> <span style="color:#009a9a">3\. Let `CREF(A)` be `add_lvalue_reference_t<add_const_t<A>>`. Let `UNCVREF(A)` be `remove_cv_t<remove_reference_t<A>>`. Let `XREF(A)` denote a unary template `T` such that `T<UNCVREF(A)>` denotes the same type as `A`. Let `COPYCV(FROM,TO)` be an alias for type `TO` with the addition of `FROM`'s top-level cv-qualifiers. [*Example:* -- `COPYCV(int const, short volatile)` is an alias for `short const volatile`. -- *exit example*] Let `COND_RES(X,Y)` be `decltype(declval<bool>()? declval<X>() : declval<Y>())`. Given types `A` and `B`, let `X` be `remove_reference_t<A>`, let `Y` be `remove_reference_t<B>`, and let `COMMON_REF(A,B)` be:</span>
>
>> <span style="color:#009a9a">(3.1) -- If `A` and `B` are both lvalue reference types, `COMMON_REF(A,B)` is `COND_RES(COPYCV(X,Y) &, COPYCV(Y,X) &)`.
>> (3.2) -- If `A` and `B` are both rvalue reference types, let `R` be `COMMON_REF(X&, Y&)`. If `R` is a reference type, `COMMON_REF(A,B)` is `remove_reference_t<R> &&`. Otherwise, it is `R`.
>> (3.3) -- If `A` is an lvalue reference type and `B` is an rvalue reference type, then `COMMON_REF(A,B)` is `COMMON_REF(X&,Y const&)`.
>> (3.4) -- If `A` is an rvalue reference type and `B` is an lvalue reference type, then `COMMON_REF(A,B)` is `COMMON_REF(X const&,Y&)`.
>> (3.5) -- Otherwise, `COMMON_REF(A,B)` is `decay_t<COND_RES(CREF(A), CREF(B))>`.</span>
>
> <span style="color:#009a9a">If any of the types computed above are ill-formed, then `COMMON_REF(A,B)` is ill-formed.</span>
>
> <span style="color:#009a9a">4\. <span style="color:blue">[*Editorial note:* -- The following text in black is taken from the current C++17 draft --*end note*]</span></span> For the `common_type` trait applied to a parameter pack `T` of types, the member type shall be either defined or not present as follows:
>
>> (4.1) -- If `sizeof...(T)` is zero, there shall be no member `type`.
>> (4.2) -- If `sizeof...(T)` is one, let `T0` denote the sole type in the pack `T`. The member typedef type shall denote the same type as `decay_t<T0>`.
>> <span style="color:#009a9a">(4.3) -- If `sizeof...(T)` is two, let `T0` and `T1` denote the two types in the pack `T`, and let `X` and `Y` be `decay_<T0>` and `decay_t<T1>` respectively. Then if `X` and `T0` denote the same type and `Y` and `T1` denote the same type:</span>
>>> <span style="color:#009a9a">(4.2.1) -- If `COMMON_REF(T0, T1)` denotes a valid type, then the member typedef `type` denotes that type. Otherwise, there shall be no member `type`.
>>> (4.2.2) -- Otherwise, if `common_type_t<X, Y>` denotes a valid type, then the member typedef `type` denotes that type. Otherwise, there shall be no member `type`.</span>
>>
>> (4.4) -- If `sizeof...(T)` is greater than <span style="color:red; text-decoration:line-through">one</span><span style="color:#009a9a">two</span>, let `T1`, `T2`, and `R`, respectively, denote the first, second, and (pack of) remaining types comprising `T`. <span style="color:red; text-decoration:line-through">[ *Note:* `sizeof...(R)` may be zero. --*end note* ]</span> Let `C` <span style="color:red; text-decoration:line-through">denote the type, if any, of an unevaluated conditional expression (5.16) whose first operand is an arbitrary value of type bool, whose second operand is an xvalue of type T1, and whose third operand is an xvalue of type T2.</span><span style="color:#009a9a">be the type `common_type_t<T1,T2>`.</span> If there is such a type `C`, the member typedef `type` shall denote the same type, if any, as `common_type_t<C,R...>`. Otherwise, there shall be no member type.
>
> <span style="color:#009a9a">5\. For the `common_reference` trait applied to a parameter pack `T` of types, the member type shall be either defined or not present as follows:</span>
>
>> <span style="color:#009a9a">(5.1) -- If `sizeof...(T)` is zero, there shall be no member `type`.
>> (5.2) -- If `sizeof...(T)` is one, let `T0` denote the sole type in the pack `T`. The member typedef type shall denote the same type as `T0`.
>> (5.3) -- If `sizeof...(T)` is two, let `T0` and `T1` denote the two types in the pack `T`. Then if `COMMON_REF(T0,T1)` denotes a valid type and either `COMMON_REF(T0,T1)` is a reference type or `basic_common_reference_t<UNCVREF(T0),UNCVREF(T1),XREF(T0),XREF(T1)>` does not denote a valid type then:</span>
>>> <span style="color:#009a9a">(5.2.1) -- The member typedef `type` denotes `COMMON_REF(T0, T1)`.
>>> (5.2.2) -- Otherwise, if `basic_common_reference_t<UNCVREF(T0),UNCVREF(T1),XREF(T0),XREF(T1)>` denotes a valid type, then the member typedef `type` denotes that type. Otherwise, there shall be no member `type`.</span>
>>
>> <span style="color:#009a9a">(5.4) -- If `sizeof...(T)` is greater than two, let `T1`, `T2`, and `R`, respectively, denote the first, second, and (pack of) remaining types comprising `T`. Let `C` be the type `common_reference_t<T1,T2>`. If there is such a type `C`, the member typedef `type` shall denote the same type, if any, as `common_reference_t<C,R...>`. Otherwise, there shall be no member type.</span>

To [19.2] Core Language Concepts, add the following:

> **19.2.*X* Concept CommonReference [concepts.lib.corelang.commonref]**
>
> If `T` and `U` can both be explicitly converted or bound to a third type, `C`, then `T` and `U` share a *common reference type*, `C`. [ *Note:* `C` could be the same as `T`, or `U`, or it could be a different type. `C` may be a reference type. `C` may not be unique. --*end note* ] Informally, two types `T` and `U` model the `CommonReference` concept when the type alias `CommonReferenceType<T, U>` is well-formed and names a common reference type of `T` and `U`.
> 
> ```c++
> template <class T, class U>
> using CommonReferenceType = common_reference_t<T, U>;
> 
> template <class T, class U>
> concept bool CommonReference() {
>   return 
>     requires (T&& t, U&& u) {
>       typename CommonReferenceType<T, U>;
>       typename CommonReferenceType<U, T>;
>       requires Same<CommonReferenceType<T, U>,
>         CommonReferenceType<U, T>>;
>       CommonReferenceType<T, U>(forward<T>(t));
>       CommonReferenceType<T, U>(forward<U>(u));
>     };
> }
> ```


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
[9]: http://www.open-std.org/jtc1/sc22/wg21/docs/papers/2004/n1640.html "New Iterator Concepts"
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

Appendix 1: Reference implementations of `common_type` and `common_reference`
=========

```c++
#include <utility>
#include <type_traits>

using std::is_same;
using std::decay_t;
using std::declval;

template <class T>
using __t = typename T::type;

template <class T>
constexpr typename __t<T>::value_type __v = __t<T>::value;

template <class T, class... Args>
using __apply = typename T::template apply<Args...>;

template <class T, class U>
struct __compose {
  template <class V>
  using apply = __apply<T, __apply<U, V>>;
};

template <template <class...> class T, class... Args>
struct __defer { };

template <template <class...> class T, class... Args>
  requires requires { typename T<Args...>; }
struct __defer<T, Args...> {
  using type = T<Args...>;
};

template <template <class...> class T>
struct __q {
  template <class... U>
  using apply = __t<__defer<T, U...>>;
};

template <class T>
struct __id {
  using type = T;
};

template <class T>
using __cref =
  std::add_lvalue_reference_t<std::add_const_t<T>>;

template <class T>
using __uncvref = std::remove_cv_t<std::remove_reference_t<T>>;

template <class From, class To>
struct __copy_cv_ {
  using type = To;
};
template <class From, class To>
struct __copy_cv_<From const, To> {
  using type = To const;
};
template <class From, class To>
struct __copy_cv_<From volatile, To> {
  using type = To volatile;
};
template <class From, class To>
struct __copy_cv_<From const volatile, To> {
  using type = To const volatile;
};

template <class From, class To>
using __copy_cv = __t<__copy_cv_<From, To>>;

template <class T, class U>
struct __builtin_common_;

template <class T, class U>
using __cond_res =
  decltype(true ? declval<T>() : declval<U>());

template <class T, class U>
using __builtin_common_t =
  __apply<__builtin_common_<T, U>>;

template <class T, class U>
struct __builtin_common_ {
  template <class X = T, class Y = U>
  using apply = decay_t<__cond_res<__cref<X>, __cref<Y>>>;
};
template <class T, class U>
struct __builtin_common_<T &&, U &&> {
  template <class X = T, class Y = U,
    class R = __builtin_common_t<X &, Y &>>
  using apply =
    std::conditional_t<__v<std::is_reference<R>>,
      std::remove_reference_t<R> &&, R>;
};
template <class T, class U>
struct __builtin_common_<T &, U &> {
  template <class X = T, class Y = U>
  using apply =
    __cond_res<__copy_cv<Y, X> &, __copy_cv<X, Y> &>;
};
template <class T, class U>
struct __builtin_common_<T &, U &&>
  : __builtin_common_<T &, U const &> { };
template <class T, class U>
struct __builtin_common_<T &&, U &>
  : __builtin_common_<T const &, U &> { };

template <class T, class U>
using __builtin_common = __defer<__builtin_common_t, T, U>;

template <class ...Ts>
struct common_type { };

template <class... T>
using common_type_t = __t<common_type<T...>>;

template <class T>
struct common_type<T> : std::decay<T> { };

template <class T, class U>
struct common_type<T, U>
  : common_type<decay_t<T>, decay_t<U>> { };

template <class T, class U>
  requires __v<is_same<decay_t<T>, T>> &&
    __v<is_same<decay_t<U>, U>>
struct common_type<T, U> : __builtin_common<T, U> { };

template <class T, class U, class V, class... W>
struct common_type<T, U, V, W...> { };

template <class T, class U, class V, class... W>
  requires requires { typename common_type_t<T, U>; }
struct common_type<T, U, V, W...>
  : common_type<common_type_t<T, U>, V, W...> { };

namespace __qual {
  using __rref = __q<std::add_rvalue_reference_t>;
  using __lref = __q<std::add_lvalue_reference_t>;
  template <class>
  struct __xref { using type = __compose<__q<__t>, __q<__id>>; };
  template <class T>
  struct __xref<T&> { using type = __compose<__lref, __t<__xref<T>>>; };
  template <class T>
  struct __xref<T&&> { using type = __compose<__rref, __t<__xref<T>>>; };
  template <class T>
  struct __xref<const T> { using type = __q<std::add_const_t>; };
  template <class T>
  struct __xref<volatile T> { using type = __q<std::add_volatile_t>; };
  template <class T>
  struct __xref<const volatile T> { using type = __q<std::add_cv_t>; };
}

template <class T, class U, template <class> class TQual,
  template <class> class UQual>
struct basic_common_reference { };

template <class T, class U>
using __basic_common_reference_t =
  __t<basic_common_reference<__uncvref<T>, __uncvref<U>,
    __qual::__xref<T>::type::template apply,
    __qual::__xref<U>::type::template apply>>;

template <class... T>
struct common_reference { };

template <class... T>
using common_reference_t = __t<common_reference<T...>>;

template <class T>
struct common_reference<T> {
  using type = T;
};

template <class T, class U>
struct common_reference<T, U>
  : __defer<__basic_common_reference_t, T, U> { };

template <class T, class U>
  requires requires {typename __builtin_common_t<T, U>;} &&
    (__v<std::is_reference<__builtin_common_t<T, U>>> ||
    !requires {typename __basic_common_reference_t<T, U>;})
struct common_reference<T, U> : __builtin_common<T, U> { };

template <class T, class U, class V, class... W>
struct common_reference<T, U, V, W...> { };

template <class T, class U, class V, class... W>
  requires requires { typename common_reference_t<T, U>; }
struct common_reference<T, U, V, W...>
  : common_reference<common_reference_t<T, U>, V, W...> { };
```