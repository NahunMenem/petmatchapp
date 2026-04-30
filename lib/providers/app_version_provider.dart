import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/app_version_model.dart';
import '../services/app_version_service.dart';

final appVersionServiceProvider = Provider<AppVersionService>(
  (ref) => AppVersionService(),
);

final appVersionProvider = FutureProvider<AppVersionStatus>((ref) {
  return ref.read(appVersionServiceProvider).checkVersion();
});
