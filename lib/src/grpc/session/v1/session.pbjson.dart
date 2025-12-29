// This is a generated file - do not edit.
//
// Generated from session/v1/session.proto.

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

@$core.Deprecated('Use makeRequestDescriptor instead')
const MakeRequest$json = {
  '1': 'MakeRequest',
  '2': [
    {'1': 'username', '3': 1, '4': 1, '5': 9, '10': 'username'},
    {'1': 'password', '3': 2, '4': 1, '5': 9, '10': 'password'},
  ],
};

/// Descriptor for `MakeRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List makeRequestDescriptor = $convert.base64Decode(
    'CgtNYWtlUmVxdWVzdBIaCgh1c2VybmFtZRgBIAEoCVIIdXNlcm5hbWUSGgoIcGFzc3dvcmQYAi'
    'ABKAlSCHBhc3N3b3Jk');

@$core.Deprecated('Use makeResponseDescriptor instead')
const MakeResponse$json = {
  '1': 'MakeResponse',
  '2': [
    {'1': 'success', '3': 1, '4': 1, '5': 8, '10': 'success'},
    {'1': 'token', '3': 2, '4': 1, '5': 9, '10': 'token'},
    {'1': 'user_id', '3': 3, '4': 1, '5': 9, '10': 'userId'},
    {'1': 'session_expired', '3': 4, '4': 1, '5': 9, '10': 'sessionExpired'},
  ],
};

/// Descriptor for `MakeResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List makeResponseDescriptor = $convert.base64Decode(
    'CgxNYWtlUmVzcG9uc2USGAoHc3VjY2VzcxgBIAEoCFIHc3VjY2VzcxIUCgV0b2tlbhgCIAEoCV'
    'IFdG9rZW4SFwoHdXNlcl9pZBgDIAEoCVIGdXNlcklkEicKD3Nlc3Npb25fZXhwaXJlZBgEIAEo'
    'CVIOc2Vzc2lvbkV4cGlyZWQ=');

@$core.Deprecated('Use checkRequestDescriptor instead')
const CheckRequest$json = {
  '1': 'CheckRequest',
  '2': [
    {'1': 'username', '3': 1, '4': 1, '5': 9, '10': 'username'},
  ],
};

/// Descriptor for `CheckRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List checkRequestDescriptor = $convert
    .base64Decode('CgxDaGVja1JlcXVlc3QSGgoIdXNlcm5hbWUYASABKAlSCHVzZXJuYW1l');

@$core.Deprecated('Use checkResponseDescriptor instead')
const CheckResponse$json = {
  '1': 'CheckResponse',
  '2': [
    {'1': 'is_authenticated', '3': 1, '4': 1, '5': 8, '10': 'isAuthenticated'},
    {'1': 'session_expired', '3': 2, '4': 1, '5': 9, '10': 'sessionExpired'},
    {'1': 'new_token', '3': 3, '4': 1, '5': 9, '10': 'newToken'},
  ],
};

/// Descriptor for `CheckResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List checkResponseDescriptor = $convert.base64Decode(
    'Cg1DaGVja1Jlc3BvbnNlEikKEGlzX2F1dGhlbnRpY2F0ZWQYASABKAhSD2lzQXV0aGVudGljYX'
    'RlZBInCg9zZXNzaW9uX2V4cGlyZWQYAiABKAlSDnNlc3Npb25FeHBpcmVkEhsKCW5ld190b2tl'
    'bhgDIAEoCVIIbmV3VG9rZW4=');

@$core.Deprecated('Use dropRequestDescriptor instead')
const DropRequest$json = {
  '1': 'DropRequest',
  '2': [
    {'1': 'username', '3': 1, '4': 1, '5': 9, '10': 'username'},
  ],
};

/// Descriptor for `DropRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List dropRequestDescriptor = $convert
    .base64Decode('CgtEcm9wUmVxdWVzdBIaCgh1c2VybmFtZRgBIAEoCVIIdXNlcm5hbWU=');

