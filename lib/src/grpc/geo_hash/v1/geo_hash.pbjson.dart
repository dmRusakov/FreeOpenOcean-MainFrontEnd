// This is a generated file - do not edit.
//
// Generated from geo_hash/v1/geo_hash.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_relative_imports
// ignore_for_file: unused_import

import 'dart:convert' as $convert;
import 'dart:core' as $core;
import 'dart:typed_data' as $typed_data;

@$core.Deprecated('Use encodeGeoHashRequestDescriptor instead')
const EncodeGeoHashRequest$json = {
  '1': 'EncodeGeoHashRequest',
  '2': [
    {'1': 'lat', '3': 1, '4': 1, '5': 1, '10': 'lat'},
    {'1': 'lon', '3': 2, '4': 1, '5': 1, '10': 'lon'},
    {'1': 'zoom', '3': 3, '4': 1, '5': 5, '10': 'zoom'},
  ],
};

/// Descriptor for `EncodeGeoHashRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List encodeGeoHashRequestDescriptor = $convert.base64Decode(
    'ChRFbmNvZGVHZW9IYXNoUmVxdWVzdBIQCgNsYXQYASABKAFSA2xhdBIQCgNsb24YAiABKAFSA2'
    'xvbhISCgR6b29tGAMgASgFUgR6b29t');

@$core.Deprecated('Use encodeGeoHashResponseDescriptor instead')
const EncodeGeoHashResponse$json = {
  '1': 'EncodeGeoHashResponse',
  '2': [
    {'1': 'hash', '3': 1, '4': 1, '5': 9, '10': 'hash'},
  ],
};

/// Descriptor for `EncodeGeoHashResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List encodeGeoHashResponseDescriptor =
    $convert.base64Decode(
        'ChVFbmNvZGVHZW9IYXNoUmVzcG9uc2USEgoEaGFzaBgBIAEoCVIEaGFzaA==');

@$core.Deprecated('Use checkGeoHashRequestDescriptor instead')
const CheckGeoHashRequest$json = {
  '1': 'CheckGeoHashRequest',
  '2': [
    {'1': 'hash', '3': 1, '4': 1, '5': 9, '10': 'hash'},
    {'1': 'lat', '3': 2, '4': 1, '5': 1, '10': 'lat'},
    {'1': 'lon', '3': 3, '4': 1, '5': 1, '10': 'lon'},
    {'1': 'zoom', '3': 4, '4': 1, '5': 5, '10': 'zoom'},
  ],
};

/// Descriptor for `CheckGeoHashRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List checkGeoHashRequestDescriptor = $convert.base64Decode(
    'ChNDaGVja0dlb0hhc2hSZXF1ZXN0EhIKBGhhc2gYASABKAlSBGhhc2gSEAoDbGF0GAIgASgBUg'
    'NsYXQSEAoDbG9uGAMgASgBUgNsb24SEgoEem9vbRgEIAEoBVIEem9vbQ==');

@$core.Deprecated('Use checkGeoHashResponseDescriptor instead')
const CheckGeoHashResponse$json = {
  '1': 'CheckGeoHashResponse',
  '2': [
    {'1': 'is_valid', '3': 1, '4': 1, '5': 8, '10': 'isValid'},
  ],
};

/// Descriptor for `CheckGeoHashResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List checkGeoHashResponseDescriptor =
    $convert.base64Decode(
        'ChRDaGVja0dlb0hhc2hSZXNwb25zZRIZCghpc192YWxpZBgBIAEoCFIHaXNWYWxpZA==');
