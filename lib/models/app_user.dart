class AppUser {
  final String id;
  final String name;
  final String email;
  final String role; // 'customer' | 'store'

  const AppUser({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
  });

  bool get isStore => role == 'store';
  bool get isCustomer => role == 'customer';

  factory AppUser.fromMap(Map<String, dynamic> map) {
    return AppUser(
      id: map['id'] as String,
      name: (map['name'] ?? '') as String,
      email: (map['email'] ?? '') as String,
      role: (map['role'] ?? 'customer') as String,
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'email': email,
        'role': role,
      };
}
