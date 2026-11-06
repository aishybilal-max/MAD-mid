/// Used on platforms without a browser (Android, iOS, desktop).
class WebNotify {
  static Future<String> show(String title, String body) async =>
      'Browser notifications are not available on this platform.';
}
