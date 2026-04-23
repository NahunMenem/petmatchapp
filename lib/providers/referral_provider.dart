import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/referral_model.dart';
import 'auth_provider.dart';

final referralSummaryProvider = FutureProvider<ReferralSummary>((ref) async {
  ref.watch(authProvider.select((state) => state.valueOrNull?.user?.id));
  return ref.read(authServiceProvider).getReferralSummary();
});
