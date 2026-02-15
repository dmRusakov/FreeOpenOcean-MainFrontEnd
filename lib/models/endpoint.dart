class Endpoint {
  late String id;
  late String name;
  final String httpHost;
  final int httpPort;
  final String grpcHost;
  final int grpcPort;
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
    required this.httpHost,
    required this.httpPort,
    required this.country,
    this.appKey = 'none',
    this.isGrpc = false,
    this.isActive = false,
  });

  Uri httpStatusUri(String path) => Uri.parse('$httpHost:$httpPort$path');
}
