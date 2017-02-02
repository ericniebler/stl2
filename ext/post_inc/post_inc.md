---
pagetitle: Post-Increment on Input and Output Iterators
title: Post-Increment on Input and Output Iterators
...

# Synopsis

The requirement for InputIterators to provide a post-increment operator that returns a type satisfying the Readable concept presents significant implementation challenges for many Input iterators, and makes some impossible to implement. This paper suggests removing the requirement for InputIterators. Specifically, we propose lifting the requirement that the return type of the post-increment operator for `InputIterator` satisfy `Readable`. We retain the requirement for forward iterators.

Note that nothing would prevent a given input iterator from supporting the syntax `*i++` or prevent non-generic code from making use of that syntax. The only change would be that generic code that operates on input iterators would need to change statements like `fn(*i++)` to `fn(*i); ++i`. This is likely to be more efficient, as is discussed below.

In Issaquah, the problem was discussed and a straw poll taken. The wording of the poll was as follows:

> Do we want to loosen the requirement on `InputIterator` post-increment to permit `void` return?
>
> | SF | F | N | A | SA |
> |----|---|---|---|----|
> | 13 | 6 | 1 | 0 | 1  |

# Input Iterators

## The Problem

Iterator post-increment requires that the expression `*i++` advances the iterator but returns the previous value. For forward iterators, that is trivially implementable by having the expression `i++` return a copy of the iterator before the application of _pre_-increment; e.g., `{ auto tmp = i; ++i; return tmp; }`. This doesn't work for InputIterators because pre-increment invalidates all copies of the iterator. When considering an iterator like `istreambuf_iterator` it is easy to see why: incrementing reads from a stream, thereby consuming the range as it is traversed.

In order for an iterator like `istreambuf_iterator` to give the expression `*i++` the required semantics, `i++` must return a proxy object that caches the previous value within it, and returns a reference to the previous value from an overloaded unary `operator*`. This proxy object must satisfy the `Readable` concept for `istreambuf_iterator` to satisfy the `InputIterator` concept in the Ranges TS.

### Operator Expense

`Readable` requires `Movable` and `DefaultConstructible`. For value types that are not themselves `Movable` or `DefaultConstructible`, various hacks are necessary for the proxy object to satisfy the concepts; e.g., storing the previous value in a `std::optional` or on the heap. Types that are not efficiently movable (e.g., `std::array`) are copied into the proxy object at great runtime cost, a cost that is hidden in the innocuous-looking expression `i++`.

Types that are _not_ movable simply cannot be cached. An input iterator over non-movable types is simply disallowed by the requirements on `operator++(int)`.

### Adaptor Complications

The standard specifies the existence of several iterator adaptors (e.g., `move_iterator`), and future iterations of the Ranges TS will propose many more. `move_iterator` is required to work with input iterators. Consider the difficulty of impementing `move_iterator`'s postfix increment operator. Below is the implementation as specified in the current draft standard.

```c++
template <InputIterator I>
move_iterator<I> move_iterator<I>::operator++(int) {
    auto tmp = *this;
    ++this->current; // A data member of type I
    return tmp;
}
```

This implementation is obviously wrong for input iterators -- it is guaranteed to return an invalid iterator -- and yet this is precisely what the standard specifies today. Correcting the problem is non-trivial. `move_iterator`'s postfix increment operator would need to return a proxy for input iterators only. Below is a rough demonstration, expressed in C++17.

```c++
template <InputIterator I>
auto move_iterator<I>::operator++(int) {
    using _Cat = iterator_category;
    if constexpr (is_base_of_v<forward_iterator_tag, _Cat>) {
        // Forward iterators permit a simple implementation
        return move_iterator{this->current++};
    } else {
        // Input iterators must return a proxy
        using _R = decay_t<decltype(this->current++)>;
        struct __proxy {
            using value_type = value_type_t<_R>;
            using _Ref = reference_t<_R>;
            using reference = conditional_t<
                is_reference_v<_Ref>,
                remove_reference_t<_Ref>&&,
                decay_t<_Ref>>;
            _R __cache;
            reference operator*() const {
                return static_cast<reference>(*__cache);
            }
        };
        return __proxy{this->current++};
    }
}
```

The very fact that the C++ standard gets this wrong for `move_iterator` demonstrates the complex subtlety that the requirement introduces into the standard iterator concepts.

