import 'package:google_sign_in/google_sign_in.dart';
import '../core/constants/api_constants.dart';
import '../models/referral_model.dart';
import '../models/user_model.dart';
import 'api_service.dart';
import 'storage_service.dart';

class AuthService {
  static const _googleWebClientId = String.fromEnvironment(
    'GOOGLE_WEB_CLIENT_ID',
  );

  final _api = ApiService();
  final _googleSignIn = GoogleSignIn(
    scopes: ['email', 'profile'],
    serverClientId: _googleWebClientId == '' ? null : _googleWebClientId,
  );

  Future<UserModel> login({
    required String email,
    required String password,
  }) async {
    final response = await _api.post(
      ApiConstants.login,
      data: {'email': email, 'password': password},
    );
    return _handleAuthResponse(response.data);
  }

  Future<UserModel> register({
    required String name,
    required String email,
    required String password,
    String? referralCode,
  }) async {
    final response = await _api.post(
      ApiConstants.register,
      data: {
        'name': name,
        'email': email,
        'password': password,
        if (referralCode != null && referralCode.trim().isNotEmpty)
          'referral_code': referralCode.trim(),
      },
    );
    return _handleAuthResponse(response.data);
  }

  Future<UserModel?> signInWithGoogle({String? referralCode}) async {
    final googleUser = await _googleSignIn.signIn();
    if (googleUser == null) return null;

    final googleAuth = await googleUser.authentication;
    if (googleAuth.idToken == null && googleAuth.accessToken == null) {
      throw Exception('Google no devolvio credenciales');
    }

    final response = await _api.post(
      ApiConstants.googleAuth,
      data: {
        if (googleAuth.idToken != null) 'id_token': googleAuth.idToken,
        if (googleAuth.accessToken != null)
          'access_token': googleAuth.accessToken,
        if (referralCode != null && referralCode.trim().isNotEmpty)
          'referral_code': referralCode.trim(),
      },
    );
    return _handleAuthResponse(response.data);
  }

  Future<UserModel> getMe() async {
    final response = await _api.get(ApiConstants.me);
    return UserModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<ReferralSummary> getReferralSummary() async {
    final response = await _api.get(ApiConstants.myReferral);
    return ReferralSummary.fromJson(response.data as Map<String, dynamic>);
  }

  Future<UserModel> updateLocation({
    required double latitude,
    required double longitude,
    String? location,
  }) async {
    final response = await _api.patch(
      ApiConstants.updateLocation,
      data: {
        'latitude': latitude,
        'longitude': longitude,
        if (location != null) 'location': location,
      },
    );
    return UserModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<void> logout() async {
    await _googleSignIn.signOut();
    await StorageService.clearAll();
  }

  Future<bool> isLoggedIn() async {
    final token = await StorageService.getAccessToken();
    return token != null;
  }

  Future<UserModel> _handleAuthResponse(dynamic data) async {
    await StorageService.saveTokens(
      accessToken: data['access_token'] as String,
      refreshToken: data['refresh_token'] as String,
    );
    final user = UserModel.fromJson(data['user'] as Map<String, dynamic>);
    await StorageService.saveUserId(user.id);
    return user;
  }
}
