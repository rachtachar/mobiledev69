class UserModel {
  final int id;
  final String username;
  final String firstName;
  final String lastName;
  final String email;
  final String displayName;

  const UserModel({
    required this.id,
    required this.username,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.displayName,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    final rawId = json['id'] ?? json['sub'];
    return UserModel(
      id: rawId is int ? rawId : int.tryParse(rawId?.toString() ?? '0') ?? 0,
      username: json['username'] ?? json['preferred_username'] ?? '',
      firstName: json['first_name'] ?? json['given_name'] ?? '',
      lastName: json['last_name'] ?? json['family_name'] ?? '',
      email: json['email'] ?? '',
      displayName: json['display_name'] ?? json['name'] ?? (json['preferred_username'] ?? json['username'] ?? ''),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'username': username,
    'first_name': firstName,
    'last_name': lastName,
    'email': email,
    'display_name': displayName,
  };
}