The problem is even worse for other iterator adaptors. Imagine an adaptor that transforms its base iterator's reference somehow. Just because the iterator knows how to transform the base iterator's reference type is no guarantee that it knows how to transform its postfix-increment proxy reference type. In other words, for some transformation `TFX`, the well-formedness of `TFX(*it)` doesn't ensure the well-formedness of `TFX(*it++)`. That's because the types of the expressions `*it` and `*it++` are not required to be the same for input iterators. For example, `*it` might be an `int&`, but `*it++` might be an `int`.

In other words, due to the inherent oddness of the postfix increment operator, it is impossible to implement a generic iterator adaptor for all valid input iterators.

## Alternative Solutions

The following solutions have been considered and dismissed.

### Do nothing

One obvious solution is to simply do nothing. We have lived with the oddness of input iterator's postfix increment operator long enough. We can continue to live with it in the Ranges TS and beyond. Some generic iterator adaptors will be impossible to get completely correct, but its likely to be corner cases that will fail. Again, probably not a _huge_ deal. Despite the preceeding, we have decided to push forward our suggested resolution because with Concepts we have a chance to correct various shortcomings of the iterator concepts. Now is the time for any breaking changes. This change sweeps away the necessity for a lot of needless complexity in iterator implementations, and steers users away from using a surprisingly expensive iterator operation.

With the Ranges TS, we have a chance to try out this change without fully committing to it. Should the lack of `*i++` prove to be an adoption challenge, we would still have time to add it back in should the Ranges TS ever be merged into the IS.

### Remove postfix increment entirely

During the Issaquah 2016 meeting when this issue was discussed in LEWG, several in the room expressed support for the notion of simply removing postfix increment for input iterators entirely. (This is in contrast with requiring postfix increment but permitting it to return, say, `void`.) The following straw poll was taken on that question:

> Do we want to remove the requirement for InputIterator post-increment entirely (for the Ranges TS)?
>
> | SF | F | N | A | SA |
> |----|---|---|---|----|
> |  7 | 6 | 7 | 2 | 0  |

Although there does appear to be weak consensus to remove `i++` entirely from the `InputIterator` concept, the consensus to keep `i++` but permit it to return `void` is stronger.

The authors of the Ranges TS strongly prefer keeping the postfix increment operator for input iterators. Consider the following fairly common (anti-)pattern:

```c++
for (auto i = v.begin(); i != v.end(); i++) {
    // ...
}
```

Aside from concerns over the cost of post-increment, there is nothing wrong with this code _per se_, and the authors see no compelling reason to break it. And by permitting `i++` to return `void`, we would actually be mitigating the performance problem.

# Output Iterators

After considering the issue for input iterators, its natural to wonder what the situation is for output iterators. Should `OutputIterator` require writabilty for the expression `o++`? The present draft of the Ranges TS places no requirements on the expression `o++`, making the expression `*o++ = t` non-portable in generic code. Perhaps we should add it.

On the one hand, output iterators need not cache any previous value in the result of `o++` to give `*o++ = t` the correct semantics. As a result, there is no performance problem with postfix increment, and no known difficulty adapting output iterators. _Not_ supporting writability for `o++` would seem to be a needless incompatibiliity with the iterators in the IS. We don't know of an output iterator for which the postfix increment operator is not completely trivial and efficient.

On the other hand, its hard to say with certainty that there will _never_ be an output iterator with an expensive and complicated postfix increment. And supporting `*o++` for output iterators but not for input iterators is inconsistent and confusing.

Avoiding needless breakage _seems_ like the more convincing argument. Neither of the authors of the Ranges TS has any strong opinions on the matter, but this paper suggests adding back the writability requirement on `o++`.

# Proposed Design

Change the definition of `InputIterator` ([iterators.input]) as follows:

