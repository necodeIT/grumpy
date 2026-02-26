// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'storage_key.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$StorageKey {

/// Logical namespace partition.
 String get namespace;/// Stable identifier inside [namespace].
 String get primaryKey;/// Serialized-shape fingerprint.
 String get schemaId;/// Optional manual compatibility version.
 int? get compatVersion;
/// Create a copy of StorageKey
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$StorageKeyCopyWith<StorageKey> get copyWith => _$StorageKeyCopyWithImpl<StorageKey>(this as StorageKey, _$identity);

  /// Serializes this StorageKey to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is StorageKey&&(identical(other.namespace, namespace) || other.namespace == namespace)&&(identical(other.primaryKey, primaryKey) || other.primaryKey == primaryKey)&&(identical(other.schemaId, schemaId) || other.schemaId == schemaId)&&(identical(other.compatVersion, compatVersion) || other.compatVersion == compatVersion));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,namespace,primaryKey,schemaId,compatVersion);

@override
String toString() {
  return 'StorageKey(namespace: $namespace, primaryKey: $primaryKey, schemaId: $schemaId, compatVersion: $compatVersion)';
}


}

/// @nodoc
abstract mixin class $StorageKeyCopyWith<$Res>  {
  factory $StorageKeyCopyWith(StorageKey value, $Res Function(StorageKey) _then) = _$StorageKeyCopyWithImpl;
@useResult
$Res call({
 String namespace, String primaryKey, String schemaId, int? compatVersion
});




}
/// @nodoc
class _$StorageKeyCopyWithImpl<$Res>
    implements $StorageKeyCopyWith<$Res> {
  _$StorageKeyCopyWithImpl(this._self, this._then);

  final StorageKey _self;
  final $Res Function(StorageKey) _then;

/// Create a copy of StorageKey
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? namespace = null,Object? primaryKey = null,Object? schemaId = null,Object? compatVersion = freezed,}) {
  return _then(_self.copyWith(
namespace: null == namespace ? _self.namespace : namespace // ignore: cast_nullable_to_non_nullable
as String,primaryKey: null == primaryKey ? _self.primaryKey : primaryKey // ignore: cast_nullable_to_non_nullable
as String,schemaId: null == schemaId ? _self.schemaId : schemaId // ignore: cast_nullable_to_non_nullable
as String,compatVersion: freezed == compatVersion ? _self.compatVersion : compatVersion // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}

}


/// Adds pattern-matching-related methods to [StorageKey].
extension StorageKeyPatterns on StorageKey {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _StorageKey value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _StorageKey() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _StorageKey value)  $default,){
final _that = this;
switch (_that) {
case _StorageKey():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _StorageKey value)?  $default,){
final _that = this;
switch (_that) {
case _StorageKey() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String namespace,  String primaryKey,  String schemaId,  int? compatVersion)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _StorageKey() when $default != null:
return $default(_that.namespace,_that.primaryKey,_that.schemaId,_that.compatVersion);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String namespace,  String primaryKey,  String schemaId,  int? compatVersion)  $default,) {final _that = this;
switch (_that) {
case _StorageKey():
return $default(_that.namespace,_that.primaryKey,_that.schemaId,_that.compatVersion);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String namespace,  String primaryKey,  String schemaId,  int? compatVersion)?  $default,) {final _that = this;
switch (_that) {
case _StorageKey() when $default != null:
return $default(_that.namespace,_that.primaryKey,_that.schemaId,_that.compatVersion);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _StorageKey extends StorageKey {
  const _StorageKey({required this.namespace, required this.primaryKey, required this.schemaId, this.compatVersion}): super._();
  factory _StorageKey.fromJson(Map<String, dynamic> json) => _$StorageKeyFromJson(json);

/// Logical namespace partition.
@override final  String namespace;
/// Stable identifier inside [namespace].
@override final  String primaryKey;
/// Serialized-shape fingerprint.
@override final  String schemaId;
/// Optional manual compatibility version.
@override final  int? compatVersion;

/// Create a copy of StorageKey
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$StorageKeyCopyWith<_StorageKey> get copyWith => __$StorageKeyCopyWithImpl<_StorageKey>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$StorageKeyToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _StorageKey&&(identical(other.namespace, namespace) || other.namespace == namespace)&&(identical(other.primaryKey, primaryKey) || other.primaryKey == primaryKey)&&(identical(other.schemaId, schemaId) || other.schemaId == schemaId)&&(identical(other.compatVersion, compatVersion) || other.compatVersion == compatVersion));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,namespace,primaryKey,schemaId,compatVersion);

@override
String toString() {
  return 'StorageKey(namespace: $namespace, primaryKey: $primaryKey, schemaId: $schemaId, compatVersion: $compatVersion)';
}


}

/// @nodoc
abstract mixin class _$StorageKeyCopyWith<$Res> implements $StorageKeyCopyWith<$Res> {
  factory _$StorageKeyCopyWith(_StorageKey value, $Res Function(_StorageKey) _then) = __$StorageKeyCopyWithImpl;
@override @useResult
$Res call({
 String namespace, String primaryKey, String schemaId, int? compatVersion
});




}
/// @nodoc
class __$StorageKeyCopyWithImpl<$Res>
    implements _$StorageKeyCopyWith<$Res> {
  __$StorageKeyCopyWithImpl(this._self, this._then);

  final _StorageKey _self;
  final $Res Function(_StorageKey) _then;

/// Create a copy of StorageKey
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? namespace = null,Object? primaryKey = null,Object? schemaId = null,Object? compatVersion = freezed,}) {
  return _then(_StorageKey(
namespace: null == namespace ? _self.namespace : namespace // ignore: cast_nullable_to_non_nullable
as String,primaryKey: null == primaryKey ? _self.primaryKey : primaryKey // ignore: cast_nullable_to_non_nullable
as String,schemaId: null == schemaId ? _self.schemaId : schemaId // ignore: cast_nullable_to_non_nullable
as String,compatVersion: freezed == compatVersion ? _self.compatVersion : compatVersion // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}


}

// dart format on
