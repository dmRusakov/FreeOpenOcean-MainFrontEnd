// This is a generated file - do not edit.
//
// Generated from geo_hash/v1/geo_hash.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_relative_imports

import 'dart:core' as $core;

import 'package:protobuf/protobuf.dart' as $pb;

export 'package:protobuf/protobuf.dart' show GeneratedMessageGenericExtensions;

class EncodeGeoHashRequest extends $pb.GeneratedMessage {
  factory EncodeGeoHashRequest({
    $core.double? lat,
    $core.double? lon,
    $core.int? zoom,
  }) {
    final result = create();
    if (lat != null) result.lat = lat;
    if (lon != null) result.lon = lon;
    if (zoom != null) result.zoom = zoom;
    return result;
  }

  EncodeGeoHashRequest._();

  factory EncodeGeoHashRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory EncodeGeoHashRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'EncodeGeoHashRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'geo_hash.v1'),
      createEmptyInstance: create)
    ..aD(1, _omitFieldNames ? '' : 'lat')
    ..aD(2, _omitFieldNames ? '' : 'lon')
    ..aI(3, _omitFieldNames ? '' : 'zoom')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  EncodeGeoHashRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  EncodeGeoHashRequest copyWith(void Function(EncodeGeoHashRequest) updates) =>
      super.copyWith((message) => updates(message as EncodeGeoHashRequest))
          as EncodeGeoHashRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static EncodeGeoHashRequest create() => EncodeGeoHashRequest._();
  @$core.override
  EncodeGeoHashRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static EncodeGeoHashRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<EncodeGeoHashRequest>(create);
  static EncodeGeoHashRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.double get lat => $_getN(0);
  @$pb.TagNumber(1)
  set lat($core.double value) => $_setDouble(0, value);
  @$pb.TagNumber(1)
  $core.bool hasLat() => $_has(0);
  @$pb.TagNumber(1)
  void clearLat() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.double get lon => $_getN(1);
  @$pb.TagNumber(2)
  set lon($core.double value) => $_setDouble(1, value);
  @$pb.TagNumber(2)
  $core.bool hasLon() => $_has(1);
  @$pb.TagNumber(2)
  void clearLon() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.int get zoom => $_getIZ(2);
  @$pb.TagNumber(3)
  set zoom($core.int value) => $_setSignedInt32(2, value);
  @$pb.TagNumber(3)
  $core.bool hasZoom() => $_has(2);
  @$pb.TagNumber(3)
  void clearZoom() => $_clearField(3);
}

class EncodeGeoHashResponse extends $pb.GeneratedMessage {
  factory EncodeGeoHashResponse({
    $core.String? hash,
  }) {
    final result = create();
    if (hash != null) result.hash = hash;
    return result;
  }

  EncodeGeoHashResponse._();

  factory EncodeGeoHashResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory EncodeGeoHashResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'EncodeGeoHashResponse',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'geo_hash.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'hash')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  EncodeGeoHashResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  EncodeGeoHashResponse copyWith(
          void Function(EncodeGeoHashResponse) updates) =>
      super.copyWith((message) => updates(message as EncodeGeoHashResponse))
          as EncodeGeoHashResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static EncodeGeoHashResponse create() => EncodeGeoHashResponse._();
  @$core.override
  EncodeGeoHashResponse createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static EncodeGeoHashResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<EncodeGeoHashResponse>(create);
  static EncodeGeoHashResponse? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get hash => $_getSZ(0);
  @$pb.TagNumber(1)
  set hash($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasHash() => $_has(0);
  @$pb.TagNumber(1)
  void clearHash() => $_clearField(1);
}

class CheckGeoHashRequest extends $pb.GeneratedMessage {
  factory CheckGeoHashRequest({
    $core.String? hash,
    $core.double? lat,
    $core.double? lon,
    $core.int? zoom,
  }) {
    final result = create();
    if (hash != null) result.hash = hash;
    if (lat != null) result.lat = lat;
    if (lon != null) result.lon = lon;
    if (zoom != null) result.zoom = zoom;
    return result;
  }

  CheckGeoHashRequest._();

  factory CheckGeoHashRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory CheckGeoHashRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'CheckGeoHashRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'geo_hash.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'hash')
    ..aD(2, _omitFieldNames ? '' : 'lat')
    ..aD(3, _omitFieldNames ? '' : 'lon')
    ..aI(4, _omitFieldNames ? '' : 'zoom')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  CheckGeoHashRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  CheckGeoHashRequest copyWith(void Function(CheckGeoHashRequest) updates) =>
      super.copyWith((message) => updates(message as CheckGeoHashRequest))
          as CheckGeoHashRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static CheckGeoHashRequest create() => CheckGeoHashRequest._();
  @$core.override
  CheckGeoHashRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static CheckGeoHashRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<CheckGeoHashRequest>(create);
  static CheckGeoHashRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get hash => $_getSZ(0);
  @$pb.TagNumber(1)
  set hash($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasHash() => $_has(0);
  @$pb.TagNumber(1)
  void clearHash() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.double get lat => $_getN(1);
  @$pb.TagNumber(2)
  set lat($core.double value) => $_setDouble(1, value);
  @$pb.TagNumber(2)
  $core.bool hasLat() => $_has(1);
  @$pb.TagNumber(2)
  void clearLat() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.double get lon => $_getN(2);
  @$pb.TagNumber(3)
  set lon($core.double value) => $_setDouble(2, value);
  @$pb.TagNumber(3)
  $core.bool hasLon() => $_has(2);
  @$pb.TagNumber(3)
  void clearLon() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.int get zoom => $_getIZ(3);
  @$pb.TagNumber(4)
  set zoom($core.int value) => $_setSignedInt32(3, value);
  @$pb.TagNumber(4)
  $core.bool hasZoom() => $_has(3);
  @$pb.TagNumber(4)
  void clearZoom() => $_clearField(4);
}

class CheckGeoHashResponse extends $pb.GeneratedMessage {
  factory CheckGeoHashResponse({
    $core.bool? isValid,
  }) {
    final result = create();
    if (isValid != null) result.isValid = isValid;
    return result;
  }

  CheckGeoHashResponse._();

  factory CheckGeoHashResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory CheckGeoHashResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'CheckGeoHashResponse',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'geo_hash.v1'),
      createEmptyInstance: create)
    ..aOB(1, _omitFieldNames ? '' : 'isValid')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  CheckGeoHashResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  CheckGeoHashResponse copyWith(void Function(CheckGeoHashResponse) updates) =>
      super.copyWith((message) => updates(message as CheckGeoHashResponse))
          as CheckGeoHashResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static CheckGeoHashResponse create() => CheckGeoHashResponse._();
  @$core.override
  CheckGeoHashResponse createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static CheckGeoHashResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<CheckGeoHashResponse>(create);
  static CheckGeoHashResponse? _defaultInstance;

  @$pb.TagNumber(1)
  $core.bool get isValid => $_getBF(0);
  @$pb.TagNumber(1)
  set isValid($core.bool value) => $_setBool(0, value);
  @$pb.TagNumber(1)
  $core.bool hasIsValid() => $_has(0);
  @$pb.TagNumber(1)
  void clearIsValid() => $_clearField(1);
}

const $core.bool _omitFieldNames =
    $core.bool.fromEnvironment('protobuf.omit_field_names');
const $core.bool _omitMessageNames =
    $core.bool.fromEnvironment('protobuf.omit_message_names');
