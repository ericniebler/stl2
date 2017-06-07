---
pagetitle: "Switch the Ranges TS to Use Variable Concepts"
title: "Switch the Ranges TS to Use Variable Concepts"
...

# Synopsis

Currently, the Ranges TS uses function-style concepts. That's because in a few places, concept names
are "overloaded". Rather than have some variable concepts and some function concepts, the Ranges TS
opted for function concepts everywhere. The has proven unsatisfactory, because it fills function
signatures with useless syntactic noise (e.g., `()`).

Also, committee in Kona (2016) expressed concern at there being multiple ways to define a concept.
There seemed interest in eliminating function-style concept definitions. The Ranges TS was given as
an example of where function-style concepts were used. But the Ranges TS does not need them and
would in fact probably be better off without them.

The reasons for dropping function-style concepts from the Ranges TS then are:

1. To eliminate syntactic noise.
2. To avoid depending on a feature that may get dropped.
3. To avoid being a reason to keep a little-loved feature.

The reasons for keeping function-style concepts in the Ranges TS are:

1. Love them or hate them, function-style concepts are a part of the Concepts TS as-published.
2. In several places, the Ranges TS defines concepts with similar semantic meaning but different
numbers of arguments; function-style concepts neatly captures this intent.

# Proposed Solution

We propose respecifying the Ranges TS in terms of variable-style concepts. There are three cases
to handle:

1. Non-overloaded concepts
2. Cross-type concepts
3. Variable-argument concepts

## Non-overloaded concepts

In the case of concepts that are not overloaded, changing to a variable concepts is purely a
syntactic rewrite. For example, the following function-style concept:

```c++
template <class T>
concept bool Movable() {
  return MoveConstructible<T>() &&
    Assignable<T&, T>() &&
    Swappable<T&>();
}
```

would become:

```c++
template <class T>
concept bool Movable =
  MoveConstructible<T> &&
  Assignable<T&, T> &&
  Swappable<T&>;
```

Obviously, all uses of this concept would also need to be changed to drop the trailing empty parens
("`()`").

## Cross-type concepts

Some binary concepts offer a unary form to mean "same type", such that `Concept<A>()` is
semantically identical to `Concept<A, A>()` (e.g., `EqualityComparable`). In these cases, a simple
rewrite into a variable form will not result in valid code, since variable concepts cannot be
overloaded. In these cases, we must find a different spelling for the unary and binary forms.

The suggestion is to use the sufffix `With` for the binary form. So, `EqualityComparable<int>` would
be roughly equivalent to `EqualityComparableWith<int, int>`. This follows the precedent set by the
type traits `is_swappable` and `is_swappable_with`.

The concepts in the Ranges TS that this applies to are:

- `EqualityComparable`
- `Swappable`
- `StrictTotallyOrdered`

This pattern also appears in the relation concepts:

- `Relation`
- `StrictWeakOrder`

However, the single-argument forms `Relation<R, T>()` and `StrictWeakOder<R, T>()` forms are used
nowhere in the Ranges TS and can simply be dropped with no impact.

## Variable-argument concepts

The concepts that have to do with callables naturally permit a variable number of arguments and
are best expressed using variadic parameters packs. However, the *indirect* callable concepts used
to constrain the higher-order STL algorithms are fixed-arity (not variadic) so as to be able to
check callability with the cross-product of the iterators' associated types. The STL algorithms
only ever deal with unary and binary callables, so the indirect callable concepts are "overloaded"
on zero, one, or two arguments.

The affected concepts are:

- `IndirectInvocable`
- `IndirectRegularInvocable`
- `IndirectPredicate`

(The concepts `IndirectRelation` and `IndirectStrictWeakOrder` are unaffected because they are not
overloaded.)

The concept `IndirectInvocable` is used to constrain the `for_each` algorithm, where the function
object it constrains is unary. So, we suggest dropping the nullary and binary forms of this concept
and renaming `IndirectInvocable` to `IndirectUnaryInvocable`.

Likewise, the concept `IndirectRegularInvocable` is used to constrain the `projected` class
template, where the function object it constrains is unary. So, we suggest dropping the nullary and
binary forms of this concept and renaming `IndirectRegularInvocable` to
`IndirectRegularUnaryInvocable`.

We observe that `IndirectPredicate` is only ever used to constrain unary or binary predicates, so
we suggest breaking that concepts into `IndirectUnaryPredicate` and `IndirectBinaryPredicate`.

# Discussion

