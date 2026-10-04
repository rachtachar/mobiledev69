import 'user_model.dart';

class FriendRequestModel {
  final int id;
  final UserModel fromUser;
  final UserModel toUser;
  final String status;
  final DateTime createdAt;
  final DateTime updatedAt;

  FriendRequestModel({
    required this.id,
    required this.fromUser,
    required this.toUser,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
  });

  factory FriendRequestModel.fromJson(Map<String, dynamic> json) {
    return FriendRequestModel(
      id: json['id'] as int,
      fromUser: UserModel.fromJson(json['from_user'] as Map<String, dynamic>),
      toUser: UserModel.fromJson(json['to_user'] as Map<String, dynamic>),
      status: json['status'] as String? ?? 'pending',
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'from_user': fromUser.toJson(),
    'to_user': toUser.toJson(),
    'status': status,
    'created_at': createdAt.toIso8601String(),
    'updated_at': updatedAt.toIso8601String(),
  };
}
