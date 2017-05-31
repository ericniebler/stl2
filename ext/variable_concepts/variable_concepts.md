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

## Cross-type concepts

Some binary concepts offer a unary form to mean "same type", such that `Concept<A>()` is
semantically identical to `Concept<A, A>()` (e.g., `EqualityComparable`). In these cases, a simple
rewrite into a variable form will not result in valid code, since variable concepts cannot be
overloaded. In these cases, we much find a different spelling for the unary and binary forms.

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

We observe that `IndirectPredicate` is only ever used to constrain unary or binary predicates, so
we suggest breaking that concepts into `IndirectUnaryPredicate` and `IndirectBinaryPredicate`.

The concept `IndirectInvocable` is used to constrain the `for_each` algorithm, where the function
object it constrains is unary. So, we suggest dropping the nullary and binary forms of this concept
and renaming `IndirectInvocable` to `IndirectUnaryInvocable`.

Likewise, the concept `IndirectRegularInvocable` is used to constrain the `projected` class
template, where the function object it constrains is unary. So, we suggest dropping the nullary and
binary forms of this concept and renaming `IndirectRegularInvocable` to
`IndirectRegularUnaryInvocable`.

# Discussion

Should the committee ever decide to permit variable-style concepts to be overloaded, we could
decide to revert the name changes proposed in this document. For example, we could offer
`EqualityComparable<A, B>` as an alternate syntax for `EqualityComparableWith<A, B>`, and deprecate
`EqualityComparableWith`. This is a much better migration story that to leave the Ranges TS using
a feature that has a seemingly limited shelf life.

## Alternative Solutions

The following solutions have been considered and dismissed.

### Leave Function-Style Intact

There is nothing wrong per-se with leaving the concepts as function-style. The Ranges TS
is based on the Concepts TS as published, which supports the syntax.

This option comes with a few lasting costs. At every use of every concept defined in the Ranges TS,
the user will have to append a semantically meaningless set of empty parenthesis, a small cost,
surely, but one that adds up over time to a significant amount of syntactic noise.

Additionally, should the committee ever decide to drop function-style concepts, the Ranges TS would
be left behind. Compiler implementors would need to carry forward support for a language feature
that (possibly) never made it into the International Standard until such time as the Ranges TS as
published could be phased out. This situation is best avoided.

# Proposed Design

TODO


# Acknowledgements

I would like to thank Casey Carter for his review feedback.
