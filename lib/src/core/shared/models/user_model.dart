class UserModel {
  final String id;
  final String image;
  final String fullName;
  final String phoneNumber;
  final String email;
  final String city;
  final int userType;
  final bool allowNotify;
  final String? token;

  UserModel({
    required this.id,
    required this.image,
    required this.fullName,
    required this.phoneNumber,
    required this.email,
    required this.city,
    required this.userType,
    required this.allowNotify,
    required this.token,
  });

  factory UserModel.initial() => UserModel(
    id: '',
    image: '',
    fullName: '',
    phoneNumber: '',
    email: '',
    city: '',
    userType: 0,
    allowNotify: false,
    token: '',
  );

  UserModel copyWith({
    String? id,
    String? image,
    String? fullName,
    String? phoneNumber,
    String? email,
    String? city,
    int? userType,
    bool? allowNotify,
    String? token,
  }) {
    return UserModel(
      id: id ?? this.id,
      image: image ?? this.image,
      fullName: fullName ?? this.fullName,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      email: email ?? this.email,
      city: city ?? this.city,
      userType: userType ?? this.userType,
      allowNotify: allowNotify ?? this.allowNotify,
      token: token ?? this.token,
    );
  }

  /// Null-safe parsing with type coercion and support for both
  /// `snake_case` (most backends) and `camelCase` keys. Never throws on a
  /// missing/mistyped field — falls back to the same defaults as
  /// [UserModel.initial].
  factory UserModel.fromJson(Map<String, dynamic> json) => UserModel(
    id: (json['id'] ?? '').toString(),
    image: (json['image'] ?? '').toString(),
    fullName: (json['full_name'] ?? json['fullName'] ?? '').toString(),
    phoneNumber: (json['phone_number'] ?? json['phoneNumber'] ?? '').toString(),
    email: (json['email'] ?? '').toString(),
    city: (json['city'] ?? '').toString(),
    userType: _toInt(json['user_type'] ?? json['userType']),
    allowNotify: _toBool(json['allow_notify'] ?? json['allowNotify']),
    token: (json['token'] ?? json['access_token'])?.toString(),
  );

  static int _toInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  static bool _toBool(dynamic value) {
    if (value is bool) return value;
    if (value is num) return value != 0;
    final s = value?.toString().toLowerCase();
    return s == 'true' || s == '1';
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'image': image,
    'full_name': fullName,
    'phone_number': phoneNumber,
    'email': email,
    'city': city,
    'user_type': userType,
    'allow_notify': allowNotify,
    // token intentionally excluded — persisted in TokenStorage.
  };
}
