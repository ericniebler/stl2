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
2. To eliminate user confusion that comes at a concept's point-of-use, where sometimes parens are
needed (in `requires` clauses) and sometimes not (when the concept is used as a placeholder).
3. To avoid depending on a feature that may get dropped.
4. To avoid becoming a reason to keep a little-loved feature.

There is really only one reason for keeping function-style concepts in the Ranges TS:

1. In several places, the Ranges TS defines concepts with similar semantic meaning but different
numbers of parameters; function-style concepts neatly captures this intent by allowing these
concepts to share a name.

# Revision History
## R1
* Restore the `()` that were inadvertently ommitted from the `Swappable` constraints on the members of class `tagged`, and then strike them.

# Proposed Solution

We propose respecifying the Ranges TS in terms of variable-style concepts. There are three cases
to handle:

1. Non-overloaded concepts
2. Cross-type concepts
3. Variable-argument concepts

## Non-overloaded concepts

In the case of concepts that are not overloaded, changing to variable concepts is purely a
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
("`()`"), if any.

## Cross-type concepts

Some binary concepts offer a unary form to mean "same type", such that `Concept<A>()` is
semantically identical to `Concept<A, A>()` (e.g., `EqualityComparable`). In these cases, a simple
rewrite into a variable form will not result in valid code, since variable concepts cannot be
overloaded. In these cases, we must find a different spelling for the unary and binary forms.

The suggestion is to use the suffix `With` for the binary form. So, `EqualityComparable<int>` would
be roughly equivalent to `EqualityComparableWith<int, int>`. This follows the precedent set by the
type traits `is_swappable` and `is_swappable_with`.

The concepts in the Ranges TS to which this applies are:

- `EqualityComparable`
- `Swappable`
- `StrictTotallyOrdered`

This pattern also appears in the relation concepts:

- `Relation`
- `StrictWeakOrder`

However, the forms `Relation<R, T>()` and `StrictWeakOrder<R, T>()` are used nowhere in the Ranges
TS and can simply be dropped with no impact.

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