> <tt>template &lt;class I&gt;</tt>
> <tt>concept bool InputIterator() {</tt>
> <tt>&nbsp;&nbsp;return Iterator&lt;I&gt;() &amp;&amp;</tt>
> <tt>&nbsp;&nbsp;&nbsp;&nbsp;Readable&lt;I&gt;() &amp;&amp;</tt>
> <tt>&nbsp;&nbsp;&nbsp;&nbsp;<del>requires(I i, const I ci) {</del></tt>
> <tt>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<ins>requires {</ins> typename iterator_category_t&lt;I&gt;; <ins>} &amp;&amp;</ins></tt>
> <tt>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<del>requires</del> DerivedFrom&lt;iterator_category_t&lt;I&gt;, input_iterator_tag&gt;();</tt>
> <tt>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<del>{ i++ } -> Readable; // not required to be equality preserving</del></tt>
> <tt>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<del>requires Same&lt;value_type_t&lt;I&gt;, value_type_t<decltype(i++)>>();</del></tt>
> <tt>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<del>{ *ci } -> const value_type_t&lt;I&gt;&amp;;</del></tt>
> <tt>&nbsp;&nbsp;&nbsp;&nbsp;<del>};</del></tt>
> <tt>}</tt>

<ednote>[<i>Editor's note:</i> Note: the line `{ *ci } -> const value_type_t<I>&;` is deleted here as a drive-by fix of [stl2 issue 307](https://github.com/ericniebler/stl2/issues/307) in which the edits necessary to support proxy iterators (P0022) were applied incompletely.]<ednote>

Change the definition of `OutputIterator` ([iterators.output]) as follows:

> <tt>template &lt;class I, class T&gt;</tt>
> <tt>concept bool OutputIterator() {</tt>
> <tt>&nbsp;&nbsp;return Iterator&lt;I&gt;() &amp;&amp; Writable&lt;I, T&gt;()<del>;</del> <ins>&amp;&amp;</ins></tt>
> <tt>&nbsp;&nbsp;&nbsp;&nbsp;<ins>requires(I i, T&amp;&amp; t) {</ins></tt>
> <tt>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<ins>*i++ = std::forward<T>(t); // not required to be equality preserving</ins></tt>
> <tt>&nbsp;&nbsp;&nbsp;&nbsp;<ins>};</ins></tt>
> <tt>}</tt>

Change the class synopsis of `insert_iterator` ([insert.iterator]) as follows:

> <tt>namespace std { namespace experimental { namespace ranges { inline namespace v1 {</tt>
> <tt>&nbsp;&nbsp;template &lt;class Container&gt;</tt>
> <tt>&nbsp;&nbsp;class insert_iterator {</tt>
> <tt>&nbsp;&nbsp;public:</tt>
> <tt>&nbsp;&nbsp;&nbsp;&nbsp;// ... as before</tt>
> <tt>&nbsp;&nbsp;&nbsp;&nbsp;insert_iterator<ins>&amp;</ins> operator++(int);</tt>
> <tt>&nbsp;&nbsp;&nbsp;&nbsp;// ... as before</tt>
> <tt>&nbsp;&nbsp;};</tt>
> <tt>}</tt>

Change [insert.iter.op++] as follows:

> `insert_iterator& operator++();`
> <tt>insert_iterator<ins>&amp;</ins> operator++(int);</tt>
> > 1 Returns: `*this.`

<ednote>[<i>Editor's note:</i> Thus restoring the signature of `insert_iterator`'s postfix increment operator to the version in the IS.]<ednote>

Change the class synopsis of `move_iterator` ([move.iterator]) as follows:

> <tt>namespace std { namespace experimental { namespace ranges { inline namespace v1 {</tt>
> <tt>&nbsp;&nbsp;template &lt;InputIterator I&gt;</tt>
> <tt>&nbsp;&nbsp;class move_iterator {</tt>
> <tt>&nbsp;&nbsp;public:</tt>
> <tt>&nbsp;&nbsp;&nbsp;&nbsp;// ... as before</tt>
> <tt>&nbsp;&nbsp;&nbsp;&nbsp;<del>move_iterator operator++(int);</del></tt>
> <tt>&nbsp;&nbsp;&nbsp;&nbsp;<ins>void operator++(int);</ins></tt>
> <tt>&nbsp;&nbsp;&nbsp;&nbsp;<ins>move_iterator operator++(int)</ins></tt>
> <tt>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<ins>requires ForwardIterator&lt;I&gt;();</ins></tt>
> <tt>&nbsp;&nbsp;&nbsp;&nbsp;// ... as before</tt>
> <tt>&nbsp;&nbsp;};</tt>
> <tt>}</tt>

Change [move.iter.op.incr] as follows:

> `move_iterator& operator++();`
> > 1 Effects: Equivalent to `++current`.
> > 2 Returns: `*this.`
>
> <tt><ins>void operator++(int);<ins></tt>
> > <ins>3 Effects: Equivalent to `++current`.</ins>
>
> <tt>move_iterator operator++(int)<del>;</del></tt>
> <tt>&nbsp;&nbsp;<ins>requires ForwardIterator&lt;I&gt;();</ins></tt>
> > 4 Effects: Equivalent to:
> >
> > > ```
> > > move_iterator tmp = *this;
> > > ++current;
> > > return tmp;
> > > ```

Change the class synopsis of `common_iterator` ([common.iterator]) as follows:

> <tt>namespace std { namespace experimental { namespace ranges { inline namespace v1 {</tt>
> <tt>&nbsp;&nbsp;template &lt;Iterator I, Sentinel&lt;I&gt; S&gt;</tt>
> <tt>&nbsp;&nbsp;&nbsp;&nbsp;requires !Same&lt;I, S&gt;()</tt>
> <tt>&nbsp;&nbsp;class common_iterator {</tt>
> <tt>&nbsp;&nbsp;public:</tt>
> <tt>&nbsp;&nbsp;&nbsp;&nbsp;// ... as before</tt>
> <tt>&nbsp;&nbsp;&nbsp;&nbsp;<del>common_iterator operator++(int);</del></tt>
> <tt>&nbsp;&nbsp;&nbsp;&nbsp;<ins><i>see below</i> operator++(int);</ins></tt>
> <tt>&nbsp;&nbsp;&nbsp;&nbsp;<ins>common_iterator operator++(int)</ins></tt>
> <tt>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<ins>requires ForwardIterator&lt;I&gt;();</ins></tt>
> <tt>&nbsp;&nbsp;&nbsp;&nbsp;// ... as before</tt>
> <tt>&nbsp;&nbsp;};</tt>
> <tt>}</tt>

Change [common.iter.op.incr] as follows:

> `common_iterator& operator++();`
> > 1 Requires: `!is_sentinel`.
> > 2 Effects: <ins>Equivalent to</ins> `++iter`.
> > 3 Returns: `*this.`
>
> <tt><ins>decltype(auto) operator++(int);<ins></tt>
> > <ins>4 Requires: `!is_sentinel`.</ins>
> > <ins>5 Effects: Equivalent to `return iter++`.</ins>
>
> <tt>common_iterator operator++(int)<del>;</del></tt>
> <tt>&nbsp;&nbsp;<ins>requires ForwardIterator&lt;I&gt;();</ins></tt>
> > 6 Requires: `!is_sentinel`.
> > 7 Effects: Equivalent to:
> >
> > > ```
> > > common_iterator tmp = *this;
> > > ++iter;
> > > return tmp;
> > > ```

<ednote>[<i>Editor's note:</i> For input and output iterators, we return the result of `iter++` directly. That permits `common_iterator`'s postfix increment operator to work correctly with input and output iterators that return proxies (e.g., `istreambuf_iterator`) or references to `*this` (e.g., `insert_iterator`) from their postfix increment operator.]<ednote>

Change the class synopsis of `counted_iterator` ([counted.iterator]) as follows:

> <tt>namespace std { namespace experimental { namespace ranges { inline namespace v1 {</tt>
> <tt>&nbsp;&nbsp;template &lt;Iterator I&gt;</tt>
> <tt>&nbsp;&nbsp;class counted_iterator {</tt>
> <tt>&nbsp;&nbsp;public:</tt>
> <tt>&nbsp;&nbsp;&nbsp;&nbsp;// ... as before</tt>
> <tt>&nbsp;&nbsp;&nbsp;&nbsp;<del>counted_iterator operator++(int);</del></tt>
> <tt>&nbsp;&nbsp;&nbsp;&nbsp;<ins><i>see below</i> operator++(int);</ins></tt>
> <tt>&nbsp;&nbsp;&nbsp;&nbsp;<ins>counted_iterator operator++(int)</ins></tt>
> <tt>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<ins>requires ForwardIterator&lt;I&gt;();</ins></tt>
> <tt>&nbsp;&nbsp;&nbsp;&nbsp;// ... as before</tt>
> <tt>&nbsp;&nbsp;};</tt>
> <tt>}</tt>

Change [counted.iter.op.incr] as follows:

> `counted_iterator& operator++();`
> > 1 Requires: `cnt > 0`.
> > 2 Effects: Equivalent to:
> >
> > > ```
> > > ++current;
> > > --cnt
> > > ```
> >
> > 3 Returns: `*this.`
>
> <tt><ins>decltype(auto) operator++(int);<ins></tt>
> > <ins>4 Requires: `cnt > 0`.</ins>
> > <ins>5 Effects: Equivalent to:</ins>
> >
> > > <tt><ins>-\-cnt</ins></tt>
> > > <tt><ins>return current++;</ins></tt>
>
> <tt>counted_iterator operator++(int)<del>;</del></tt>
> <tt>&nbsp;&nbsp;<ins>requires ForwardIterator&lt;I&gt;();</ins></tt>
> > 6 Requires: `cnt > 0`.
> > 7 Effects: Equivalent to:
> >
> > > ```
> > > counted_iterator tmp = *this;
> > > ++current;
> > > --cnt;
> > > return tmp;
> > > ```

<ednote>[<i>Editor's note:</i> For input and output iterators, we return the result of `current++` directly. That permits `counted_iterator`'s postfix increment operator to work correctly with input and output iterators that return proxies (e.g., `istreambuf_iterator`) or references to `*this` (e.g., `insert_iterator`) from their postfix increment operator.]<ednote>

No changes to `istream_iterator` or `istreambuf_iterator`.

<ednote>[<i>Editor's note:</i> We suggest leaving the postfix increment operators on the `istream(buf)` iterators intact to ease migration to the Ranges TS.]<ednote>

Change the class synopsis of `ostream_iterator` ([ostream.iterator]) as follows:

> <tt>namespace std { namespace experimental { namespace ranges { inline namespace v1 {</tt>
> <tt>&nbsp;&nbsp;template &lt;class T, class charT = char, class traits = char_traits&lt;charT&gt;&gt;</tt>
> <tt>&nbsp;&nbsp;class ostream_iterator {</tt>
> <tt>&nbsp;&nbsp;public:</tt>
> <tt>&nbsp;&nbsp;&nbsp;&nbsp;// ... as before</tt>
> <tt>&nbsp;&nbsp;&nbsp;&nbsp;ostream_iterator<ins>&amp;</ins> operator++(int);</tt>
> <tt>&nbsp;&nbsp;&nbsp;&nbsp;// ... as before</tt>
> <tt>&nbsp;&nbsp;};</tt>
> <tt>}</tt>

Change [ostream.iter.ops] as follows:

> // ... as before
> `ostream_iterator& operator++();`
> <tt>ostream_iterator<ins>&amp;</ins> operator++(int);</tt>
> > 3 Returns: `*this.`

<ednote>[<i>Editor's note:</i> Thus restoring the signature of `ostream_iterator`'s postfix increment operator to the version in the IS.]</ednote>

Change the class synopsis of `ostreambuf_iterator` ([ostreambuf.iterator]) as follows:

> <tt>namespace std { namespace experimental { namespace ranges { inline namespace v1 {</tt>
> <tt>&nbsp;&nbsp;template &lt;class charT, class traits = char_traits&lt;charT&gt;&gt;</tt>
> <tt>&nbsp;&nbsp;class ostreambuf_iterator {</tt>
> <tt>&nbsp;&nbsp;public:</tt>
> <tt>&nbsp;&nbsp;&nbsp;&nbsp;// ... as before</tt>
> <tt>&nbsp;&nbsp;&nbsp;&nbsp;ostreambuf_iterator<ins>&amp;</ins> operator++(int);</tt>
> <tt>&nbsp;&nbsp;&nbsp;&nbsp;// ... as before</tt>
> <tt>&nbsp;&nbsp;};</tt>
> <tt>}</tt>

Change [ostreambuf.iter.ops] as follows:

> // ... as before
> `ostreambuf_iterator& operator++();`
> <tt>ostreambuf_iterator<ins>&amp;</ins> operator++(int);</tt>
> > 5 Returns: `*this.`

<ednote>[<i>Editor's note:</i> Thus restoring the signature of `ostreambuf_iterator`'s postfix increment operator to the version in the IS.]</ednote>
