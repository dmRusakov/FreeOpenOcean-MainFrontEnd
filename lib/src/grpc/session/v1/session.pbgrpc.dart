// This is a generated file - do not edit.
//
// Generated from session/v1/session.proto.

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

import 'session.pb.dart' as $0;

export 'session.pb.dart';

@$pb.GrpcServiceName('session.v1.SessionService')
class SessionServiceClient extends $grpc.Client {
  /// The hostname for this service.
  static const $core.String defaultHost = '';

  /// OAuth scopes needed for the client.
  static const $core.List<$core.String> oauthScopes = [
    '',
  ];

  SessionServiceClient(super.channel, {super.options, super.interceptors});

  $grpc.ResponseFuture<$0.MakeResponse> make(
    $0.MakeRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$make, request, options: options);
  }

  $grpc.ResponseFuture<$0.CheckResponse> check(
    $0.CheckRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$check, request, options: options);
  }

  $grpc.ResponseFuture<$0.DropResponse> drop(
    $0.DropRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$drop, request, options: options);
  }

  $grpc.ResponseFuture<$0.InfoResponse> info(
    $0.InfoRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$info, request, options: options);
  }

  // method descriptors

  static final _$make = $grpc.ClientMethod<$0.MakeRequest, $0.MakeResponse>(
      '/session.v1.SessionService/Make',
      ($0.MakeRequest value) => value.writeToBuffer(),
      $0.MakeResponse.fromBuffer);
  static final _$check = $grpc.ClientMethod<$0.CheckRequest, $0.CheckResponse>(
      '/session.v1.SessionService/Check',
      ($0.CheckRequest value) => value.writeToBuffer(),
      $0.CheckResponse.fromBuffer);
  static final _$drop = $grpc.ClientMethod<$0.DropRequest, $0.DropResponse>(
      '/session.v1.SessionService/Drop',
      ($0.DropRequest value) => value.writeToBuffer(),
      $0.DropResponse.fromBuffer);
  static final _$info = $grpc.ClientMethod<$0.InfoRequest, $0.InfoResponse>(
      '/session.v1.SessionService/Info',
      ($0.InfoRequest value) => value.writeToBuffer(),
      $0.InfoResponse.fromBuffer);
}

@$pb.GrpcServiceName('session.v1.SessionService')
abstract class SessionServiceBase extends $grpc.Service {
  $core.String get $name => 'session.v1.SessionService';

  SessionServiceBase() {
    $addMethod($grpc.ServiceMethod<$0.MakeRequest, $0.MakeResponse>(
        'Make',
        make_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $0.MakeRequest.fromBuffer(value),
        ($0.MakeResponse value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.CheckRequest, $0.CheckResponse>(
        'Check',
        check_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $0.CheckRequest.fromBuffer(value),
        ($0.CheckResponse value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.DropRequest, $0.DropResponse>(
        'Drop',
        drop_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $0.DropRequest.fromBuffer(value),
        ($0.DropResponse value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.InfoRequest, $0.InfoResponse>(
        'Info',
        info_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $0.InfoRequest.fromBuffer(value),
        ($0.InfoResponse value) => value.writeToBuffer()));
  }

  $async.Future<$0.MakeResponse> make_Pre(
      $grpc.ServiceCall $call, $async.Future<$0.MakeRequest> $request) async {
    return make($call, await $request);
  }

  $async.Future<$0.MakeResponse> make(
      $grpc.ServiceCall call, $0.MakeRequest request);

  $async.Future<$0.CheckResponse> check_Pre(
      $grpc.ServiceCall $call, $async.Future<$0.CheckRequest> $request) async {
    return check($call, await $request);
  }

  $async.Future<$0.CheckResponse> check(
      $grpc.ServiceCall call, $0.CheckRequest request);

  $async.Future<$0.DropResponse> drop_Pre(
      $grpc.ServiceCall $call, $async.Future<$0.DropRequest> $request) async {
    return drop($call, await $request);
  }

  $async.Future<$0.DropResponse> drop(
      $grpc.ServiceCall call, $0.DropRequest request);

  $async.Future<$0.InfoResponse> info_Pre(
      $grpc.ServiceCall $call, $async.Future<$0.InfoRequest> $request) async {
    return info($call, await $request);
  }

  $async.Future<$0.InfoResponse> info(
      $grpc.ServiceCall call, $0.InfoRequest request);
}
