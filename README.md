# Free Open Ocean

Flutter frontend for ocean charts and localized content.

## Development

Run `flutter pub get`, `flutter analyze`, and `flutter test`.
The private gRPC contracts dependency requires access to the existing Git repository.
Run the web app with `flutter run -d chrome`.

Debug/profile builds default to HTTP ports 8081/8082 and gRPC ports 50051/50052.
Android uses the emulator host alias `10.0.2.2`; web and desktop use `localhost`.
For physical devices, pass a reachable backend address explicitly.

## Deployment configuration

Release builds have **no implicit localhost backend**. Set the actual service URLs
at build time. These are public connection settings, not secret storage.

- `API_HTTP_URLS`: comma-separated HTTP(S) base URLs for web. HTTPS URLs support
  optional ports and path prefixes. Configure the backend's CORS policy for the
  frontend origin and the `Content-Type`, `X-App-Session`, and `X-App-Key` headers.
- `API_GRPC_URLS`: comma-separated `grpcs://host:port` addresses for native apps.
  `grpcs` enables TLS (default port 443); `grpc` uses plaintext (default port 50051)
  for local development. Use reachable, TLS-enabled endpoints for deployment.
- `MAP_API_KEY`: optional override for the existing Protomaps browser key.

For example, replace the example domain with your own backend:

```sh
flutter build web --dart-define=API_HTTP_URLS=https://api.example.com
flutter build apk --dart-define=API_GRPC_URLS=grpcs://api.example.com:443
```

With no configured release backend, the shell and map remain available, the
connection status is offline, and server content offers retry. No production
address is assumed by the app.

## Connection behavior

Normal and silent modes both allow backend requests; silent retains its existing
presentation behavior. Disabled mode stops backend discovery and page requests,
cancels active backend transports, and clears the selected endpoint. External map
and font services are independent of this backend connection setting.

Startup waits for discovery to finish before showing the app. Failed discovery
retries every 20 seconds; healthy endpoints are rechecked every 15 minutes.
Page requests have bounded endpoint and transport waits, localized error messages,
and an explicit retry action. Switching country or language preserves the page's
query parameters and reloads localized content.

Country/language URLs take precedence over saved settings when a deep link is
opened. Opening the app root uses the saved region.