@$core.Deprecated('Use dropResponseDescriptor instead')
const DropResponse$json = {
  '1': 'DropResponse',
  '2': [
    {'1': 'success', '3': 1, '4': 1, '5': 8, '10': 'success'},
  ],
};

/// Descriptor for `DropResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List dropResponseDescriptor = $convert
    .base64Decode('CgxEcm9wUmVzcG9uc2USGAoHc3VjY2VzcxgBIAEoCFIHc3VjY2Vzcw==');

@$core.Deprecated('Use infoRequestDescriptor instead')
const InfoRequest$json = {
  '1': 'InfoRequest',
  '2': [
    {'1': 'username', '3': 1, '4': 1, '5': 9, '10': 'username'},
  ],
};

/// Descriptor for `InfoRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List infoRequestDescriptor = $convert
    .base64Decode('CgtJbmZvUmVxdWVzdBIaCgh1c2VybmFtZRgBIAEoCVIIdXNlcm5hbWU=');

@$core.Deprecated('Use infoResponseDescriptor instead')
const InfoResponse$json = {
  '1': 'InfoResponse',
  '2': [
    {'1': 'user_id', '3': 10, '4': 1, '5': 9, '10': 'userId'},
    {'1': 'username', '3': 11, '4': 1, '5': 9, '10': 'username'},
    {'1': 'first_name', '3': 12, '4': 1, '5': 9, '10': 'firstName'},
    {'1': 'middle_name', '3': 13, '4': 1, '5': 9, '10': 'middleName'},
    {'1': 'last_name', '3': 14, '4': 1, '5': 9, '10': 'lastName'},
    {'1': 'email', '3': 20, '4': 1, '5': 9, '10': 'email'},
    {'1': 'roles', '3': 30, '4': 3, '5': 9, '10': 'roles'},
    {'1': 'language', '3': 40, '4': 1, '5': 9, '10': 'language'},
    {'1': 'timezone', '3': 41, '4': 1, '5': 9, '10': 'timezone'},
    {'1': 'theme', '3': 42, '4': 1, '5': 9, '10': 'theme'},
    {'1': 'notifications', '3': 43, '4': 1, '5': 8, '10': 'notifications'},
    {'1': 'session_expired', '3': 50, '4': 1, '5': 9, '10': 'sessionExpired'},
    {'1': 'profile_picture', '3': 60, '4': 1, '5': 9, '10': 'profilePicture'},
  ],
};

/// Descriptor for `InfoResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List infoResponseDescriptor = $convert.base64Decode(
    'CgxJbmZvUmVzcG9uc2USFwoHdXNlcl9pZBgKIAEoCVIGdXNlcklkEhoKCHVzZXJuYW1lGAsgAS'
    'gJUgh1c2VybmFtZRIdCgpmaXJzdF9uYW1lGAwgASgJUglmaXJzdE5hbWUSHwoLbWlkZGxlX25h'
    'bWUYDSABKAlSCm1pZGRsZU5hbWUSGwoJbGFzdF9uYW1lGA4gASgJUghsYXN0TmFtZRIUCgVlbW'
    'FpbBgUIAEoCVIFZW1haWwSFAoFcm9sZXMYHiADKAlSBXJvbGVzEhoKCGxhbmd1YWdlGCggASgJ'
    'UghsYW5ndWFnZRIaCgh0aW1lem9uZRgpIAEoCVIIdGltZXpvbmUSFAoFdGhlbWUYKiABKAlSBX'
    'RoZW1lEiQKDW5vdGlmaWNhdGlvbnMYKyABKAhSDW5vdGlmaWNhdGlvbnMSJwoPc2Vzc2lvbl9l'
    'eHBpcmVkGDIgASgJUg5zZXNzaW9uRXhwaXJlZBInCg9wcm9maWxlX3BpY3R1cmUYPCABKAlSDn'
    'Byb2ZpbGVQaWN0dXJl');
