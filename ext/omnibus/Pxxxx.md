---
pagetitle: Ranges TS Design Updates Omnibus
title: Ranges TS Design Updates Omnibus
...

# Introduction
This paper presents several design changes to N4560, the working paper for the Technical Specification for C++ Extensions for Ranges (the "Ranges TS"). Each change will be presented herein in a separate section that motivates the change and describes the design problem that change is meant to address. Technical specifications are relatively brief, since the complete specification and wording of all the changes is in N4569, a document that speculatively integrates these changes completely with the wording of N4560. This process is "unusual" in that the proposal authors failed to grok the process changes resulting from incorporating the evolving proposal into a TS working paper.

To throw some more fuel on the fires of confusion: the first design change presented herein (customization point redesign) *is* present in N4560. However, it was not included in the text of the proposal P0021R0 that was voted to become the initial text of the new TS working paper in Kona. The change was "backdoored" into the WP between P0021 and the publication of N4560 in the post-Kona mailing.

# Customization Points
Customization points are pain points, as the motivation of N4381 makes clear:

> The correct usage of customization points like `swap` is to first bring the standard `swap` into scope with a using declaration, and then to call `swap` unqualified:

> ```c++
> using std::swap;
> swap(a, b);
> ```

> One problem with this approach is that it is error-prone. It is all too easy to call (qualified) `std::swap` in a generic context, which is potentially wrong since it will fail to find any user-defined overloads.

> Another potential problem – and one that will likely become bigger with the advent of Concepts Lite – is the inability to centralize constraints-checking. Suppose that a future version of `std::begin` requires that its argument model a Range concept. Adding such a constraint would have no effect on code that uses `std::begin` idiomatically:

> ```c++
> using std::begin;
> begin(a);
> ```

> If the call to `begin` dispatches to a user-defined overload, then the constraint on `std::begin` has been bypassed.

> This paper aims to rectify these problems by recommending that future customization points be global function objects that do argument dependent lookup internally on the users’ behalf.

The range access customization points - those defined in [iterator.range], literally titled "Range Access" - should enforce "range-ness" via constraints. As constraints are pushed futher out into the "leaves" of the design, diagnostics occur closer to the point of the actual error. This design principle drives conceptification of the standard library, and it applies to customization points just as well as algorithms. Applying constraints to the customization points even enables catching errors in code that treats an argument as a range but does not properly constrain it to be so.

The same argument applies to the "Container access" customization points defined in [iterator.container] in the Working Paper. It's peculiar that these are in a distinct section from [iterator.range], since there seems to be nothing container-specific in their definitions. They seem to actually be range access customization points as well.

The Ranges TS has another customization point problem that N4381 does not cover: an implementation of the Ranges TS needs to co-exist alongside an implementation of the standard library. There's little benefit to providing customization points with strong semantic constraints if ADL can result in calls to the customization points of the same name in namespace `std`. For example, consider the definition of the single-type `Swappable` concept:

```c++
namespace std { namespace experimental { namespace ranges { inline namespace v1 {
  template <class T>
  concept bool Swappable() {
    return requires(T&& t, T&& u) {
      (void)swap(std::forward<T>(t), std::forward<T>(u));
    };
  }
}}}}
```

unqualified name lookup for the name `swap` could find the unconstrained `swap` in namespace `std` either directly - it's only a couple of hops up the namespace hierarchy - or via ADL if `std` is an associated namespace of `T` or `U`. If `std::swap` is unconstrained, the concept is "satisfied" for all types, and effectively useless. The Ranges TS deals with this problem by requiring changes to `std::swap`, a practice which has historically been forbidden for TSs. Applying similar constraints to all of the customization points defined in the TS by modifying the definitions in namespace `std` is an unsatisfactory solution, if not an altogether untenable.

We propose a combination of the approach used in N4381 with a "poison pill" technique to correct the lookup problem. Namely, we specify that unqualified lookup intended to find user-defined overloads via ADL must be performed in a context that includes a deleted overload matching the signature of the implementation in namespace `std`. E.g., for the customization point `begin`, the unqualified lookup for `begin(E)` (for some arbitrary expression `E`) is performed in a context that includes the declaration `void begin(const auto&) = delete;`. This "poison pill" has two distinct effects on overload resolution. First, the poison pill hides the declaration in namespace `std` from normal unqualified lookup, simply by having the same name. Second, for actual argument expressions for which the overload in namespace `std` is viable and found by ADL, the poisin pill will also be viable causing overload resolution to fail due to ambiguity. The net effect is to preclude the overload in namespace `std` from being chosen by overload resolution, or indeed any overload found by ADL that is not more specialized or more constrained than the poison pill.

All of this complicated customization point machinery is necessary to facilitate strong semantics through the addition of constraints. Let `E` be an arbitrary expression that denotes a range. The type of `begin(E)` must satisfy `Iterator`, so the customization point `begin` should constrain its return type to satisfy `Iterator`. Similarly, `end` should constrain its return type to satisfy `Sentinel<decltype(end(E)), decltype(begin(E))>()` since the iterator and sentinel types of a range must satisfy `Sentinel`. The constraints on `begin` and `end` should apply equally to the `const` and/or `reverse` variants thereof: `cbegin`, `cend`, `rbegin`, `rend`, `crbegin`, and `crend`. The size of a `SizedRange` always has a type the satisfies `Integral`, so the customization point `size` should should constrain its return type to satisfy `Integral`. `empty` should constrain its return type to be exactly `bool`. (Requiring the return type of `empty` to satisfy `Boolean` would also be a reasonable choice, but there seems to be no motivating reason for that relaxation at this time.)

## Technical Specifications
Add a new subsection to the end of [type.descriptions] to introduce *customization point object* as a term of art:

> 1 A *customization point object* is a function object (20.9) with a literal class type that interacts with user-defined types while enforcing semantic requirements on that interaction.

> 2 The type of a customization point object shall satisfy `Semiregular` (19.4.8).

> 3 All instances of a specific customization point object type shall be equal.

> 4 The type of a customization point object `T` shall satisfy `Function<const T, Args..>()` (19.5.2) when the types of `Args...` meet the requirements specified in that customization point object’s definition. Otherwise, `T` shall not have a function call operator that participates in overload resolution.

> 5 Each customization point object type constrains its return type to satisfy a particular concept.

> 6 The library defines several named customization point objects. In every translation unit where such a name is defined, it shall refer to the same instance of the customization point object.

> 7 [ Note: Many of the customization points objects in the library evaluate function call expressions with an unqualified name which results in a call to a user-defined function found by argument dependent name lookup (3.4.2). To preclude such an expression resulting in a call to unconstrained functions with the same name in namespace `std`, customization point objects specify that lookup for these expressions is performed in a context that includes deleted overloads matching the signatures of overloads defined in namespace `std`. When the deleted overloads are viable, user-defined overloads must be more specialized (14.5.6.2) or more constrained (Concepts TS [temp.constr.order]) to be used by a customization point object. ---end note]

In [concepts.lib.corelang.swappable], replace references to `swap` in the concept definitions with references to `ranges::swap`, to make it clear that the name is used qualified here, and remove the casts to `void`:

> ```c++
> template <class T>
> concept bool Swappable() {
>   return requires(T&& a, T&& b) {
>     ranges::swap(std::forward<T>(a), std::forward<T>(b));
>   };
> }
>
> template <class T, class U>
> concept bool Swappable() {
>   return Swappable<T>() &&
>     Swappable<U>() &&
>     Common<T, U>() &&
>     requires(T&& t, U&& u) {
>       ranges::swap(std::forward<T>(t), std::forward<U>(u));
>       ranges::swap(std::forward<U>(u), std::forward<T>(t));
>     };
> }
> ```

Strike the entire note in paragraph 1 that explains the purpose of the casts to `void`.

Change paragraph 3 to read:

> An object `t` is *swappable with* an object `u` if and only if `Swappable<T, U>()` is satisfied. `Swappable<T, U>()` is satisfied if and only if given distinct objects `tt` equal to `t` and `uu` equal to `u`, after evaluating either `ranges::swap(t, u)` or `ranges::swap(u, t)`, `tt` is equal to `u` and `uu` is equal to `t`.

Strike paragraph 4.

In [utility], strike paragraph 1 (the modifications to the synposis of the standard header `utility`).

In paragraph 2, the synopsis of the header `experimental/ranges/utility`, strike `using std::swap;` and insert the text:
```c++
namespace {
  constexpr unspecified swap = unspecified;
}
```
Replace the entire content of [utility.swap] with:

> The name `swap` denotes a customization point object (17.5.2.1.5). The effect of the expression `ranges::swap(E1, E2)` for some expressions `E1` and `E2` is equivalent to:

> * `(void)swap(E1, E2)`, with overload resolution performed in a context that includes the declarations:
> ```c++
> template <class T>
> void swap(T&, T&) = delete;
> template <class T, size_t N>
> void swap(T(&)[N], T(&)[N]) = delete;
> ```
> and does not include a declaration of `ranges::swap`. If the function selected by overload resolution does not exchange the values denoted by `E1` and `E2`, the program is ill-formed with no diagnostic required.

> * Otherwise, `(void)swap_ranges(E1, E2)` if `E1` and `E2` are lvalues of array types (3.9.2) of equal extent and `ranges::swap(*(E1), *(E2))` is a valid expression, except that `noexcept(ranges::swap(E1, E2))` is equal to `noexcept(ranges::swap(*(E1), *(E2)))`.

> * Otherwise, if `E1` and `E2` are lvalues of the same type `T` which meets the syntactic requirements of `MoveConstructible<T>()` and `Assignable<T&, T&&>()`, exchanges the denoted values. `ranges::swap(E1, E2)` is a constant expression if the constructor selected by overload resolution for `T{std::move(E1)}` is a `constexpr` constructor and the expression `E1 = std::move(E2)` can appear in a `constexpr` function. `noexcept(ranges::swap(E1, E2))` is equal to `is_nothrow_move_constructible<T>::value && is_nothrow_move_assignable<T>::value`. If either `MoveConstructible<T>()` or `Assignable<T&, T&&>()` is not satisfied, the program is ill-formed with no diagnostic required. `ranges::swap(E1, E2)` has type `void`.

