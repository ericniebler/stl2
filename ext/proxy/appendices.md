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

template <class T>
struct __id { using type = T; };

template <template <class...> class T, class... U>
concept bool _Valid = requires { typename T<U...>; };

template <class U, template <class...> class T, class... V>
concept bool _Is = _Valid<T, U, V...> && __v<T<U, V...>>;

template <class U, class V>
concept bool _ConvertibleTo = _Is<U, std::is_convertible, V>;

template <template <class...> class T, class... U>
struct __defer { };
_Valid{T, ...U}
struct __defer<T, U...> : __id<T<U...>> { };

template <template <class...> class T>
struct __q {
  template <class... U>
  using apply = __t<__defer<T, U...>>;
};

template <class T>
struct __has_type : std::false_type { };
template <class T> requires _Valid<__t, T>
struct __has_type<T> : std::true_type { };

template <class T, class X = std::remove_reference_t<T>>
using __cref = std::add_lvalue_reference_t<std::add_const_t<X>>;
template <class T>
using __uncvref = std::remove_cv_t<std::remove_reference_t<T>>;

template <class T, class U>
using __cond = decltype(true ? declval<T>() : declval<U>());

template <class From, class To>
struct __copy_cv_ : __id<To> { };
template <class From, class To>
struct __copy_cv_<From const, To> : std::add_const<To> { };
template <class From, class To>
struct __copy_cv_<From volatile, To> : std::add_volatile<To> { };
template <class From, class To>
struct __copy_cv_<From const volatile, To> : std::add_cv<To> { };
template <class From, class To>
using __copy_cv = __t<__copy_cv_<From, To>>;

template <class T, class U>
struct __builtin_common { };
template <class T, class U>
using __builtin_common_t = __t<__builtin_common<T, U>>;
template <class T, class U>
  requires _Valid<__cond, __cref<T>, __cref<U>>
struct __builtin_common<T, U> :
  std::decay<__cond<__cref<T>, __cref<U>>> { };
template <class T, class U, class R = __builtin_common_t<T &, U &>>
using __rref_res = std::conditional_t<__v<std::is_reference<R>>,
  std::remove_reference_t<R> &&, R>;
template <class T, class U>
  requires _Valid<__builtin_common_t, T &, U &>
    && _ConvertibleTo<T &&, __rref_res<T, U>>
    && _ConvertibleTo<U &&, __rref_res<T, U>>
struct __builtin_common<T &&, U &&> : __id<__rref_res<T, U>> { };
template <class T, class U>
using __lref_res = __cond<__copy_cv<T, U> &, __copy_cv<U, T> &>;
template <class T, class U>
struct __builtin_common<T &, U &> : __defer<__lref_res, T, U> { };
template <class T, class U>
  requires _Valid<__builtin_common_t, T &, U const &>
    && _ConvertibleTo<U &&, __builtin_common_t<T &, U const &>>
struct __builtin_common<T &, U &&> :
  __builtin_common<T &, U const &> { };
template <class T, class U>
struct __builtin_common<T &&, U &> : __builtin_common<U &, T &&> { };

// common_type
template <class ...Ts>
struct common_type { };

template <class... T>
using common_type_t = __t<common_type<T...>>;

template <class T>
struct common_type<T> : std::decay<T> { };

template <class T, class U>
struct common_type<T, U>
  : common_type<decay_t<T>, decay_t<U>> { };

template <class T>
concept bool _Decayed = __v<is_same<decay_t<T>, T>>;

template <_Decayed T, _Decayed U>
struct common_type<T, U> : __builtin_common<T, U> { };

template <class T, class U, class V, class... W>
  requires _Valid<common_type_t, T, U>
struct common_type<T, U, V, W...>
  : common_type<common_type_t<T, U>, V, W...> { };

namespace __qual {
  using __rref = __q<std::add_rvalue_reference_t>;
  using __lref = __q<std::add_lvalue_reference_t>;
  template <class>
  struct __xref : __id<__compose<__q<__t>, __q<__id>>> { };
  template <class T>
  struct __xref<T&> : __id<__compose<__lref, __t<__xref<T>>>> { };
  template <class T>
  struct __xref<T&&> : __id<__compose<__rref, __t<__xref<T>>>> { };
  template <class T>
  struct __xref<const T> : __id<__q<std::add_const_t>> { };
  template <class T>
  struct __xref<volatile T> : __id<__q<std::add_volatile_t>> { };
  template <class T>
  struct __xref<const volatile T> : __id<__q<std::add_cv_t>> { };
}

template <class T, class U, template <class> class TQual,
  template <class> class UQual>
struct basic_common_reference { };

template <class T, class U>
using __basic_common_reference =
  basic_common_reference<__uncvref<T>, __uncvref<U>,
    __qual::__xref<T>::type::template apply,
    __qual::__xref<U>::type::template apply>;

// common_reference
template <class... T>
struct common_reference { };

template <class... T>
using common_reference_t = __t<common_reference<T...>>;

template <class T>
struct common_reference<T> : __id<T> { };

template <class T, class U>
struct common_reference<T, U>
  : std::conditional_t<
      __v<__has_type<__basic_common_reference<T, U>>>,
      __basic_common_reference<T, U>, common_type<T, U>> { };

template <class T, class U>
  requires _Valid<__builtin_common_t, T, U>
    && __v<std::is_reference<__builtin_common_t<T, U>>>
struct common_reference<T, U> : __builtin_common<T, U> { };

template <class T, class U, class V, class... W>
  requires _Valid<common_reference_t, T, U>
struct common_reference<T, U, V, W...>
  : common_reference<common_reference_t<T, U>, V, W...> { };
```