Should the committee ever decide to permit variable-style concepts to be overloaded, we could
decide to revert the name changes proposed in this document. For example, we could offer
`EqualityComparable<A, B>` as an alternate syntax for `EqualityComparableWith<A, B>`, and deprecate
`EqualityComparableWith`.

## Alternative Solutions

The following solutions have been considered and dismissed.

### Leave Function-Style Intact

There is nothing wrong *per se* with leaving the concepts as function-style. The Ranges TS
is based on the Concepts TS as published, which supports the syntax.

This option comes with a few lasting costs. At every use of every concept defined in the Ranges TS,
the user will have to append a semantically meaningless set of empty parenthesis, a small cost,
surely, but one that adds up over time to a significant amount of syntactic noise.

Additionally, should the committee ever decide to drop function-style concepts, the Ranges TS would
be left behind. Compiler implementors would need to carry forward support for a language feature
that (possibly) never made it into the International Standard until such time as the Ranges TS as
published could be phased out. This situation is best avoided.

# Implementation Experience

All the interface changes suggested in this document have been implemented and tested in the
Ranges TS's reference implementation at https://github.com/CaseyCarter/cmcstl2. The change was
straightforward and unsurprising.

# Proposed Design

In all places in the document where concept checks are applied with a trailing set of empty parens
("`()`"), remove the parens.

## Section "Concepts library" ([concepts.lib])

In "Header `<experimental/ranges/concepts>` synopsis" ([concepts.lib.synopsis]), except where noted
below, change all the concept definitions from function-style concepts to variable-style concepts,
following the pattern for `Same` shown below:

<blockquote><tt>
template &lt;class T, class U&gt;<br/>
concept bool Same<del>() {</del><ins> =</ins><br/>
&nbsp;&nbsp;<del>return</del> <i>see below</i>;<br/>
<del>}</del>
</tt></blockquote>

Change the second (binary) forms of `Swappable`, `EqualityComparable`, and `StrictTotallyOrdered` as
follows:

<blockquote><tt>
template &lt;class T, class U&gt;<br/>
concept bool Swappable<ins>With</ins><del>() {</del><ins> =</ins><br/>
&nbsp;&nbsp;<del>return</del> <i>see below</i>;<br/>
<del>}</del>
</tt></blockquote>

<blockquote><tt>
template &lt;class T, class U&gt;<br/>
concept bool EqualityComparable<ins>With</ins><del>() {</del><ins> =</ins><br/>
&nbsp;&nbsp;<del>return</del> <i>see below</i>;<br/>
<del>}</del>
</tt></blockquote>

<blockquote><tt>
template &lt;class T, class U&gt;<br/>
concept bool StrictTotallyOrdered<ins>With</ins><del>() {</del><ins> =</ins><br/>
&nbsp;&nbsp;<del>return</del> <i>see below</i>;<br/>
<del>}</del>
</tt></blockquote>

In addition, remove the following two concept declarations:

<blockquote><tt><del>
template &lt;class R, class T&gt;<br/>
concept bool Relation() {<br/>
&nbsp;&nbsp;return see below;<br/>
}<br/>
<br/>
template &lt;class R, class T&gt;<br/>
concept bool StrictWeakOrder() {<br/>
&nbsp;&nbsp;return see below;<br/>
}
</del></tt></blockquote>

Make the corresponding edits in sections 7.3 [concepts.lib.corelang] through section 7.6
[Callable concepts], except as follows.

In section "Concept `Swappable`" ([concepts.lib.corelang.swappable]), change the name of the binary
form of `Swappable` to `SwappableWith` as follows:

