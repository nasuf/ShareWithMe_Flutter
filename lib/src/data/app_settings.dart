part of '../../main.dart';

class AppSettings {
  static const _backendUrlKey = 'backend_url';

  Future<String?> loadBackendUrl() async {
    final preferences = await SharedPreferences.getInstance();
    final value = preferences.getString(_backendUrlKey)?.trim();
    return value == null || value.isEmpty ? null : value;
  }

  Future<void> saveBackendUrl(String value) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(_backendUrlKey, value.trim());
  }
}
