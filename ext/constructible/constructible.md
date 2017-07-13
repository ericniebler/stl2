---
pagetitle: "Ranges TS: Assorted Object Concept Fixes"
title: "Ranges TS: Assorted Object Concept Fixes"
...

# Synopsis

This paper suggests reformulations of the following fundamental object concepts to resolve a number of outstanding issues, and to bring them in line with (what experience has shown to be) user expectations:

- `Destructible`
- `Constructible`
- `DefaultConstructible`
- `MoveConstructible`
- `CopyConstructible`
- `Assignable`

The suggested changes make them behave more like what their associated type traits do.

In addition, we suggest a change to `Movable` that correctly positions it as the base of the `Regular` concept hierarchy, which concerns itself with types with value semantics.

# Revision History
## R1
* [Per LWG Kona direction, removed the requirement that `Destructible` types do not overload `operator&`](https://github.com/ericniebler/stl2/commit/e426f096407c24063af8da3e9235c9d1b297df14).
* [Add `Readable` and `Writable` changes (Issue #330, #381, #387, #399)](https://github.com/ericniebler/stl2/commit/565c767f61767a4b4a90706821a6dcf0dcf1db06).
* [Reorganize bullet points in Move/CopyConstructible](https://github.com/ericniebler/stl2/commit/283b722356801056e5e95891e9ed09a12526f611).
* [Add missing comma in the new description of `Destructible`](https://github.com/ericniebler/stl2/commit/c6efdfe2d635e31610466faea8e02dfd3da53e3c).
* [Rebase `Assignable` changes onto the post-P0370 wording](https://github.com/ericniebler/stl2/commit/d72a3b2232c8aa339e044db11bec685e02b32c7c).
* [Address #293 in `MoveConstructible`](https://github.com/ericniebler/stl2/commit/15ff17eb92f28ea920f9d04627af82e3d243bc75).
* [s/there is no subsumption relationship/there need not be any subsumption relationship/g](https://github.com/ericniebler/stl2/commit/e8881723b91c277ccd1a76637d2709c540466403).

## R2
* Add this revision history
* Concept definitions in the style of "`Concept<T>()` is satisfied if and only if:" should use "only if."

# Problem description

The [Palo Alto report](http://www.open-std.org/jtc1/sc22/wg21/docs/papers/2012/n3351.pdf), on which the design of the Ranges TS is based, suggested the object concepts `Semiregular` and `Regular` for constraining standard library components. In an appendix it concedes that many generic components could more usefully be constrained with decompositions of these very coarse concepts: `Movable` and `Copyable`.

While implementing a subset of a constrained Standard Library, the authors of the Ranges TS found that even more fine-grained "object" concepts were often useful: `MoveConstructible`,  `CopyConstructible`, `Assignable`, and others. These concepts are needed to avoid over-constraining low-level library utilities like `pair`, `tuple`, `variant` and more. Rather than aping the similarly named type-traits, the authors of the Ranges TS tried to preserve the intent of the Palo Alto report by giving them semantic weight. It did this in various ways, including:

- Requiring that destructible objects can have their address taken.
- Requiring that destructible objects can have their destructor called explicitly.
- Requiring that constructible objects are destructible.
- Testing that objects could be allocated and deallocated in dynamic as well as automatic storage.
- Testing for array allocation and deallocation.
- Testing that default constructors are not `explicit`.

Although well-intentioned, many of the extra semantic requirements have proved to be problematic in practice. Here, for instance, are seven currently open [stl2](https://github.com/ericniebler/stl2) bugs that need resolution:

1. **"Why do neither reference types nor array types satisfy `Destructible`?" ([stl2#70](https://github.com/ericniebler/stl2/issues/70))**
> This issue, raised independently by Walter Brown, Alisdair Meredith, and others, questions the decision to have `Destructible<T>()` require the valid expression `t.~T()` for some lvalue `t` of type `T`. That has the effect of
preventing reference and array types from satisfying `Destructible`.
>
> In addition, `Destructible` requires `&t` to have type `T*`. This also prevents reference types from satisfying `Destructible` since you can't form a pointer to a reference.
>
> A reasonable interpretation of "destructible" is "can fall out of scope". This is roughly what is tested by the `is_destructible` type trait. By this rubric, references and array types should satisfy `Destructible` as they do for the trait.

2. **"Is it intended that `Constructible<int&, long&>()` is true?" ([stl2#301](https://github.com/ericniebler/stl2/issues/301))**
> `Constructible<T, Args...>()` tries to test that the type `T` can be constructed on the heap as well as in automatic storage. But requiring the expression `new T{declval<Args>()...}` causes reference types to fail to satisfy the concept since references cannot be dynamically allocated. `Constructible` "solves" this problem by handling references separately; their required expression is merely `T(declval<Args>()...)`. That syntax has the unfortunate effect of being a function-style cast, which in the case of `int&` and `long&`, amounts to a `reinterpret_cast`.
>
> We could patch this up by using universal initialization syntax, but that comes with its own problems. Instead, we opted for a more radical simplification: just do what `is_constructible` does.

3. **"`Movable<int&&>()` is `true` and it should probably be `false`" ([stl2#310](https://github.com/ericniebler/stl2/issues/310))**
> A cursory review of the places that use `Movable` in the Ranges TS reveals that they all are expecting types with value semantics. A reference does not exhibit value semantics, so it is surprising for `int&&` to satisfy `Movable`.

4. **"Is it intended that an aggregate with a deleted or nonexistent default constructor satisfy `DefaultConstructible`?" ([stl2#300](https://github.com/ericniebler/stl2/issues/300))**
> Consider a type such as the following:
> ```c++
> struct A{
>     A(const A&) = default;
> };
> ```
> This type is not default constructible; the statement `auto a = A();` is ill-formed. However, since `A` is an aggregate, the statement `auto a = A{};` is well-formed. Since `Constructible` is testing for the latter syntax and not the former, `A` satisfies `DefaultConstructible`. This is in contrast with the result of `std::is_default_constructible<A>::value`, which is `false`.

5. **"Assignable concept looks wrong" ([stl2#229](https://github.com/ericniebler/stl2/issues/229))**
> There are a few problems with `Assignable`. The given definition, `Assignable<T, U>()` would appear to work with reference types (as one would expect), but the prose description reads, "Let `t` be an lvalue of type `T`..." There are no lvalues of reference type, so the wording is simply wrong. The wording also erroneously uses `==` instead of the magic phrase "is equal to," accidentally requiring the types to satisfy (some part of) `EqualityComparable`.
>
> Also, LWG requested at the Issaquah 2016 meeting that this concept be changed such that it is only satisfied when `T` is an lvalue reference type.

6. **"MoveConstructible<T>() != std::is_move_constructible<T>()"  ([stl2#313](https://github.com/ericniebler/stl2/issues/313))**
> The definition of `MoveConstructible` applies `remove_cv_t` to its argument before testing it, as shown below:
> ```c++
> template <class T>
> concept bool MoveConstructible() {
>  return Constructible<T, remove_cv_t<T>&&>() &&
>    ConvertibleTo<remove_cv_t<T>&&, T>();
> }
> ```
> This somewhat surprisingly causes `const some_move_only_type` to satisfy `MoveConstructible`, when it probably shouldn't. `std::is_move_constructible<const some_move_only_type>::value` is `false`, for instance.

7. **"Subsumption and object concepts" ([CaseyCarter/stl2#22](https://github.com/CaseyCarter/stl2/issues/22))**
> This issue relates to the fact that there is _almost_ a perfect sequence of subsumption relationships from `Destructible`, through `Constructible`, and all the way to `Regular`. The "almost" is the problem. Given a set of overloads constrained with these concepts, there will be ambiguity due to the fact that _in some cases_ `Constructible` does not subsume `Destructible` (e.g., for references).

We were also motivated by the very real user confusion about why concepts with names similar to associated type traits gives different answers for different types and type categories.

It remains our intention to resist the temptation to constrain the library with semantically meaningless, purely syntactic concepts.

# Solution description

At the high level, the solution this paper suggests is to break the object concepts into two logical groups: the lower-level concepts that follow the lead of their similarly-named type traits with regard to "odd" types (references, arrays, _cv_ `void`), and the higher-level concepts that deal only with value semantic types.

The lower-level concepts are those that have corresponding type traits, and behave largely like them. They can no longer properly be thought of as "object" concepts, so they rightly belong with the core language concepts.

- `Destructible`
- `Constructible`
- `DefaultConstructible`
- `MoveConstructible`
- `CopyConstructible`
- `Assignable`

These concepts are great for constraining the special members of low-level generic facilities like `std::tuple` and `std::optional`, but they are too fiddly for constraining anything but the most trivial generic algorithms. Unlike the type traits, these concepts require additional syntax and semantics for the sake of the generic programmer's sanity, although the requirements are light.

The higher-level concepts are those that the Palo Alto report describes, and are satisfied by object types only:

- `Movable`
- `Copyable`
- `Semiregular`
- `Regular`

These are the concepts that largely constrain the algorithms in the STL.

The changes suggested in this paper bear on [LWG#2146](https://cplusplus.github.io/LWG/lwg-active.html#2146), "Are reference types Copy/Move-Constructible/Assignable or Destructible?" There seems to be some discomfort with the current behavior of the type traits with regard to reference types. Should that issue be resolved such that reference types are deemed to _not_ be copy/move-constructible/assignable or destructible, the concepts should follow suit. Until such time, the authors feel that hewing to the behavior of the traits is the best way to avoid confusion.

In the "Proposed Resolution" that follows, there are editorial notes that highlight specific changes and describe their intent and impact.

# Proposed Resolution

<ednote>[_Editor's note:_ Edit subsection "Concept `Assignable`" ([concepts.lib.corelang.assignable]) as follows:]</ednote>

> > <tt>template &lt;class T, class U&gt;</tt>
> > <tt>concept bool Assignable() {</tt>
> > <tt>&nbsp;&nbsp;<del>return CommonReference&lt;const T&amp;, const U&amp;&gt;() &amp;&amp; requires(T&amp;&amp; t, U&amp;&amp; u) {</del></tt>
> > <tt>&nbsp;&nbsp;&nbsp;&nbsp;<del>{ std::forward&lt;T&gt;(t) = std::forward&lt;U&gt;(u) } -&gt; Same&lt;T&amp;&gt;;</del></tt>
> > <tt>&nbsp;&nbsp;<del>};</del></tt>
> > <tt>&nbsp;&nbsp;<ins>return is_lvalue_reference&lt;T&gt;::value &amp;&amp; // see below</ins></tt>
> > <tt>&nbsp;&nbsp;&nbsp;&nbsp;<ins>CommonReference&lt;</ins></tt>
> > <tt>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<ins>const remove_reference_t&lt;T&gt;&amp;,</ins></tt>
> > <tt>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<ins>const remove_reference_t&lt;U&gt;&amp;&gt;() &amp;&amp;</ins></tt>
> > <tt>&nbsp;&nbsp;&nbsp;&nbsp;<ins>requires(T t, U&amp;&amp; u) {</ins></tt>
> > <tt>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<ins>{ t = std::forward&lt;U&gt;(u) } -&gt; Same&lt;T&gt;&amp;&amp;;</ins></tt>
> > <tt>}</tt>
>
> 1 <del>Let `t` be an lvalue of type `T`, and `R` be the type `remove_reference_t<U>`. If `U` is an lvalue reference type, let `v` be an lvalue of type `R`; otherwise, let `v` be an rvalue of type `R`. Let `uu` be a distinct object of type `R` such that `uu` is equal to `v`.</del><ins>Let `t` be an lvalue which refers to an object `o` such that `decltype((t))` is `T`, and `u` an expression such that `decltype((u))` is `U`. Let `u2` be a distinct object that is equal to `u`.</ins> Then `Assignable<T, U>()` is satisfied only if
>
> > (1.1) -- <tt>addressof(t = <del>v</del><ins>u</ins>) == addressof(<del>t</del><ins>o</ins>)</tt>.
> >
> > (1.2) -- After evaluating <tt>t = <del>v</del><ins>u</ins></tt>, <tt>t</tt> is equal to <tt><del>uu</del><ins>u2</ins></tt> and:
> >
> > > (1.2.1) -- If <del>`v`</del><ins>`u`</ins> is a non-`const` <del>rvalue, its</del><ins>xvalue, the</ins> resulting state <ins>of the object to which it refers</ins> is valid but unspecified ([lib.types.movedfrom]).
> > >
> > > (1.2.2) -- Otherwise, <del>`v`</del><ins>if `u` is a glvalue, the object to which it refers</ins> is not modified.
>
> <ins>2 There need not be any subsumption relationship between `Assignable<T, U>()` and `is_lvalue_reference<T>::value`.

<ednote>[_Editor's note:_ Prior to this change, `Assignable` is trying to work with proxy reference types and failing. It perfectly forwards its arguments, but requires the return type of assignment to be `T&` (which is not true for some proxy types). Also, the allowable moved-from state of the rhs expression (`u`) is described in terms of its value category. But if the rhs is a proxy reference (e.g., `reference_wrapper<int>`) then the value category of the proxy bears no relation to the value category of the referent.</ednote>

<ednote>The issue was discussed in the Issaquah 2016 meeting. The guidance given there was to narrowly focus this concept on "traditional" assignability only -- assignments to non-`const` lvalues from non-proxy expressions -- and solve the proxy problem at a later date. That is the direction taken here.]</ednote>

<ednote>[_Editor's note:_ Move subsection "Concept `Destructible`" ([concepts.lib.object.destructible]) to subsection "Core language concepts" ([concepts.lib.corelang]) after [concepts.lib.corelang.swappable], change its stable id to [concepts.lib.corelang.destructible] and edit it as follows:]</ednote>

> 1 <del>The `Destructible` concept is the base of the hierarchy of object concepts. It specifies properties that all such object types have in common.</del><ins>The `Destructible` concept specifies properties of all types, instances of which can be destroyed at the end of their lifetime, or reference types.</ins>
>
> > <tt>template &lt;class T&gt;</tt>
> > <tt>concept bool Destructible() {</tt>
> > <tt>&nbsp;&nbsp;<del>return requires(T t, const T ct, T* p) {</del></tt>
> > <tt>&nbsp;&nbsp;&nbsp;&nbsp;<del>{ t.~T() } noexcept;</del></tt>
> > <tt>&nbsp;&nbsp;&nbsp;&nbsp;<del>{ &amp;t } -&gt; Same&lt;T\*&gt;; // not required to be equality preserving</del></tt>
> > <tt>&nbsp;&nbsp;&nbsp;&nbsp;<del>{ &amp;ct } -&gt; Same&lt;const T\*&gt;; // not required to be equality preserving</del></tt>
> > <tt>&nbsp;&nbsp;&nbsp;&nbsp;<del>delete p;</del></tt>
> > <tt>&nbsp;&nbsp;&nbsp;&nbsp;<del>delete[] p;</del></tt>
> > <tt>&nbsp;&nbsp;<del>};</del></tt>
> > <tt>&nbsp;&nbsp;<ins>return is_nothrow_destructible&lt;T&gt;::value; // see below</ins></tt>
> > <tt>}</tt>
>
> &#8203;<del>2 The expression requirement `&ct` does not require implicit expression variants.</del>
>
> &#8203;<del>3 Given a (possibly `const`) lvalue `t` of type <tt>T</tt> and pointer `p` of type `T*`,  `Destructible<T>()` is satisfied only if</del>
>
> > &#8203;<del>(3.1) -- After evaluating the expression `t.~T()`, `delete p`, or `delete[] p`, all resources owned by the denoted object(s) are reclaimed.</del>
> >
> > &#8203;<del>(3.2) -- `&t == addressof(t)`.</del>
> >
> > &#8203;<del>(3.3) -- The expression `&t` is non-modifying.</del>
>
> &#8203;<ins>2 There need not be any subsumption relationship between `Destructible<T>()` and `is_nothrow_destructible<T>::value`.

<ednote>[_Editor's note:_ In the minutes of Ranges TS wording review at Kona on 2015-08-14, the following is recorded:</ednote>

<blockquote><ednote>In 19.4.1 Alisdair asks whether reference types are Destructible. Eric pointed to <a href="https://github.com/ericniebler/stl2/issues/70">issue 70</a>, regarding reference types and array types. Alisdair concerned that Destructible sounds like something that goes out of scope, maybe this concept is really describing Deletable.</ednote></blockquote>

<ednote>We took this as guidance to make `Destructible` behave more like the type traits with regard to "strange" types like references and arrays. We also dropped the requirement for dynamic [array] deallocation. Per discussion in Kona 2016, we drop the requirement for a sane address-of operation. We require that destructors are marked `noexcept` since `noexcept` clauses throughout the standard and the Ranges TS tacitly assume it, and because sane implementations require it.]</ednote>

<ednote>[_Editor's note:_ Move subsection "Concept `Constructible`" ([concepts.lib.object.constructible]) to subsection "Core language concepts" ([concepts.lib.corelang]) after [concepts.lib.corelang.destructible], change its stable id to [concepts.lib.corelang.constructible] and edit it as follows:]</ednote>

> 1 The `Constructible` concept is used to constrain the <del>type of a variable to be either an object type constructible from</del><ins>initialization of a variable of a type with</ins> a given set of argument types<del>, or a reference type that can be bound to those arguments</del>.
>
> > <tt><del>template &lt;class T, class.\.. Args&gt;</del></tt>
> > <tt><del>concept bool __ConstructibleObject = // exposition only</del></tt>
> > <tt>&nbsp;&nbsp;<del>Destructible&lt;T&gt;() &amp;&amp; requires(Args&amp;&amp;.\.. args) {</del></tt>
> > <tt>&nbsp;&nbsp;&nbsp;&nbsp;<del>T{std::forward&lt;Args&gt;(args).\..}; // not required to be equality preserving</del></tt>
> > <tt>&nbsp;&nbsp;&nbsp;&nbsp;<del>new T{std::forward&lt;Args&gt;(args).\..}; // not required to be equality preserving</del></tt>
> > <tt>&nbsp;&nbsp;<del>};</del></tt>
> > <tt></tt>
> > <tt><del>template &lt;class T, class..\. Args&gt;</del></tt>
> > <tt><del>concept bool __BindableReference = // exposition only</del></tt>
> > <tt>&nbsp;&nbsp;<del>is_reference&lt;T&gt;::value &amp;&amp; requires(Args&amp;&amp;.\.. args) {</del></tt>
> > <tt>&nbsp;&nbsp;&nbsp;&nbsp;<del>T(std::forward&lt;Args&gt;(args).\..);</del></tt>
> > <tt>&nbsp;&nbsp;<del>};</del></tt>
> > <tt></tt>
> > <tt>template &lt;class T, class..\. Args&gt;</tt>
> > <tt>concept bool Constructible() {</tt>
> > <tt>&nbsp;&nbsp;<del>return __ConstructibleObject&lt;T, Args.\..&gt; ||</del></tt>
> > <tt>&nbsp;&nbsp;&nbsp;&nbsp;<del>__BindableReference&lt;T, Args.\..&gt;;</del></tt>
> > <tt>&nbsp;&nbsp;<ins>return Destructible&lt;T&gt;() && is_constructible&lt;T, Args.\..&gt;::value; // see below</ins></tt>
> > <tt>}</tt>
>
> &#8203;<ins>2 There need not be any subsumption relationship between `Constructible<T, Args...>()` and `is_constructible<T, Args...>::value`.

<ednote>[_Editor's note:_ `Constructible` now always subsumes `Destructible`, fixing [CaseyCarter/stl2#22](https://github.com/CaseyCarter/stl2/issues/22) which regards overload ambiguities introduced by the lack of such a simple subsumption relationship. `Constructible` follows `Destructible` by dropping the requirement for dynamic [array] allocation.]</ednote>

<ednote>[_Editor's note:_ Move subsection "Concept `DefaultConstructible`" ([concepts.lib.object.defaultconstructible]) to subsection "Core language concepts" ([concepts.lib.corelang]) after [concepts.lib.corelang.constructible], change its stable id to [concepts.lib.corelang.defaultconstructible] and edit it as follows:]</ednote>

> > <tt>template &lt;class T&gt;</tt>
> > <tt>concept bool DefaultConstructible() {</tt>
> > <tt>&nbsp;&nbsp;return Constructible&lt;T&gt;()<ins>;</ins> <del>&amp;&amp;</del></tt>
> > <tt>&nbsp;&nbsp;&nbsp;&nbsp;<del>requires(const size_t n) {</del></tt>
> > <tt>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<del>new T[n]{}; // not required to be equality preserving</del></tt>
> > <tt>&nbsp;&nbsp;&nbsp;&nbsp;<del>};</del></tt>
> > <tt>}</tt>
>
> &#8203;<del>1 [ _Note:_ The array allocation expression `new T[n]{}` implicitly requires that `T` has a non-explicit default constructor. --_end note_ ]

<ednote>[_Editor's note:_ `DefaultConstructible<T>()` could trivially be replaced with `Constructible<T>()`. We are ambivalant about whether to remove `DefaultConstructible` or not, although we note that keeping it gives us the opportunity to augment this concept to require non-`explicit` default constructibility. Such a requirement is trivial to add, should the committee decide to.]</ednote>

<ednote>[_Editor's note:_ Move subsection "Concept `MoveConstructible`" ([concepts.lib.object.moveconstructible]) to subsection "Core language concepts" ([concepts.lib.corelang]) after [concepts.lib.corelang.defaultconstructible], change its stable id to [concepts.lib.corelang.moveconstructible] and edit it as follows:]</ednote>

> > <tt>template &lt;class T&gt;</tt>
> > <tt>concept bool MoveConstructible() {</tt>
> > <tt>&nbsp;&nbsp;return Constructible&lt;T, <del>remove_cv_t&lt;</del>T<del>&gt;&amp;&amp;</del>&gt;() &amp;&amp;</tt>
> > <tt>&nbsp;&nbsp;&nbsp;&nbsp;ConvertibleTo&lt;<del>remove_cv_t&lt;</del>T<del>&gt;&amp;&amp;</del>, T&gt;();</tt>
> > <tt>}</tt>
>
> 1 <ins>If `T` is an object type, then</ins> let `rv` be an rvalue of type <del>`remove_cv_t<`</del>`T`<del>`>`</del><ins> and `u2` a distinct object of type `T` equal to `rv`</ins>. <del>Then</del> `MoveConstructible<T>()` is satisfied only if
>
> > (1.1) -- After the definition `T u = rv;`, `u` is equal to <ins>`u2`</ins><del>the value of `rv` before the construction</del>.
> >
> > (1.2) -- `T{rv}` <del>or `*new T{rv}`</del> is equal to <ins>`u2`</ins><del>the value of `rv` before the construction</del>.
> >
> > &#8203;<ins>(1.3</ins><del>2</del><ins>) -- If `T` is not `const`,</ins> `rv`'s resulting state is valid but unspecified ([lib.types.movedfrom])<ins>; otherwise, it is unchanged</ins>.

<ednote>[_Editor's note:_ We no longer strip top-level `const` from the parameter to harmonize `MoveConstructible` with `is_move_constructible`. And as with `is_move_constructible`, `MoveConstructible<int&&>()` is `true`. See [LWG#2146](https://cplusplus.github.io/LWG/lwg-active.html#2146).</ednote>

<ednote>The description of `MoveConstructible` adds semantic requirements when `T` is an object type. It says nothing about non-object types because no additional semantic requirements are necessary.]</ednote>

<ednote>[_Editor's note:_ Move subsection "Concept `CopyConstructible`" ([concepts.lib.object.copyconstructible]) to subsection "Core language concepts" ([concepts.lib.corelang]) after [concepts.lib.corelang.moveconstructible], change its stable id to [concepts.lib.corelang.copyconstructible] and edit it as follows:]</ednote>

> > <tt>template &lt;class T&gt;</tt>
> > <tt>concept bool CopyConstructible() {</tt>
> > <tt>&nbsp;&nbsp;return MoveConstructible&lt;T&gt;() &amp;&amp;</tt>
> > <tt>&nbsp;&nbsp;&nbsp;&nbsp;<del>Constructible&lt;T, const remove_cv_t&lt;T&gt;&amp;&gt;() &amp;&amp;</del></tt>
> > <tt>&nbsp;&nbsp;&nbsp;&nbsp;<del>ConvertibleTo&lt;remove_cv_t&lt;T&gt;&amp;, T&gt;() &amp;&amp;</del></tt>
> > <tt>&nbsp;&nbsp;&nbsp;&nbsp;<del>ConvertibleTo&lt;const remove_cv_t&lt;T&gt;&amp;, T&gt;() &amp;&amp;</del></tt>
> > <tt>&nbsp;&nbsp;&nbsp;&nbsp;<del>ConvertibleTo&lt;const remove_cv_t&lt;T&gt;&amp;&amp;, T&gt;();</del></tt>
> > <tt>&nbsp;&nbsp;&nbsp;&nbsp;<ins>Constructible&lt;T, T&amp;&gt;() &amp;&amp; ConvertibleTo&lt;T&amp;, T&gt;() &amp;&amp;</ins></tt>
> > <tt>&nbsp;&nbsp;&nbsp;&nbsp;<ins>Constructible&lt;T, const T&amp;&gt;() &amp;&amp; ConvertibleTo&lt;const T&amp;, T&gt;() &amp;&amp;</ins></tt>
> > <tt>&nbsp;&nbsp;&nbsp;&nbsp;<ins>Constructible&lt;T, const T&gt;() &amp;&amp; ConvertibleTo&lt;const T, T&gt;();</ins></tt>
> > <tt>}</tt>
>
> 1 <ins>If `T` is an object type, then</ins> let `v` be an lvalue of type (possibly `const`) <del>`remove_cv_t<`</del>`T`<del>`>`</del> or an rvalue of type `const` <del>`remove_cv_t<`</del>`T`<del>`>`</del>. <del>Then</del> `CopyConstructible<T>()` is satisfied only if
>
> > (1.1) -- After the definition `T u = v;`, `u` is equal to `v`.
> >
> > (1.2) -- `T{v}` <del>or `*new T{v}`</del> is equal to `v`.

<ednote>[_Editor's note:_ As with `MoveConstructible`, we no longer strip top-level _cv_-qualifiers to bring `CopyConstructible` into harmony with `is_copy_constructible`.</ednote>

<ednote>Since `Constructible` no longer directly tests that `T(args...)` is a valid expression, it doesn't implicitly require the _cv_-qualified expression variants as described in subsection "Equality Preservation" ([concepts.lib.general.equality]/6). As a result, we needed to _explicitly_ add the additional requirements for `Constructible<T, T&>()` and `Constructible<T, const T&&>()`.</ednote>

<ednote>Like `MoveConstructible`, `CopyConstructible` adds no additional semantic requirements for non-object types.]</ednote>

<ednote>[_Editor's note:_ Edit subsection "Concept `Movable`" ([concepts.lib.object.movable]) as follows:]</ednote>

> > <tt>template &lt;class T&gt;</tt>
> > <tt>concept bool Movable() {</tt>
> > <tt>&nbsp;&nbsp;return <ins>is_object&lt;T&gt;::value &amp;&amp;</ins> MoveConstructible&lt;T&gt;() &amp;&amp;</tt>
> > <tt>&nbsp;&nbsp;&nbsp;&nbsp;Assignable&lt;T&amp;, T&gt;() &amp;&amp;</tt>
> > <tt>&nbsp;&nbsp;&nbsp;&nbsp;Swappable&lt;T&amp;&gt;();</tt>
> > <tt>}</tt>
>
> &#8203;<ins>1 There need not be any subsumption relationship between `Movable<T>()` and `is_object<T>::value`.

<ednote>[_Editor's note:_ `Movable` is the base concept of the `Regular` hierarchy. These concepts are concerned with value semantics. As such, it makes no sense for `Movable<int&&>()` to return `true` ([stl2#310](https://github.com/ericniebler/stl2/issues/310)). We add the requirement that `T` is an object type to resolve the issue. Since `Movable` is subsumed by `Copyable`, `Semiregular`, and `Regular`, these concepts will only ever by satisfied by object types.]</ednote>

<ednote>[_Editor's note:_ Edit subsection "Concept `Readable`" ([iterators.readable]) as follows (also includes the fix for [stl2#330](https://github.com/ericniebler/stl2/issues/330) and [stl2#399](https://github.com/ericniebler/stl2/issues/399)):]</ednote>

> > <tt>template &lt;class I<ins>n</ins>&gt;</tt>
> > <tt>concept bool Readable() {</tt>
> > <tt>&nbsp;&nbsp;<del>return Movable&lt;I&gt;() &amp; DefaultConstructible&lt;I&gt;() &amp;&amp;</del></tt>
> > <tt>&nbsp;&nbsp;<ins>return </ins>requires<del>(const I&amp; i)</del> {</tt>
> > <tt>&nbsp;&nbsp;&nbsp;&nbsp;typename value_type_t&lt;I<ins>n</ins>&gt;;</tt>
> > <tt>&nbsp;&nbsp;&nbsp;&nbsp;typename reference_t&lt;I<ins>n</ins>&gt;;</tt>
> > <tt>&nbsp;&nbsp;&nbsp;&nbsp;typename rvalue_reference_t&lt;I<ins>n</ins>&gt;;</tt>
> > <tt>&nbsp;&nbsp;&nbsp;&nbsp;<del>{ \*i } -&gt; Same&lt;reference_t&lt;I&gt;&gt;;</del></tt>
> > <tt>&nbsp;&nbsp;&nbsp;&nbsp;<del>{ ranges::iter_move(i) } -&gt; Same&lt;rvalue_reference_t&lt;I&gt;&gt;;</del></tt>
> > <tt>&nbsp;&nbsp;} &amp;&amp;</tt>
> > <tt>&nbsp;&nbsp;CommonReference&lt;reference_t&lt;I<ins>n</ins>&gt;<ins>&amp;&amp;</ins>, value_type_t&lt;I<ins>n</ins>&gt;&amp;&gt;() &amp;&amp;</tt>
> > <tt>&nbsp;&nbsp;CommonReference&lt;reference_t&lt;I<ins>n</ins>&gt;<ins>&amp;&amp;</ins>, rvalue_reference_t&lt;I<ins>n</ins>&gt;<ins>&amp;&amp;</ins>&gt;() &amp;&amp;</tt>
> > <tt>&nbsp;&nbsp;CommonReference&lt;rvalue_reference_t&lt;I<ins>n</ins>&gt;<ins>&amp;&amp;</ins>, const value_type_t&lt;I<ins>n</ins>&gt;&amp;&gt;();</tt>
> > <tt>}</tt>

<ednote>[_Editor's note:_ Edit subsection "Concept `Writable`" ([iterators.writable]) as follows (also includes the fixes for [stl2#381](https://github.com/ericniebler/stl2/issues/381) and [stl2#387](https://github.com/ericniebler/stl2/issues/387)):]</ednote>

> > <tt>template &lt;class Out, class T&gt;</tt>
> > <tt>concept bool Writable() {</tt>
> > <tt>&nbsp;&nbsp;return <del>Movable&lt;Out&gt;() &amp; DefaultConstructible&lt;Out&gt;() &amp;&amp;</del></tt>
> > <tt>&nbsp;&nbsp;&nbsp;&nbsp;requires(Out<ins>&amp;&amp;</ins> o, T&& t) {</tt>
> > <tt>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;\*o = std::forward&lt;T&gt;(t); // not required to be equality preserving</tt>
> > <tt>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<ins>\*std::forward&lt;Out&gt;(o) = std::forward&lt;T&gt;(t); // not required to be equality preserving</ins></tt>
> > <tt>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<ins>const_cast&lt;const reference_t&lt;Out&gt;&amp;&amp;&gt;(\*o) =</ins></tt>
> > <tt>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<ins>std::forward&lt;T&gt;(t); // not required to be equality preserving</ins></tt>
> > <tt>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<ins>const_cast&lt;const reference_t&lt;Out&gt;&amp;&amp;&gt;(\*std::forward&lt;Out&gt;(o)) =</ins></tt>
> > <tt>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<ins>std::forward&lt;T&gt;(t); // not required to be equality preserving</ins></tt>
> > <tt>&nbsp;&nbsp;&nbsp;&nbsp;};</tt>
> > <tt>}</tt>


# Acknowledgements

I would like to thank Casey Carter and Andrew Sutton for their review feedback.
