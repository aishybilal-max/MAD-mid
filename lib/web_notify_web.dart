import 'dart:js_interop';
import 'dart:js_interop_unsafe';

/// Browser (Chrome) notifications, used only when the app runs on the web.
class WebNotify {
  static String _esc(String s) => s
      .replaceAll(r'\', r'\\')
      .replaceAll("'", r"\'")
      .replaceAll('\n', r'\n');

  static Future<String> show(String title, String body) async {
    try {
      final code = "(async function(){"
          "if(!('Notification' in window)) return;"
          "var p = Notification.permission;"
          "if(p !== 'granted' && p !== 'denied') p = await Notification.requestPermission();"
          "if(p === 'granted') new Notification('${_esc(title)}', {body: '${_esc(body)}'});"
          "})();";
      globalContext.callMethod('eval'.toJS, code.toJS);
      return 'If Chrome asks, click Allow. If nothing appears, click the lock icon in the address bar and allow notifications for this site, and turn off Windows Focus Assist.';
    } catch (e) {
      return 'Browser notification failed: $e';
    }
  }
}
