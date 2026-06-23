part of '../../main.dart';

String defaultBackendUrl() {
  if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
    return 'http://10.0.2.2:8080';
  }
  return 'http://127.0.0.1:8080';
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
