// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:convert';

class UserModel {
  final int? id;
  final String? full_name;
  final String? user_name;
  final String? email;
  final String? password;
  final String? token;
  final DateTime? created_at;

  UserModel({
    this.id,
    this.full_name,
    this.user_name,
    this.email,
    this.password,
    this.token,
    this.created_at,
  });

  UserModel copyWith({
    int? id,
    String? full_name,
    String? user_name,
    String? email,
    String? password,
    String? token,
    DateTime? created_at,
  }) {
    return UserModel(
      id: id ?? this.id,
      full_name: full_name ?? this.full_name,
      user_name: user_name ?? this.user_name,
      email: email ?? this.email,
      password: password ?? this.password,
      token: token ?? this.token,
      created_at: created_at ?? this.created_at,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'id': id,
      'full_name': full_name,
      'user_name': user_name,
      'email': email,
      'password': password,
      'token': token,
      'created_at': created_at?.toIso8601String(),
    };
  }

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      id: map['id'] != null ? map['id'] as int : null,
      full_name: map['full_name'] != null ? map['full_name'] as String : null,
      user_name: map['user_name'] != null ? map['user_name'] as String : null,
      email: map['email'] != null ? map['email'] as String : null,
      password: map['password'] != null ? map['password'] as String : null,
      token: map['token'] != null ? map['token'] as String : null,
      created_at: map['created_at'] != null
          ? DateTime.parse(map['created_at'] as String)
          : null,
    );
  }

  String toJson() => json.encode(toMap());

  factory UserModel.fromJson(String source) =>
      UserModel.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  String toString() {
    return 'UserModel(id: $id, full_name: $full_name, user_name: $user_name, email: $email, password: $password, token: $token, created_at: $created_at)';
  }

  @override
  bool operator ==(covariant UserModel other) {
    if (identical(this, other)) return true;

    return other.id == id &&
        other.full_name == full_name &&
        other.user_name == user_name &&
        other.email == email &&
        other.password == password &&
        other.token == token &&
        other.created_at == created_at;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        full_name.hashCode ^
        user_name.hashCode ^
        email.hashCode ^
        password.hashCode ^
        token.hashCode ^
        created_at.hashCode;
  }
}