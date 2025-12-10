// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'retry_policy.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$RetryPolicy {

/// The duration to wait before each retry attempt.
 Duration get delay;/// The maximum number of retry attempts before giving up.
 int get maxAttempts;
/// Create a copy of RetryPolicy
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$RetryPolicyCopyWith<RetryPolicy> get copyWith => _$RetryPolicyCopyWithImpl<RetryPolicy>(this as RetryPolicy, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is RetryPolicy&&(identical(other.delay, delay) || other.delay == delay)&&(identical(other.maxAttempts, maxAttempts) || other.maxAttempts == maxAttempts));
}


@override
int get hashCode => Object.hash(runtimeType,delay,maxAttempts);



}

/// @nodoc
abstract mixin class $RetryPolicyCopyWith<$Res>  {
  factory $RetryPolicyCopyWith(RetryPolicy value, $Res Function(RetryPolicy) _then) = _$RetryPolicyCopyWithImpl;
@useResult
$Res call({
 Duration delay, int maxAttempts
});




}
/// @nodoc
class _$RetryPolicyCopyWithImpl<$Res>
    implements $RetryPolicyCopyWith<$Res> {
  _$RetryPolicyCopyWithImpl(this._self, this._then);

  final RetryPolicy _self;
  final $Res Function(RetryPolicy) _then;

/// Create a copy of RetryPolicy
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? delay = null,Object? maxAttempts = null,}) {
  return _then(_self.copyWith(
delay: null == delay ? _self.delay : delay // ignore: cast_nullable_to_non_nullable
as Duration,maxAttempts: null == maxAttempts ? _self.maxAttempts : maxAttempts // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [RetryPolicy].
extension RetryPolicyPatterns on RetryPolicy {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _RetryPolicy value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _RetryPolicy() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _RetryPolicy value)  $default,){
final _that = this;
switch (_that) {
case _RetryPolicy():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _RetryPolicy value)?  $default,){
final _that = this;
switch (_that) {
case _RetryPolicy() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( Duration delay,  int maxAttempts)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _RetryPolicy() when $default != null:
return $default(_that.delay,_that.maxAttempts);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( Duration delay,  int maxAttempts)  $default,) {final _that = this;
switch (_that) {
case _RetryPolicy():
return $default(_that.delay,_that.maxAttempts);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( Duration delay,  int maxAttempts)?  $default,) {final _that = this;
switch (_that) {
case _RetryPolicy() when $default != null:
return $default(_that.delay,_that.maxAttempts);case _:
  return null;

}
}

}

/// @nodoc


class _RetryPolicy extends RetryPolicy {
  const _RetryPolicy({required this.delay, required this.maxAttempts}): assert(maxAttempts > 0, 'maxAttempts must be greater than 0'),super._();
  

/// The duration to wait before each retry attempt.
@override final  Duration delay;
/// The maximum number of retry attempts before giving up.
@override final  int maxAttempts;

/// Create a copy of RetryPolicy
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$RetryPolicyCopyWith<_RetryPolicy> get copyWith => __$RetryPolicyCopyWithImpl<_RetryPolicy>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _RetryPolicy&&(identical(other.delay, delay) || other.delay == delay)&&(identical(other.maxAttempts, maxAttempts) || other.maxAttempts == maxAttempts));
}


@override
int get hashCode => Object.hash(runtimeType,delay,maxAttempts);



}

/// @nodoc
abstract mixin class _$RetryPolicyCopyWith<$Res> implements $RetryPolicyCopyWith<$Res> {
  factory _$RetryPolicyCopyWith(_RetryPolicy value, $Res Function(_RetryPolicy) _then) = __$RetryPolicyCopyWithImpl;
@override @useResult
$Res call({
 Duration delay, int maxAttempts
});




}
/// @nodoc
class __$RetryPolicyCopyWithImpl<$Res>
    implements _$RetryPolicyCopyWith<$Res> {
  __$RetryPolicyCopyWithImpl(this._self, this._then);

  final _RetryPolicy _self;
  final $Res Function(_RetryPolicy) _then;

/// Create a copy of RetryPolicy
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? delay = null,Object? maxAttempts = null,}) {
  return _then(_RetryPolicy(
delay: null == delay ? _self.delay : delay // ignore: cast_nullable_to_non_nullable
as Duration,maxAttempts: null == maxAttempts ? _self.maxAttempts : maxAttempts // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

// dart format on
