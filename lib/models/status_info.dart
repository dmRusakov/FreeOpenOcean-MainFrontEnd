class StatusInfo {
  final bool ok;
  final String serverName;
  final String message;
  final int loads;

  const StatusInfo({required this.ok, this.serverName = '', this.loads = 0, this.message = ''});
}
