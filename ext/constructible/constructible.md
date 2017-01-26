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

Although well-intentioned, many of the extra semantic requirements have proved to be problematic in practice. Here, for instance, are five currently open [stl2](https://github.com/ericniebler/stl2) bugs that need resolution:

- "Why do neither reference types nor array types satisfy `Destructible`?" ([stl2#70](https://github.com/ericniebler/stl2/issues/70)).
- "Is it intended that `Constructible<int&, long&>()` is true?" ([stl2#301](https://github.com/ericniebler/stl2/issues/301)).
- "`Movable<int&&>()` is `true` and it should probably be `false`" ([stl2#310](https://github.com/ericniebler/stl2/issues/310)).
- "Is it intended that an aggregate with a deleted or nonexistent default constructor satisfy `DefaultConstructible`?" ([stl2#300](https://github.com/ericniebler/stl2/issues/300)).
- "Assignable concept looks wrong" ([stl2#229](https://github.com/ericniebler/stl2/issues/229)).

In addition we repeatedly have to answer questions about why concepts with names similar to associated type traits gives different answers for different types and type categories. It's confusing.

On the other hand, we want to resist the temptation to constrain the library with semantically meaningless, purely syntactic concepts.

# Solution

At the high level, the solution this paper suggests is to break the object concepts into two groups: the lower-level concepts that are largely syntactic (with light semantic constraints), and the higher-level concepts that enforce more semantically meaningful clusters of requirements.

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

Edit subsection "Concept `Destructible`" ([concepts.lib.object.destructible]) as follows:

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
> > &#8203;<del>(3.1) - After evaluating the expression `t.~T()`, `delete p`, or `delete[] p`, all resources owned by the denoted object(s) are reclaimed.</del>
> > 
> > (3.<del>2</del><ins>1</ins>) - `&t == std::addressof(t)`.
> > 
> > (3.<del>3</del><ins>2</ins>) - The expression `&t` is non-modifying.
