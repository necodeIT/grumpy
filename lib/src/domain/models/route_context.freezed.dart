// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'route_context.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$RouteContext {

/// The full path of the current route.
 String get fullPath;/// The path parameters extracted from the route.
 Map<String, String> get pathParams;/// The query parameters extracted from the route.
 Map<String, String> get queryParams;/// The query parameters extracted from the route, allowing multiple values per key.
 Map<String, List<String>> get queryParamsAll;/// The fragment identifier from the URL, if any.
 String get fragment;
/// Create a copy of RouteContext
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$RouteContextCopyWith<RouteContext> get copyWith => _$RouteContextCopyWithImpl<RouteContext>(this as RouteContext, _$identity);

  /// Serializes this RouteContext to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is RouteContext&&(identical(other.fullPath, fullPath) || other.fullPath == fullPath)&&const DeepCollectionEquality().equals(other.pathParams, pathParams)&&const DeepCollectionEquality().equals(other.queryParams, queryParams)&&const DeepCollectionEquality().equals(other.queryParamsAll, queryParamsAll)&&(identical(other.fragment, fragment) || other.fragment == fragment));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,fullPath,const DeepCollectionEquality().hash(pathParams),const DeepCollectionEquality().hash(queryParams),const DeepCollectionEquality().hash(queryParamsAll),fragment);

@override
String toString() {
  return 'RouteContext(fullPath: $fullPath, pathParams: $pathParams, queryParams: $queryParams, queryParamsAll: $queryParamsAll, fragment: $fragment)';
}


}

/// @nodoc
abstract mixin class $RouteContextCopyWith<$Res>  {
  factory $RouteContextCopyWith(RouteContext value, $Res Function(RouteContext) _then) = _$RouteContextCopyWithImpl;
@useResult
$Res call({
 String fullPath, Map<String, String> pathParams, Map<String, String> queryParams, Map<String, List<String>> queryParamsAll, String fragment
});




}
/// @nodoc
class _$RouteContextCopyWithImpl<$Res>
    implements $RouteContextCopyWith<$Res> {
  _$RouteContextCopyWithImpl(this._self, this._then);

  final RouteContext _self;
  final $Res Function(RouteContext) _then;

/// Create a copy of RouteContext
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? fullPath = null,Object? pathParams = null,Object? queryParams = null,Object? queryParamsAll = null,Object? fragment = null,}) {
  return _then(_self.copyWith(
fullPath: null == fullPath ? _self.fullPath : fullPath // ignore: cast_nullable_to_non_nullable
as String,pathParams: null == pathParams ? _self.pathParams : pathParams // ignore: cast_nullable_to_non_nullable
as Map<String, String>,queryParams: null == queryParams ? _self.queryParams : queryParams // ignore: cast_nullable_to_non_nullable
as Map<String, String>,queryParamsAll: null == queryParamsAll ? _self.queryParamsAll : queryParamsAll // ignore: cast_nullable_to_non_nullable
as Map<String, List<String>>,fragment: null == fragment ? _self.fragment : fragment // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [RouteContext].
extension RouteContextPatterns on RouteContext {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _RouteContext value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _RouteContext() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _RouteContext value)  $default,){
final _that = this;
switch (_that) {
case _RouteContext():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _RouteContext value)?  $default,){
final _that = this;
switch (_that) {
case _RouteContext() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String fullPath,  Map<String, String> pathParams,  Map<String, String> queryParams,  Map<String, List<String>> queryParamsAll,  String fragment)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _RouteContext() when $default != null:
return $default(_that.fullPath,_that.pathParams,_that.queryParams,_that.queryParamsAll,_that.fragment);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String fullPath,  Map<String, String> pathParams,  Map<String, String> queryParams,  Map<String, List<String>> queryParamsAll,  String fragment)  $default,) {final _that = this;
switch (_that) {
case _RouteContext():
return $default(_that.fullPath,_that.pathParams,_that.queryParams,_that.queryParamsAll,_that.fragment);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String fullPath,  Map<String, String> pathParams,  Map<String, String> queryParams,  Map<String, List<String>> queryParamsAll,  String fragment)?  $default,) {final _that = this;
switch (_that) {
case _RouteContext() when $default != null:
return $default(_that.fullPath,_that.pathParams,_that.queryParams,_that.queryParamsAll,_that.fragment);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _RouteContext extends RouteContext {
  const _RouteContext({required this.fullPath, final  Map<String, String> pathParams = const {}, final  Map<String, String> queryParams = const {}, final  Map<String, List<String>> queryParamsAll = const {}, this.fragment = ''}): _pathParams = pathParams,_queryParams = queryParams,_queryParamsAll = queryParamsAll,super._();
  factory _RouteContext.fromJson(Map<String, dynamic> json) => _$RouteContextFromJson(json);

/// The full path of the current route.
@override final  String fullPath;
/// The path parameters extracted from the route.
 final  Map<String, String> _pathParams;
/// The path parameters extracted from the route.
@override@JsonKey() Map<String, String> get pathParams {
  if (_pathParams is EqualUnmodifiableMapView) return _pathParams;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_pathParams);
}

/// The query parameters extracted from the route.
 final  Map<String, String> _queryParams;
/// The query parameters extracted from the route.
@override@JsonKey() Map<String, String> get queryParams {
  if (_queryParams is EqualUnmodifiableMapView) return _queryParams;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_queryParams);
}

/// The query parameters extracted from the route, allowing multiple values per key.
 final  Map<String, List<String>> _queryParamsAll;
/// The query parameters extracted from the route, allowing multiple values per key.
@override@JsonKey() Map<String, List<String>> get queryParamsAll {
  if (_queryParamsAll is EqualUnmodifiableMapView) return _queryParamsAll;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_queryParamsAll);
}

/// The fragment identifier from the URL, if any.
@override@JsonKey() final  String fragment;

/// Create a copy of RouteContext
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$RouteContextCopyWith<_RouteContext> get copyWith => __$RouteContextCopyWithImpl<_RouteContext>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$RouteContextToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _RouteContext&&(identical(other.fullPath, fullPath) || other.fullPath == fullPath)&&const DeepCollectionEquality().equals(other._pathParams, _pathParams)&&const DeepCollectionEquality().equals(other._queryParams, _queryParams)&&const DeepCollectionEquality().equals(other._queryParamsAll, _queryParamsAll)&&(identical(other.fragment, fragment) || other.fragment == fragment));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,fullPath,const DeepCollectionEquality().hash(_pathParams),const DeepCollectionEquality().hash(_queryParams),const DeepCollectionEquality().hash(_queryParamsAll),fragment);