> * Otherwise, `ranges::swap(E1, E2)` is ill-formed.

> Remark: Whenever `ranges::swap(E1, E2)` is a valid expression, it exchanges the values denoted by `E1` and `E2` and has type `void`.

Note that This formulation intentionally allows swapping arrays with identical extent and differing element types, but only when swapping the element types is well-defined. Swapping arrays of `int` and `double` continues to be ill-formed, but arrays of `T` and `U` are swappable whenever `T&` and `U&` are swappable.

In [taggedtup.tagged], add to the synopsis of class template `tagged` the declaration:

> ```c++
> friend void swap(tagged&, tagged&) noexcept(see below )
> requires Swappable<Base&>();
> ```

and remove the non-member `swap` function declaration. Add paragraphs specifying the `swap` friend:

> ```c++
> friend void swap(tagged& lhs, tagged& rhs) noexcept(see below )
> requires Swappable<Base&>();
> ```

> 23 Remarks: The expression in the `noexcept` is equivalent to `noexcept(lhs.swap(rhs))`

> 24 Effects: `lhs.swap(rhs)`.

> 25 Throws: Nothing unless the call to `lhs.swap(rhs)` throws.

Strike the section [tagged.special] that describes the non-member `swap` overload.

From [iterator.synopsis], strike the declarations of the "Range access" customization points:

> ```c++
> using std::begin;
> using std::end;
> template <class>
>   concept bool _Auto = true;
> template <_Auto C> constexpr auto cbegin(const C& c) noexcept(noexcept(begin(c)))
>   -> decltype(begin(c));
> template <_Auto C> constexpr auto cend(const C& c) noexcept(noexcept(end(c)))
>   -> decltype(end(c));
> template <_Auto C> auto rbegin(C& c) -> decltype(c.rbegin());
> template <_Auto C> auto rbegin(const C& c) -> decltype(c.rbegin());
> template <_Auto C> auto rend(C& c) -> decltype(c.rend());
> template <_Auto C> auto rend(const C& c) -> decltype(c.rend());
> template <_Auto T, size_t N> reverse_iterator<T*> rbegin(T (&array)[N]);
> template <_Auto T, size_t N> reverse_iterator<T*> rend(T (&array)[N]);
> template <_Auto E> reverse_iterator<const E*> rbegin(initializer_list<E> il);
> template <_Auto E> reverse_iterator<const E*> rend(initializer_list<E> il);
> template <_Auto C> auto crbegin(const C& c) -> decltype(ranges_v1::rbegin(c));
> template <_Auto C> auto crend(const C& c) -> decltype(ranges_v1::rend(c));
> template <class C> auto size(const C& c) -> decltype(c.size());
> template <class T, size_t N> constexpr size_t beginsize(T (&array)[N]) noexcept;
> template <class E> size_t size(initializer_list<E> il) noexcept;
> ```

and replace with:

> ```c++
> namespace {
>   constexpr unspecified begin = unspecified;
>   constexpr unspecified end = unspecified;
>   constexpr unspecified cbegin = unspecified;
>   constexpr unspecified cend = unspecified;
>   constexpr unspecified rbegin = unspecified;
>   constexpr unspecified rend = unspecified;
>   constexpr unspecified crbegin = unspecified;
>   constexpr unspecified crend = unspecified;
> }
> ```

and under the `// 24.11, Range primitives:` comment:

> ```c++
> namespace {
>   constexpr unspecified size = unspecified;
>   constexpr unspecified empty = unspecified;
>   constexpr unspecified data = unspecified;
>   constexpr unspecified cdata = unspecified;
> }
> ```

In [ranges.range], define `iterator_t`, `sentinel_t`, and concept `Range` as:

> ```c++
> template <class T>
> using iterator_t = decltype(ranges::begin(declval<T&>()));
>
> template <class T>
> using sentinel_t = decltype(ranges::end(declval<T&>()));
>
> template <class T>
> concept bool Range() {
>   return requires {
>     typename sentinel_t<T>;
>   };
> }
> ```

Strike paragraph 2.1.

In [ranges.sized], replace references to `size` with `ranges::size`, again to make it clear that no ADL happens in the pertinent expressions. Strike paragraph 2.1.

Strike all content from [iterator.range]. Add a new subsection [iterator.range.begin]:

> 1 The name `begin` denotes a customization point object (17.5.2.1.5). The effect of the expression `ranges::begin(E)` for some expression `E` is equivalent to:

> * `ranges::begin((const T&)(E))` if `E` is an rvalue of type `T`. This usage is deprecated. [Note: This deprecated usage exists so that `ranges::begin(E)` behaves similarly to `std::begin(E)` as defined in ISO/IEC 14882 when `E` is an rvalue. ---end note ]

> * Otherwise, `(E) + 0` if `E` has array type (3.9.2).

> * Otherwise, `DECAY_COPY((E).begin())` if its type `I` meets the syntactic requirements of `Iterator<I>()`. If `Iterator` is not satisfied, the program is ill-formed with no diagnostic required.

> * Otherwise, `DECAY_COPY(begin(E))` if its type `I` meets the syntactic requirements of `Iterator<I>()` with overload resolution performed in a context that includes the declaration `void begin(auto&) = delete;` and does not include a declaration of `ranges::begin`. If `Iterator` is not satisfied, the program is ill-formed with no diagnostic required.

> * Otherwise, `ranges::begin(E)` is ill-formed.

> 2 Remark: Whenever `ranges::begin(E)` is a valid expression, the type of `ranges::begin(E)` satisfies `Iterator`.

and a new subsection [iterator.range.end]:

> 1 The name `end` denotes a customization point object (17.5.2.1.5). The effect of the expression `ranges::end(E)` for some expression `E` is equivalent to:

> * `ranges::end((const T&)(E))` if `E` is an rvalue of type `T`. This usage is deprecated. [Note: This deprecated usage exists so that `ranges::end(E)` behaves similarly to `std::end(E)` as defined in ISO/IEC 14882 when `E` is an rvalue. ---end note ]

> * Otherwise, `(E) + extent<T>::value` if `E` has array type (3.9.2) `T`.

> * Otherwise, `DECAY_COPY((E).end())` if its type `S` meets the syntactic requirements of `Sentinel<S, decltype(ranges::begin(E)>()`. If `Sentinel` is not satisfied, the program is ill-formed with no diagnostic
required.

> * Otherwise, `DECAY_COPY(end(E))` if its type `S` meets the syntactic requirements of `Sentinel<S, decltype(ranges::begin(E))>()` with overload resolution performed in a context that includes the declaration `void end(auto&) = delete;` and does not include a declaration of `ranges::end`. If `Sentinel` is not satisfied, the program is ill-formed with no diagnostic required.

> * Otherwise, `ranges::end(E)` is ill-formed.

> 2 Remark: Whenever `ranges::end(E)` is a valid expression, the types of `ranges::end(E)` and `ranges::begin(E)` satisfy `Sentinel`.

and a new subsection [iterator.range.cbegin]:

> 1 The name `cbegin` denotes a customization point object (17.5.2.1.5). The effect of the expression `ranges::cbegin(E)` for some expression `E` of type `T` is equivalent to `ranges::begin((const T&)(E))`.

> 2 Use of `ranges::cbegin(E)` with rvalue `E` is deprecated. [ Note: This deprecated usage exists so that `ranges::cbegin(E)` behaves similarly to `std::cbegin(E)` as defined in ISO/IEC 14882 when `E` is an rvalue. ---end note ]

> 3 [ Note: Whenever `ranges::cbegin(E)` is a valid expression, the type of `ranges::cbegin(E)` satisfies `Iterator`. ---end note ]

and a new subsection [iterator.range.cend]:

> 1 The name `cend` denotes a customization point object (17.5.2.1.5). The effect of the expression `ranges::cend(E)` for some expression `E` of type `T` is equivalent to `ranges::end((const T&)(E))`.

> 2 Use of `ranges::cend(E)` with rvalue `E` is deprecated. [ Note: This deprecated usage exists so that `ranges::cend(E)` behaves similarly to `std::cend(E)` as defined in ISO/IEC 14882 when `E` is an rvalue. ---end note ]

> 3 [ Note: Whenever `ranges::cend(E)` is a valid expression, the types of `ranges::cend(E)` and `ranges::cbegin(E)` satisfy `Sentinel`. ---end note ]

and a new subsection [iterator.range.rbegin]:

> 1 The name `rbegin` denotes a customization point object (17.5.2.1.5). The effect of the expression `ranges::rbegin(E)` for some expression `E` is equivalent to:

> * `ranges::rbegin((const T&)(E))` if `E` is an rvalue of type `T`. This usage is deprecated. [Note: This deprecated usage exists so that `ranges::rbegin(E)` behaves similarly to `std::rbegin(E)` as defined in ISO/IEC 14882 when `E` is an rvalue. ---end note ]

> * Otherwise, `make_reverse_iterator((E) + extent<T>::value)` if `E` has array type (3.9.2) `T`.

> * Otherwise, `DECAY_COPY((E).rbegin())` if its type `I` meets the syntactic requirements of `Iterator<I>()`. If `Iterator` is not satisfied, the program is ill-formed with no diagnostic required.

> * Otherwise, `make_reverse_iterator(ranges::end(E))` if both `ranges::begin(E)` and `ranges::end(E)` have the same type `I` which meets the syntactic requirements of `BidirectionalIterator<I>()` (24.2.16). If `BidirectionalIterator` is not satisfied, the program is ill-formed with no diagnostic required.

> * Otherwise, `ranges::rbegin(E)` is ill-formed.

> 2 Remark: Whenever `ranges::rbegin(E)` is a valid expression, the type of `ranges::rbegin(E)` satisfies `Iterator`.

and a new subsection [iterator.range.rend]:

> 1 The name `rend` denotes a customization point object (17.5.2.1.5). The effect of the expression `ranges::rend(E)` for some expression `E` is equivalent to:

> * `ranges::rend((const T&)(E))` if `E` is an rvalue of type `T`. This usage is deprecated. [Note: This deprecated usage exists so that `ranges::rend(E)` behaves similarly to `std::rend(E)` as defined in ISO/IEC 14882 when `E` is an rvalue. ---end note ]