We observe that `IndirectPredicate` is only ever used to constrain unary predicates (once we fix
[ericniebler/stl2#411](https://github.com/ericniebler/stl2/issues/411)), so we suggest dropping the binary form and renaming `IndirectPredicate`
to `IndirectUnaryPredicate`.

# Discussion

Should the committee ever decide to permit variable-style concepts to be overloaded, we could
decide to revert the name changes proposed in this document. For example, we could offer
`EqualityComparable<A, B>` as an alternate syntax for `EqualityComparableWith<A, B>`, and deprecate
`EqualityComparableWith`.

## Alternative Solutions

The following solutions have been considered and dismissed.

### Leave Function-Style Intact

There is nothing wrong *per se* with leaving the concepts as function-style. The Ranges TS
is based on the Concepts TS as published, which supports the syntax. Giving up function-style
concepts forces us to come up with unique names for semantically similar things, including the
admittedly awful `IndirectUnaryInvocable` and friends.

This option comes with a few lasting costs, already discussed above. We feel the costs of sticking
with function-style concepts outweigh the benefits of being able to "overload" concept names.

# Implementation Experience

All the interface changes suggested in this document have been implemented and tested in the
Ranges TS's reference implementation at https://github.com/CaseyCarter/cmcstl2. The change was
straightforward and unsurprising.

# Proposed Design

<ednote>[ *Editorial note:* In places where a purely mechanical transformation is sufficient, rather
than show all the diffs (which would be overwhelming and tend to obsure the more meaningful edits),
we describe the transformation, give an example, and instruct the editor to make the mechanical
change everywhere applicable. In other cases, where concepts change name or need to be respecified,
the changes are shown explicitly with diff marks. ]</ednote>

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

In the section "Concept `Movable` ([concepts.lib.object.movable]), change the definition of
`Movable` as follows (includes changes from [P0547R1](http://wg21.link/P0547R1) and
[ericniebler/stl2#174 "Swappable concept and P0185 swappable traits"](
https://github.com/ericniebler/stl2/issues/174)):

<blockquote><tt>
template &lt;class T&gt;</br>
concept bool Movable<del>() {</del><ins> =</ins></br>
&nbsp;&nbsp;<del>return</del> std::is_object&lt;T&gt;::value &amp;&amp; // <i>see below</i></br>
&nbsp;&nbsp;&nbsp;&nbsp;MoveConstructible&lt;T&gt; &amp;&amp;</br>
&nbsp;&nbsp;&nbsp;&nbsp;Assignable&lt;T&amp;, T&gt; &amp;&amp;</br>
&nbsp;&nbsp;&nbsp;&nbsp;Swappable&lt;T<del>&amp;</del>&gt;;</br>
<del>}</del><br/>
</tt></blockquote>

In section "Concept `Swappable`" ([concepts.lib.corelang.swappable]), change the name of the binary
form of `Swappable` to `SwappableWith` as follows:

<ednote>[ <i>Editorial note:</i> This includes the resolutions of [ericniebler/stl2#155 "Comparison
concepts and reference types"](https://github.com/ericniebler/stl2/issues/155) and
[ericniebler/stl2#174 "Swappable concept and P0185 swappable traits"](
https://github.com/ericniebler/stl2/issues/174). ]</ednote>

<blockquote><tt>
template &lt;class T&gt;<br/>
concept bool Swappable<del>() {</del><ins> =</ins><br/>
&nbsp;&nbsp;<del>return</del> requires(T&amp;<del>&amp;</del> a, T&amp;<del>&amp;</del> b) {<br/>
&nbsp;&nbsp;&nbsp;&nbsp;ranges::swap(<del>std::forward&lt;T&gt;(</del>a<del>)</del>, <del>std::forward&lt;T&gt;(</del>b<del>)</del>);<br/>
&nbsp;&nbsp;};<br/>
<del>}</del><br/>
<br/>
template &lt;class T, class U&gt;<br/>
concept bool Swappable<ins>With =</ins><del>() {</del><br/>
&nbsp;&nbsp;<del>return Swappable&lt;T&gt;() &amp;&amp;</del><br/>
&nbsp;&nbsp;&nbsp;&nbsp;<del>Swappable&lt;U&gt;() &amp;&amp;</del><br/>
&nbsp;&nbsp;&nbsp;&nbsp;CommonReference&lt;<br/>
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;const remove_reference_t&lt;T&gt;&amp;,<br/>
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;const remove_reference_t&lt;U&gt;&amp;&gt;<del>()</del> &amp;&amp;<br/>
&nbsp;&nbsp;&nbsp;&nbsp;requires(T&amp;&amp; t, U&amp;&amp; u) {<br/>
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<ins>ranges::swap(std::forward&lt;T&gt;(t), std::forward&lt;T&gt;(t));</ins><br/>
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<ins>ranges::swap(std::forward&lt;U&gt;(u), std::forward&lt;U&gt;(u));</ins><br/>
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;ranges::swap(std::forward&lt;T&gt;(t), std::forward&lt;U&gt;(u));<br/>
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;ranges::swap(std::forward&lt;U&gt;(u), std::forward&lt;T&gt;(t));<br/>
&nbsp;&nbsp;&nbsp;&nbsp;};<br/>
<del>}</del>
</tt></blockquote>

In [concepts.lib.corelang.swappable]/p2, change the two occurrences of `Swappable<T, U>()` to
`SwappableWith<T, U>`.

Change section "Concept `EqualityComparable`" ([concepts.lib.compare.equalitycomparable])/p3-4 as
follows:

<blockquote>
3 [ <i>Note:</i> The requirement that the expression <tt>a == b</tt> is equality preserving implies that</br>
<tt>==</tt> is reflexive, transitive, and symmetric. <i>-- end note</i> ]</br>
</br>
<blockquote><tt>
template &lt;class T, class U&gt;</br>
concept bool EqualityComparable<ins>With</ins><del>() {</del><ins> =</ins></br>
&nbsp;&nbsp;<del>return</del></br>
&nbsp;&nbsp;&nbsp;&nbsp;EqualityComparable&lt;T&gt;<del>()</del> &amp;&amp;</br>
&nbsp;&nbsp;&nbsp;&nbsp;EqualityComparable&lt;U&gt;<del>()</del> &amp;&amp;</br>
&nbsp;&nbsp;&nbsp;&nbsp;CommonReference&lt;</br>
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;const remove_reference_t&lt;T&gt;&amp;,</br>
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;const remove_reference_t&lt;U&gt;&amp;><del>()</del> &amp;&amp;</br>
&nbsp;&nbsp;&nbsp;&nbsp;EqualityComparable&lt;</br>
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;common_reference_t&lt;</br>
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;const remove_reference_t&lt;T&gt;&amp;,</br>
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;const remove_reference_t&lt;U&gt;&amp;&gt;&gt;<del>()</del> &amp;&amp;</br>
&nbsp;&nbsp;&nbsp;&nbsp;WeaklyEqualityComparable&lt;T, U&gt;<del>()</del>;</br>
<del>}</del></br>
</tt></blockquote>
</br>
4 Let <tt>a</tt> be a <tt>const</tt> lvalue of type <tt>remove_reference_t&lt;T&gt;</tt>, <tt>b</tt> be a <tt>const</tt> lvalue of type</br>
<tt>remove_reference_t&lt;U&gt;</tt>, and <tt>C</tt> be <tt>common_reference_t&lt;const remove_reference_t&lt;T&gt;&amp;,</br>
const remove_reference_t&lt;U&gt;&amp;&gt;</tt>. Then <tt>EqualityComparable<ins>With</ins>&lt;T, U&gt;<del>()</del></tt> is satisfied if</br>
and only if:</br>
</br>
(4.1) -- <tt>bool(t == u) == bool(C(t) == C(u))</tt>.</br>
</blockquote>

<ednote>[<i>Note:</i>This includes the resolution of [ericniebler/stl2#155](
  https://github.com/ericniebler/stl2/issues/155). ] </ednote>

In section "Concept `StrictTotallyOrdered`" ([concepts.lib.corelang.stricttotallyordered]), change the name of the binary
form of `StrictTotallyOrdered` to `StrictTotallyOrderedWith` as follows:

<ednote>[ <i>Editorial note:</i> This includes the resolution of [ericniebler/stl2#155 "Comparison
concepts and reference types"](https://github.com/ericniebler/stl2/issues/155). ]</ednote>

<blockquote><tt>
template &lt;class T&gt;<br/>
concept bool StrictTotallyOrdered<ins>With</ins><del>() {</del><ins> =</ins><br/>
&nbsp;&nbsp;<del>return</del><br/>
&nbsp;&nbsp;&nbsp;&nbsp;StrictTotallyOrdered&lt;T&gt;<del>()</del> &amp;&amp;</br>
&nbsp;&nbsp;&nbsp;&nbsp;StrictTotallyOrdered&lt;U&gt;<del>()</del> &amp;&amp;</br>
&nbsp;&nbsp;&nbsp;&nbsp;CommonReference&lt;</br>
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;const remove_reference_t&lt;T&gt;&amp;,</br>
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;const remove_reference_t&lt;U&gt;&amp;&gt;<del>()</del> &amp;&amp;</br>
&nbsp;&nbsp;&nbsp;&nbsp;StrictTotallyOrdered&lt;</br>
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;common_reference_t&lt;</br>
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;const remove_reference_t&lt;T&gt;&amp;,</br>
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;const remove_reference_t&lt;U&gt;&amp;&gt;&gt;<del>()</del> &amp;&amp;</br>
&nbsp;&nbsp;&nbsp;&nbsp;EqualityComparable<ins>With</ins>&lt;T, U&gt;<del>()</del> &amp;&amp;</br>
&nbsp;&nbsp;&nbsp;&nbsp;requires(const remove_reference_t&lt;T&gt;&amp; t,</br>
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;const remove_reference_t&lt;U&gt;&amp; u) {</br>
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;{ t &lt; u } -&gt; Boolean&amp;&amp;;</br>
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;{ t &gt; u } -&gt; Boolean&amp;&amp;;</br>
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;{ t &lt;= u } -&gt; Boolean&amp;&amp;;</br>
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;{ t &gt;= u } -&gt; Boolean&amp;&amp;;</br>
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;{ u &lt; t } -&gt; Boolean&amp;&amp;;</br>
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;{ u &gt; t } -&gt; Boolean&amp;&amp;;</br>
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;{ u &lt;= t } -&gt; Boolean&amp;&amp;;</br>
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;{ u &gt;= t } -&gt; Boolean&amp;&amp;;</br>
&nbsp;&nbsp;&nbsp;&nbsp;};</br>
<del>}</del>
</tt></blockquote>

In [concepts.lib.corelang.stricttotallyordered]/p2, change the occurrence of
`StrictTotallyOrdered<T, U>()` to `StrictTotallyOrderedWith<T, U>`.

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

Change section "Header `<experimental/ranges/utility>` synopsis" ([utility]/p2) as follows
(includes the resolution of [ericniebler/stl2#174 "Swappable concept and P0185 swappable traits"](
https://github.com/ericniebler/stl2/issues/174)):

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
<del>}</del><br/>
<br/>
template &lt;class Base, TagSpecifier... Tags&gt;<br/>
&nbsp;&nbsp;requires sizeof...(Tags) &lt;= tuple_size&lt;Base&gt;::value<br/>
struct tagged : <br/>
&nbsp;&nbsp;[...]<br/>
&nbsp;&nbsp;tagged&amp; operator=(U&amp;&amp; u) noexcept(<i>see below</i>);<br/>
&nbsp;&nbsp;void swap(tagged&amp; that) noexcept(<i>see below</i>)<br/>
&nbsp;&nbsp;&nbsp;&nbsp;requires Swappable&lt;Base<del>&amp;</del>&gt;<del>()</del>;<br/>
&nbsp;&nbsp;friend void swap(tagged&amp;, tagged&amp;) noexcept(<i>see below</i>)<br/>
&nbsp;&nbsp;&nbsp;&nbsp;requires Swappable&lt;Base<del>&amp;</del>&gt;<del>()</del>;<br/>
};<br/>
</tt></blockquote>

Make the accompanying edit to the definitions of `TagSpecifier` and `TaggedType` in section
"Class template `tagged`" [taggedtup.tagged]/p2, and to the detailed specifications of
`tagged::swap` and the non-member `swap(tagged&, tagged&)` overload in
[taggedtup.tagged]/p20 and p23


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
<del>template &lt;class F, class I1, class I2&gt;</br>
concept bool IndirectPredicate() {</br>
&nbsp;&nbsp;return <i>see below</i> ;</br>
}</del></br>
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
<del>template &lt;class F, class I1, class I2&gt;</br>
concept bool IndirectPredicate() {</br>
&nbsp;&nbsp;return Readable&lt;I1&gt;() &amp;&amp; Readable&lt;I2&gt;() &amp;&amp;</br>
&nbsp;&nbsp;&nbsp;&nbsp;CopyConstructible&lt;F&gt;() &amp;&amp;</br>
&nbsp;&nbsp;&nbsp;&nbsp;Predicate&lt;F&amp;, value_type_t&lt;I1&gt;&amp;, value_type_t&lt;I2&gt;&amp;&gt;() &amp;&amp;</br>
&nbsp;&nbsp;&nbsp;&nbsp;Predicate&lt;F&amp;, value_type_t&lt;I1&gt;&amp;, reference_t&lt;I2&gt;&gt;() &amp;&amp;</br>
&nbsp;&nbsp;&nbsp;&nbsp;Predicate&lt;F&amp;, reference_t&lt;I1&gt;, value_type_t&lt;I2&gt;&amp;&gt;() &amp;&amp;</br>
&nbsp;&nbsp;&nbsp;&nbsp;Predicate&lt;F&amp;, reference_t&lt;I1&gt;, reference_t&lt;I2&gt;&gt;() &amp;&amp;</br>
&nbsp;&nbsp;&nbsp;&nbsp;Predicate&lt;F&amp;, iter_common_reference_t&lt;I1&gt;, iter_common_reference_t&lt;I2&gt;&gt;();</br>
}</del></br>
</tt></blockquote>

In section "Class template `projected`" ([projected]), change the occurrence of
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

In "Header `<experimental/ranges/algorithm>` synopsis" ([algorithms.general]/p2), make the following
changes:

<blockquote><tt>
template &lt;InputIterator I, Sentinel&lt;I&gt; S, class Proj = identity,</br>
&nbsp;&nbsp;&nbsp;&nbsp;Indirect<ins>Unary</ins>Predicate&lt;projected&lt;I, Proj&gt;&gt; Pred&gt;</br>
&nbsp;&nbsp;bool all_of(I first, S last, Pred pred, Proj proj = Proj{});</br>
template &lt;InputRange Rng, class Proj = identity,</br>
&nbsp;&nbsp;&nbsp;&nbsp;Indirect<ins>Unary</ins>Predicate&lt;projected&lt;iterator_t&lt;Rng&gt;, Proj&gt;&gt; Pred&gt;</br>
&nbsp;&nbsp;bool all_of(Rng&amp;&amp; rng, Pred pred, Proj proj = Proj{});</br>
</br>
template &lt;InputIterator I, Sentinel&lt;I&gt; S, class Proj = identity,</br>
&nbsp;&nbsp;&nbsp;&nbsp;Indirect<ins>Unary</ins>Predicate&lt;projected&lt;I, Proj&gt;&gt; Pred&gt;</br>
&nbsp;&nbsp;bool any_of(I first, S last, Pred pred, Proj proj = Proj{});</br>
template &lt;InputRange Rng, class Proj = identity,</br>
&nbsp;&nbsp;&nbsp;&nbsp;Indirect<ins>Unary</ins>Predicate&lt;projected&lt;iterator_t&lt;Rng&gt;, Proj&gt;&gt; Pred&gt;</br>
&nbsp;&nbsp;bool any_of(Rng&amp;&amp; rng, Pred pred, Proj proj = Proj{});</br>
</br>
template &lt;InputIterator I, Sentinel&lt;I&gt; S, class Proj = identity,</br>
&nbsp;&nbsp;&nbsp;&nbsp;Indirect<ins>Unary</ins>Predicate&lt;projected&lt;I, Proj&gt;&gt; Pred&gt;</br>
&nbsp;&nbsp;bool none_of(I first, S last, Pred pred, Proj proj = Proj{});</br>
template &lt;InputRange Rng, class Proj = identity,</br>
&nbsp;&nbsp;&nbsp;&nbsp;Indirect<ins>Unary</ins>Predicate&lt;projected&lt;iterator_t&lt;Rng&gt;, Proj&gt;&gt; Pred&gt;</br>
&nbsp;&nbsp;bool none_of(Rng&amp;&amp; rng, Pred pred, Proj proj = Proj{});</br>
</br>
template &lt;InputIterator I, Sentinel&lt;I&gt; S, class Proj = identity,</br>
&nbsp;&nbsp;&nbsp;&nbsp;Indirect<ins>Unary</ins>Invocable&lt;projected&lt;I, Proj&gt;&gt; Fun&gt;</br>
&nbsp;&nbsp;tagged_pair&lt;tag::in(I), tag::fun(Fun)&gt;</br>
&nbsp;&nbsp;&nbsp;&nbsp;for_each(I first, S last, Fun f, Proj proj = Proj{});</br>
template &lt;InputRange Rng, class Proj = identity,</br>
&nbsp;&nbsp;&nbsp;&nbsp;Indirect<ins>Unary</ins>Invocable&lt;projected&lt;iterator_t&lt;Rng&gt;, Proj&gt;&gt; Fun&gt;</br>
&nbsp;&nbsp;tagged_pair&lt;tag::in(safe_iterator_t&lt;Rng&gt;), tag::fun(Fun)&gt;</br>
&nbsp;&nbsp;&nbsp;&nbsp;for_each(Rng&amp;&amp; rng, Fun f, Proj proj = Proj{});</br>
</br>
[...]</br>
</br>
template &lt;InputIterator I, Sentinel&lt;I&gt; S, class Proj = identity,</br>
&nbsp;&nbsp;&nbsp;&nbsp;Indirect<ins>Unary</ins>Predicate&lt;projected&lt;I, Proj&gt;&gt; Pred&gt;</br>
&nbsp;&nbsp;I find_if(I first, S last, Pred pred, Proj proj = Proj{});</br>
template &lt;InputRange Rng, class Proj = identity,</br>
&nbsp;&nbsp;&nbsp;&nbsp;Indirect<ins>Unary</ins>Predicate&lt;projected&lt;iterator_t&lt;Rng&gt;, Proj&gt;&gt; Pred&gt;</br>
&nbsp;&nbsp;safe_iterator_t&lt;Rng&gt;</br>
&nbsp;&nbsp;&nbsp;&nbsp;find_if(Rng&amp;&amp; rng, Pred pred, Proj proj = Proj{});</br>
</br>
template &lt;InputIterator I, Sentinel&lt;I&gt; S, class Proj = identity,</br>
&nbsp;&nbsp;&nbsp;&nbsp;Indirect<ins>Unary</ins>Predicate&lt;projected&lt;I, Proj&gt;&gt; Pred&gt;</br>
&nbsp;&nbsp;I find_if_not(I first, S last, Pred pred, Proj proj = Proj{});</br>
template &lt;InputRange Rng, class Proj = identity,</br>
&nbsp;&nbsp;&nbsp;&nbsp;Indirect<ins>Unary</ins>Predicate&lt;projected&lt;iterator_t&lt;Rng&gt;, Proj&gt;&gt; Pred&gt;</br>
&nbsp;&nbsp;safe_iterator_t&lt;Rng&gt;</br>
&nbsp;&nbsp;&nbsp;&nbsp;find_if_not(Rng&amp;&amp; rng, Pred pred, Proj proj = Proj{});</br>
</br>
[...]</br>
</br>
template &lt;InputIterator I, Sentinel&lt;I&gt; S, class Proj = identity,</br>
&nbsp;&nbsp;&nbsp;&nbsp;Indirect<ins>Unary</ins>Predicate&lt;projected&lt;I, Proj&gt;&gt; Pred&gt;</br>
&nbsp;&nbsp;difference_type_t&lt;I&gt;</br>
&nbsp;&nbsp;&nbsp;&nbsp;count_if(I first, S last, Pred pred, Proj proj = Proj{});</br>
template &lt;InputRange Rng, class Proj = identity,</br>
&nbsp;&nbsp;&nbsp;&nbsp;Indirect<ins>Unary</ins>Predicate&lt;projected&lt;iterator_t&lt;Rng&gt;, Proj&gt;&gt; Pred&gt;</br>
&nbsp;&nbsp;difference_type_t&lt;iterator_t&lt;Rng&gt;&gt;</br>
&nbsp;&nbsp;&nbsp;&nbsp;count_if(Rng&amp;&amp; rng, Pred pred, Proj proj = Proj{});</br>
</br>
[...]</br>
</br>
template &lt;InputIterator I, Sentinel&lt;I&gt; S, WeaklyIncrementable O, class Proj = identity,</br>
&nbsp;&nbsp;&nbsp;&nbsp;Indirect<ins>Unary</ins>Predicate&lt;projected&lt;I, Proj&gt;&gt; Pred&gt;</br>
&nbsp;&nbsp;requires IndirectlyCopyable&lt;I, O&gt;<del>()</del></br>
&nbsp;&nbsp;tagged_pair&lt;tag::in(I), tag::out(O)&gt;</br>
&nbsp;&nbsp;&nbsp;&nbsp;copy_if(I first, S last, O result, Pred pred, Proj proj = Proj{});</br>
template &lt;InputRange Rng, WeaklyIncrementable O, class Proj = identity,</br>
&nbsp;&nbsp;&nbsp;&nbsp;Indirect<ins>Unary</ins>Predicate&lt;projected&lt;iterator_t&lt;Rng&gt;, Proj&gt;&gt; Pred&gt;</br>
&nbsp;&nbsp;requires IndirectlyCopyable&lt;iterator_t&lt;Rng&gt;, O&gt;<del>()</del></br>
&nbsp;&nbsp;tagged_pair&lt;tag::in(safe_iterator_t&lt;Rng&gt;), tag::out(O)&gt;</br>
&nbsp;&nbsp;&nbsp;&nbsp;copy_if(Rng&amp;&amp; rng, O result, Pred pred, Proj proj = Proj{});</br>
</br>
[...]</br>
</br>
template &lt;ForwardIterator I, Sentinel&lt;I&gt; S, class T, class Proj = identity,</br>
&nbsp;&nbsp;&nbsp;&nbsp;Indirect<ins>Unary</ins>Predicate&lt;projected&lt;I, Proj&gt;&gt; Pred&gt;</br>
&nbsp;&nbsp;requires Writable&lt;I, const T&amp;&gt;<del>()</del></br>
&nbsp;&nbsp;I</br>
&nbsp;&nbsp;&nbsp;&nbsp;replace_if(I first, S last, Pred pred, const T&amp; new_value, Proj proj = Proj{});</br>
template &lt;ForwardRange Rng, class T, class Proj = identity,</br>
&nbsp;&nbsp;&nbsp;&nbsp;Indirect<ins>Unary</ins>Predicate&lt;projected&lt;iterator_t&lt;Rng&gt;, Proj&gt;&gt; Pred&gt;</br>
&nbsp;&nbsp;requires Writable&lt;iterator_t&lt;Rng&gt;, const T&amp;&gt;<del>()</del></br>
&nbsp;&nbsp;safe_iterator_t&lt;Rng&gt;</br>
&nbsp;&nbsp;&nbsp;&nbsp;replace_if(Rng&amp;&amp; rng, Pred pred, const T&amp; new_value, Proj proj = Proj{});</br>
</br>
[...]</br>
</br>
template &lt;InputIterator I, Sentinel&lt;I&gt; S, class T, OutputIterator&lt;const T&amp;&gt; O,</br>
&nbsp;&nbsp;&nbsp;&nbsp;class Proj = identity, Indirect<ins>Unary</ins>Predicate&lt;projected&lt;I, Proj&gt;&gt; Pred&gt;</br>
&nbsp;&nbsp;requires IndirectlyCopyable&lt;I, O&gt;<del>()</del></br>
&nbsp;&nbsp;tagged_pair&lt;tag::in(I), tag::out(O)&gt;</br>
&nbsp;&nbsp;&nbsp;&nbsp;replace_copy_if(I first, S last, O result, Pred pred, const T&amp; new_value,</br>
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;Proj proj = Proj{});</br>
template &lt;InputRange Rng, class T, OutputIterator&lt;const T&amp;&gt; O, class Proj = identity,</br>
&nbsp;&nbsp;&nbsp;&nbsp;Indirect<ins>Unary</ins>Predicate&lt;projected&lt;iterator_t&lt;Rng&gt;, Proj&gt;&gt; Pred&gt;</br>
&nbsp;&nbsp;requires IndirectlyCopyable&lt;iterator_t&lt;Rng&gt;, O&gt;<del>()</del></br>
&nbsp;&nbsp;tagged_pair&lt;tag::in(safe_iterator_t&lt;Rng&gt;), tag::out(O)&gt;</br>
&nbsp;&nbsp;&nbsp;&nbsp;replace_copy_if(Rng&amp;&amp; rng, O result, Pred pred, const T&amp; new_value,</br>
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;Proj proj = Proj{});</br>
</br>
[...]</br>
</br>
template &lt;ForwardIterator I, Sentinel&lt;I&gt; S, class Proj = identity,</br>
&nbsp;&nbsp;&nbsp;&nbsp;Indirect<ins>Unary</ins>Predicate&lt;projected&lt;I, Proj&gt;&gt; Pred&gt;</br>
&nbsp;&nbsp;requires Permutable&lt;I&gt;<del>()</del></br>
&nbsp;&nbsp;I remove_if(I first, S last, Pred pred, Proj proj = Proj{});</br>
template &lt;ForwardRange Rng, class Proj = identity,</br>
&nbsp;&nbsp;&nbsp;&nbsp;Indirect<ins>Unary</ins>Predicate&lt;projected&lt;iterator_t&lt;Rng&gt;, Proj&gt;&gt; Pred&gt;</br>
&nbsp;&nbsp;requires Permutable&lt;iterator_t&lt;Rng&gt;&gt;<del>()</del></br>
&nbsp;&nbsp;safe_iterator_t&lt;Rng&gt;</br>
&nbsp;&nbsp;&nbsp;&nbsp;remove_if(Rng&amp;&amp; rng, Pred pred, Proj proj = Proj{});</br>
</br>
[...]</br>
</br>
template &lt;InputIterator I, Sentinel&lt;I&gt; S, WeaklyIncrementable O,</br>
&nbsp;&nbsp;&nbsp;&nbsp;class Proj = identity, Indirect<ins>Unary</ins>Predicate&lt;projected&lt;I, Proj&gt;&gt; Pred&gt;</br>
&nbsp;&nbsp;requires IndirectlyCopyable&lt;I, O&gt;<del>()</del></br>
&nbsp;&nbsp;tagged_pair&lt;tag::in(I), tag::out(O)&gt;</br>
&nbsp;&nbsp;&nbsp;&nbsp;remove_copy_if(I first, S last, O result, Pred pred, Proj proj = Proj{});</br>
template &lt;InputRange Rng, WeaklyIncrementable O, class Proj = identity,</br>
&nbsp;&nbsp;&nbsp;&nbsp;Indirect<ins>Unary</ins>Predicate&lt;projected&lt;iterator_t&lt;Rng&gt;, Proj&gt;&gt; Pred&gt;</br>
&nbsp;&nbsp;requires IndirectlyCopyable&lt;iterator_t&lt;Rng&gt;, O&gt;<del>()</del></br>
&nbsp;&nbsp;tagged_pair&lt;tag::in(safe_iterator_t&lt;Rng&gt;), tag::out(O)&gt;</br>
&nbsp;&nbsp;&nbsp;&nbsp;remove_copy_if(Rng&amp;&amp; rng, O result, Pred pred, Proj proj = Proj{});</br>
</br>
[...]</br>
</br>
template &lt;InputIterator I, Sentinel&lt;I&gt; S, class Proj = identity,</br>
&nbsp;&nbsp;&nbsp;&nbsp;Indirect<ins>Unary</ins>Predicate&lt;projected&lt;I, Proj&gt;&gt; Pred&gt;</br>
&nbsp;&nbsp;bool is_partitioned(I first, S last, Pred pred, Proj proj = Proj{});</br>
template &lt;InputRange Rng, class Proj = identity,</br>
&nbsp;&nbsp;&nbsp;&nbsp;Indirect<ins>Unary</ins>Predicate&lt;projected&lt;iterator_t&lt;Rng&gt;, Proj&gt;&gt; Pred&gt;</br>
&nbsp;&nbsp;bool</br>
&nbsp;&nbsp;is_partitioned(Rng&amp;&amp; rng, Pred pred, Proj proj = Proj{});</br>
</br>
template &lt;ForwardIterator I, Sentinel&lt;I&gt; S, class Proj = identity,</br>
&nbsp;&nbsp;&nbsp;&nbsp;Indirect<ins>Unary</ins>Predicate&lt;projected&lt;I, Proj&gt;&gt; Pred&gt;</br>
&nbsp;&nbsp;requires Permutable&lt;I&gt;<del>()</del></br>
&nbsp;&nbsp;I partition(I first, S last, Pred pred, Proj proj = Proj{});</br>
template &lt;ForwardRange Rng, class Proj = identity,</br>
&nbsp;&nbsp;&nbsp;&nbsp;Indirect<ins>Unary</ins>Predicate&lt;projected&lt;iterator_t&lt;Rng&gt;, Proj&gt;&gt; Pred&gt;</br>
&nbsp;&nbsp;requires Permutable&lt;iterator_t&lt;Rng&gt;&gt;<del>()</del></br>
&nbsp;&nbsp;safe_iterator_t&lt;Rng&gt;</br>
&nbsp;&nbsp;&nbsp;&nbsp;partition(Rng&amp;&amp; rng, Pred pred, Proj proj = Proj{});</br>
</br>
template &lt;BidirectionalIterator I, Sentinel&lt;I&gt; S, class Proj = identity,</br>
&nbsp;&nbsp;&nbsp;&nbsp;Indirect<ins>Unary</ins>Predicate&lt;projected&lt;I, Proj&gt;&gt; Pred&gt;</br>
&nbsp;&nbsp;requires Permutable&lt;I&gt;<del>()</del></br>
&nbsp;&nbsp;I stable_partition(I first, S last, Pred pred, Proj proj = Proj{});</br>
template &lt;BidirectionalRange Rng, class Proj = identity,</br>
&nbsp;&nbsp;&nbsp;&nbsp;Indirect<ins>Unary</ins>Predicate&lt;projected&lt;iterator_t&lt;Rng&gt;, Proj&gt;&gt; Pred&gt;</br>
&nbsp;&nbsp;requires Permutable&lt;iterator_t&lt;Rng&gt;&gt;<del>()</del></br>
&nbsp;&nbsp;safe_iterator_t&lt;Rng&gt;</br>
&nbsp;&nbsp;&nbsp;&nbsp;stable_partition(Rng&amp;&amp; rng, Pred pred, Proj proj = Proj{});</br>
</br>
template &lt;InputIterator I, Sentinel&lt;I&gt; S, WeaklyIncrementable O1, WeaklyIncrementable O2,</br>
&nbsp;&nbsp;&nbsp;&nbsp;class Proj = identity, Indirect<ins>Unary</ins>Predicate&lt;projected&lt;I, Proj&gt;&gt; Pred&gt;</br>
&nbsp;&nbsp;requires IndirectlyCopyable&lt;I, O1&gt;<del>()</del> &amp;&amp; IndirectlyCopyable&lt;I, O2&gt;<del>()</del></br>
&nbsp;&nbsp;tagged_tuple&lt;tag::in(I), tag::out1(O1), tag::out2(O2)&gt;</br>
&nbsp;&nbsp;&nbsp;&nbsp;partition_copy(I first, S last, O1 out_true, O2 out_false, Pred pred,</br>
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;Proj proj = Proj{});</br>
template &lt;InputRange Rng, WeaklyIncrementable O1, WeaklyIncrementable O2,</br>
&nbsp;&nbsp;&nbsp;&nbsp;class Proj = identity,</br>
&nbsp;&nbsp;&nbsp;&nbsp;Indirect<ins>Unary</ins>Predicate&lt;projected&lt;iterator_t&lt;Rng&gt;, Proj&gt;&gt; Pred&gt;</br>
&nbsp;&nbsp;requires IndirectlyCopyable&lt;iterator_t&lt;Rng&gt;, O1&gt;<del>()</del> &amp;&amp;</br>
&nbsp;&nbsp;&nbsp;&nbsp;IndirectlyCopyable&lt;iterator_t&lt;Rng&gt;, O2&gt;<del>()</del></br>
&nbsp;&nbsp;tagged_tuple&lt;tag::in(safe_iterator_t&lt;Rng&gt;), tag::out1(O1), tag::out2(O2)&gt;</br>
&nbsp;&nbsp;&nbsp;&nbsp;partition_copy(Rng&amp;&amp; rng, O1 out_true, O2 out_false, Pred pred, Proj proj = Proj{});</br>
</br>
template &lt;ForwardIterator I, Sentinel&lt;I&gt; S, class Proj = identity,</br>
&nbsp;&nbsp;&nbsp;&nbsp;Indirect<ins>Unary</ins>Predicate&lt;projected&lt;I, Proj&gt;&gt; Pred&gt;</br>
&nbsp;&nbsp;I partition_point(I first, S last, Pred pred, Proj proj = Proj{});</br>
template &lt;ForwardRange Rng, class Proj = identity,</br>
&nbsp;&nbsp;&nbsp;&nbsp;Indirect<ins>Unary</ins>Predicate&lt;projected&lt;iterator_t&lt;Rng&gt;, Proj&gt;&gt; Pred&gt;</br>
&nbsp;&nbsp;safe_iterator_t&lt;Rng&gt;</br>
&nbsp;&nbsp;partition_point(Rng&amp;&amp; rng, Pred pred, Proj proj = Proj{});</br>
</tt></blockquote>

In section "All of" ([alg.all_of]), change the signature of the `all_of` algorithm to match those
shown in `<experimental/ranges/algorithm>` synopsis ([algorithms.general]/p2) above.

Likewise, do the same for the following algorithms:
- `any_of` in section "Any of" ([alg.any_of])
- `none_of` in section "None of" ([alg.none_of])
- `for_each` in section "For each" ([alg.for_each])
- `find_if` in section "Find" ([alg.find])
- `find_if_not` in section "Find" ([alg.find])
- `count_if` in section "Count" ([alg.count])
- `copy_if` in section "Copy" ([alg.copy])
- `replace_if` in section "Replace" ([alg.replace])
- `replace_copy_if` in section "Replace" ([alg.replace])
- `remove_if` in section "Remove" ([alg.remove])
- `remove_copy_if` in section "Remove" ([alg.remove])
- `is_partitioned` in section "Partitions" ([alg.partitions])
- `partition` in section "Partitions" ([alg.partitions])
- `stable_partition` in section "Partitions" ([alg.partitions])
- `partition_copy` in section "Partitions" ([alg.partitions])
- `partition_point` in section "Partitions" ([alg.partitions])

# Acknowledgements

I would like to thank Casey Carter for his review feedback.
