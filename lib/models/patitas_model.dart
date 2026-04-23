class PatitasPack {
  final String id;
  final String name;
  final int price;
  final int basePatitas;
  final int bonusPatitas;
  final int totalPatitas;

  const PatitasPack({
    required this.id,
    required this.name,
    required this.price,
    required this.basePatitas,
    required this.bonusPatitas,
    required this.totalPatitas,
  });

  factory PatitasPack.fromJson(Map<String, dynamic> json) {
    return PatitasPack(
      id: json['id'] as String,
      name: json['name'] as String,
      price: json['price'] as int,
      basePatitas: json['base_patitas'] as int,
      bonusPatitas: json['bonus_patitas'] as int,
      totalPatitas: json['total_patitas'] as int,
    );
  }
}

class PatitasTransaction {
  final String id;
  final String type;
  final int amount;
  final String description;
  final String status;
  final DateTime date;

  const PatitasTransaction({
    required this.id,
    required this.type,
    required this.amount,
    required this.description,
    required this.status,
    required this.date,
  });

  factory PatitasTransaction.fromJson(Map<String, dynamic> json) {
    return PatitasTransaction(
      id: json['id'] as String,
      type: json['tipo'] as String,
      amount: json['cantidad'] as int,
      description: json['descripcion'] as String,
      status: json['estado'] as String,
      date: DateTime.parse(json['fecha'] as String),
    );
  }
}

class PatitasWallet {
  final int patitas;
  final List<PatitasTransaction> transactions;

  const PatitasWallet({
    required this.patitas,
    required this.transactions,
  });

  factory PatitasWallet.fromJson(Map<String, dynamic> json) {
    final transactions = (json['transactions'] as List<dynamic>? ?? [])
        .map(
            (item) => PatitasTransaction.fromJson(item as Map<String, dynamic>))
        .toList();

    return PatitasWallet(
      patitas: json['patitas'] as int? ?? 0,
      transactions: transactions,
    );
  }
}

class PatitasPreference {
  final String preferenceId;
  final String initPoint;
  final String? sandboxInitPoint;

  const PatitasPreference({
    required this.preferenceId,
    required this.initPoint,
    this.sandboxInitPoint,
  });

  factory PatitasPreference.fromJson(Map<String, dynamic> json) {
    return PatitasPreference(
      preferenceId: json['preference_id'] as String,
      initPoint: json['init_point'] as String,
      sandboxInitPoint: json['sandbox_init_point'] as String?,
    );
  }
}

class PatitasActions {
  static const lostNotification2km = 'lost_notification_2km';
  static const lostNotification5km = 'lost_notification_5km';
  static const adoptionFeature = 'adoption_feature';
  static const adoptionFeature24h = 'adoption_feature_24h';
  static const matchingUnlimitedLikes1d = 'matching_unlimited_likes_1d';
  static const matchingSeeLikes = 'matching_see_likes';
  static const matchingSuperLike = 'matching_super_like';
  static const matchingAdvancedFilters30d = 'matching_advanced_filters_30d';
  static const profileBoost = 'profile_boost';
  static const profileStrongBoost = 'profile_strong_boost';
}

class AdvancedFiltersAccess {
  final bool active;
  final DateTime? expiresAt;
  final int cost;
  final int? patitas;

  const AdvancedFiltersAccess({
    required this.active,
    this.expiresAt,
    this.cost = 30,
    this.patitas,
  });

  factory AdvancedFiltersAccess.fromJson(Map<String, dynamic> json) {
    final expires = json['expires_at'];
    return AdvancedFiltersAccess(
      active: json['active'] as bool? ?? false,
      expiresAt: expires is String ? DateTime.tryParse(expires) : null,
      cost: json['cost'] as int? ?? 30,
      patitas: json['patitas'] as int?,
    );
  }
}

class PatitasFallback {
  static const packs = [
    PatitasPack(
      id: 'starter',
      name: 'Starter',
      price: 3000,
      basePatitas: 100,
      bonusPatitas: 0,
      totalPatitas: 100,
    ),
    PatitasPack(
      id: 'popular',
      name: 'Popular',
      price: 6000,
      basePatitas: 250,
      bonusPatitas: 25,
      totalPatitas: 275,
    ),
    PatitasPack(
      id: 'pro',
      name: 'Pro',
      price: 10000,
      basePatitas: 500,
      bonusPatitas: 100,
      totalPatitas: 600,
    ),
  ];

  static final wallet = PatitasWallet(
    patitas: 120,
    transactions: [
      PatitasTransaction(
        id: 'fallback-starter',
        type: 'compra',
        amount: 100,
        description: 'Pack Starter comprado',
        status: 'approved',
        date: DateTime(2026, 4, 22, 10, 30),
      ),
      PatitasTransaction(
        id: 'fallback-lost',
        type: 'uso',
        amount: -20,
        description: 'Notificacion perdidos 2km',
        status: 'used',
        date: DateTime(2026, 4, 21, 8, 15),
      ),
      PatitasTransaction(
        id: 'fallback-boost',
        type: 'uso',
        amount: -25,
        description: 'Boost de perfil activado',
        status: 'used',
        date: DateTime(2026, 4, 20, 16, 45),
      ),
    ],
  );
}
