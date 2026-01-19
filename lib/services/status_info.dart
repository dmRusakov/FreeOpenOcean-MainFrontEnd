class StatusInfo {
  final bool ok;
  final String serverName;
  final String message;

  const StatusInfo({required this.ok, this.serverName = '', this.message = ''});
}
