import 'dart:js_interop';
import 'dart:js_interop_unsafe';

/// Browser EyeDropper. Returns `#rrggbb`, or null when the pick is cancelled.
Future<String?> pickScreenHex() async {
  try {
    final ctor = globalContext.getProperty<JSAny?>('EyeDropper'.toJS);
    if (ctor == null || !ctor.isA<JSFunction>()) return null;
    final dropper = (ctor as JSFunction).callAsConstructor<JSObject>();
    final result = await dropper.callMethod<JSPromise<JSObject>>('open'.toJS).toDart;
    return result.getProperty<JSString>('sRGBHex'.toJS).toDart;
  } catch (_) {
    return null;
  }
}