> * Otherwise, `make_reverse_iterator((E) + 0)` if `E` has array type (3.9.2).

> * Otherwise, `DECAY_COPY((E).rend())` if its type `S` meets the syntactic requirements of `Sentinel<S, decltype(ranges::rbegin(E))>()`. If `Sentinel` is not satisfied, the program is ill-formed with no diagnostic required.

> * Otherwise, `make_reverse_iterator(ranges::begin(E))` if both `ranges::begin(E)` and `ranges::end(E)` have the same type `I` which meets the syntactic requirements of `BidirectionalIterator<I>()` (24.2.16). If `BidirectionalIterator` is not satisfied, the program is ill-formed with no diagnostic required.

> * Otherwise, `ranges::rend(E)` is ill-formed.

> 2 Remark: Whenever `ranges::rend(E)` is a valid expression, the types of `ranges::rend(E)` and `ranges::rbegin(E)` satisfy `Sentinel`.

and a new subsection [iterator.range.crbegin]:

> 1 The name `crbegin` denotes a customization point object (17.5.2.1.5). The effect of the expression `ranges::crbegin(E)` for some expression `E` of type `T` is equivalent to `ranges::rbegin((const T&)(E))`.

> 2 Use of `ranges::crbegin(E)` with rvalue `E` is deprecated. [ Note: This deprecated usage exists so that `ranges::crbegin(E)` behaves similarly to `std::crbegin(E)` as defined in ISO/IEC 14882 when `E` is an rvalue. ---end note ]

> 3 [ Note: Whenever `ranges::crbegin(E)` is a valid expression, the type of `ranges::crbegin(E)` satisfies `Iterator`. ---end note ]

and a new subsection [iterator.range.crend]:

> 1 The name `crend` denotes a customization point object (17.5.2.1.5). The effect of the expression `ranges::crend(E)` for some expression `E` of type `T` is equivalent to `ranges::rend((const T&)(E))`.

> 2 Use of `ranges::crend(E)` with rvalue `E` is deprecated. [ Note: This deprecated usage exists so that `ranges::crend(E)` behaves similarly to `std::crend(E)` as defined in ISO/IEC 14882 when `E` is an rvalue. ---end note ]

> 3 [ Note: Whenever `ranges::crend(E)` is a valid expression, the types of `ranges::crend(E)` and `ranges::crbegin(E)` satisfy `Sentinel`. ---end note ]

In [range.primitives], remove paragraphs 1-3 that define overloads of `size`. Add a new subsection [range.primitives.size]:

> 1 The name `size` denotes a customization point object (17.5.2.1.5). The effect of the expression `ranges::size(E)` for some expression `E` with type `T` is equivalent to:

> * `extent<T>::value` if `T` is an array type (3.9.2).

> * Otherwise, `DECAY_COPY(((const T&)(E)).size())` if its type `I` satisfies `Integral<I>()` and `disable_sized_range<T>` (24.9.2.3) is `false`.

> * Otherwise, `DECAY_COPY(size((const T&)(E)))` if its type `I` satisfies `Integral<I>()` with overload resolution performed in a context that includes the declaration `void size(const auto&) = delete;` and does not include a declaration of `ranges::size`, and `disable_sized_range<T>` is `false`.

> * Otherwise, `DECAY_COPY(ranges::cend(E) - ranges::cbegin(E))`, except that `E` is only evaluated once, if the types `I` and `S` of `ranges::cbegin(E)` and `ranges::cend(E)` meet the syntactic requirements of `SizedSentinel<S, I>()` (24.2.9), and `ForwardIterator<I>()`. If `SizedSentinel` and `ForwardIterator` are not satisfied, the program is ill-formed with no diagnostic required.

> * Otherwise, `ranges::size(E)` is ill-formed.

> 2 [ Note: Whenever `ranges::size(E)` is a valid expression, the type of `ranges::size(E)` satisfies `Integral`. ---end note ]

and new subsection [range.primitives.empty]:

> 1 The name `empty` denotes a customization point object (17.5.2.1.5). The effect of the expression `ranges::empty(E)` for some expression `E` is equivalent to:

> * `bool((E).empty())` if it is valid.

> * Otherwise, `ranges::size(E) != 0` if it is valid.

> * Otherwise, `bool(ranges::begin(E) != ranges::end(E))`, except that `E` is only evaluated once, if the type of `ranges::begin(E)` satisfies `ForwardIterator`.

> * Otherwise, `ranges::empty(E)` is ill-formed.

> 2 Remark: Whenever `ranges::empty(E)` is a valid expression, it has type `bool`.

and a new subsection [range.primitives.data]:

> 1 The name `data` denotes a customization point object (17.5.2.1.5). The effect of the expression `ranges::data(E)` for some expression `E` is equivalent to:

> * `ranges::data((const T&)(E))` if `E` is an rvalue of type `T`. This usage is deprecated. [Note: This deprecated usage exists so that `ranges::data(E)` behaves similarly to `std::data(E)` as defined in the C++ Working Paper when `E` is an rvalue. ---end note ]

> * Otherwise, `DECAY_COPY((E).data())` if it has pointer to object type.

> * Otherwise, `ranges::begin(E)` if it has pointer to object type.

> * Otherwise, `ranges::data(E)` is ill-formed.

> 2 Remark: Whenever `ranges::data(E)` is a valid expression, it has pointer to object type.

and a new subsection [range.primitives.cdata]:

> 1 The name `cdata` denotes a customization point object (17.5.2.1.5). The effect of the expression `ranges::cdata(E)` for some expression `E` of type `T` is equivalent to `ranges::data((const T&)(E))`.

> 2 Use of `ranges::cdata(E)` with rvalue `E` is deprecated. [ Note: This deprecated usage exists so that `ranges::cdata(E)` has behavior consistent with `ranges::data(E)` when `E` is an rvalue. ---end note ]

> 3 [ Note: Whenever `ranges::cdata(E)` is a valid expression, it has pointer to object type. ---end note ]

Algorithms
==========
There are several small issues that apply to many or all of the algorithm specifications that must be addressed by the addition of requirements in [algorithms.general]. First, an ambiguity exists for algorithms with both a two-range overload and a range + iterator overload, e.g.:

```c++
template <Range R1, Range R2>
void foo(R1&&, R2&&);

template <Range R, Iterator I>
void foo(R&&, I);
```
overload resolution is ambiguous when passing an array as the second parameter of `foo`, since arrays decay to pointers. Resolving this ambiguity is not complicated, but would muddy the algorithm declarations. Instead of altering the declarations, we require implementors to resolve the ambiguity in a new paragraph at the end of [algorithms.general]:

> 16 Some algorithms declare both an overload that takes a `Range` and an `Iterator`, and an overload that takes two `Range` parameters. Since an array type (3.9.2) both satisfies `Range` and decays to a pointer (4.2) which satisfies `Iterator`, such overloads are ambiguous when an array is passed as the second argument. Implementations shall provide a mechanism to resolve this ambiguity in favor of the overload that takes two ranges.

The Ranges TS adds many "range" algorithm overloads that are specified to forward to "iterator" overloads. Implementing such a range overload by directly forwarding would create inefficiencies due to introducing additional copies or moves of the arguments, e.g. `find_if` could be implemented as:

```c++
template<InputRange Rng, class Proj = identity,
  IndirectCallablePredicate<Projected<IteratorType<Rng>, Proj>> Pred>
safe_iterator_t<Rng>
  find_if(Rng&& rng, Pred pred, Proj proj = Proj{}) {
    return find_if(begin(rng), end(rng), std::move(pred), std::move(proj));
  }
```

which introduces moves of `pred` and `proj` that could be eliminated by perfect forwarding:

```c++
template<InputRange Rng, class Proj, class Pred>
  requires IndirectCallablePredicate<decay_t<Pred>, Projected<iterator_t<Rng>, decay_t<Proj>>>()
safe_iterator_t<Rng>
  find_if(Rng&& rng, Pred&& pred, Proj&& proj) {
    return find_if(begin(rng), end(rng), std::forward<Pred>(pred), std::forward<Proj>(proj));
  }

template<InputRange Rng, class Pred>
  requires IndirectCallablePredicate<decay_t<Pred>, iterator_t<Rng>>()
safe_iterator_t<Rng>
  find_if(Rng&& rng, Pred&& pred) {
    return find_if(begin(rng), end(rng), std::forward<Pred>(pred));
  }
```

except that forwarding arguments in this manner is visible to users, and so not permitted under the as-if rule: the forwarding implementation sequences the calls to begin and end *before* the actual arguments to `pred` and `proj` are copied or moved, whereas the non-forwarding implementation sequences those class *after* the argument expressions to `pred` and `proj` are copied/moved into their argument objects. To provide increased implementor freedom to perform such optimizations, and to implement the iterator/range disambiguation for arrays discussed above, we propose that the number and order of template parameters to algorithms be unspecified, and that the creation of the actual argument objects from the argument expressions be decoupled from the algorithm invocation. Such a decoupling would allow an algorithm implementation to omit or delay creation of its nominal argument objects from the actual argument expressions. These proposals can each be specified with new paragraphs in [algorithm.general]:

> 17 The number and order of template parameters for algorithm declarations is unspecified, except where explicitly stated otherwise.

> 18 Despite that the algorithm declarations nominally accept parameters by value, it is unspecified when and if the argument expressions are used to initialize the actual parameters except that any such initialization shall be sequenced before (1.9) the algorithm returns. [ Note: The behavior of a program that modifies the values of the actual argument expressions is consequently undefined unless the algorithm return happens before (1.10) any such modifications. ---end note ]

These changes make both of the example implementations of `find_if` above conforming.

Function Objects
================
The resolution of LWG2450 ensures that the transparent specialiations of `greater`, `less`, `greater_equal`, and `less_equal` use the same ordering as the specializations for pointers when applied to pointer types. The function objects in the Ranges TS should behave similarly. Further the constraints on the comparison function objects seem to put the cart before the horse. `equal_to`, for example, is specified in the Ranges TS as:

```c++
template <class T = void>
  requires EqualityComparable<T>() || Same<T, void>()
struct equal_to;
```
which forbids specialization of `equal_to` for types `T` that do not satisfy `EqualityComparable<T>() || Same<T, void>()`, i.e., are not `void` or `EqualityComparable`. It seems that non-`EqualityComparable` types are *exactly* the types for which a user might want to specialize `equal_to`. For types that *are* `EqualityComparable`, the default implementation will work correctly with no need for specialization. It would seem that the `EqualityComparable` requirement on `equal_to` - and the similar requirements for the other comparision function objects - is actually a requirement for the default implementation that should not be applied to the base template.

Both of these issues can be corrected by respecifying the function objects. In [function.objects]/2, the synopsis of `<experimental/ranges/functional>`, replace the declarations of the comparison function objects with:

```c++
// 20.9.5, comparisons:
template <class T = void>
struct equal_to; // not defined
template<EqualityComparable T> struct equal_to<T>;

template <class T = void>
struct not_equal_to; // not defined
template<EqualityComparable T> struct not_equal_to<T>;

template <class T = void>
struct greater; // not defined
template<StrictTotallyOrdered T> struct greater<T>;
template<class T> struct greater<T*>;

template <class T = void>
struct less; // not defined
template<StrictTotallyOrdered T> struct less<T>;
template<class T> struct less<T*>;

template <class T = void>
struct greater_equal; // not defined
template<StrictTotallyOrdered T> struct greater_equal<T>;
template<class T> struct greater_equal<T*>;

template <class T = void>
struct less_equal; // not defined
template<StrictTotallyOrdered T> struct less_equal<T>;
template<class T> struct less_equal<T*>;

template<> struct equal_to<void>;
template<> struct not_equal_to<void>;
template<> struct greater<void>;
template<> struct less<void>;
template<> struct greater_equal<void>;
template<> struct less_equal<void>;
```
and replace the entire content of [comparisons] with:

> 1 The library provides basic function object classes for all of the comparison operators in the language (5.9, 5.10).

> ```c++
> template <EqualityComparable T>
> struct equal_to<T> {
>   constexpr bool operator()(const T& x, const T& y) const;
> };
> ```

> 2 `operator()` returns `x == y`.

> ```c++
> template <EqualityComparable T>
> struct not_equal_to<T> {
>   constexpr bool operator()(const T& x, const T& y) const;
> };
> ```

> 3 `operator()` returns `x != y`.

> ```c++
> template <StrictTotallyOrdered T>
> struct greater<T> {
>   constexpr bool operator()(const T& x, const T& y) const;
> };
> template <class T>
> struct greater<T*> {
>   constexpr bool operator()(T* x, T* y) const;
> };
> ```

> 4 `operator()` returns `x > y`.

> ```c++
> template <StrictTotallyOrdered T>
> struct less<T> {
>   constexpr bool operator()(const T& x, const T& y) const;
> };
> template <class T>
> struct less<T*> {
>   constexpr bool operator()(T* x, T* y) const;
> };
> ```

> 5 `operator()` returns `x < y`.

> ```c++
> template <StrictTotallyOrdered T>
> struct greater_equal<T> {
>   constexpr bool operator()(const T& x, const T& y) const;
> };
> template <class T>
> struct greater_equal<T*> {
>   constexpr bool operator()(T* x, T* y) const;
> };
> ```

> 6 `operator()` returns `x >= y`.

> ```c++
> template <StrictTotallyOrdered T>
> struct less_equal<T> {
>   constexpr bool operator()(const T& x, const T& y) const;
> };
> template <class T>
> struct less_equal<T*> {
>   constexpr bool operator()(T* x, T* y) const;
> };
> ```

> 7 `operator()` returns `x <= y`.

> ```c++
> template <> struct equal_to<void> {
>   template <class T, class U>
>     requires EqualityComparable<T, U>()
>   constexpr auto operator()(T&& t, U&& u) const
>     -> decltype(std::forward<T>(t) == std::forward<U>(u));
>
>   typedef unspecified is_transparent;
> };
> ```

> 8 `operator()` returns `std::forward<T>(t) == std::forward<U>(u)`.

> ```c++
> template <> struct not_equal_to<void> {
>   template <class T, class U>
>     requires EqualityComparable<T, U>()
>   constexpr auto operator()(T&& t, U&& u) const
>     -> decltype(std::forward<T>(t) != std::forward<U>(u));
>
>   typedef unspecified is_transparent;
> };
> ```

> 9 `operator()` returns `std::forward<T>(t) != std::forward<U>(u)`.

> ```c++
> template <> struct greater<void> {
>   template <class T, class U>
>     requires StrictTotallyOrdered<T, U>()
>       || BUILTIN_PTR_CMP(T, >, U) // exposition only, see below
>   constexpr auto operator()(T&& t, U&& u) const
>     -> decltype(std::forward<T>(t) > std::forward<U>(u));
>
>   typedef unspecified is_transparent;
> };
> ```

> 10 `operator()` returns `std::forward<T>(t) > std::forward<U>(u)`.

> ```c++
> template <> struct less<void> {
>   template <class T, class U>
>     requires StrictTotallyOrdered<T, U>()
>       || BUILTIN_PTR_CMP(T, <, U) // exposition only, see below
>   constexpr auto operator()(T&& t, U&& u) const
>     -> decltype(std::forward<T>(t) < std::forward<U>(u));
>
>   typedef unspecified is_transparent;
> };
> ```

> 11 `operator()` returns `std::forward<T>(t) < std::forward<U>(u)`.

> ```c++
> template <> struct greater_equal<void> {
>   template <class T, class U>
>     requires StrictTotallyOrdered<T, U>()
>       || BUILTIN_PTR_CMP(T, >=, U) // exposition only, see below
>   constexpr auto operator()(T&& t, U&& u) const
>     -> decltype(std::forward<T>(t) >= std::forward<U>(u));
>
>   typedef unspecified is_transparent;
> };
> ```

> 12 `operator()` returns `std::forward<T>(t) >= std::forward<U>(u)`.

> ```c++
> template <> struct less_equal<void> {
>   template <class T, class U>
>     requires StrictTotallyOrdered<T, U>()
>       || BUILTIN_PTR_CMP(T, <=, U) // exposition only, see below
>   constexpr auto operator()(T&& t, U&& u) const
>     -> decltype(std::forward<T>(t) <= std::forward<U>(u));
>
>   typedef unspecified is_transparent;
> };
> ```

> 13 `operator()` returns `std::forward<T>(t) <= std::forward<U>(u)`.

