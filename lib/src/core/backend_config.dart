part of '../../main.dart';

const String productionBackendUrl = 'http://192.210.235.115:8080';
const String _buildBackendUrl = String.fromEnvironment(
  'SHARE_WITH_ME_BACKEND_URL',
  defaultValue: productionBackendUrl,
);
const String buildApiToken = String.fromEnvironment('SHARE_WITH_ME_API_TOKEN');

String defaultBackendUrl() {
  return normalizeBackendUrl(_buildBackendUrl);
}

bool isLegacyLocalBackendUrl(String value) {
  final normalized = normalizeBackendUrl(value);
  final uri = Uri.parse(normalized);
  return isPrivateBackendHost(uri.host);
}

bool isPrivateBackendHost(String host) {
  final value = host.toLowerCase();
  if (value == 'localhost' ||
      value == '127.0.0.1' ||
      value == '0.0.0.0' ||
      value == '::1' ||
      value == '10.0.2.2') {
    return true;
  }
  final parts = value.split('.');
  if (parts.length != 4) {
    return false;
  }
  final octets = parts.map(int.tryParse).toList();
  if (octets.any((part) => part == null || part < 0 || part > 255)) {
    return false;
  }
  final first = octets[0]!;
  final second = octets[1]!;
  return first == 10 ||
      first == 127 ||
      (first == 172 && second >= 16 && second <= 31) ||
      (first == 192 && second == 168) ||
      (first == 169 && second == 254);
}

String normalizeBackendUrl(String input) {
  var value = input.trim();
  if (value.isEmpty) {
    throw const FormatException('后端地址不能为空');
  }
  if (!RegExp(r'^[a-zA-Z][a-zA-Z0-9+.-]*://').hasMatch(value)) {
    value = 'http://$value';
  }

  final uri = Uri.tryParse(value);
  if (uri == null || !uri.hasScheme || !uri.hasAuthority || uri.host.isEmpty) {
    throw const FormatException('请输入有效的后端地址');
  }
  if (uri.scheme != 'http' && uri.scheme != 'https') {
    throw const FormatException('后端地址必须使用 http 或 https');
  }
  if (uri.userInfo.isNotEmpty || uri.hasQuery || uri.hasFragment) {
    throw const FormatException('后端地址不要包含账号、查询参数或片段');
  }

  final path = uri.path == '/' ? '' : uri.path.replaceFirst(RegExp(r'/+$'), '');
  return '${uri.scheme}://${uri.authority}$path';
}

String resolveBackendMediaUrl(String baseUrl, String imageUrl) {
  final value = imageUrl.trim();
  if (value.isEmpty || RegExp(r'^[a-zA-Z][a-zA-Z0-9+.-]*://').hasMatch(value)) {
    return value;
  }
  final cleanBase = baseUrl.endsWith('/')
      ? baseUrl.substring(0, baseUrl.length - 1)
      : baseUrl;
  final cleanPath = value.startsWith('/') ? value : '/$value';
  return '$cleanBase$cleanPath';
}
