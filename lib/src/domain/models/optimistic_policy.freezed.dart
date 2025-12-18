// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'optimistic_policy.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$OptimisticPolicy<T> {

/// The function to generate the optimistic value based on the current value.
 T Function(T) get optimisticValue;/// A function to determine whether to revert based on the error.
///
/// If this function returns `true`, the operation will revert to the
/// [snapshotValue].
///
/// If it returns `false`, the optimistic update is retained despite the error
/// when [propagateError] is `false`. If [propagateError] is `true`, the error is still thrown
/// but the optimistic update is not reverted.
 bool Function(Object? error) get shouldRevert;
/// Create a copy of OptimisticPolicy
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$OptimisticPolicyCopyWith<T, OptimisticPolicy<T>> get copyWith => _$OptimisticPolicyCopyWithImpl<T, OptimisticPolicy<T>>(this as OptimisticPolicy<T>, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is OptimisticPolicy<T>&&(identical(other.optimisticValue, optimisticValue) || other.optimisticValue == optimisticValue)&&(identical(other.shouldRevert, shouldRevert) || other.shouldRevert == shouldRevert));
}


@override
int get hashCode => Object.hash(runtimeType,optimisticValue,shouldRevert);



}

/// @nodoc
abstract mixin class $OptimisticPolicyCopyWith<T,$Res>  {
  factory $OptimisticPolicyCopyWith(OptimisticPolicy<T> value, $Res Function(OptimisticPolicy<T>) _then) = _$OptimisticPolicyCopyWithImpl;
@useResult
$Res call({
 T Function(T) optimisticValue, bool Function(Object? error) shouldRevert
});




}
/// @nodoc
class _$OptimisticPolicyCopyWithImpl<T,$Res>
    implements $OptimisticPolicyCopyWith<T, $Res> {
  _$OptimisticPolicyCopyWithImpl(this._self, this._then);

  final OptimisticPolicy<T> _self;
  final $Res Function(OptimisticPolicy<T>) _then;

/// Create a copy of OptimisticPolicy
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? optimisticValue = null,Object? shouldRevert = null,}) {
  return _then(_self.copyWith(
optimisticValue: null == optimisticValue ? _self.optimisticValue : optimisticValue // ignore: cast_nullable_to_non_nullable
as T Function(T),shouldRevert: null == shouldRevert ? _self.shouldRevert : shouldRevert // ignore: cast_nullable_to_non_nullable
as bool Function(Object? error),
  ));
}

}


/// Adds pattern-matching-related methods to [OptimisticPolicy].
extension OptimisticPolicyPatterns<T> on OptimisticPolicy<T> {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _OptimisticPolicy<T> value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _OptimisticPolicy() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _OptimisticPolicy<T> value)  $default,){
final _that = this;
switch (_that) {
case _OptimisticPolicy():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _OptimisticPolicy<T> value)?  $default,){
final _that = this;
switch (_that) {
case _OptimisticPolicy() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( T Function(T) optimisticValue,  bool Function(Object? error) shouldRevert)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _OptimisticPolicy() when $default != null:
return $default(_that.optimisticValue,_that.shouldRevert);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( T Function(T) optimisticValue,  bool Function(Object? error) shouldRevert)  $default,) {final _that = this;
switch (_that) {
case _OptimisticPolicy():
return $default(_that.optimisticValue,_that.shouldRevert);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( T Function(T) optimisticValue,  bool Function(Object? error) shouldRevert)?  $default,) {final _that = this;
switch (_that) {
case _OptimisticPolicy() when $default != null:
return $default(_that.optimisticValue,_that.shouldRevert);case _:
  return null;

}
}

}

/// @nodoc


class _OptimisticPolicy<T> extends OptimisticPolicy<T> {
  const _OptimisticPolicy({required this.optimisticValue, required this.shouldRevert}): super._();
  

/// The function to generate the optimistic value based on the current value.
@override final  T Function(T) optimisticValue;
/// A function to determine whether to revert based on the error.
///
/// If this function returns `true`, the operation will revert to the
/// [snapshotValue].
///
/// If it returns `false`, the optimistic update is retained despite the error
/// when [propagateError] is `false`. If [propagateError] is `true`, the error is still thrown
/// but the optimistic update is not reverted.
@override final  bool Function(Object? error) shouldRevert;

/// Create a copy of OptimisticPolicy
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$OptimisticPolicyCopyWith<T, _OptimisticPolicy<T>> get copyWith => __$OptimisticPolicyCopyWithImpl<T, _OptimisticPolicy<T>>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _OptimisticPolicy<T>&&(identical(other.optimisticValue, optimisticValue) || other.optimisticValue == optimisticValue)&&(identical(other.shouldRevert, shouldRevert) || other.shouldRevert == shouldRevert));
}


@override
int get hashCode => Object.hash(runtimeType,optimisticValue,shouldRevert);



}

/// @nodoc
abstract mixin class _$OptimisticPolicyCopyWith<T,$Res> implements $OptimisticPolicyCopyWith<T, $Res> {
  factory _$OptimisticPolicyCopyWith(_OptimisticPolicy<T> value, $Res Function(_OptimisticPolicy<T>) _then) = __$OptimisticPolicyCopyWithImpl;
@override @useResult
$Res call({
 T Function(T) optimisticValue, bool Function(Object? error) shouldRevert
});




}
/// @nodoc
class __$OptimisticPolicyCopyWithImpl<T,$Res>
    implements _$OptimisticPolicyCopyWith<T, $Res> {
  __$OptimisticPolicyCopyWithImpl(this._self, this._then);

  final _OptimisticPolicy<T> _self;
  final $Res Function(_OptimisticPolicy<T>) _then;

/// Create a copy of OptimisticPolicy
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? optimisticValue = null,Object? shouldRevert = null,}) {
  return _then(_OptimisticPolicy<T>(
optimisticValue: null == optimisticValue ? _self.optimisticValue : optimisticValue // ignore: cast_nullable_to_non_nullable
as T Function(T),shouldRevert: null == shouldRevert ? _self.shouldRevert : shouldRevert // ignore: cast_nullable_to_non_nullable
as bool Function(Object? error),
  ));
}


}

// dart format on
