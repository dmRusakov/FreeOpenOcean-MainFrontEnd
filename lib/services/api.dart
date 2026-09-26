import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:grpc/grpc.dart';
import 'package:http/http.dart' as http;
// The contracts package currently exposes generated files only.
// ignore: implementation_imports
import 'package:foo_grpc/src/grpc/v1/status.pbgrpc.dart' as status_pb;
import '../config/config.dart';
import '../models/endpoint.dart';
import '../models/connection_exception.dart';
import 'app.dart';

enum ConnectionMode { normal, silent, disable }

enum ConnectionStatus { online, connecting, offline }

class Api {
  static const statusGetPath = '/status.v1.Status/Get';
  final App app;
  final Duration retryInterval;
  final Duration healthInterval;
  final Duration probeTimeout;
  final List<Endpoint> endpoints;
  final bool useHttp;
  final http.Client Function() clientFactory;
  final Set<http.Client> _clients = {};
  final Set<ClientChannel> _channels = {};
  Timer? _timer;
  Future<void>? _refreshing;
  late ConnectionMode _mode;
  int _generation = 0;
  bool _disposed = false;

  Api({
    required this.app,
    List<Endpoint>? endpoints,
    this.retryInterval = const Duration(seconds: 20),
    this.healthInterval = const Duration(minutes: 15),
    this.probeTimeout = const Duration(seconds: 5),
    this.useHttp = kIsWeb,
    http.Client Function()? clientFactory,
    bool autoStart = true,
  }) : endpoints = endpoints ?? Config.endpoints,
       clientFactory = clientFactory ?? http.Client.new {
    _mode = app.connectionMode;
    app.addListener(_onAppChanged);
    if (autoStart) unawaited(refresh());
  }

  Endpoint? get selectedEndpoint => app.endpoint;
  bool get isEnabled =>
      !_disposed && app.connectionMode != ConnectionMode.disable;

  void _ensureEnabled([int? generation]) {
    if (!isEnabled || generation != null && generation != _generation) {
      throw const ConnectionUnavailable(
        'Backend connection is disabled or has changed.',
      );
    }
  }

  void _onAppChanged() {
    if (_mode == app.connectionMode) return;
    final wasDisabled = _mode == ConnectionMode.disable;
    _mode = app.connectionMode;
    if (_mode == ConnectionMode.disable) {
      _generation++;
      _refreshing = null;
      _timer?.cancel();
      _cancelRequests();
      unawaited(app.setConnectionStatus(ConnectionStatus.offline));
    } else if (wasDisabled) {
      unawaited(refresh());
    }
  }

  void _cancelRequests() {
    for (final client in _clients.toList()) {
      client.close();
    }
    _clients.clear();
    for (final channel in _channels.toList()) {
      unawaited(channel.terminate());
    }
    _channels.clear();
  }

  Future<http.Response> post(
    Endpoint ep,
    String path,
    List<int> body, {
    Duration timeout = const Duration(seconds: 10),
  }) async {
    _ensureEnabled();
    final generation = _generation;
    final sessionId = await app.getSessionId();
    _ensureEnabled(generation);
    final client = clientFactory();
    _clients.add(client);
    try {
      final response = await client
          .post(
            ep.httpStatusUri(path),
            headers: {
              'Content-Type': 'application/x-protobuf',
              'X-App-Session': sessionId,
              'X-App-Key': ep.appKey,
            },
            body: body,
          )
          .timeout(timeout);
      _ensureEnabled(generation);
      return response;
    } finally {
      _clients.remove(client);
      client.close();
    }
  }

  Future<T> grpc<T>(
    Endpoint ep,
    Future<T> Function(ClientChannel, CallOptions) request, {
    Duration timeout = const Duration(seconds: 10),
  }) async {
    _ensureEnabled();
    final generation = _generation;
    final sessionId = await app.getSessionId();
    _ensureEnabled(generation);
    final channel = ClientChannel(
      ep.grpcHost,
      port: ep.grpcPort,
      options: ChannelOptions(
        credentials: ep.grpcSecure
            ? const ChannelCredentials.secure()
            : const ChannelCredentials.insecure(),
      ),
    );
    _channels.add(channel);
    try {
      final result = await request(
        channel,
        CallOptions(
          timeout: timeout,
          metadata: {'x-app-session': sessionId, 'x-app-key': ep.appKey},
        ),
      ).timeout(timeout);
      _ensureEnabled(generation);
      return result;
    } finally {
      _channels.remove(channel);
      await channel.terminate();
    }
  }

  Future<bool> checkEndpoint(
    Endpoint ep, {
    Duration timeout = const Duration(seconds: 5),
  }) async {
    if (!isEnabled) return false;
    final started = DateTime.now();
    try {
      final request = status_pb.GetRequest();
      final status_pb.GetResponse response;
      if (useHttp) {
        final result = await post(
          ep,
          statusGetPath,
          request.writeToBuffer(),
          timeout: timeout,
        );
        if (result.statusCode != 200) return false;
        response = status_pb.GetResponse.fromBuffer(result.bodyBytes);
      } else {
        response = await grpc(
          ep,
          (channel, options) =>
              status_pb.StatusClient(channel).get(request, options: options),
          timeout: timeout,
        );
      }
      ep.id = response.id;
      ep.name = response.name;
      ep.appKey = response.key;
      ep.loads = 0;
      ep.isGrpc = !useHttp;
      ep.durations = DateTime.now().difference(started);
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<Endpoint?> getFastestEndpoint(
    List<Endpoint> candidates, {
    Duration timeout = const Duration(seconds: 5),
  }) async {
    if (!isEnabled) return null;
    final results = await Future.wait(
      candidates.map(
        (ep) async => await checkEndpoint(ep, timeout: timeout) ? ep : null,
      ),
    );
    final reachable = results.whereType<Endpoint>().toList()
      ..sort((a, b) => a.durations.compareTo(b.durations));
    return reachable.isEmpty ? null : reachable.first;
  }

  Future<void> refresh() {
    if (_disposed) return Future.value();
    if (!isEnabled) return app.setConnectionStatus(ConnectionStatus.offline);
    if (_refreshing != null) return _refreshing!;
    _timer?.cancel();
    final generation = _generation;
    late final Future<void> work;
    work = _discover(generation).whenComplete(() {
      if (identical(_refreshing, work)) _refreshing = null;
      if (isEnabled && generation == _generation) {
        _timer = Timer(
          selectedEndpoint == null ? retryInterval : healthInterval,
          () => unawaited(refresh()),
        );
      }
    });
    _refreshing = work;
    return work;
  }

  Future<void> _discover(int generation) async {
    await app.setConnectionStatus(ConnectionStatus.connecting);
    final fastest = await getFastestEndpoint(endpoints, timeout: probeTimeout);
    if (!isEnabled || generation != _generation) return;
    // Publish availability before persisting the selected endpoint.
    final saved = app.setEndpoint(fastest);
    await app.setConnectionStatus(
      fastest == null ? ConnectionStatus.offline : ConnectionStatus.online,
    );
    try {
      await saved;
    } catch (error) {
      debugPrint('Could not persist the selected endpoint: $error');
    }
  }

  void dispose() {
    if (_disposed) return;
    _disposed = true;
    _generation++;
    app.removeListener(_onAppChanged);
    _timer?.cancel();
    _cancelRequests();
  }
}
