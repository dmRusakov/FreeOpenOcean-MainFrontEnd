import 'package:flutter/material.dart';
import 'package:free_open_ocean/pages/page_template.dart';
import 'package:free_open_ocean/core/localization/AppLocalizations.dart';
import 'package:grpc/grpc.dart';
import 'package:free_open_ocean/src/grpc/status/v1/status.pbgrpc.dart';
import 'package:flutter/foundation.dart';
import 'dart:io';

class UserPage extends StatefulWidget {
  final Map<String, String>? params;

  const UserPage({super.key, this.params});

  @override
  State<UserPage> createState() => _UserPageState();
}

class _UserPageState extends State<UserPage> {
  String statusResult = 'Loading status...';

  @override
  void initState() {
    super.initState();
    _callStatus();
  }

  Future<void> _callStatus() async {
    // check is web (wep get http 1.1 / other get grpc)
    print("55555555555555");
    print(kIsWeb);


    try {
      final host = Platform.isAndroid || Platform.isIOS ? '10.0.2.2' : 'localhost';
      final channel = ClientChannel(
        host,
        port: 50051,
        options: const ChannelOptions(credentials: ChannelCredentials.insecure()),
      );
      final client = StatusClient(channel);
      final request = GetRequest();
      final response = await client.get(request);
      setState(() {
        statusResult = 'ID: ${response.id}, Name: ${response.name}, Loads: ${response.loads}%';
      });
      await channel.shutdown();
    } catch (e) {
      print(e);
      setState(() {
        statusResult = 'Error: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;

    return PageTemplate(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(localizations.translate('user_page')),
            const SizedBox(height: 20),
            Text(statusResult),
          ],
        ),
      ),
    );
  }
}
