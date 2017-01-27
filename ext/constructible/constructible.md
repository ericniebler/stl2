---
pagetitle: Assorted Object Concept Fixes
title: Assorted Object Concept Fixes
...

# Synopsis

This paper suggests reformulations of the following fundamental object concepts to resolve a number of outstanding issues, and to bring them in line with (what experience has show to be) user expectations:

- `Destructible`
- `Constructible`
- `DefaultConstructible`
- `MoveConstructible`
- `CopyConstructible`
- `Assignable`

The suggested changes make them behave more like what their associated type traits do.

In addition, we suggest a change to `Movable` that correctly positions it as the base concept of the more semanticallly meaningful `Regular` concept heirarchy.

# Problem description

The Palo Alto report (N3351), on which the design of the Ranges TS is based, suggested the object concepts `Semiregular` and `Regular` for constraining standard library components. In an appendix it conceeds that many generic components could more usefully be constrained with decompositions of these very coarse concepts: `Movable` and `Copyable`.

While implementing a constrained STL, the authors of the Ranges TS found that even more fine-grained "object" concepts were often useful: `MoveConstructible`,  `CopyConstructible`, `Assignable`, and others. These concepts are needed to avoid over-constraining low-level library utilities like `pair`, `tuple`, `variant` and more. Rather than aping the similarly named type-traits, the authors of the Ranges TS tried to preserve the intent of the Palo Alto report by giving them semantic weight. It did this in various ways, including:

- Requiring that destructible objects can have their address taken.
- Requiring that destructible objects can have their destructor called explicitly.
- Requiring that constructible objects are destructible.
- Testing that objects could be allocated and deallocated in dynamic as well as automatic storage. 
- Testing that default constructors are not `explicit`.