<ednote>[ <i>Editorial note:</i> This includes the resolution of [ericniebler/stl2#155 "Comparison
concepts and reference types"](https://github.com/ericniebler/stl2/issues/155). ]</ednote>

<blockquote><tt>
template &lt;class T&gt;<br/>
concept bool Swappable<del>() {</del><ins> =</ins><br/>
&nbsp;&nbsp;<del>return</del> requires(T&amp;&amp; a, T&amp;&amp; b) {<br/>
&nbsp;&nbsp;&nbsp;&nbsp;ranges::swap(std::forward&lt;T&gt;(a), std::forward&lt;T&gt;(b));<br/>
&nbsp;&nbsp;};<br/>
<del>}</del><br/>
<br/>
template &lt;class T, class U&gt;<br/>
concept bool Swappable<ins>With =</ins><del>() {</del><br/>
&nbsp;&nbsp;return Swappable&lt;T&gt;<del>()</del> &amp;&amp;<br/>
&nbsp;&nbsp;&nbsp;&nbsp;Swappable&lt;U&gt;<del>()</del> &amp;&amp;<br/>
&nbsp;&nbsp;&nbsp;&nbsp;CommonReference&lt;<br/>
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;const remove_reference_t&lt;T&gt;&amp;,<br/>
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;const remove_reference_t&lt;U&gt;&amp;&gt;<del>()</del> &amp;&amp;<br/>
&nbsp;&nbsp;&nbsp;&nbsp;requires(T&amp;&amp; t, U&amp;&amp; u) {<br/>
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;ranges::swap(std::forward&lt;T&gt;(t), std::forward&lt;U&gt;(u));<br/>
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;ranges::swap(std::forward&lt;U&gt;(u), std::forward&lt;T&gt;(t));<br/>
&nbsp;&nbsp;&nbsp;&nbsp;};<br/>
<del>}</del>
</tt></blockquote>

In [concepts.lib.corelang.swappable]/p2, change the two occurrances of `Swappable<T, U>()` to
`SwappableWith<T, U>`.

Change section "Concept `Relation`" ([concepts.lib.callable.relation]) as follows:

<ednote>[ <i>Editorial note:</i> This includes the resolution of [ericniebler/stl2#155 "Comparison
concepts and reference types"](https://github.com/ericniebler/stl2/issues/155). ]</ednote>

<blockquote><tt><del>
template &lt;class R, class T&gt;<br/>
concept bool Relation() {<br/>
&nbsp;&nbsp;return Predicate&lt;R, T, T&gt;;<br/>
}<br/></del>
<br/>
template &lt;class R, class T, class U&gt;<br/>
concept bool Relation<del>() {</del><ins> =</ins><br/>
&nbsp;&nbsp;<del>return Relation</del><ins>Predicate</ins>&lt;R, T<ins>, T</ins>&gt;<del>()</del> &amp;&amp;<br/>
&nbsp;&nbsp;&nbsp;&nbsp;<del>Relation</del><ins>Predicate</ins>&lt;R, U<ins>, U</ins>&gt;<del>()</del> &amp;&amp;<br/>
&nbsp;&nbsp;&nbsp;&nbsp;CommonReference&lt;<br/>
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;const remove_reference_t&lt;T&gt;&amp;,<br/>
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;const remove_reference_t&lt;U&gt;&amp;&gt;<del>()</del> &amp;&amp;<br/>
&nbsp;&nbsp;&nbsp;&nbsp;<del>Relation</del><ins>Predicate</ins>&lt;R,<br/>
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<ins>common_reference_t&lt;</ins><br/>
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<ins>const remove_reference_t&lt;T&gt;&amp;,</ins><br/>
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<ins>const remove_reference_t&lt;U&gt;&amp;&gt;,</ins><br/>
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;common_reference_t&lt;<br/>
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;const remove_reference_t&lt;T&gt;&amp;,<br/>
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;const remove_reference_t&lt;U&gt;&amp;&gt;&gt;<del>()</del> &amp;&amp;<br/>
&nbsp;&nbsp;&nbsp;&nbsp;Predicate&lt;R, T, U&gt;<del>()</del> &amp;&amp;<br/>
&nbsp;&nbsp;&nbsp;&nbsp;Predicate&lt;R, U, T&gt;<del>()</del>;<br/>
<del>}</del>
</tt></blockquote>

Change section "Concept `StrictWeakOrder`" ([concepts.lib.callable.strictweakorder]) as follows:

<blockquote><tt><del>
template &lt;class R, class T&gt;<br/>
concept bool StrictWeakOrder() {<br/>
&nbsp;&nbsp;return Relation&lt;R, T&gt;();<br/>
}<br/></del>
<br/>
template &lt;class R, class T, class U&gt;<br/>
concept bool StrictWeakOrder<del>() {</del><ins> =</ins><br/>
&nbsp;&nbsp;<del>return</del> Relation&lt;R, T, U&gt;<del>()</del>;<br/>
<del>}</del>
</tt></blockquote>

## Section "General utilities library" ([utilities])

Change section "Header `<experimental/ranges/utility>` synopsis" ([utility]/p2) as follows:

<blockquote><tt>
// 8.5.2, struct with named accessors<br/>
template &lt;class T&gt;<br/>
concept bool TagSpecifier<del>() {</del><ins> =</ins><br/>
&nbsp;&nbsp;<del>return</del> <i>see below</i> ;<br/>
<del>}</del><br/>
<br/>
template &lt;class F&gt;<br/>
concept bool TaggedType<del>() {</del><ins> =</ins><br/>
&nbsp;&nbsp;<del>return</del> <i>see below</i> ;<br/>
<del>}</del>
</tt></blockquote>

Make the accompanying edit to the definitions of `TagSpecifier` and `TaggedType` in section
"Class template `tagged`" [taggedtup.tagged]/p2.

In the declarations of `equal_to<void>::operator()` and `not_equal_to<void>::operator()` in section
"Comparisons" [comparisons]/p8-9, change `EqualityComparable<T, U>()` to
`EqualityComparableWith<T, U>`.

In the declarations of `greater<void>::operator()`, `less<void>::operator()`,
`greater_equal<void>::operator()`, and `less_equal<void>::operator()` in section
"Comparisons" [comparisons]/p10-13, change `StrictTotallyOrdered<T, U>()` to
`StrictTotallyOrderedWith<T, U>`.

## Section "Iterators library" ([iterators])

In "Header `<experimental/ranges/iterators>` synopsis" ([concepts.lib.synopsis]), except where noted
below, change all the function-style concept definitions to variable-style concepts.

In section "Header `<experimental/ranges/iterator>` synopsis" ([iterator.synopsis]), make the
following changes:

<blockquote><tt>
// 9.4, indirect callable requirements:</br>
// 9.4.2, indirect callables:</br>
<del>template &lt;class F&gt;</br>
concept bool IndirectInvocable() {</br>
&nbsp;&nbsp;return <i>see below</i> ;</br>
}</del></br>
template &lt;class F, class I&gt;</br>
concept bool Indirect<ins>Unary</ins>Invocable<del>() {</del><ins> =</ins></br>
&nbsp;&nbsp;<del>return</del> <i>see below</i> ;</br>
<del>}</del></br>
<del>template &lt;class F, class I1, class I2&gt;</br>
concept bool IndirectInvocable() {</br>
&nbsp;&nbsp;return <i>see below</i> ;</br>
}</del></br>
<del>template &lt;class F&gt;</br>
concept bool IndirectRegularInvocable() {</br>
&nbsp;&nbsp;return <i>see below</i> ;</br>
}</del></br>
template &lt;class F, class I&gt;</br>
concept bool IndirectRegular<ins>Unary</ins>Invocable<del>() {</del><ins> =</ins></br>
&nbsp;&nbsp;<del>return</del> <i>see below</i> ;</br>
<del>}</del></br>
<del>template &lt;class F, class I1, class I2&gt;</br>
concept bool IndirectRegularInvocable() {</br>
&nbsp;&nbsp;return <i>see below</i> ;</br>
}</del></br>
template &lt;class F, class I&gt;</br>
concept bool Indirect<ins>Unary</ins>Predicate<del>() {</del><ins> =</ins></br>
&nbsp;&nbsp;<del>return</del> <i>see below</i> ;</br>
<del>}</del></br>
template &lt;class F, class I1, class I2&gt;</br>
concept bool Indirect<ins>Binary</ins>Predicate<del>() {</del><ins> =</ins></br>
&nbsp;&nbsp;<del>return</del> <i>see below</i> ;</br>
<del>}</del></br>
</br>
[...]</br>
</br>
// 9.4.3, projected:</br>
template &lt;Readable I, IndirectRegular<ins>Unary</ins>Invocable&lt;I&gt; Proj&gt;</br>
struct projected;</br>
</br>
[...]</br>
</br>
// 9.7, predefined iterators and sentinels:</br>
// 9.7.1, reverse iterators:</br>
template &lt;BidirectionalIterator I&gt; class reverse_iterator;</br>
</br>
template &lt;class I1, class I2&gt;</br>
&nbsp;&nbsp;&nbsp;&nbsp;requires EqualityComparable<ins>With</ins>&lt;I1, I2&gt;<del>()</del></br>
&nbsp;&nbsp;bool operator==(</br>
&nbsp;&nbsp;&nbsp;&nbsp;const reverse_iterator&lt;I1&gt;&amp; x,</br>
&nbsp;&nbsp;&nbsp;&nbsp;const reverse_iterator&lt;I2&gt;&amp; y);</br>
template &lt;class I1, class I2&gt;</br>
&nbsp;&nbsp;&nbsp;&nbsp;requires EqualityComparable<ins>With</ins>&lt;I1, I2&gt;<del>()</del></br>
&nbsp;&nbsp;bool operator!=(</br>
&nbsp;&nbsp;&nbsp;&nbsp;const reverse_iterator&lt;I1&gt;&amp; x,</br>
&nbsp;&nbsp;&nbsp;&nbsp;const reverse_iterator&lt;I2&gt;&amp; y);</br>
template &lt;class I1, class I2&gt;</br>
&nbsp;&nbsp;&nbsp;&nbsp;requires StrictTotallyOrdered<ins>With</ins>&lt;I1, I2&gt;<del>()</del></br>
&nbsp;&nbsp;bool operator&lt;(</br>
&nbsp;&nbsp;&nbsp;&nbsp;const reverse_iterator&lt;I1&gt;&amp; x,</br>
&nbsp;&nbsp;&nbsp;&nbsp;const reverse_iterator&lt;I2&gt;&amp; y);</br>
template &lt;class I1, class I2&gt;</br>
requires StrictTotallyOrdered<ins>With</ins>&lt;I1, I2&gt;<del>()</del></br>
&nbsp;&nbsp;bool operator&gt;(</br>
&nbsp;&nbsp;&nbsp;&nbsp;const reverse_iterator&lt;I1&gt;&amp; x,</br>
&nbsp;&nbsp;&nbsp;&nbsp;const reverse_iterator&lt;I2&gt;&amp; y);</br>
template &lt;class I1, class I2&gt;</br>
requires StrictTotallyOrdered<ins>With</ins>&lt;I1, I2&gt;<del>()</del></br>
&nbsp;&nbsp;bool operator&gt;=(</br>
&nbsp;&nbsp;&nbsp;&nbsp;const reverse_iterator&lt;I1&gt;&amp; x,</br>
&nbsp;&nbsp;&nbsp;&nbsp;const reverse_iterator&lt;I2&gt;&amp; y);</br>
template &lt;class I1, class I2&gt;</br>
requires StrictTotallyOrdered<ins>With</ins>&lt;I1, I2&gt;<del>()</del></br>
&nbsp;&nbsp;bool operator&lt;=(</br>
&nbsp;&nbsp;&nbsp;&nbsp;const reverse_iterator&lt;I1&gt;&amp; x,</br>
&nbsp;&nbsp;&nbsp;&nbsp;const reverse_iterator&lt;I2&gt;&amp; y);</br>
</br>
[...]</br>
</br>
// 9.7.3, move iterators and sentinels:</br>
template &lt;InputIterator I&gt; class move_iterator;</br>
template &lt;class I1, class I2&gt;</br>
&nbsp;&nbsp;&nbsp;&nbsp;requires EqualityComparable<ins>With</ins>&lt;I1, I2&gt;<del>()</del></br>
&nbsp;&nbsp;bool operator==(</br>
&nbsp;&nbsp;&nbsp;&nbsp;const move_iterator&lt;I1&gt;&amp; x, const move_iterator&lt;I2&gt;&amp; y);</br>
template &lt;class I1, class I2&gt;</br>
&nbsp;&nbsp;&nbsp;&nbsp;requires EqualityComparable<ins>With</ins>&lt;I1, I2&gt;<del>()</del></br>
&nbsp;&nbsp;bool operator!=(</br>
&nbsp;&nbsp;&nbsp;&nbsp;const move_iterator&lt;I1&gt;&amp; x, const move_iterator&lt;I2&gt;&amp; y);</br>
template &lt;class I1, class I2&gt;</br>
&nbsp;&nbsp;&nbsp;&nbsp;requires StrictTotallyOrdered<ins>With</ins>&lt;I1, I2&gt;<del>()</del></br>
&nbsp;&nbsp;bool operator&lt;(</br>
&nbsp;&nbsp;&nbsp;&nbsp;const move_iterator&lt;I1&gt;&amp; x, const move_iterator&lt;I2&gt;&amp; y);</br>
template &lt;class I1, class I2&gt;</br>
&nbsp;&nbsp;&nbsp;&nbsp;requires StrictTotallyOrdered<ins>With</ins>&lt;I1, I2&gt;<del>()</del></br>
&nbsp;&nbsp;bool operator&lt;=(</br>
&nbsp;&nbsp;&nbsp;&nbsp;const move_iterator&lt;I1&gt;&amp; x, const move_iterator&lt;I2&gt;&amp; y);</br>
template &lt;class I1, class I2&gt;</br>
&nbsp;&nbsp;&nbsp;&nbsp;requires StrictTotallyOrdered<ins>With</ins>&lt;I1, I2&gt;<del>()</del></br>
&nbsp;&nbsp;bool operator&gt;(</br>
&nbsp;&nbsp;&nbsp;&nbsp;const move_iterator&lt;I1&gt;&amp; x, const move_iterator&lt;I2&gt;&amp; y);</br>
template &lt;class I1, class I2&gt;</br>
&nbsp;&nbsp;&nbsp;&nbsp;requires StrictTotallyOrdered<ins>With</ins>&lt;I1, I2&gt;<del>()</del></br>
&nbsp;&nbsp;bool operator&gt;=(</br>
&nbsp;&nbsp;&nbsp;&nbsp;const move_iterator&lt;I1&gt;&amp; x, const move_iterator&lt;I2&gt;&amp; y);</br>
</br>
[...]</br>
</br>
template &lt;class I1, class I2, Sentinel&lt;I2&gt; S1, Sentinel&lt;I1&gt; S2&gt;</br>
&nbsp;&nbsp;bool operator==(</br>
&nbsp;&nbsp;&nbsp;&nbsp;const common_iterator&lt;I1, S1&gt;&amp; x, const common_iterator&lt;I2, S2&gt;&amp; y);</br>
template &lt;class I1, class I2, Sentinel&lt;I2&gt; S1, Sentinel&lt;I1&gt; S2&gt;</br>
&nbsp;&nbsp;&nbsp;&nbsp;requires EqualityComparable<ins>With</ins>&lt;I1, I2&gt;<del>()</del></br>
&nbsp;&nbsp;bool operator==(</br>
&nbsp;&nbsp;&nbsp;&nbsp;const common_iterator&lt;I1, S1&gt;&amp; x, const common_iterator&lt;I2, S2&gt;&amp; y);</br>
template &lt;class I1, class I2, Sentinel&lt;I2&gt; S1, Sentinel&lt;I1&gt; S2&gt;</br>
&nbsp;&nbsp;bool operator!=(</br>
&nbsp;&nbsp;&nbsp;&nbsp;const common_iterator&lt;I1, S1&gt;&amp; x, const common_iterator&lt;I2, S2&gt;&amp; y);</br>
</tt></blockquote>

<ednote>[<i>Editorial note:</i> The resolution of [ericniebler/stl2#286](
https://github.com/ericniebler/stl2/issues/286) changes `indirect_result_of` to no longer use
`IndirectInvocable`, so no change is necessary there. -- <i>end note</i>]</ednote>

Change section "Indirect callables" [indirectcallable.indirectinvocable] as follows:

<blockquote><tt>
<del>template &lt;class F&gt;</br>
concept bool IndirectInvocable() {</br>
&nbsp;&nbsp;return CopyConstructible&lt;F&gt;() &amp;&amp;</br>
&nbsp;&nbsp;&nbsp;&nbsp;Invocable&lt;F&amp;&gt;();</br>
}</del></br>
template &lt;class F, class I&gt;</br>
concept bool Indirect<ins>Unary</ins>Invocable<del>() {</del><ins> =</ins></br>
&nbsp;&nbsp;<del>return</del> Readable&lt;I&gt;<del>()</del> &amp;&amp;</br>
&nbsp;&nbsp;&nbsp;&nbsp;CopyConstructible&lt;F&gt;<del>()</del> &amp;&amp;</br>
&nbsp;&nbsp;&nbsp;&nbsp;Invocable&lt;F&amp;, value_type_t&lt;I&gt;&amp;&gt;<del>()</del> &amp;&amp;</br>
&nbsp;&nbsp;&nbsp;&nbsp;Invocable&lt;F&amp;, reference_t&lt;I&gt;&gt;<del>()</del> &amp;&amp;</br>
&nbsp;&nbsp;&nbsp;&nbsp;Invocable&lt;F&amp;, iter_common_reference_t&lt;I&gt;&gt;<del>()</del>;</br>
<del>}</del></br>
<del>template &lt;class F, class I1, class I2&gt;</br>
concept bool IndirectInvocable() {</br>
&nbsp;&nbsp;return Readable&lt;I1&gt;() &amp;&amp; Readable&lt;I2&gt;() &amp;&amp;</br>
&nbsp;&nbsp;&nbsp;&nbsp;CopyConstructible&lt;F&gt;() &amp;&amp;</br>
&nbsp;&nbsp;&nbsp;&nbsp;Invocable&lt;F&amp;, value_type_t&lt;I1&gt;&amp;, value_type_t&lt;I2&gt;&amp;&gt;() &amp;&amp;</br>
&nbsp;&nbsp;&nbsp;&nbsp;Invocable&lt;F&amp;, value_type_t&lt;I1&gt;&amp;, reference_t&lt;I2&gt;&gt;() &amp;&amp;</br>
&nbsp;&nbsp;&nbsp;&nbsp;Invocable&lt;F&amp;, reference_t&lt;I1&gt;, value_type_t&lt;I2&gt;&amp;&gt;() &amp;&amp;</br>
&nbsp;&nbsp;&nbsp;&nbsp;Invocable&lt;F&amp;, reference_t&lt;I1&gt;, reference_t&lt;I2&gt;&gt;() &amp;&amp;</br>
&nbsp;&nbsp;&nbsp;&nbsp;Invocable&lt;F&amp;, iter_common_reference_t&lt;I1&gt;, iter_common_reference_t&lt;I2&gt;&gt;();</br>
}</br>
</br>
template &lt;class F&gt;</br>
concept bool IndirectRegularInvocable() {</br>
&nbsp;&nbsp;return CopyConstructible&lt;F&gt;() &amp;&amp;</br>
&nbsp;&nbsp;&nbsp;&nbsp;RegularInvocable&lt;F&amp;&gt;();</br>
}</del></br>
template &lt;class F, class I&gt;</br>
concept bool IndirectRegular<ins>Unary</ins>Invocable<del>() {</del><ins> =</ins></br>
&nbsp;&nbsp;<del>return</del> Readable&lt;I&gt;<del>()</del> &amp;&amp;</br>
&nbsp;&nbsp;&nbsp;&nbsp;CopyConstructible&lt;F&gt;<del>()</del> &amp;&amp;</br>
&nbsp;&nbsp;&nbsp;&nbsp;RegularInvocable&lt;F&amp;, value_type_t&lt;I&gt;&amp;&gt;<del>()</del> &amp;&amp;</br>
&nbsp;&nbsp;&nbsp;&nbsp;RegularInvocable&lt;F&amp;, reference_t&lt;I&gt;&gt;<del>()</del> &amp;&amp;</br>
&nbsp;&nbsp;&nbsp;&nbsp;RegularInvocable&lt;F&amp;, iter_common_reference_t&lt;I&gt;&gt;<del>()</del>;</br>
<del>}</del></br>
<del>template &lt;class F, class I1, class I2&gt;</br>
concept bool IndirectRegularInvocable() {</br>
&nbsp;&nbsp;return Readable&lt;I1&gt;() &amp;&amp; Readable&lt;I2&gt;() &amp;&amp;</br>
&nbsp;&nbsp;&nbsp;&nbsp;CopyConstructible&lt;F&gt;() &amp;&amp;</br>
&nbsp;&nbsp;&nbsp;&nbsp;RegularInvocable&lt;F&amp;, value_type_t&lt;I1&gt;&amp;, value_type_t&lt;I2&gt;&amp;&gt;() &amp;&amp;</br>
&nbsp;&nbsp;&nbsp;&nbsp;RegularInvocable&lt;F&amp;, value_type_t&lt;I1&gt;&amp;, reference_t&lt;I2&gt;&gt;() &amp;&amp;</br>
&nbsp;&nbsp;&nbsp;&nbsp;RegularInvocable&lt;F&amp;, reference_t&lt;I1&gt;, value_type_t&lt;I2&gt;&amp;&gt;() &amp;&amp;</br>
&nbsp;&nbsp;&nbsp;&nbsp;RegularInvocable&lt;F&amp;, reference_t&lt;I1&gt;, reference_t&lt;I2&gt;&gt;() &amp;&amp;</br>
&nbsp;&nbsp;&nbsp;&nbsp;RegularInvocable&lt;F&amp;, iter_common_reference_t&lt;I1&gt;, iter_common_reference_t&lt;I2&gt;&gt;();</br>
}</del></br>
</br>
template &lt;class F, class I&gt;</br>
concept bool Indirect<ins>Unary</ins>Predicate<del>() {</del><ins> =</ins></br>
&nbsp;&nbsp;<del>return</del> Readable&lt;I&gt;<del>()</del> &amp;&amp;</br>
&nbsp;&nbsp;&nbsp;&nbsp;CopyConstructible&lt;F&gt;<del>()</del> &amp;&amp;</br>
&nbsp;&nbsp;&nbsp;&nbsp;Predicate&lt;F&amp;, value_type_t&lt;I&gt;&amp;&gt;<del>()</del> &amp;&amp;</br>
&nbsp;&nbsp;&nbsp;&nbsp;Predicate&lt;F&amp;, reference_t&lt;I&gt;&gt;<del>()</del> &amp;&amp;</br>
&nbsp;&nbsp;&nbsp;&nbsp;Predicate&lt;F&amp;, iter_common_reference_t&lt;I&gt;&gt;<del>()</del>;</br>
<del>}</del></br>
template &lt;class F, class I1, class I2&gt;</br>
concept bool Indirect<ins>Binary</ins>Predicate<del>() {</del><ins> =</ins></br>
&nbsp;&nbsp;<del>return</del> Readable&lt;I1&gt;<del>()</del> &amp;&amp; Readable&lt;I2&gt;<del>()</del> &amp;&amp;</br>
&nbsp;&nbsp;&nbsp;&nbsp;CopyConstructible&lt;F&gt;<del>()</del> &amp;&amp;</br>
&nbsp;&nbsp;&nbsp;&nbsp;Predicate&lt;F&amp;, value_type_t&lt;I1&gt;&amp;, value_type_t&lt;I2&gt;&amp;&gt;<del>()</del> &amp;&amp;</br>
&nbsp;&nbsp;&nbsp;&nbsp;Predicate&lt;F&amp;, value_type_t&lt;I1&gt;&amp;, reference_t&lt;I2&gt;&gt;<del>()</del> &amp;&amp;</br>
&nbsp;&nbsp;&nbsp;&nbsp;Predicate&lt;F&amp;, reference_t&lt;I1&gt;, value_type_t&lt;I2&gt;&amp;&gt;<del>()</del> &amp;&amp;</br>
&nbsp;&nbsp;&nbsp;&nbsp;Predicate&lt;F&amp;, reference_t&lt;I1&gt;, reference_t&lt;I2&gt;&gt;<del>()</del> &amp;&amp;</br>
&nbsp;&nbsp;&nbsp;&nbsp;Predicate&lt;F&amp;, iter_common_reference_t&lt;I1&gt;, iter_common_reference_t&lt;I2&gt;&gt;<del>()</del>;</br>
<del>}</del></br>
</tt></blockquote>

In section "Class template `projected`" ([projected]), change the occurance of
`IndirectRegularInvocable` to `IndirectRegularUnaryInvocable`.

In [commonalgoreq.general]/p2, change the note to read:

> [...] `equal_to<>` requires its arguments satisfy <tt>EqualityComparable<ins>With</ins></tt> (7.4.3), and
> `less<>` requires its arguments satisfy <tt>StrictTotallyOrdered<ins>With</ins></tt> (7.4.4). [...]

In section "Class template `reverse_iterator`" ([reverse.iterator]), in the synopsis and in definitions
of the relational operators ([reverse.iter.op==] through [reverse.iter.op<=]), change
`EqualityComparable<I1, I2>()` to `EqualityComparableWith<I1, I2>`, and change 
`StrictTotallyOrdered<I1, I2>()` to `StrictTotallyOrderedWith<I1, I2>` as shown above in the
`<experimental/ranges/iterator>` synopsis ([iterator.synopsis]).

In section "Class template `move_iterator`" ([move.iterator]), in the synopsis (p2) and in definitions
of the relational operators ([[move.iter.op.comp]]), change `EqualityComparable<I1, I2>()` to
`EqualityComparableWith<I1, I2>`, and change  `StrictTotallyOrdered<I1, I2>()` to
`StrictTotallyOrderedWith<I1, I2>` as shown above in the `<experimental/ranges/iterator>` synopsis
([iterator.synopsis]).

In section "Class template `move_sentinel`" ([move.sentinel]), in the `move_if` example in para 2,
change `IndirectPredicate` to `IndirectUnaryPredicate`.

In section "Class template `common_iterator`" ([common.iterator]), in the synopsis (p2) and in definitions
of the relational operators ([[common.iter.op.comp]]), change `EqualityComparable<I1, I2>()` to
`EqualityComparableWith<I1, I2>` as shown above in the `<experimental/ranges/iterator>` synopsis
([iterator.synopsis]).

In section "Range requirements" ([ranges.requirements]), change all function-style concept definitions
to variable-style concept definitions.


## Section "Algorithms library" [algorithms]


# Acknowledgements

I would like to thank Casey Carter for his review feedback.
