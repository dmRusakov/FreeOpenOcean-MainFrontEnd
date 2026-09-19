class ConnectionUnavailable implements Exception {
  final String message;
  const ConnectionUnavailable([
    this.message = 'No backend connection is available.',
  ]);
  @override
  String toString() => message;
}
