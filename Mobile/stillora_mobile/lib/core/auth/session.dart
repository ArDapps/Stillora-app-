import 'package:equatable/equatable.dart';

class SessionUser extends Equatable {
  const SessionUser({
    required this.id,
    required this.email,
    required this.name,
    required this.avatarUrl,
  });

  factory SessionUser.fromJson(Map<String, dynamic> json) {
    return SessionUser(
      id: (json['sub'] ?? json['id'] ?? '') as String,
      email: (json['email'] ?? '') as String,
      name: (json['name'] ?? 'Stillora user') as String,
      avatarUrl: (json['picture'] ?? json['avatarUrl'] ?? '') as String,
    );
  }

  final String id;
  final String email;
  final String name;
  final String avatarUrl;

  @override
  List<Object?> get props => [id, email, name, avatarUrl];
}

class AuthSession extends Equatable {
  const AuthSession({required this.token, required this.user});

  final String token;
  final SessionUser user;

  @override
  List<Object?> get props => [token, user];
}
