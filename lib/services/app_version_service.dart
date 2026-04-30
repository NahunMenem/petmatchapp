import 'dart:io';

import 'package:dio/dio.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../core/constants/api_constants.dart';
import '../models/app_version_model.dart';
import 'api_service.dart';

class AppVersionService {
  AppVersionService({ApiService? api}) : _api = api ?? ApiService();

  final ApiService _api;

  Future<AppVersionStatus> checkVersion() async {
    final packageInfo = await PackageInfo.fromPlatform();
    final currentVersion = packageInfo.version;
    final currentBuild = packageInfo.buildNumber;

    try {
      final response = await _api.get(
        ApiConstants.appVersion,
        queryParams: {
          'platform': Platform.isIOS ? 'ios' : 'android',
          'version': currentVersion,
          'build': currentBuild,
        },
      );
      final data = response.data as Map<String, dynamic>;
      final platform = Platform.isIOS ? 'ios' : 'android';
      final minimumVersion = _stringValue(
        data['min_${platform}_version'] ??
            data['minimum_${platform}_version'] ??
            data['min_version'] ??
            data['minimum_version'],
        currentVersion,
      );
      final latestVersion = _stringValue(
        data['latest_${platform}_version'] ??
            data['latest_version'] ??
            data['current_version'],
        minimumVersion,
      );
      final serverRequiresUpdate =
          data['force_update'] == true || data['required'] == true;
      final updateRequired = serverRequiresUpdate ||
          _compareVersions(currentVersion, minimumVersion) < 0;

      return AppVersionStatus(
        updateRequired: updateRequired,
        currentVersion: currentVersion,
        currentBuild: currentBuild,
        minimumVersion: minimumVersion,
        latestVersion: latestVersion,
        message: _stringValue(
          data['message'],
          'Hay una nueva versión de PawMatch. Actualizá la app para seguir usando todas las funciones.',
        ),
        iosUrl: _stringValue(
          data['ios_url'] ?? data['app_store_url'],
          AppStoreLinks.ios,
        ),
        androidUrl: _stringValue(
          data['android_url'] ?? data['play_store_url'],
          AppStoreLinks.android,
        ),
      );
    } on DioException catch (error) {
      if (error.response?.statusCode == 404) {
        return AppVersionStatus.allowed(
          currentVersion: currentVersion,
          currentBuild: currentBuild,
        );
      }
      return AppVersionStatus.allowed(
        currentVersion: currentVersion,
        currentBuild: currentBuild,
      );
    } catch (_) {
      return AppVersionStatus.allowed(
        currentVersion: currentVersion,
        currentBuild: currentBuild,
      );
    }
  }

  static String _stringValue(dynamic value, String fallback) {
    final text = value?.toString().trim();
    return text == null || text.isEmpty ? fallback : text;
  }

  static int _compareVersions(String left, String right) {
    final leftParts = _versionParts(left);
    final rightParts = _versionParts(right);
    final maxLength = leftParts.length > rightParts.length
        ? leftParts.length
        : rightParts.length;

    for (var i = 0; i < maxLength; i++) {
      final a = i < leftParts.length ? leftParts[i] : 0;
      final b = i < rightParts.length ? rightParts[i] : 0;
      if (a != b) return a.compareTo(b);
    }
    return 0;
  }

  static List<int> _versionParts(String version) {
    return version
        .split(RegExp(r'[.+-]'))
        .map((part) => int.tryParse(part) ?? 0)
        .toList();
  }
}
