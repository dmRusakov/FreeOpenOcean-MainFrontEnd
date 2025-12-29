// This is a generated file - do not edit.
//
// Generated from geo_hash/v1/geo_hash.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_relative_imports

import 'dart:async' as $async;
import 'dart:core' as $core;

import 'package:grpc/service_api.dart' as $grpc;
import 'package:protobuf/protobuf.dart' as $pb;

import 'geo_hash.pb.dart' as $0;

export 'geo_hash.pb.dart';

@$pb.GrpcServiceName('geo_hash.v1.GeoHash')
class GeoHashClient extends $grpc.Client {
  /// The hostname for this service.
  static const $core.String defaultHost = '';

  /// OAuth scopes needed for the client.
  static const $core.List<$core.String> oauthScopes = [
    '',
  ];

  GeoHashClient(super.channel, {super.options, super.interceptors});

  $grpc.ResponseFuture<$0.EncodeGeoHashResponse> encode(
    $0.EncodeGeoHashRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$encode, request, options: options);
  }

  $grpc.ResponseFuture<$0.CheckGeoHashResponse> check(
    $0.CheckGeoHashRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$check, request, options: options);
  }

  // method descriptors

  static final _$encode =
      $grpc.ClientMethod<$0.EncodeGeoHashRequest, $0.EncodeGeoHashResponse>(
          '/geo_hash.v1.GeoHash/Encode',
          ($0.EncodeGeoHashRequest value) => value.writeToBuffer(),
          $0.EncodeGeoHashResponse.fromBuffer);
  static final _$check =
      $grpc.ClientMethod<$0.CheckGeoHashRequest, $0.CheckGeoHashResponse>(
          '/geo_hash.v1.GeoHash/Check',
          ($0.CheckGeoHashRequest value) => value.writeToBuffer(),
          $0.CheckGeoHashResponse.fromBuffer);
}

@$pb.GrpcServiceName('geo_hash.v1.GeoHash')
abstract class GeoHashServiceBase extends $grpc.Service {
  $core.String get $name => 'geo_hash.v1.GeoHash';

  GeoHashServiceBase() {
    $addMethod(
        $grpc.ServiceMethod<$0.EncodeGeoHashRequest, $0.EncodeGeoHashResponse>(
            'Encode',
            encode_Pre,
            false,
            false,
            ($core.List<$core.int> value) =>
                $0.EncodeGeoHashRequest.fromBuffer(value),
            ($0.EncodeGeoHashResponse value) => value.writeToBuffer()));
    $addMethod(
        $grpc.ServiceMethod<$0.CheckGeoHashRequest, $0.CheckGeoHashResponse>(
            'Check',
            check_Pre,
            false,
            false,
            ($core.List<$core.int> value) =>
                $0.CheckGeoHashRequest.fromBuffer(value),
            ($0.CheckGeoHashResponse value) => value.writeToBuffer()));
  }

  $async.Future<$0.EncodeGeoHashResponse> encode_Pre($grpc.ServiceCall $call,
      $async.Future<$0.EncodeGeoHashRequest> $request) async {
    return encode($call, await $request);
  }

  $async.Future<$0.EncodeGeoHashResponse> encode(
      $grpc.ServiceCall call, $0.EncodeGeoHashRequest request);

  $async.Future<$0.CheckGeoHashResponse> check_Pre($grpc.ServiceCall $call,
      $async.Future<$0.CheckGeoHashRequest> $request) async {
    return check($call, await $request);
  }

  $async.Future<$0.CheckGeoHashResponse> check(
      $grpc.ServiceCall call, $0.CheckGeoHashRequest request);
}