> 14 For templates `greater`, `less`, `greater_equal`, and `less_equal`, the specializations for any pointer type yield a total order, even if the built-in operators `<`, `>`, `<=`, `>=` do not. [Editor’s note: The following sentence is taken from the proposed resolution of LWG #2450.] For template specializations `greater<void>`, `less<void>`, `greater_equal<void>`, and `less_equal<void>`, if the call operator calls a built-in operator comparing pointers, the call operator yields a total order.

> 15 If `X` is an lvalue reference type, let `x` be an lvalue of type `X`, or an rvalue otherwise. If `Y` is an lvalue reference type, let `y` be an lvalue of type `Y`, or an rvalue otherwise. Given a relational operator `OP`, `BUILTIN_PTR_CMP(X, OP, Y)` shall be true if an only if `OP` in the expression `(X&&)x OP (Y&&)y` resolves to a built-in operator comparing pointers.

> 16 All specializations of `equal_to`, `not_equal_to`, `greater`, `less`, `greater_equal`, and `less_equal` shall satisfy `DefaultConstructible` (19.4.3).

> 17 For all object types `T` for which there exists a specialization `less<T>`, the instantiation `less<T>` shall satisfy `StrictWeakOrder<less<T>, T>()` (19.5.6).

> 18 For all object types `T` for which there exists a specialization `equal_to<T>`, the instantiation `equal_to<T>` shall satisfy `Relation<equal_to<T>, T>()` (19.5.5), and `equal_to<T>` shall induce an equivalence relation on its arguments.

> 19 For any (possibly const) lvalues `x` and `y` of types `T`, the following shall be true

> * If there exists a specialization `not_equal_to<T>`, then the instantiation `not_equal_to<T>` shall satisfy `Relation<not_equal_to<T>, T>()`, and `not_equal_to<T>{}(x, y)` shall equal `!equal_to<T>{}(x, y)`.

> * If there exists a specialization `greater<T>`, then the instantiation `greater<T>` shall satisfy `StrictWeakOrder<greater<T>, T>()`, and `greater<T>{}(x, y)` shall equal `less<T>{}(y, x)`.

> * If there exists a specialization `greater_equal<T>`, then the instantiation `greater_equal<T>` shall satisfy `Relation<greater_equal<T>, T>()`, and `greater_equal<T>{}(x, y)` shall equal `!less<T>{}(x, y)`.

> * If there exists a specialization `less_equal<T>`, then the instantiation `less_equal<T>` shall satisfy `Relation<greater_equal<T>, T>()`, and `less_equal<T>{}(x, y)` shall equal `!less<T>{}(y, x)`.

> 20 For any pointer type `T`, the specializations `equal_to<T>`, `not_equal_to<T>`, `greater<T>`, `less<T>`, `greater_equal<T>`, `less_equal<T>` shall yield the same results as `equal_to<void*>`, `not_equal_to<void*>`, `greater<void*>`, `less<void*>`, `greater_equal<void*>`, `less_equal<void*>`, respectively.


Function -> Callable
====================
A thorough examination of the Ranges TS shows that the `Function` concept family (`Function`, `RegularFunction`, `Predicate`, `Relation`, and `StrictWeakOrder`; described in [concepts.lib.functions]) is only used in the definition of the `IndirectCallableXXX` concept family. All predicates and projections used by the algorithms are actually *callables*: object types that are evaluated via the `INVOKE` metasyntactic function. We propose to greatly simplify the specification by importing `std::invoke` from the C++ WP and replacing the `Function` concept family with a similar family of `Callable` concepts. This enables the replacement of all declarations of the form `Function<FunctionType<F>, Args...>` with `Callable<F, Args...>`, and elimination of the `as_function` machinery.

Rename section [concepts.lib.functions] to [concepts.lib.callables]; similarly rename all subsections of the form [concepts.lib.functions.Xfunction] to [concepts.lib.callables.Xcallable]. Replace the content of the section now named [concepts.lib.callables.callable]:

> 1 The `Callable` concept specifies a relationship between a callable type (20.9.1) `F` and a set of argument types `Args...` which can be evaluated by the library function `invoke` (20.9.3).

> ```c++
> template <class F, class...Args>
> concept bool Callable() {
>   return CopyConstructible<F>() &&
>     requires (F f, Args&&...args) {
>       invoke(f, std::forward<Args>(args)...); // not required to be equality preserving
>     };
> }
> ```

> 2 [ Note: Since the `invoke` function call expression is not required to be equality-preserving (19.1.1), a function that generates random numbers may satisfy `Callable`. ---end note ]

and the section [concepts.lib.callables.regularcallable]:

> ```c++
> concept bool RegularCallable() {
>   return Callable<F, Args...>();
> }
> ```

> 1 The `invoke` function call expression shall be equality-preserving (19.1.1). [ Note: This requirement supersedes the annotation in the definition of `Callable`. ---end note ]

> 2 [ Note: A random number generator does not satisfy `RegularCallable`. ---end note ]

> 3 [ Note: The distinction between `Callable` and `RegularCallable` is purely semantic. ---end note ]

in section [concepts.lib.callables.predicate], replace references to `RegularFunction` with `RegularCallable`. In [function.objects], add to the synopsis of header `<experimental/ranges/functional>` the declaration:

> ```c++
> template <class F, class... Args>
> result_of_t<F&&(Args&&...)> invoke(F&& f, Args&&... args);
> ```

Insert a new subsection [func.invoke] under [function.objects]:

> ```c++
> result_of_t<F&&(Args&&...)> invoke(F&& f, Args&&... args);
> ```
> 1 Effects: Equivalent to `INVOKE(std::forward<F>(f), std::forward<Args>(args)...)` (20.9.2).

Remove the section [indirectcallables.functiontype]. In [indirectcallables.indirectfunc], replace the concept definitions with:

> ```c++
> template <class F, class...Is>
> concept bool IndirectCallable() {
>   return (Readable<Is>() && ...) &&
>     Callable<F, value_type_t<Is>...>();
> }
>
> template <class F, class...Is>
> concept bool IndirectRegularCallable() {
>   return (Readable<Is>() && ...) &&
>     RegularCallable<F, value_type_t<Is>...>();
> }
>
> template <class F, class...Is>
> concept bool IndirectCallablePredicate() {
>   return (Readable<Is>() && ...) &&
>     Predicate<F, value_type_t<Is>...>();
> }
>
> template <class F, class I1, class I2 = I1>
> concept bool IndirectCallableRelation() {
>   return Readable<I1>() && Readable<I2>() &&
>     Relation<F, value_type_t<I1>, value_type_t<I2>>();
> }
>
> template <class F, class I1, class I2 = I1>
> concept bool IndirectCallableStrictWeakOrder() {
>   return Readable<I1>() && Readable<I2>() &&
>     StrictWeakOrder<F, value_type_t<I1>, value_type_t<I2>>();
> }
>
> template <class> struct indirect_result_of { };
> template <class F, class...Is>
> requires IndirectCallable<remove_reference_t<F>, Is...>()
> struct indirect_result_of<F(Is...)> :
>   result_of<F(value_type_t<Is>...)> { };
> template <class F>
> using indirect_result_of_t = typename indirect_result_of<F>::type;
> ```

Replace the definition of `projected` in [projected] with:

> ```c++
> template <Readable I, IndirectRegularCallable<I> Proj>
>   requires RegularCallable<Proj, reference_t<I>>()
> struct projected {
>   using value_type = decay_t<indirect_result_of_t<Proj&(I)>>;
>   result_of_t<Proj&(reference_t<I>)> operator*() const;
> };
> ```

In [algorithm] replace references to `Function` with `Callable`. Strike paragraph [algorithm.general]/10 that describes how the algorithms use the removed `as_function` to implement predicate and projection callables. Replace all references to `INVOKE` in the algorithm descriptions with `invoke`. Replace the descriptive text in [alg.generate] with:

> Effects: Assigns the value of `invoke(gen)` through successive iterators in the range `[first,last)`, where `last` is `first + max(n, 0)` for `generate_n`.

> Returns: `last`.

> Complexity: Exactly `last - first` evaluations of `invoke(gen)` and assignments.


Assignable Semantics
====================
There seems to be some confusion in the Ranges TS about the relationship between the `Movable` and `Swappable` concepts. For example, the `Permutable` concept is required by algorithms that swap range elements, and it requires `IndirectlyMovable` instead of `IndirectlySwappable`. The specification of `swap` itself requires `Movable` elements. Does that imply that a `Movable` type `T` must satisfy `Swappable`? Certainly we experienced C++ programmers know the requirements for `std::swap` well enough that we often conflate movability with swappability.

Unfortunately, the answer to this leading question is "no." If `a` and `b` are lvalues of some `Movable` type `T`, then certainly `std::swap(a, b)` will swap the denoted values. However, `Swappable` requires that an overload found by ADL, if any, must exchange the denoted values. There is nothing in the `Movable` concept that forbids definition of a function `swap` that accepts two lvalue references to `T` and launches the missiles. We *could* redress this issue by better distinguishing move and swap operations, fastidiously requiring `Swappable` in the proper places, and attempting to better educate C++ users. However, it is our belief that this issue is so engrained in C++ culture that it would be best to make it valid.

Consequently, we propose the addition of semantic requirements to the previously purely syntactic `Assignable` concept, which when combined with `MoveConstructible` suffice to support implementation of the "default" `swap`. Specifically, we relocate the semantic requirements on the assignment expressions from `Movable` and `Copyable` to `Assignable`, which also simplifies the definitions of those two concepts. We then add a `Swappable` requirement to `Movable`, bringing `Swappable` properly into the object concept hierarchy.

Replace the content of [concepts.lib.corelang.assignable] with:

> ```c++
> template <class T, class U>
> concept bool Assignable() {
>   return Common<T, U>() && requires(T&& a, U&& b) {
>     { std::forward<T>(a) = std::forward<U>(b) } -> Same<T&>;
>   };
> }
> ```

> 1 Let `t` be an lvalue of type `T`, and `R` be the type `remove_reference_t<U>`. If `U` is an lvalue reference type, let `v` be a lvalue of type `R`; otherwise, let `v` be an rvalue of type `R`. Let `uu` be a distinct object of type `R` such that `uu == v`. Then `Assignable<T, U>()` is satisfied if and only if

> * `std::addressof(t = v) == std::addressof(t)`.

> * After evaluating `t = v`:

>   * `t == uu`.

>   * If `v` is a non-const rvalue, its resulting state is unspecified. [Note: `v` must still meet the requirements of the library component that is using it. The operations listed in those requirements must work as specified. ---end note ]

>   * Otherwise, `v` is not modified.

The entire content of [concepts.lib.object.movable] becomes:

> ```c++
> template <class T>
> concept bool Movable() {
>   return MoveConstructible<T>() &&
>     Assignable<T&, T&&>() &&
>     Swappable<T&>();
> }
> ```

Since the prose requirements are now redundant. As are those in [concepts.lib.object.copyable], which also now becomes simply a concept definition:

> ```c++
> template <class T>
> concept bool Copyable() {
>   return CopyConstructible<T>() &&
>     Movable<T>() &&
>     Assignable<T&, const T&>();
> }
> ```

It is now possible to change the `Movable` requirement on `exchange` in the `<experimental/ranges/utility>` header synopsis of [utility]/2 and its definition in [utility.exchange] to `MoveConstructible`:

> ```c++
> template <MoveConstructible T, class U=T>
> requires Assignable<T&, U>()
> T exchange(T& obj, U&& new_val);
> ```

which suffices to implement `exchange` along with the stronger `Assignable` semantics. (A similar change could be applied to the definition of the default `swap` implementation. We don't propose this here as we've already included the effect in the definition of the `swap` customization point earlier.)


Iterator/Sentinel Overhaul
==========================
One of the differences between the iterator model of the Ranges TS and that of Standard C++ is that the difference operation, as represented in the `SizedIteratorRange` concept, has been made semi-orthogonal to iterator category. Random access iterators *must* satisfy `SizedIteratorRange`, iterators of other categories *may* satisfy `SizedIteratorRange`. `SizedRange` provides a similar facility for ranges that know how many elements they contain, even if pairs of their iterators don't know how far apart they are. The TS has a mechanism for ranges to opt out of "sized-ness", but doesn't provide a similar mechanism for iterator and sentinel type pairs to opt out of "sized-ness."

Why is this even a concern? The specification of some functions in the library assumes they can be implemented to take advantage of size/distance information when available. In some cases the requirement is explicit:

> ```c++
> template <Range R>
> DifferenceType<IteratorType<R>> distance(R&& r);
> ```

> 1 Returns: `ranges::distance(begin(r), end(r))`

> ```c++
> template <SizedRange R>
> DifferenceType<IteratorType<R>> distance(R&& r);
> ```

> 2 Returns: `size(r)`

and in others, implicit:

> ```c++
> template <Iterator I, Sentinel<I> S>
> void advance(I& i, S bound);
> ```

> ...

> 7 If `SizedIteratorRange<I,S>()` is satisfied, equivalent to: `advance(i, bound - i)`.

Many of the algorithms have implementations that can take advantage of size information as well. We see three design choices for the use of size information in the library:

1. The requirement is always made explicit, as with `distance` above. A function with an alternative implementation that uses size information must be presented as an explicit overload that requires `SizedRange` or `SizedIteratorRange`. Users can see immediately whether or not they may legally pass a parameter that "looks like" it is `Sized` (i.e., meets the syntactic requirements but not the semantic requirements of the pertinent `Sized` concept) to a function.

2. Requirements can be implicit, as with `advance` above. To determine whether or not a user may legally pass a parameter that "looks like" it is `Sized`, the user examine the specification of that function and possibly the specifications of other functions that it is specified to use.

3. Make a library-wide blanket requirement that all ranges/iterator-and-sentinel pairs that meet the syntax of the pertinent `Sized` concept *must* meet the semantics.

Choices 1 & 2 suffer from the same problems. They require that the entire library be explicitly partitioned at specification time into components that may or may not use size information in their implementations. They require that users be familiar with (or have *exhaustive* knowledge for choice 2) the specifications of the library components to know which are "safe" to use. There is an enormous specification load on the library, and cognitive load on the users, to support what are essentially near-pathological corner case iterators & ranges.

Choice 3 is effectively a library-wide "duck typing" rule for a very specific case: it allows a library component to treat a parameter that is known to be a bird (e.g., `Range`) as a duck (e.g., `SizedRange`) if it looks like a duck. While this rule is also implicit, it has the advantage of being applied uniformly library-wide. We propose that choice 3 be used for the Ranges TS and that a mechanism similar to that used to opt out of `SizedRange` be provided for iterator/sentinel type pairs to opt out of `SizedIteratorRange`.

In passing, we note that the name `SizedIteratorRange` is confusing in the context of the TS, where all other `XXXRange` concepts are refinements of `Range`. Since `SizedIteratorRange` is a refinement of `Sentinel`, we think the name `SizedSentinel` is more appropriate. The template parameter order should be changed for consistency with the parameter order of `Sentinel`. Also, relocating the concept definition from its lonely section [iteratorranges.sizediteratorrange] - the sole subsection of [iteratorranges] - to be immediately after the definition of `Sentinel` produces a more comprehensible specification.

A thorough audit of iterator/sentinel semantics provides some opportunities to cleanup the language in [iterator.requirements.general], and sharpen the specifications of the iterator and sentinel concepts. Unfortunately, we notice a problem along the way: an inconsistency in the `Sentinel` semantics.

`Sentinel<S, I>()` requires `EqualityComparable<S, I>()`, which in turn requires that whenever `s1 == s2 && i1 == i2 && s1 == i1` for some values `s1, s2` and `i1, i2` of types `S` and `I`, that `s1 == i2 && s2 == i1` must also hold. Cross-type `EqualityComparable` (EC) establishes a tight correspondence between the values of the two types so that `==` is transitive across types. Cross-type EC also requires the partipant types to individually satisfy single-type EC which requires `==` to mean "equals," i.e., substitutable in equality-preserving expressions.

Let's try to define a sentinel type for pointers to "`int` that is less than some specified bound":

```c++
struct S {
  int bound;

  bool operator == (const S& that) const { return bound == that.bound; }
  bool operator != (const S& that) const { return !(*this == that); }

  friend bool operator == (const S& s, const int* p) {
    return *p >= s.bound;
  }
  friend bool operator == (const int* p, const S& s) {
    return s == p;
  }
  friend bool operator != (const int* p, const S& s) {
    return !(s == p);
  }
  friend bool operator != (const S& s, const int* p) {
    return !(s == p);
  }
};

int a[] = {1,2};
```
Is `Sentinel<S, int*>()` satisfied? Clearly the syntactic requirements are met. Consider the ranges `[a+1,S{1})` and `[a+1,S{2})`. Both `a+1 == S{1}` and `a+1 == S{2}` hold, so both ranges are empty. By cross-type EC, `(a+1 == S{1}) && (a+1 == S{2})` implies that `S{1} == S{2}` which is certainly NOT true from the definition of `S::operator==`. `S` is not a proper sentinel for `int*`.

Much of the literature around sentinels suggests that "sentinels should always compare equal." If we alter the definition of `S::operator==` so that it always returns `true`, the problem above is solved. But now consider the ranges `[a+0,S{1})` and `[a+0,S{2})`. We know from the examination of `[a+1,S{1})` and `[a+1,S{2})` that `S{1} == S{2}`. Single-type EC tells us that `S{1}` and `S{2}` must be equal (substitutable in equality-preserving expressions). But then `a+0 == S{1}` (1 >= 1) implies that `a+0 == S{2}` (1 >= 2). Another contradiction.

The principle at work here is a fundamental property of `EqualityComparable` types: any state that affects the observable behavior of an object - as witnessed by equality-preserving expressions - must participate in that object's value. Otherwise, two objects differing only in that state are `==` but NOT "equal," breaking single-type `EqualityComparable`'s requirement that `==` means "equals." We must either abandon what seems to be a large class of useful stateful sentinels, or reformulate the `Sentinel` concept to not require cross-type `EqualityComparable` and the resultant transitivity of `==`.

If we can't put sentinels into a correspondence with iterators, then sentinels must not represent *positions*. What then, are they? A perusal of the algorithms makes it clear what they require of sentinels (using `i` and `s` to denote an iterator and a sentinel):

* `i == s`, `i != s`, `s == i`, and `s != i` must all be equality-preserving expressions with the same domain
* Complement: `i != s` must be the complement of `i == s`
* Symmetry: `i == s` must be equivalent to `s == i`, and `s != i` equivalent to `i != s`
* `i == s` must be well-defined when `[i,s)` denotes a range

All requirements but the last are not particular to iterators and sentinels. We propose they be combined into a new comparison concept:

> ```c++
> template <class T, class U>
> concept bool WeaklyEqualityComparable() {
>   return requires(const T t, const U u) {
>     { t == u } -> Boolean;
>     { u == t } -> Boolean;
>     { t != u } -> Boolean;
>     { u != t } -> Boolean;
>   };
> }
> ```

> 1 Let `t` and `u` be objects of types `T` and `U`. `WeaklyEqualityComparable<T, U>()` is satisfied if and only if:

> * `t == u`, `u == t`, `t != u`, and `u != t` have the same domain.

> * `bool(u == t) == bool(t == u)`.

> * `bool(t != u) == !bool(t == u)`.

> * `bool(u != t) == bool(t != u)`.

`WeaklyEqualityComparable` can then be refined by `EqualityComparable<T>`, `EqualityComparable<T, U>`, and `Sentinel`.

We also note that the algorithms don't require comparison of sentinels with sentinels; we therefore propose that sentinels be `Semiregular` instead of `Regular`.

Comparing sentinels with other sentinels isn't the only operation that is not useful to generic code: the algorithms never compare input / output iterators with input / output iterators. They only compare input / output iterators with sentinels. The reason for this is fairly obvious: input / output ranges are single-pass, so an iterator + sentinel algorithm only has access to one valid iterator value at a time; the "current" value. Obviously the "current" value is always equal to itself.

The only difference between the `Weak` and non-`Weak` variants of the `Iterator`, `InputIterator`, and `OutputIterator` concepts is the requirement for equality comparison. Why have concepts that only differ by the addition of a useless requirement? Indeed the `==` operator is slightly worse than useless since its domain is so narrow: It always either returns `true` or has undefined behavior. Of course, now that we've relaxed the Sentinel relationship the design can support "weak" ranges: ranges delimited by a "weak" iterator and a sentinel. We therefore propose that `Sentinel` be relaxed to specify the relationship between a `WeakIterator` and a `Semiregular` type that denote a range.

We also propose that `ForwardIterator<I>` be specified to refine `Sentinel<I, I>` instead of `Iterator`, after which it becomes clear that the `Iterator`, `InputIterator`, and `OutputIterator` concepts have become extraneous. The algorithms and operations can all be respecified in terms of the `Weak` variants where necessary. We propose doing so,  eliminating the non-`Weak` concepts altogether, and then stripping the `Weak` prefix from the names of `WeakIterator`, `WeakInputIterator`, and `WeakOutputIterator`.

Technical Specifications
------------------------
In [concepts.lib.general.equality], remove the note from paragraph 1 and replace paragraph 2 with:

> Not all input values must be valid for a given expression; e.g., for integers `a` and `b`, the expression `a / b` is not well-defined when `b` is `0`. This does not preclude the expression `a / b` being equality preserving. The *domain* of an expression is the set of input values for which the  expression is required to be well-defined.

Replace [concepts.lib.compare.equalitycomparable] with:

> ```c++
> template <class T, class U>
> concept bool WeaklyEqualityComparable() {
>   return requires(const T t, const U u) {
>     { t == u } -> Boolean;
>     { u == t } -> Boolean;
>     { t != u } -> Boolean;
>     { u != t } -> Boolean;
>   };
> }
> ```

> Let `t` and `u` be objects of types `T` and `U`. `WeaklyEqualityComparable<T, U>()` is satisfied if and only if:

> * `t == u`, `u == t`, `t != u`, and `u != t` have the same domain.
> * `bool(u == t) == bool(t == u)`.
> * `bool(t != u) == !bool(t == u)`.
> * `bool(u != t) == bool(t != u)`.

> ```c++
> template <class T>
> concept bool EqualityComparable() {
>   return WeaklyEqualityComparable<T, T>();
> }
> ```

> 1 Let `a` and `b` be objects of type `T`. `EqualityComparable<T>()` is satisfied if and only if `bool(a == b)` if and only if `a` is equal to `b`.

> 2 [ Note: The requirement that the expression `a == b` is equality preserving implies that `==` is reflexive, transitive, and symmetric. ---end note ]

> ```c++
> template <class T, class U>
> concept bool EqualityComparable() {
>   return Common<T, U>() &&
>     EqualityComparable<T>() &&
>     EqualityComparable<U>() &&
>     EqualityComparable<common_type_t<T, U>>() &&
>     WeaklyEqualityComparable<T, U>();
> }
> ```

> 3 Let `a` be an object of type `T`, `b` an object of type `U`, and `C` be `common_type_t<T, U>`. Then `EqualityComparable<T, U>()` is satisfied if and only if `bool(a == b) == bool(C(a) == C(b))`.

In [iterator.requirements.general]/1, strike the words "for which equality is defined" (all iterators have a difference type in the Ranges TS). In paras 2 and 3 and table 4, replace "seven" with "five" and strike references to weak input / output iterators. Strike the word "Weak" from para 5. Replace paras 7 through 9 with:

> 7 Most of the library’s algorithmic templates that operate on data structures have interfaces that use ranges. A range is an iterator and a *sentinel* that designate the beginning and end of the computation.

> 8 A sentinel `s` is called *reachable* from an iterator `i` if and only if there is a finite sequence of applications of the expression `++i` that makes `i == s`. If `s` is reachable from `i`, they denote a range.

> 9 A range `[i,s)` is empty if `i == s`; otherwise, `[i,s)` refers to the elements in the data structure starting with the element pointed to by `i` and up to but not including the element pointed to by the first iterator `j` such that `j == s`.

> 10 A range `[i,s)` is valid if and only if `s` is reachable from `i`. The result of the application of functions in the library to invalid ranges is undefined.

Strike paragraph 13.

Strike section [iterators.iterator], and rename section [iterators.weakiterator] to [iterators.iterator]. Strike the prefix `Weak` wherever it appears in the section.

Replace the content of [iterators.sentinel] with:

> 1 The Sentinel concept specifies the relationship between an `Iterator` type and a `Semiregular` type whose values denote a range.

> ```c++
> template <class S, class I>
> concept bool Sentinel() {
>   return Semiregular<S>() &&
>     Iterator<I>() &&
>     WeaklyEqualityComparable<S, I>();
> }
> ```

> 2 Let `s` and `i` be values of type `S` and `I` such that `[i,s)` denotes a range. Types `S` and `I` satisfy `Sentinel<S, I>()` if and only if:

> (2.1) --- i == s is well-defined.

> (2.2) --- If bool(i != s) then i is dereferenceable and [++i,s) denotes a range.

> 3 The domain of `==` can change over time. Given an iterator `i` and sentinel `s` such that `[i,s)` denotes a range and `i != s`, `[i,s)` is not required to continue to denote a range after incrementing any iterator equal to `i`. [Note: Consequently, `i == s` is no longer required to be well-defined. - end note]

Add new subsection "Concept SizedSentinel" [iterators.sizedsentinel]:

> 1 The `SizedSentinel` concept specifies requirements on an `Iterator` (24.2.7) and a `Sentinel` that allow the use of the `-` operator to compute the distance between them in constant time.

> ```c++
> template <class S, class I>
> constexpr bool disable_sized_sentinel = false;
>
> template <class S, class I>
> concept bool SizedSentinel() {
>   return Sentinel<S, I>() &&
>   !disable_sized_sentinel<remove_cv_t<S>, remove_cv_t<I>> &&
>   requires (const I i, const S s) {
>     { s - i } -> Same<difference_type_t<I>>;
>     { i - s } -> Same<difference_type_t<I>>;
>   };
> }
> ```

> 3 Let `i` be an iterator of type `I`, and `s` a sentinel of type `S` such that `[i,s)` denotes a range. Let N be the smallest number of applications of `++i` necessary to make `bool(i == s)` be `true`. `SizedSentinel<S, I>()` is satisfied if and only if:

> (3.1) --- If N is representable by `difference_type_t<I>`, then `s - i` is well-defined and equals N.

> (3.2) --- If -N is representable by `difference_type_t<I>`, then `i - s` is well-defined and equals -N.

> 4 The `disable_sized_sentinel<S, I>` predicate provides a mechanism to enable use of sentinels and iterators with the library that meet the syntactic requirements but do not in fact satisfy `SizedSentinel`.

> 5 [ Note: A program that instantiates a library template that requires `SizedSentinel` with an iterator type `I` and sentinel type `S` that meet the syntactic requirements of `SizedSentinel<S, I>()` but do not satisfy `SizedSentinel` is ill-formed with no diagnostic required unless `disable_sized_sentinel<S, I>` evaluates to true (17.5.1.3). ---end note ]

> 5 [ Note: The `SizedSentinel` concept is satisfied by pairs of `RandomAccessIterator`s
and by counted iterators and their sentinels. ---end note ]

**Replace all references to `SizedIteratorRange<I, S>` in the document with references to `SizedSentinel<S, I>`.**

Remove section [iterators.input]. Rename section [iterators.weakinput] to [iterators.input], and strip the prefix `Weak` wherever it appears.

Remove section [iterators.output]. Rename section [iterators.weakoutput] to [iterators.output], and strip the prefix `Weak` wherever it appears.

In section [iterators.forward], replace para 2 with:

> 2 The `ForwardIterator` concept refines `InputIterator` (24.2.11), adding equality comparison and the multi-pass guarantee, described below.

> ```c++
> template <class I>
> concept bool ForwardIterator() {
>   return InputIterator<I>() &&
>   DerivedFrom<iterator_category_t<I>, forward_iterator_tag>() &&
>   Incrementable<I>() &&
>   Sentinel<I, I>();
> }
> ```

Remove section [iteratorranges].

In section [iterator.synopsis], remove the definition of `weak_input_iterator_tag`, and define `input_iterator_tag` with no bases. Strip occurrences of the prefix `Weak`. Replace the declarations delimited by the comments `// XXX Common iterators`, `// XXX Default sentinels`, `// XXX Counted iterators`, `// XXX Unreachable sentinels` with:

> ```c++
> // XXX Common iterators
> template <Iterator I, Sentinel<I> S>
>   requires !Same<I, S>()
> class common_iterator;
>
> template <Readable I, class S>
> struct value_type<common_iterator<I, S>>;
>
> template <InputIterator I, class S>
> struct iterator_category<common_iterator<I, S>>;
>
> template <ForwardIterator I, class S>
> struct iterator_category<common_iterator<I, S>>;
>
> template <class I1, class I2, Sentinel<I2> S1, Sentinel<I1> S2>
> bool operator==(
>   const common_iterator<I1, S1>& x, const common_iterator<I2, S2>& y);
> template <class I1, class I2, Sentinel<I2> S1, Sentinel<I1> S2>
>   requires EqualityComparable<I1, I2>()
> bool operator==(
>   const common_iterator<I1, S1>& x, const common_iterator<I2, S2>& y);
> template <class I1, class I2, Sentinel<I2> S1, Sentinel<I1> S2>
>   requires EqualityComparable<I1, I2>()
> bool operator!=(
>   const common_iterator<I1, S1>& x, const common_iterator<I2, S2>& y);
> template <class I2, SizedSentinel<I2> I1, SizedSentinel<I2> S1, SizedSentinel<I1> S2>
> difference_type_t<I2> operator-(
>   const common_iterator<I1, S1>& x, const common_iterator<I2, S2>& y);
>
> // XXX Default sentinels
> class default_sentinel;
>
> // XXX Counted iterators
> template <Iterator I> class counted_iterator;
>
> template <class I1, class I2>
>   requires Common<I1, I2>()
> bool operator==(
>   const counted_iterator<I1>& x, const counted_iterator<I2>& y);
> bool operator==(
>   const counted_iterator<auto>& x, default_sentinel y);
> bool operator==(
>   default_sentinel x, const counted_iterator<auto>& yx);
> template <class I1, class I2>
>   requires Common<I1, I2>()
> bool operator!=(
>   const counted_iterator<I1>& x, const counted_iterator<I2>& y);
> bool operator!=(
>   const counted_iterator<auto>& x, default_sentinel y);
> bool operator!=(
>   default_sentinel x, const counted_iterator<auto>& y);
> template <class I1, class I2>
>   requires Common<I1, I2>()
> bool operator<(
>   const counted_iterator<I1>& x, const counted_iterator<I2>& y);
> template <class I1, class I2>
>   requires Common<I1, I2>()
> bool operator<=(
>   const counted_iterator<I1>& x, const counted_iterator<I2>& y);
> template <class I1, class I2>
>   requires Common<I1, I2>()
> bool operator>(
>   const counted_iterator<I1>& x, const counted_iterator<I2>& y);
> template <class I1, class I2>
>   requires Common<I1, I2>()
> bool operator>=(
>   const counted_iterator<I1>& x, const counted_iterator<I2>& y);
> template <class I1, class I2>
>   requires Common<I1, I2>()
> difference_type_t<I2> operator-(
>   const counted_iterator<I1>& x, const counted_iterator<I2>& y);
> template <class I>
>   difference_type_t<I> operator-(
>     const counted_iterator<I>& x, default_sentinel y);
> template <class I>
>   difference_type_t<I> operator-(
>     default_sentinel x, const counted_iterator<I>& y);
> template <RandomAccessIterator I>
>   counted_iterator<I>
>     operator+(difference_type_t<I> n, const counted_iterator<I>& x);
> template <Iterator I>
>   counted_iterator<I> make_counted_iterator(I i, difference_type_t<I> n);
>
> template <Iterator I>
>   void advance(counted_iterator<I>& i, difference_type_t<I> n);
>
> // XXX Unreachable sentinels
> class unreachable;
> template <Iterator I>
>   constexpr bool operator==(const I&, unreachable) noexcept;
> template <Iterator I>
>   constexpr bool operator==(unreachable, const I&) noexcept;
> template <Iterator I>
>   constexpr bool operator!=(const I&, unreachable) noexcept;
> template <Iterator I>
>   constexpr bool operator!=(unreachable, const I&) noexcept;
> ```

and replace the block of declarations in namespace `std`:

> ```c++
> namespace std {
>   // 24.6.2, iterator traits
>   template <experimental::ranges::Iterator I>
>   struct iterator_traits;
>   template <experimental::ranges::InputIterator I>
>   struct iterator_traits;
>   template <experimental::ranges::InputIterator I>
>     requires Sentinel<I, I>()
>   struct iterator_traits;
> }
> ```

In [iterator.assoc]/10, strip occurrences of the `Weak` prefix.

In [iterator.stdtraits], Add the clause `requires Sentinel<I, In>()` to the declaration of the `iterator_traits` partial specialization that has no `Weak` prefix. Strip occurrences of the `Weak` prefix.

In [std.iterator.tags], strike `weak_input_iterator_tag` as in the synopsis.

Replace the content of [iterator.operations] with the content of the section of the same name in N4569.

In [iterators.common]/2, strike ", and for use in common_type specializations that are required to make
iterator/sentinel pairs satisfy the EqualityComparable concept"

Replace the contents of [iterators.common], [default.sentinels], [iterators.counted], and [unreachable.sentinels] with the contents of the sections of the same name in N4569.

Strip occurrences of the prefix `Weak` wherever it appears in clause [algorithms].


# A Sentinel for `move_iterator`
In C++14, it is possible to wrap a pair of input iterators into `move_iterator` and pass it to an algorithm so as to convert copies into moves:
```c++
template <class InputIterator>
void foo(InputIterator first, InputIterator last) {
  bar(make_move_iterator(first), make_move_iterator(last));
}
```
In the Ranges design, ranges are typically denoted by iterator/sentinel pairs:
```c++
template <InputIterator I, Sentinel<I> S>
void foo(I first, S last) {
  bar(make_move_iterator(first), ???);
}
```
What do we pass to `bar` to denote the end of the "moved" range? `make_move_iterator(next(first, last))` is not usable if the range is single-pass. There are at least three potential solutions:

1. Define a `move_sentinel<S>` wrapper class that satisfies `Sentinel<move_sentinel<S>, move_iterator<I>>()` when `Sentinel<S, I>()` is satisfied. For ease of use, and consistency of interface, define a `make_move_sentinel` deducing helper function. This approach maintains a clear distinction between the adapted range and the underlying range. The definition of `foo` becomes:

    ```c++
    template <InputIterator I, Sentinel<I> S>
    void foo(I first, S last) {
      bar(make_move_iterator(first), make_move_sentinel(last));
    }
    ```

    This approach is straightforward, and while perhaps lacking elegance, gets the job done.

2. Define operator overloads for `==` and `!=` that accept `move_iterator<I>` and `Sentinel<I>` so that move iterators can use the sentinels of their base iterators directly:

    ```c++
    Sentinel{S, I}
    bool operator==(const move_iterator<I>& i, const S& s) {
      return i.current_ == s;
    }
    // Define != similarly, and the symmetric overloads.
    ```
    `foo` can be simpler since it passes the sentinel directly:
    ```c++
    template <InputIterator I, Sentinel<I> S>
    void foo(I first, S last) {
      bar(make_move_iterator(first), last);
    }
    ```

    This approach requires less syntax at the callsite. It is a bit lax in that it allows comparing adapted iterators with unadapted sentinels, potentially creating confusion in code readers about which iterators/sentinels are adapted and which are from the base range.

3. Ignore the problem until Ranges TS2 comes along with support for view adaptors, and the solution will look something like:

    ```c++
    template <InputIterator I, Sentinel<I> S>
    void foo(I first, S last) {
      bar(make_iterator_range(first, last) | view::move);
    }
    // Or even better:
    void foo(InputRange&& rng) {
      bar(rng | view::move);
    }
    ```

    Adapting iterator/sentinel pairs together instead of individually is preferable: it allows the library to check for errors, and to optimize the special case when `last` is also an iterator by producing a bounded range (a range whose `begin` and `end` have the same type).

The view adapter is clearly the preferable solution in the long run, but would require the introduction of too much additional machinery into the current TS to be a viable solution in the short-term. Implementation experience using the underlying sentinels directly with the move iterators was not positive: it results in less clear code, and is fragile in the face of poorly constrained iterators/sentinels. We thereforer propose the first approach as an interim solution to this problem.

Technical Specifications
------------------------
Add the following declarations to the synopsis of the `<experimental/ranges/iterator>` head in [iterator.synopsis], after between the `move_iterator` and `common_iterator` declarations:

> ```c++
> template <Semiregular S> class move_sentinel;
> template <class I, Sentinel<I> S>
>   bool operator==(
>     const move_iterator<I>& i, const move_sentinel<S>& s);
> template <class I, Sentinel<I> S>
>   bool operator==(
>     const move_sentinel<S>& s, const move_iterator<I>& i);
> template <class I, Sentinel<I> S>
>   bool operator!=(
>     const move_iterator<I>& i, const move_sentinel<S>& s);
> template <class I, Sentinel<I> S>
>   bool operator!=(
>     const move_sentinel<S>& s, const move_iterator<I>& i);
> template <class I, SizedSentinel<I> S>
>   difference_type_t<I> operator-(
>     const move_sentinel<S>& s, const move_iterator<I>& i);
> template <class I, SizedSentinel<I> S>
>   difference_type_t<I> operator-(
>     const move_iterator<I>& i, const move_sentinel<S>& s);
> template <Semiregular S>
>   move_sentinel<S> make_move_sentinel(S s);
> ```

Insert a new subsection [move.sentinel] under [iterators.move]:

> 24.7.3.4 Class template `move_sentinel` [move.sentinel]
>
> ```c++
> namespace std { namespace experimental { namespace ranges { inline namespace v1 {
>   template <Semiregular S>
>   class move_sentinel {
>   public:
>     constexpr move_sentinel();
>     explicit move_sentinel(S s);
>     move_sentinel(const move_sentinel<ConvertibleTo<S>>& s);
>     move_sentinel& operator=(const move_sentinel<ConvertibleTo<S>>& s);
>     S base() const;
>   private:
>     S last; // exposition only
>   };
>   template <class I, Sentinel<I> S>
>     bool operator==(
>       const move_iterator<I>& i, const move_sentinel<S>& s);
>   template <class I, Sentinel<I> S>
>     bool operator==(
>       const move_sentinel<S>& s, const move_iterator<I>& i);
>   template <class I, Sentinel<I> S>
>     bool operator!=(
>       const move_iterator<I>& i, const move_sentinel<S>& s);
>   template <class I, Sentinel<I> S>
>     bool operator!=(
>       const move_sentinel<S>& s, const move_iterator<I>& i);
>   template <class I, SizedSentinel<I> S>
>     difference_type_t<I> operator-(
>       const move_sentinel<S>& s, const move_iterator<I>& i);
>   template <class I, SizedSentinel<I> S>
>     difference_type_t<I> operator-(
>       const move_iterator<I>& i, const move_sentinel<S>& s);
>   template <Semiregular S>
>     move_sentinel<S> make_move_sentinel(S s);
> }}}}
> ```
>
> 24.7.3.5 `move_sentinel` operations [move.sent.ops]
> 24.7.3.5.1 `move_sentinel` constructors [move.sent.op.const]
>
> ```c++
> constexpr move_sentinel();
> ```
>
> 1 Effects: Constructs a `move_sentinel`, value-initializing `last`. If `S` is a literal type, this constructor shall be a `constexpr` constructor.
>
> ```c++
> explicit move_sentinel(S s);
> ```
>
> 2 Effects: Constructs a move_sentinel, initializing last with s.
>
> ```c++
> move_sentinel(const move_sentinel<ConvertibleTo<S>>& s);
> ```
>
> 3 Effects: Constructs a move_sentinel, initializing last with s.last.
>
> 24.7.3.5.2 `move_sentinel::operator=` [move.sent.op=]
> ```c++
> move_sentinel& operator=(const move_sentinel<ConvertibleTo<S>>& s);
> ```
>
> 1 Effects: Assigns `s.last` to `last`.
>
> 24.7.3.5.3 `move_sentinel` comparisons [move.sent.op.comp]
>
> ```c++
> template <class I, Sentinel<I> S>
>   bool operator==(
>     const move_iterator<I>& i, const move_sentinel<S>& s);```
> template <class I, Sentinel<I> S>
>   bool operator==(
>     const move_sentinel<S>& s, const move_iterator<I>& i);
> ```
>
> 1 Effects: Equivalent to `i.current == s.last`.
>
> ```c++
> template <class I, Sentinel<I> S>
>   bool operator!=(
>     const move_iterator<I>& i, const move_sentinel<S>& s);
> template <class I, Sentinel<I> S>
>   bool operator!=(
>     const move_sentinel<S>& s, const move_iterator<I>& i);
> ```
>
> 2 Effects: Equivalent to `!(i == s)`.
>
> 24.7.3.5.4 `move_sentinel` non-member functions [move.sent.nonmember]
> ```c++
> template <class I, SizedSentinel<I> S>
>   difference_type_t<I> operator-(
>     const move_sentinel<S>& s, const move_iterator<I>& i);
> ```
>
> 1 Effects: Equivalent to `s.last - i.current`.
>
> ```c++
> template <class I, SizedSentinel<I> S>
>   difference_type_t<I> operator-(
>     const move_iterator<I>& i, const move_sentinel<S>& s);
> ```
>
> 2 Effects: Equivalent to `i.current - s.last`.
>
> ```c++
> template <Semiregular S>
> move_sentinel<S> make_move_sentinel(S s);
> ```
>
> 3 Returns: `move_sentinel<S>(s)`.


# Merge `Writable` and `MoveWritable`

[PR](https://github.com/ericniebler/stl2/pull/160)

[Discussion](https://github.com/CaseyCarter/stl2/issues/17)


#Merge/MergeMovable fix

[PR](https://github.com/ericniebler/stl2/pull/157)

(This simply relaxed an overconstrained parameter, maybe could integrate into the Writable/MoveWritable discussion.)


# Implementation Experience
The proposed design changes are implemented in [CMCSTL2, a full implementation of the Ranges TS with proxy extensions][2][@cmcstl2].

# Acknowledgements
The authors would like to thank Andrew Sutton and Sean Parent for their participation in the discussions that produced most of the ideas herein.

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
    year: 2016
    month: 05
    day: 26
- id: N4560
  title: 'N4560: Working Draft: C++ Extensions for Ranges'
  type: article
  author:
  - family: Niebler
    given: Eric
  - family: Carter
    given: Casey
  issued:
    year: 2015
    month: 11
    day: 16
  URL: http://www.open-std.org/jtc1/sc22/wg21/docs/papers/2015/n4560.pdf
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

[1]: http://www.open-std.org/jtc1/sc22/wg21/docs/papers/2015/n4560.pdf "Working Draft: C++ Extensions for Ranges"
[2]: https://github.com/CaseyCarter/cmcstl2 "CMCSTL2: Casey Carter's reference implementation of STL2"
[3]: http://www.open-std.org/jtc1/sc22/wg21/docs/papers/2016/n4569.pdf "Working Draft: C++ Extensions for Ranges"
[4]: http://www.gotw.ca/publications/mill09.htm "When is a container not a container?"
[5]: http://www.github.com/ericniebler/range-v3 "Range v3"
[6]: http://www.open-std.org/jtc1/sc22/wg21/docs/papers/2012/n3351.pdf "A Concept Design for the STL"
[7]: https://www.sgi.com/tech/stl/ "SGI Standard Template Library Programmer's Guide"
[8]: http://www.open-std.org/jtc1/sc22/wg21/docs/papers/2015/n4381.html "Suggested Design for Customization Points"
