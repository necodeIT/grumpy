// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'storage_key.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_StorageKey _$StorageKeyFromJson(Map<String, dynamic> json) => _StorageKey(
  namespace: json['namespace'] as String,
  primaryKey: json['primaryKey'] as String,
  schemaId: json['schemaId'] as String,
  compatVersion: (json['compatVersion'] as num?)?.toInt(),
);

Map<String, dynamic> _$StorageKeyToJson(_StorageKey instance) =>
    <String, dynamic>{
      'namespace': instance.namespace,
      'primaryKey': instance.primaryKey,
      'schemaId': instance.schemaId,
      'compatVersion': instance.compatVersion,
    };
