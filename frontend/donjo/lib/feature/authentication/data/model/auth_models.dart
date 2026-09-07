library;

/// Data models for Authentication matching the Donjo backend API.

class UserModel {
  const UserModel({
    required this.id,
    required this.email,
    required this.fullName,
    required this.username,
    required this.dateOfBirth,
    required this.phoneNumber,
    this.mpesaPhoneNumber,
    this.profileImage,
    this.bio,
    this.interests,
    this.socialLinks,
    this.emailVerified = false,
    this.phoneVerified = false,
    this.identityVerified = false,
    this.accountStatus = 'active',
    this.isAdmin = false,
    this.trustScore = 100,
    this.trustLevel = 'basic',
    this.twoFactorEnabled = false,
    this.walletBalance = 0.0,
    this.walletCurrency = 'KES',
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String email;
  final String fullName;
  final String username;
  final String dateOfBirth;
  final String phoneNumber;
  final String? mpesaPhoneNumber;
  final String? profileImage;
  final String? bio;
  final String? interests;
  final String? socialLinks;
  final bool emailVerified;
  final bool phoneVerified;
  final bool identityVerified;
  final String accountStatus;
  final bool isAdmin;
  final int trustScore;
  final String trustLevel;
  final bool twoFactorEnabled;
  final double walletBalance;
  final String walletCurrency;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as String? ?? '',
      email: json['email'] as String? ?? '',
      fullName: json['full_name'] as String? ?? '',
      username: json['username'] as String? ?? '',
      dateOfBirth: json['date_of_birth'] as String? ?? '',
      phoneNumber: json['phone_number'] as String? ?? '',
      mpesaPhoneNumber: json['mpesa_phone_number'] as String?,
      profileImage: json['profile_image'] as String?,
      bio: json['bio'] as String?,
      interests: json['interests'] as String?,
      socialLinks: json['social_links'] as String?,
      emailVerified: json['email_verified'] as bool? ?? false,
      phoneVerified: json['phone_verified'] as bool? ?? false,
      identityVerified: json['identity_verified'] as bool? ?? false,
      accountStatus: json['account_status'] as String? ?? 'active',
      isAdmin: json['is_admin'] as bool? ?? false,
      trustScore: (json['trust_score'] as num?)?.toInt() ?? 100,
      trustLevel: json['trust_level'] as String? ?? 'basic',
      twoFactorEnabled: json['two_factor_enabled'] as bool? ?? false,
      walletBalance: (json['wallet_balance'] as num?)?.toDouble() ?? 0.0,
      walletCurrency: json['wallet_currency'] as String? ?? 'KES',
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'] as String)
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'email': email,
    'full_name': fullName,
    'username': username,
    'date_of_birth': dateOfBirth,
    'phone_number': phoneNumber,
    'mpesa_phone_number': mpesaPhoneNumber,
    'profile_image': profileImage,
    'bio': bio,
    'interests': interests,
    'social_links': socialLinks,
    'email_verified': emailVerified,
    'phone_verified': phoneVerified,
    'identity_verified': identityVerified,
    'account_status': accountStatus,
    'is_admin': isAdmin,
    'trust_score': trustScore,
    'trust_level': trustLevel,
    'two_factor_enabled': twoFactorEnabled,
    'wallet_balance': walletBalance,
    'wallet_currency': walletCurrency,
    if (createdAt != null) 'created_at': createdAt!.toIso8601String(),
    if (updatedAt != null) 'updated_at': updatedAt!.toIso8601String(),
  };
}

class TokenResponse {
  const TokenResponse({
    required this.accessToken,
    required this.refreshToken,
    required this.expiresIn,
    required this.tokenType,
  });

  final String accessToken;
  final String refreshToken;
  final int expiresIn;
  final String tokenType;

  factory TokenResponse.fromJson(Map<String, dynamic> json) {
    return TokenResponse(
      accessToken: json['access_token'] as String? ?? '',
      refreshToken: json['refresh_token'] as String? ?? '',
      expiresIn: (json['expires_in'] as num?)?.toInt() ?? 3600,
      tokenType: json['token_type'] as String? ?? 'Bearer',
    );
  }

  Map<String, dynamic> toJson() => {
    'access_token': accessToken,
    'refresh_token': refreshToken,
    'expires_in': expiresIn,
    'token_type': tokenType,
  };
}

class CreateUserRequest {
  const CreateUserRequest({
    required this.email,
    required this.password,
    required this.fullName,
    required this.username,
    required this.dateOfBirth,
    required this.phoneNumber,
    this.mpesaPhoneNumber,
  });

  final String email;
  final String password;
  final String fullName;
  final String username;
  final String dateOfBirth;
  final String phoneNumber;
  final String? mpesaPhoneNumber;

  Map<String, dynamic> toJson() => {
    'email': email,
    'password': password,
    'full_name': fullName,
    'username': username,
    'date_of_birth': dateOfBirth,
    'phone_number': phoneNumber,
    if (mpesaPhoneNumber != null && mpesaPhoneNumber!.isNotEmpty)
      'mpesa_phone_number': mpesaPhoneNumber,
  };
}

class LoginRequest {
  const LoginRequest({
    required this.email,
    required this.password,
    this.twoFactorCode,
  });

  final String email;
  final String password;
  final String? twoFactorCode;

  Map<String, dynamic> toJson() => {
    'email': email,
    'password': password,
    if (twoFactorCode != null && twoFactorCode!.isNotEmpty)
      'two_factor_code': twoFactorCode,
  };
}

class AuthResult {
  const AuthResult({
    this.user,
    this.tokens,
    this.twoFactorRequired = false,
    this.message,
  });

  final UserModel? user;
  final TokenResponse? tokens;
  final bool twoFactorRequired;
  final String? message;
}
