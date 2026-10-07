String _trim(String value) {
  var end = value.length;
  while (end > 0 && value[end - 1] == '/') {
    end--;
  }
  return value.substring(0, end);
}

bool _hasNoPath(String trimmed) {
  final uri = Uri.tryParse(trimmed);
  if (uri != null) {
    final path = uri.path;
    return path.isEmpty || path == '/';
  }
  final schemeEnd = trimmed.indexOf('://');
  final afterScheme =
      schemeEnd == -1 ? trimmed : trimmed.substring(schemeEnd + 3);
  return !afterScheme.contains('/');
}

String siteHomeUrl(String baseUrl) {
  if (baseUrl.isEmpty) return baseUrl;
  final trimmed = _trim(baseUrl);
  return _hasNoPath(trimmed) ? '$trimmed/' : trimmed;
}

String siteEndpointUrl(String baseUrl, String path) {
  if (baseUrl.isEmpty) return baseUrl;
  final trimmedBase = _trim(baseUrl);
  if (path.trim().isEmpty) return trimmedBase;
  var pathStart = 0;
  while (pathStart < path.length && path[pathStart] == '/') {
    pathStart++;
  }
  return '$trimmedBase/${path.substring(pathStart)}';
}