// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'telemetry_context.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$TelemetryContext<T> {

/// The backend-specific span object (e.g., a Sentry or OTel span).
 T get span;/// Arbitrary metadata or contextual data for this span.
///
/// Implementations may store trace IDs, sampling info, etc.
 Map<Symbol, dynamic> get attributes;/// The type of the [TelemetryService] that owns this context.
///
/// Used to ensure type-safe context lookups in [TelemetryZoneMixin].
 Type get ownerType;
/// Create a copy of TelemetryContext
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TelemetryContextCopyWith<T, TelemetryContext<T>> get copyWith => _$TelemetryContextCopyWithImpl<T, TelemetryContext<T>>(this as TelemetryContext<T>, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TelemetryContext<T>&&const DeepCollectionEquality().equals(other.span, span)&&const DeepCollectionEquality().equals(other.attributes, attributes)&&(identical(other.ownerType, ownerType) || other.ownerType == ownerType));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(span),const DeepCollectionEquality().hash(attributes),ownerType);

@override
String toString() {
  return 'TelemetryContext<$T>(span: $span, attributes: $attributes, ownerType: $ownerType)';
}


}

/// @nodoc
abstract mixin class $TelemetryContextCopyWith<T,$Res>  {
  factory $TelemetryContextCopyWith(TelemetryContext<T> value, $Res Function(TelemetryContext<T>) _then) = _$TelemetryContextCopyWithImpl;
@useResult
$Res call({
 T span, Map<Symbol, dynamic> attributes, Type ownerType
});




}
/// @nodoc
class _$TelemetryContextCopyWithImpl<T,$Res>
    implements $TelemetryContextCopyWith<T, $Res> {
  _$TelemetryContextCopyWithImpl(this._self, this._then);

  final TelemetryContext<T> _self;
  final $Res Function(TelemetryContext<T>) _then;

/// Create a copy of TelemetryContext
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? span = freezed,Object? attributes = null,Object? ownerType = null,}) {
  return _then(_self.copyWith(
span: freezed == span ? _self.span : span // ignore: cast_nullable_to_non_nullable
as T,attributes: null == attributes ? _self.attributes : attributes // ignore: cast_nullable_to_non_nullable
as Map<Symbol, dynamic>,ownerType: null == ownerType ? _self.ownerType : ownerType // ignore: cast_nullable_to_non_nullable
as Type,
  ));
}

}


/// Adds pattern-matching-related methods to [TelemetryContext].
extension TelemetryContextPatterns<T> on TelemetryContext<T> {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _TelemetryContext<T> value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _TelemetryContext() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _TelemetryContext<T> value)  $default,){
final _that = this;
switch (_that) {
case _TelemetryContext():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _TelemetryContext<T> value)?  $default,){
final _that = this;
switch (_that) {
case _TelemetryContext() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( T span,  Map<Symbol, dynamic> attributes,  Type ownerType)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _TelemetryContext() when $default != null:
return $default(_that.span,_that.attributes,_that.ownerType);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( T span,  Map<Symbol, dynamic> attributes,  Type ownerType)  $default,) {final _that = this;
switch (_that) {
case _TelemetryContext():
return $default(_that.span,_that.attributes,_that.ownerType);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( T span,  Map<Symbol, dynamic> attributes,  Type ownerType)?  $default,) {final _that = this;
switch (_that) {
case _TelemetryContext() when $default != null:
return $default(_that.span,_that.attributes,_that.ownerType);case _:
  return null;

}
}

}

/// @nodoc


class _TelemetryContext<T> extends TelemetryContext<T> {
  const _TelemetryContext({required this.span, required final  Map<Symbol, dynamic> attributes, required this.ownerType}): _attributes = attributes,super._();
  

/// The backend-specific span object (e.g., a Sentry or OTel span).
@override final  T span;
/// Arbitrary metadata or contextual data for this span.
///
/// Implementations may store trace IDs, sampling info, etc.
 final  Map<Symbol, dynamic> _attributes;
/// Arbitrary metadata or contextual data for this span.
///
/// Implementations may store trace IDs, sampling info, etc.
@override Map<Symbol, dynamic> get attributes {
  if (_attributes is EqualUnmodifiableMapView) return _attributes;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_attributes);
}

/// The type of the [TelemetryService] that owns this context.
///
/// Used to ensure type-safe context lookups in [TelemetryZoneMixin].
@override final  Type ownerType;

/// Create a copy of TelemetryContext
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$TelemetryContextCopyWith<T, _TelemetryContext<T>> get copyWith => __$TelemetryContextCopyWithImpl<T, _TelemetryContext<T>>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _TelemetryContext<T>&&const DeepCollectionEquality().equals(other.span, span)&&const DeepCollectionEquality().equals(other._attributes, _attributes)&&(identical(other.ownerType, ownerType) || other.ownerType == ownerType));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(span),const DeepCollectionEquality().hash(_attributes),ownerType);

@override
String toString() {
  return 'TelemetryContext<$T>(span: $span, attributes: $attributes, ownerType: $ownerType)';
}


}

/// @nodoc
abstract mixin class _$TelemetryContextCopyWith<T,$Res> implements $TelemetryContextCopyWith<T, $Res> {
  factory _$TelemetryContextCopyWith(_TelemetryContext<T> value, $Res Function(_TelemetryContext<T>) _then) = __$TelemetryContextCopyWithImpl;
@override @useResult
$Res call({
 T span, Map<Symbol, dynamic> attributes, Type ownerType
});




}
/// @nodoc
class __$TelemetryContextCopyWithImpl<T,$Res>
    implements _$TelemetryContextCopyWith<T, $Res> {
  __$TelemetryContextCopyWithImpl(this._self, this._then);

  final _TelemetryContext<T> _self;
  final $Res Function(_TelemetryContext<T>) _then;

/// Create a copy of TelemetryContext
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? span = freezed,Object? attributes = null,Object? ownerType = null,}) {
  return _then(_TelemetryContext<T>(
span: freezed == span ? _self.span : span // ignore: cast_nullable_to_non_nullable
as T,attributes: null == attributes ? _self._attributes : attributes // ignore: cast_nullable_to_non_nullable
as Map<Symbol, dynamic>,ownerType: null == ownerType ? _self.ownerType : ownerType // ignore: cast_nullable_to_non_nullable
as Type,
  ));
}


}

// dart format on