@override
String toString() {
  return 'RouteContext(fullPath: $fullPath, pathParams: $pathParams, queryParams: $queryParams, queryParamsAll: $queryParamsAll, fragment: $fragment)';
}


}

/// @nodoc
abstract mixin class _$RouteContextCopyWith<$Res> implements $RouteContextCopyWith<$Res> {
  factory _$RouteContextCopyWith(_RouteContext value, $Res Function(_RouteContext) _then) = __$RouteContextCopyWithImpl;
@override @useResult
$Res call({
 String fullPath, Map<String, String> pathParams, Map<String, String> queryParams, Map<String, List<String>> queryParamsAll, String fragment
});




}
/// @nodoc
class __$RouteContextCopyWithImpl<$Res>
    implements _$RouteContextCopyWith<$Res> {
  __$RouteContextCopyWithImpl(this._self, this._then);

  final _RouteContext _self;
  final $Res Function(_RouteContext) _then;

/// Create a copy of RouteContext
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? fullPath = null,Object? pathParams = null,Object? queryParams = null,Object? queryParamsAll = null,Object? fragment = null,}) {
  return _then(_RouteContext(
fullPath: null == fullPath ? _self.fullPath : fullPath // ignore: cast_nullable_to_non_nullable
as String,pathParams: null == pathParams ? _self._pathParams : pathParams // ignore: cast_nullable_to_non_nullable
as Map<String, String>,queryParams: null == queryParams ? _self._queryParams : queryParams // ignore: cast_nullable_to_non_nullable
as Map<String, String>,queryParamsAll: null == queryParamsAll ? _self._queryParamsAll : queryParamsAll // ignore: cast_nullable_to_non_nullable
as Map<String, List<String>>,fragment: null == fragment ? _self.fragment : fragment // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
