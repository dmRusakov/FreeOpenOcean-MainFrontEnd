import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:free_open_ocean/pages/page_template.dart';
import 'package:free_open_ocean/core/localization/AppLocalizations.dart';
import 'package:free_open_ocean_grpc/src/grpc/status/v1/status.pbgrpc.dart' show StatusClient;
import 'package:free_open_ocean_grpc/src/grpc/status/v1/status.pb.dart' show GetRequest;
import 'package:flutter/foundation.dart';
import 'package:grpc/grpc.dart';
import 'package:http/http.dart' as http;

const String statusGetPath = '/status.v1.Status/Get';

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
    try {
      if (kIsWeb) {
        // Use HTTP for web with JSON, matching the unit test
        final url = Uri.parse('http://localhost:8081/status.v1.Status/Get');
        final response = await http.post(
          url,
          headers: {'Content-Type': 'application/json'},
          body: '{}',
        );

        if (response.statusCode == 200) {
          // Parse the JSON response
          final data = jsonDecode(response.body);
          final id = data['id'];
          final name = data['name'];
          final loads = data['loads'];
          setState(() {
            statusResult = 'ID: $id, Name: $name, Loads: $loads%';
          });
        } else {
          setState(() {
            statusResult = 'Error: HTTP ${response.statusCode}';
          });
        }
      } else {
        // Existing gRPC logic for Android and Linux
        final host = '10.0.2.2';
        final port = 50051;
        final channel = ClientChannel(
          host,
          port: port,
          options: ChannelOptions(credentials: ChannelCredentials.insecure()),
        );
        final client = StatusClient(channel);
        final request = GetRequest();
        final response = await client.get(request);
        setState(() {
          statusResult = 'ID: ${response.id}, Name: ${response.name}, Loads: ${response.loads}%';
        });
        await channel.shutdown();
      }
    } catch (e) {
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
