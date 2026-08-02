import 'package:dio/dio.dart';

/// Outcome of a "check for update" run.
class UpdateStatus {
  const UpdateStatus({
    required this.currentVersion,
    this.latestVersion,
    this.releaseUrl,
    this.error,
  });

  final String currentVersion;
  final String? latestVersion;
  final String? releaseUrl;

  /// Set when the check could not complete (offline, no releases yet).
  final String? error;

  bool get hasError => error != null;

  bool get isUpdateAvailable {
    final latest = latestVersion;
    if (latest == null) return false;
    return compareVersions(latest, currentVersion) > 0;
  }
}

/// Asks GitHub whether a newer release than [currentVersion] has been tagged.
///
/// Failures come back as an [UpdateStatus] with an [UpdateStatus.error]: a
/// version check should never be able to crash the settings screen.
class UpdateChecker {
  UpdateChecker({
    Dio? dio,
    this.repository = 'neffex97/Tiwee',
  }) : _dio = dio ??
            Dio(
              BaseOptions(
                connectTimeout: const Duration(seconds: 10),
                receiveTimeout: const Duration(seconds: 10),
              ),
            );

  final Dio _dio;
  final String repository;

  Future<UpdateStatus> check({required String currentVersion}) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        'https://api.github.com/repos/$repository/releases/latest',
        options: Options(headers: {'Accept': 'application/vnd.github+json'}),
      );

      final data = response.data;
      final tag = data?['tag_name'] as String?;
      if (tag == null || tag.isEmpty) {
        return UpdateStatus(
          currentVersion: currentVersion,
          error: 'No releases have been published yet.',
        );
      }

      return UpdateStatus(
        currentVersion: currentVersion,
        latestVersion: normalizeVersion(tag),
        releaseUrl: data?['html_url'] as String? ??
            'https://github.com/$repository/releases/latest',
      );
    } on DioException catch (error) {
      if (error.response?.statusCode == 404) {
        return UpdateStatus(
          currentVersion: currentVersion,
          error: 'No releases have been published yet.',
        );
      }
      return UpdateStatus(
        currentVersion: currentVersion,
        error: 'Could not reach GitHub to check for updates.',
      );
    }
  }
}

/// Strips a leading `v` and any build suffix: `v1.2.0+3` -> `1.2.0`.
String normalizeVersion(String version) {
  final trimmed = version.trim();
  final withoutPrefix =
      trimmed.startsWith('v') ? trimmed.substring(1) : trimmed;
  return withoutPrefix.split('+').first;
}

/// Compares dotted versions numerically. Returns >0 when [a] is newer than [b].
int compareVersions(String a, String b) {
  final left = _parts(a);
  final right = _parts(b);
  final length = left.length > right.length ? left.length : right.length;

  for (var i = 0; i < length; i++) {
    final difference =
        (i < left.length ? left[i] : 0) - (i < right.length ? right[i] : 0);
    if (difference != 0) return difference;
  }
  return 0;
}

List<int> _parts(String version) => normalizeVersion(version)
    .split('.')
    .map((part) => int.tryParse(RegExp(r'\d+').stringMatch(part) ?? '') ?? 0)
    .toList();
