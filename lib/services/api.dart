import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:grpc/grpc.dart';
import 'package:http/http.dart' as http;
import 'package:free_open_ocean_grpc/src/grpc/status/v1/status.pbgrpc.dart' show StatusClient;
import 'package:free_open_ocean_grpc/src/grpc/status/v1/status.pb.dart' show GetRequest;
import 'package:free_open_ocean/services/status_info.dart';
import 'package:free_open_ocean/services/settings_service.dart';

class Endpoint {
  final String name;
  final String httpHost;
  final int httpPort;
  final String grpcHost;
  final int grpcPort;
  final String country;

  const Endpoint({
    required this.name,
    required this.httpHost,
    required this.httpPort,
    required this.grpcHost,
    required this.grpcPort,
    required this.country,
  });

  Uri httpStatusUri(String path) => Uri.parse('http://$httpHost:$httpPort$path');
}

class Api {
  static const String statusGetPath = '/status.v1.Status/Get';

  final SettingsService? settingsService;
  final Duration retryInterval;

  Api({this.settingsService, this.retryInterval = const Duration(seconds: 20)});

  static const List<Endpoint> endpoints = [
    Endpoint(name: 'local-1', country: 'USA', httpHost: 'localhost', httpPort: 8081, grpcHost: '10.0.2.2', grpcPort: 50051),
    Endpoint(name: 'local-2', country: 'USA', httpHost: 'localhost', httpPort: 8082, grpcHost: '10.0.2.2', grpcPort: 50052),
  ];

  Endpoint? _selectedEndpoint;
  bool _discovering = false;
  Timer? _retryTimer;
  bool _retrying = false;

  /// Public getter for the selected endpoint (may be null until discovered)
  Endpoint? get selectedEndpoint => _selectedEndpoint;

  void _startRetrying() {
    if (_retrying) return;
    _retrying = true;
    _retryTimer = Timer.periodic(retryInterval, (_) async {
      try {
        await discoverBestEndpoint();
        // if discovered an endpoint (i.e., one responded OK) stop retrying
        if (_selectedEndpoint != null) {
          _stopRetrying();
        }
      } catch (_) {
        // ignore and keep retrying
      }
    });
  }

  void _stopRetrying() {
    _retryTimer?.cancel();
    _retryTimer = null;
    _retrying = false;
  }

  /// Discover and select the best endpoint from the configured list.
  /// Selection criteria: endpoint that responds OK and has the lowest numeric `loads`.
  Future<void> discoverBestEndpoint({Duration timeout = const Duration(seconds: 3), bool force = false}) async {
    // If there's already a selected endpoint and discovery isn't forced, skip probing.
    if (_selectedEndpoint != null && !force) return;
    if (_discovering) return;
    _discovering = true;
    try {
      // try load from settings first (but verify it's actually reachable)
      final tried = <String>{};
      if (settingsService != null) {
        final saved = await settingsService!.loadSelectedEndpointName();
        if (saved != null && saved.isNotEmpty) {
          final match = endpoints.firstWhere((e) => e.name == saved, orElse: () => endpoints.first);
          tried.add(match.name);
          final probe = await _probeEndpoint(match, timeout: timeout);
          if (probe.ok) {
            _selectedEndpoint = match;
            if (settingsService != null) await settingsService!.saveSelectedEndpointName(_selectedEndpoint!.name);
            return;
          }
          // saved endpoint not reachable - continue probing others
        }
      }
      final List<_ProbeResult> results = [];

      for (final ep in endpoints) {
        if (tried.contains(ep.name)) continue;
        try {
          if (kIsWeb) {
            final probe = await _probeEndpoint(ep, timeout: timeout);
            results.add(probe);
          } else {
            final probe = await _probeEndpoint(ep, timeout: timeout);
            results.add(probe);
          }
        } catch (_) {
          // timeout or network error - treat as unreachable
          results.add(_ProbeResult(endpoint: ep, ok: false, loads: double.infinity, serverName: ep.name));
        }
      }

      // pick the ok endpoint with the minimal loads
      _ProbeResult? best;
      for (final r in results) {
        if (!r.ok) continue;
        if (best == null || r.loads < best.loads) best = r;
      }

      if (best != null) {
        _selectedEndpoint = best.endpoint;
        // persist selected endpoint name
        if (settingsService != null) {
          await settingsService!.saveSelectedEndpointName(_selectedEndpoint!.name);
        }
        // found a working endpoint -> stop any retry timer
        _stopRetrying();
      }
    } finally {
      _discovering = false;
    }
  }

  /// Helper: parse a `loads` value that may be numeric or string.
  static double _parseLoads(dynamic v) {
    if (v == null) return double.infinity;
    if (v is num) return v.toDouble();
    if (v is String) return double.tryParse(v) ?? double.infinity;
    return double.infinity;
  }

