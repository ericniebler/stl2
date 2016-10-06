
# Merge `Writable` and `MoveWritable`

[PR](https://github.com/ericniebler/stl2/pull/160)

[Discussion](https://github.com/CaseyCarter/stl2/issues/17)


#Merge/MergeMovable fix

[PR](https://github.com/ericniebler/stl2/pull/157)

(This simply relaxed an overconstrained parameter, maybe could integrate into the Writable/MoveWritable discussion.)


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