Although well-intentioned, many of the extra semantic requirements have proved to be problematic in practice. Here, for instance, are seven currently open [stl2](https://github.com/ericniebler/stl2) bugs that need resolution:

- "Why do neither reference types nor array types satisfy `Destructible`?" ([stl2#70](https://github.com/ericniebler/stl2/issues/70)).
- "Is it intended that `Constructible<int&, long&>()` is true?" ([stl2#301](https://github.com/ericniebler/stl2/issues/301)).
- "`Movable<int&&>()` is `true` and it should probably be `false`" ([stl2#310](https://github.com/ericniebler/stl2/issues/310)).
- "Is it intended that an aggregate with a deleted or nonexistent default constructor satisfy `DefaultConstructible`?" ([stl2#300](https://github.com/ericniebler/stl2/issues/300)).
- "Assignable concept looks wrong" ([stl2#229](https://github.com/ericniebler/stl2/issues/229)).
- "MoveConstructible<T>() != std::is_move_constructible<T>()"  ([stl2#313](https://github.com/ericniebler/stl2/issues/313)).
- "Subsumption and object concepts" ([CaseyCarter/stl2#22](https://github.com/CaseyCarter/stl2/issues/22)).

We were also motivated by the very real user confusion about why concepts with names similar to associated type traits gives different answers for different types and type categories.

It remains our intention to resist the temptation to constrain the library with semantically meaningless, purely syntactic concepts.

# Solution

At the high level, the solution this paper suggests is to break the object concepts into two logical groups: the lower-level concepts that are largely syntactic (with light semantic constraints), and the higher-level concepts that enforce more semantically meaningful clusters of requirements.

The lower-level concepts are those that have corresponding type traits, and behave largely like them:

- `Destructible`
- `Constructible`
- `DefaultConstructible`
- `MoveConstructible`
- `CopyConstructible`
- `Assignable`

The higher-level concepts are those that the Palo Alto report describes, and are satisfied by object types only:

- `Movable`
- `Copyable`
- `Semiregular`
- `Regular`

# Proposed Resolution

<ednote>Edit subsection "Concept `Assignable`" ([concepts.lib.corelang.assignable]) as follows:</ednote>

> > <tt>template &lt;class T, class U&gt;</tt>
> > <tt>concept bool Assignable() {</tt>
> > <tt>&nbsp;&nbsp;<del>return CommonReference&lt;const T&amp;, const U&amp;&gt;() &amp;&amp; requires(T&amp;&amp; t, U&amp;&amp; u) {</del></tt>
> > <tt>&nbsp;&nbsp;&nbsp;&nbsp;<del>{ std::forward&lt;T&gt;(t) = std::forward&lt;U&gt;(u) } -&gt; Same&lt;T&amp;&gt;;</del></tt>
> > <tt>&nbsp;&nbsp;<ins>return Same&lt;T, decay_t&lt;T&gt;&amp;&gt;() &amp;&amp;</ins></tt>
> > <tt>&nbsp;&nbsp;&nbsp;&nbsp;<ins>CommonReference&lt;T, const U&amp;&gt;() &amp;&amp;</ins></tt>
> > <tt>&nbsp;&nbsp;&nbsp;&nbsp;<ins>requires(T t, U&amp;&amp; u) {</ins></tt>
> > <tt>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<ins>{ t = std::forward&lt;U&gt;(u) } -&gt; Same&lt;T&gt;;</ins></tt>
> > <tt>&nbsp;&nbsp;&nbsp;&nbsp;};</tt>
> > <tt>}</tt>
>
> 1 <del>Let `t` be an lvalue of type `T`, and `R` be the type `remove_reference_t<U>`. If `U` is an lvalue reference type, let `v` be an lvalue of type `R`; otherwise, let `v` be an rvalue of type `R`. Let `uu` be a distinct object of type `R` such that `uu` is equal to `v`.</del><ins>Let `t` be an lvalue which refers to an object `o` such that `decltype((t))` is `T`, and `u` an expression such that `decltype((u))` is `U`. Let `u2` be a distinct object that is equal to `u`.</ins> Then `Assignable<T, U>()` is satisfied if and only if
> 
> > (1.1) -- <tt>std::addressof(t = <del>v</del><ins>u</ins>) == std::addressof(<del>t</del><ins>o</ins>)</tt>.
> > 
> > (1.2) -- After evaluating <tt>t = <del>v</del><ins>u</ins></tt>:
> > 
> > > (1.2.1) -- `t` is equal to <tt><del>uu</del><ins>u2</ins></tt>.
> > > 
> > > (1.2.2) -- If <del>`v`</del><ins>`u`</ins> is a non-`const` <del>rvalue, its</del><ins>xvalue, the</ins> resulting state <ins>of the object to which it refers</ins> is unspecified. [ _Note:_ <del>`v`</del><ins>the object</ins> must still meet the requirements of the library component that is using it. The operations listed in those requirements must work as specified. -- end note ]
> > > 
> > > (1.2.3) -- Otherwise, <del>`v`</del><ins>if `u` is a glvalue, the object to which it refers</ins> is not modified.

<ednote>Edit subsection "Concept `Destructible`" ([concepts.lib.object.destructible]) as follows:</ednote>

> 1 The `Destructible` concept is the base of the hierarchy of object concepts. It specifies properties that all such object types have in common.
> 
> > <tt>template &lt;class T&gt;</tt>
> > <tt>concept bool Destructible() {</tt>
> > <tt>&nbsp;&nbsp;<del>return requires(T t, const T ct, T* p) {</del></tt>
> > <tt>&nbsp;&nbsp;&nbsp;&nbsp;<del>{ t.~T() } noexcept;</del></tt>
> > <tt>&nbsp;&nbsp;&nbsp;&nbsp;<del>{ &amp;t } -&gt; Same&lt;T\*&gt;; // not required to be equality preserving</del></tt>
> > <tt>&nbsp;&nbsp;&nbsp;&nbsp;<del>{ &amp;ct } -&gt; Same&lt;const T\*&gt;; // not required to be equality preserving</del></tt>
> > <tt>&nbsp;&nbsp;&nbsp;&nbsp;<del>delete p;</del></tt>
> > <tt>&nbsp;&nbsp;&nbsp;&nbsp;<del>delete[] p;</del></tt>
> > <tt>&nbsp;&nbsp;<ins>return is_nothrow_destructible&lt;T&gt;::value &amp;&amp;</ins></tt>
> > <tt>&nbsp;&nbsp;&nbsp;&nbsp;<ins>requires (T&amp; t, const T&amp; ct) {</ins></tt>
> > <tt>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<ins>{ &t } -&gt; Same&lt;add_pointer_t&lt;T&gt;&gt;; // not required to be equality preserving</ins></tt>
> > <tt>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<ins>{ &ct } -&gt; Same&lt;add_pointer_t&lt;const T&gt;&gt;; // not required to be equality preserving</ins></tt>
> > <tt>&nbsp;&nbsp;&nbsp;&nbsp;};</tt>
> > <tt>}</tt>
> 
> 2 The expression requirement `&ct` does not require implicit expression variants.
> 
> 3 Given a (possibly `const`) lvalue `t` of type <tt><ins>remove_reference_t&lt;</ins>T<ins>&gt;</ins></tt><del> and pointer `p` of type `T*`</del>,  `Destructible<T>()` is satisfied if and only if
> 
> > &#8203;<del>(3.1) -- After evaluating the expression `t.~T()`, `delete p`, or `delete[] p`, all resources owned by the denoted object(s) are reclaimed.</del>
> > 
> > (3.<del>2</del><ins>1</ins>) -- `&t == std::addressof(t)`.
> > 
> > (3.<del>3</del><ins>2</ins>) -- The expression `&t` is non-modifying.

<ednote>Edit subsection "Concept `Constructible`" ([concepts.lib.object.constructible]) as follows:</ednote>

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
> > <tt>&nbsp;&nbsp;<ins>return Destructible&lt;T&gt;() && is_constructible&lt;T, Args.\..&gt;::value;</ins></tt>
> > <tt>}</tt>
>
> <ins>2 For types `T` and `Args...` to satisfy `Constructible`, the variable definition `T t(declval<Args>()...);` need not be equality preserving.<ins>

<ednote>Edit subsection "Concept `DefaultConstructible`" ([concepts.lib.object.defaultconstructible]) as follows:</ednote>

> > <tt>template &lt;class T, class..\. Args&gt;</tt>
> > <tt>concept bool DefaultConstructible() {</tt>
> > <tt>&nbsp;&nbsp;return Constructible&lt;T&gt;()<ins>;</ins> <del>&amp;&amp;</del></tt>
> > <tt>&nbsp;&nbsp;&nbsp;&nbsp;<del>requires(const size_t n) {</del></tt>
> > <tt>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<del>new T[n]{}; // not required to be equality preserving</del></tt>
> > <tt>&nbsp;&nbsp;&nbsp;&nbsp;<del>};</del></tt>
> > <tt>}</tt>
> 
> &#8203;<del>1 [ _Note:_ The array allocation expression `new T[n]{}` implicitly requires that `T` has a non-explicit default constructor. --_end note_ ]

<ednote>Edit subsection "Concept `MoveConstructible`" ([concepts.lib.object.moveconstructible]) as follows:</ednote>

> > <tt>template &lt;class T&gt;</tt>
> > <tt>concept bool MoveConstructible() {</tt>
> > <tt>&nbsp;&nbsp;return Constructible&lt;T, <del>remove_cv_t&lt;</del>T<del>&gt;</del>&amp;&amp;&gt;() &amp;&amp;</tt>
> > <tt>&nbsp;&nbsp;&nbsp;&nbsp;ConvertibleTo&lt;<del>remove_cv_t&lt;</del>T<del>&gt;</del>&amp;&amp;, T&gt;();</tt>
> > <tt>}</tt>
> 
> 1 <ins>If `T` is an object type, then</ins>
>
> > &#8203;<ins>(1.1)</ins> Let `rv` be an rvalue of type <del>`remove_cv_t<`</del>`T`<del>`>`</del>. Then `MoveConstructible<T>()` is satisfied if and only if
> >
> > > (<ins>1.</ins>1.1) -- After the definition `T u = rv;`, `u` is equal to the value of `rv` before the construction.
> > > 
> > > (<ins>1.</ins>1.2) -- `T{rv}` <del>or `*new T{rv}`</del> is equal to the value of `rv` before the construction.
> > 
> > &#8203;<ins>(1.</ins>2<ins>) If `T` is not `const`,</ins> `rv`'s resulting state is unspecified<ins>; otherwise, it is unchanged</ins>. [ _Note:_ `rv` must still meet the requirements of the library component that is using it. The operations listed in those requirements must work as specified whether `rv` has been moved from or not. --_end note_ ]

<ednote>Edit subsection "Concept `CopyConstructible`" ([concepts.lib.object.copyconstructible]) as follows:</ednote>

> > <tt>template &lt;class T&gt;</tt>
> > <tt>concept bool CopyConstructible() {</tt>
> > <tt>&nbsp;&nbsp;return MoveConstructible&lt;T&gt;() &amp;&amp;</tt>
> > <tt>&nbsp;&nbsp;&nbsp;&nbsp;<del>Constructible&lt;T, const remove_cv_t&lt;T&gt;&amp;&gt;() &amp;&amp;</del></tt>
> > <tt>&nbsp;&nbsp;&nbsp;&nbsp;<del>ConvertibleTo&lt;remove_cv_t&lt;T&gt;&amp;, T&gt;() &amp;&amp;</del></tt>
> > <tt>&nbsp;&nbsp;&nbsp;&nbsp;<del>ConvertibleTo&lt;const remove_cv_t&lt;T&gt;&amp;, T&gt;() &amp;&amp;</del></tt>
> > <tt>&nbsp;&nbsp;&nbsp;&nbsp;<del>ConvertibleTo&lt;const remove_cv_t&lt;T&gt;&amp;&amp;, T&gt;();</del></tt>
> > <tt>&nbsp;&nbsp;&nbsp;&nbsp;<ins>Constructible&lt;T, T&amp;&gt;() &amp;&amp; ConvertibleTo&lt;T&amp;, T&gt;() &amp;&amp;</ins></tt>
> > <tt>&nbsp;&nbsp;&nbsp;&nbsp;<ins>Constructible&lt;T, const T&amp;&gt;() &amp;&amp; ConvertibleTo&lt;const T&amp;, T&gt;() &amp;&amp;</ins></tt>
> > <tt>&nbsp;&nbsp;&nbsp;&nbsp;<ins>Constructible&lt;T, const T&amp;&amp;&gt;() &amp;&amp; ConvertibleTo&lt;const T&amp;&amp;, T&gt;();</ins></tt>
> > <tt>}</tt>
> 
> 1 <ins>If `T` is an object type, then</ins>
>
> > &#8203;<ins>(1.1)</ins> Let `v` be an lvalue of type (possibly `const`) <del>`remove_cv_t<`</del>`T`<del>`>`</del> or an rvalue of type `const` <del>`remove_cv_t<`</del>`T`<del>`>`</del>. Then `CopyConstructible<T>()` is satisfied if and only if
> > 
> > > (<ins>1.</ins>1.1) -- After the definition `T u = v;`, `v` is equal to `u`.
> > > 
> > > (<ins>1.</ins>1.2) -- `T{v}` <del>or `*new T{v}`</del> is equal to `v`.

<ednote>Edit subsection "Concept `Movable`" ([concepts.lib.object.movable]) as follows:</ednote>

> > <tt>template &lt;class T&gt;</tt>
> > <tt>concept bool Movable() {</tt>
> > <tt>&nbsp;&nbsp;return <ins>is_object&lt;T&gt;::value &amp;&amp;</ins> MoveConstructible&lt;T&gt;() &amp;&amp;</tt>
> > <tt>&nbsp;&nbsp;&nbsp;&nbsp;Assignable&lt;T&amp;, T&gt;() &amp;&amp;</tt>
> > <tt>&nbsp;&nbsp;&nbsp;&nbsp;Swappable&lt;T&amp;&gt;();</tt>
> > <tt>}</tt>