  /// Fetch status. Uses discovered endpoint (or discovers one first).
  /// Returns StatusInfo with ok/serverName/message.
  Future<StatusInfo> getStatus() async {
    // ensure endpoint discovered
    if (_selectedEndpoint == null) {
      // try an immediate discovery (force) before returning failure
      await discoverBestEndpoint(force: true);
    }

    final ep = _selectedEndpoint;
    if (ep == null) {
      // nothing discovered -> start periodic retrying and return failure
      _startRetrying();
      return const StatusInfo(ok: false, serverName: '', message: 'No endpoint available');
    }

    try {
      if (kIsWeb) {
        final url = Uri.parse('http://${ep.httpHost}:${ep.httpPort}$statusGetPath');
        final response = await http.post(
          url,
          headers: {'Content-Type': 'application/json'},
          body: '{}',
        ).timeout(const Duration(seconds: 5));

        if (response.statusCode == 200) {
          try {
            final data = jsonDecode(response.body);
            final id = data['id']?.toString() ?? '';
            final name = data['name']?.toString() ?? '';
            final loads = data['loads']?.toString() ?? '';
            final message = 'ID: $id, Name: $name, Loads: $loads%';
            return StatusInfo(ok: true, serverName: name, message: message);
          } catch (e) {
            return StatusInfo(ok: true, serverName: '', message: response.body);
          }
        } else {
          // server returned non-OK -> clear selected endpoint and try discovery
          _selectedEndpoint = null;
          await discoverBestEndpoint(force: true);
          if (_selectedEndpoint == null) _startRetrying();
          return StatusInfo(ok: false, serverName: '', message: 'HTTP ${response.statusCode}');
        }
      } else {
        final channel = ClientChannel(
          ep.grpcHost,
          port: ep.grpcPort,
          options: ChannelOptions(credentials: ChannelCredentials.insecure()),
        );

        try {
          final client = StatusClient(channel);
          final request = GetRequest();
          try {
            final response = await client.get(request).timeout(const Duration(seconds: 5));
            final message = 'ID: ${response.id}, Name: ${response.name}, Loads: ${response.loads}%';
            // success -> stop retrying
            _stopRetrying();
            return StatusInfo(ok: true, serverName: response.name, message: message);
          } catch (e) {
            // gRPC call failed -> clear selected endpoint and start re-discovery/retry
            _selectedEndpoint = null;
            await discoverBestEndpoint(force: true);
            if (_selectedEndpoint == null) _startRetrying();
            return StatusInfo(ok: false, serverName: '', message: e.toString());
          }
         } finally {
           await channel.shutdown();
         }
      }
    } catch (e) {
      // network or unexpected error -> clear selected endpoint and start retrying
      _selectedEndpoint = null;
      await discoverBestEndpoint(force: true);
      if (_selectedEndpoint == null) _startRetrying();
      return StatusInfo(ok: false, serverName: '', message: e.toString());
    }
  }

  /// Probe a single endpoint for status. Returns a ProbeResult with ok flag and parsed loads.
  Future<_ProbeResult> _probeEndpoint(Endpoint ep, {Duration timeout = const Duration(seconds: 3)}) async {
    try {
      if (kIsWeb) {
        final uri = ep.httpStatusUri(statusGetPath);
        final resp = await http.post(uri, headers: {'Content-Type': 'application/json'}, body: '{}').timeout(timeout);
        if (resp.statusCode == 200) {
          try {
            final data = jsonDecode(resp.body);
            final loadsVal = data['loads'];
            final loads = _parseLoads(loadsVal);
            final name = data['name']?.toString() ?? ep.name;
            return _ProbeResult(endpoint: ep, ok: true, loads: loads, serverName: name);
          } catch (_) {
            return _ProbeResult(endpoint: ep, ok: true, loads: double.infinity, serverName: ep.name);
          }
        }
        return _ProbeResult(endpoint: ep, ok: false, loads: double.infinity, serverName: ep.name);
      } else {
        final channel = ClientChannel(
          ep.grpcHost,
          port: ep.grpcPort,
          options: ChannelOptions(credentials: ChannelCredentials.insecure()),
        );
        try {
          final client = StatusClient(channel);
          final request = GetRequest();
          final response = await client.get(request).timeout(timeout);
          final loads = double.tryParse(response.loads.toString()) ?? double.infinity;
          final serverName = response.name.toString().isEmpty ? ep.name : response.name.toString();
          return _ProbeResult(endpoint: ep, ok: true, loads: loads, serverName: serverName);
        } catch (_) {
          return _ProbeResult(endpoint: ep, ok: false, loads: double.infinity, serverName: ep.name);
        } finally {
          await channel.shutdown();
        }
      }
    } catch (_) {
      return _ProbeResult(endpoint: ep, ok: false, loads: double.infinity, serverName: ep.name);
    }
  }
}

class _ProbeResult {
  final Endpoint endpoint;
  final bool ok;
  final double loads;
  final String serverName;

  _ProbeResult({required this.endpoint, required this.ok, required this.loads, required this.serverName});
}
