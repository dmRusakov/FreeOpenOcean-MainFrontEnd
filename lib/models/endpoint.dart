class Endpoint {
  late String id;
  late String name;
  final String httpHost;
  final int httpPort;
  final String grpcHost;
  final int grpcPort;
  final bool grpcSecure;
  final String country;
  late bool isGrpc;
  late String appKey;
  late bool isActive;
  late int loads;
  late Duration durations; // load time duration for the endpoint

  Endpoint({
    required this.id,
    this.name = '',
    required this.grpcHost,
    required this.grpcPort,
    this.grpcSecure = false,
    required this.httpHost,
    required this.httpPort,
    required this.country,
    this.appKey = 'none',
    this.isGrpc = false,
    this.isActive = false,
    this.loads = 0,
    this.durations = Duration.zero,
  });

  Uri httpStatusUri(String path) {
    final base = Uri.parse(httpHost);
    final prefix = base.path.replaceFirst(RegExp(r'/$'), '');
    return base.replace(port: httpPort, path: '$prefix$path');
  }
}
