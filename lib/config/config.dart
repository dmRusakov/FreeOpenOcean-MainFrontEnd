import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../models/endpoint.dart';

class Config {
  static String get apiKey => '42f6ab2492a77fae';

  static final List<Endpoint> endpoints = [
    Endpoint(id: 'foo-central-1', country: 'USA', httpHost: 'http://localhost', httpPort: 8081, grpcHost: '10.0.2.2', grpcPort: 50051),
    Endpoint(id: 'foo-central-2', country: 'USA', httpHost: 'http://localhost', httpPort: 8082, grpcHost: '10.0.2.2', grpcPort: 50052),
  ];
}
