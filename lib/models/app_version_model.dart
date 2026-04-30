class AppVersionStatus {
  final bool updateRequired;
  final String currentVersion;
  final String currentBuild;
  final String minimumVersion;
  final String latestVersion;
  final String message;
  final String iosUrl;
  final String androidUrl;

  const AppVersionStatus({
    required this.updateRequired,
    required this.currentVersion,
    required this.currentBuild,
    required this.minimumVersion,
    required this.latestVersion,
    required this.message,
    required this.iosUrl,
    required this.androidUrl,
  });

  String get currentLabel => '$currentVersion+$currentBuild';

  factory AppVersionStatus.allowed({
    required String currentVersion,
    required String currentBuild,
    String? iosUrl,
    String? androidUrl,
  }) {
    return AppVersionStatus(
      updateRequired: false,
      currentVersion: currentVersion,
      currentBuild: currentBuild,
      minimumVersion: currentVersion,
      latestVersion: currentVersion,
      message: '',
      iosUrl: iosUrl ?? AppStoreLinks.ios,
      androidUrl: androidUrl ?? AppStoreLinks.android,
    );
  }
}

class AppStoreLinks {
  static const String ios =
      'https://apps.apple.com/search?term=PawMatch&entity=software';
  static const String android =
      'https://play.google.com/store/apps/details?id=com.petmatch.petmatch';
}
