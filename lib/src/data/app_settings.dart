part of '../../main.dart';

class AppSettings {
  static const _backendUrlKey = 'backend_url';
  static const _lastClipboardImportKey = 'last_clipboard_import';

  Future<String?> loadBackendUrl() async {
    final preferences = await SharedPreferences.getInstance();
    final value = preferences.getString(_backendUrlKey)?.trim();
    return value == null || value.isEmpty ? null : value;
  }

  Future<void> saveBackendUrl(String value) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(_backendUrlKey, value.trim());
  }

  // Remembers the last clipboard link auto-imported, so the same link is not
  // re-analyzed every time the app is opened or resumed.
  Future<String?> loadLastClipboardImport() async {
    final preferences = await SharedPreferences.getInstance();
    final value = preferences.getString(_lastClipboardImportKey)?.trim();
    return value == null || value.isEmpty ? null : value;
  }

  Future<void> saveLastClipboardImport(String value) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(_lastClipboardImportKey, value.trim());
  }
}
