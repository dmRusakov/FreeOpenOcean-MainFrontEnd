import 'package:flutter_web_plugins/flutter_web_plugins.dart';
import 'package:universal_html/html.dart' as html;

void setupWeb() {
  usePathUrlStrategy();
}

// MapLibre's web implementation does not implement compass/attribution margins.
void setMapControlInsets(double right, [double bottom = 0]) {
  final style = html.document.documentElement?.style;
  style?.setProperty('--map-controls-right', '${right}px');
  style?.setProperty('--map-controls-bottom', '${bottom}px');
}
