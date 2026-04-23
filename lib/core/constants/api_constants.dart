class ApiConstants {
  // static const String baseUrl = 'http://10.0.2.2:8000'; // Android emulator → localhost
  // static const String baseUrl = 'http://localhost:8000'; // iOS simulator
  static const String baseUrl =
      'https://petmatch-back-production.up.railway.app'; // Railway

  // Auth
  static const String login = '/auth/login';
  static const String register = '/auth/register';
  static const String googleAuth = '/auth/google';
  static const String refreshToken = '/auth/refresh';
  static const String me = '/auth/me';
  static const String updateLocation = '/auth/me/location';

  // Pets
  static const String pets = '/pets';
  static const String myPets = '/pets/mine';
  static const String explore = '/pets/explore';
  static const String like = '/pets/like';
  static const String superLike = '/pets/super-like';
  static const String dislike = '/pets/dislike';
  static const String likesReceived = '/pets/likes-received';
  static const String unlockLikesReceived = '/pets/likes-received/unlock';

  // Matches
  static const String matches = '/matches';

  // Chat
  static const String conversations = '/chat/conversations';
  static const String messages = '/chat/messages';

  // Adoption
  static const String adoptions = '/adoptions';
  static const String myAdoptions = '/adoptions/mine';

  // Lost pets
  static const String lostPets = '/lost-pets';

  // Notifications
  static const String notifications = '/notifications';
  static const String notificationDeviceToken = '/notifications/device-token';

  // Patitas
  static const String patitasPacks = '/patitas/packs';
  static const String patitasWallet = '/patitas/wallet';
  static const String patitasConsume = '/patitas/consumir';
  static const String advancedFilters = '/patitas/advanced-filters';
  static const String activateAdvancedFilters =
      '/patitas/advanced-filters/activate';
  static const String createPatitasPreference = '/crear-preferencia';

  // Upload
  static const String upload = '/upload/photo';

  // Dev
  static const String seedPets = '/dev/seed-pets';
}
