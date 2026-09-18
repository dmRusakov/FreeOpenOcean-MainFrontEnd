import 'package:flutter/material.dart';
// The contracts package currently exposes generated files only.
// ignore: implementation_imports
import 'package:free_open_ocean_grpc/src/grpc/pages/v1/pages.pbgrpc.dart'
    as pages_pb;
import 'api.dart';

class PageService {
  static const pageGetPath = '/pages.v1.PageService/Get';
  final Api api;
  PageService(this.api);

  Future<pages_pb.Page> get(
    BuildContext context,
    String slug,
    String language,
    String country,
  ) async {
    final request = pages_pb.GetRequest()
      ..slug = slug.toLowerCase()
      ..languageCode = language.toLowerCase()
      ..countryCode = country.toLowerCase();
    final ep = await api.app.getEndpoint();
    if (api.useHttp) {
      final response = await api.post(ep, pageGetPath, request.writeToBuffer());
      if (response.statusCode != 200) {
        throw Exception('Page request failed (HTTP ${response.statusCode}).');
      }
      return pages_pb.Page.fromBuffer(response.bodyBytes);
    }
    return api.grpc(
      ep,
      (channel, options) =>
          pages_pb.PageServiceClient(channel).get(request, options: options),
    );
  }
}
