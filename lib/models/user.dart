class User {
  final int? id;
  final String username;
  final String passwordHash;
  final String role; // 'admin' or 'employee'

  User({
    this.id,
    required this.username,
    required this.passwordHash,
    required this.role,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'username': username,
      'passwordHash': passwordHash,
      'role': role,
    };
  }

  factory User.fromMap(Map<String, dynamic> map) {
    return User(
      id: map['id'],
      username: map['username'],
      passwordHash: map['passwordHash'],
      role: map['role'],
    );
  }
}
