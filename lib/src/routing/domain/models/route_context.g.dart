// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'route_context.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_RouteContext _$RouteContextFromJson(Map<String, dynamic> json) =>
    _RouteContext(
      fullPath: json['fullPath'] as String,
      pathParams:
          (json['pathParams'] as Map<String, dynamic>?)?.map(
            (k, e) => MapEntry(k, e as String),
          ) ??
          const {},
      queryParams:
          (json['queryParams'] as Map<String, dynamic>?)?.map(
            (k, e) => MapEntry(k, e as String),
          ) ??
          const {},
      queryParamsAll:
          (json['queryParamsAll'] as Map<String, dynamic>?)?.map(
            (k, e) => MapEntry(
              k,
              (e as List<dynamic>).map((e) => e as String).toList(),
            ),
          ) ??
          const {},
      fragment: json['fragment'] as String? ?? '',
    );

Map<String, dynamic> _$RouteContextToJson(_RouteContext instance) =>
    <String, dynamic>{
      'fullPath': instance.fullPath,
      'pathParams': instance.pathParams,
      'queryParams': instance.queryParams,
      'queryParamsAll': instance.queryParamsAll,
      'fragment': instance.fragment,
    };
