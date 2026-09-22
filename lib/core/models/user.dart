import 'enums.dart';

class User {
  final String userId;
  final String name;
  final String email;
  final String contactNo;
  final UserRole role;
  final UserStatus status;

  const User({
    required this.userId,
    required this.name,
    required this.email,
    required this.contactNo,
    required this.role,
    required this.status,
  });

  factory User.fromMap(Map<String, dynamic> map) => User(
        userId: map['user_id'] as String,
        name: map['name'] as String,
        email: map['email'] as String,
        contactNo: map['contact_no'] as String,
        role: UserRole.fromValue(map['role'] as String),
        status: UserStatus.fromValue(map['status'] as String),
      );

  Map<String, dynamic> toMap() => {
        'user_id': userId,
        'name': name,
        'email': email,
        'contact_no': contactNo,
        'role': role.value,
        'status': status.value,
      };

  User copyWith({
    String? userId,
    String? name,
    String? email,
    String? contactNo,
    UserRole? role,
    UserStatus? status,
  }) =>
      User(
        userId: userId ?? this.userId,
        name: name ?? this.name,
        email: email ?? this.email,
        contactNo: contactNo ?? this.contactNo,
        role: role ?? this.role,
        status: status ?? this.status,
      );
}
