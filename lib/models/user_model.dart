class UserModel {
  final String id;
  final String role;
  final String firstName;
  final String lastName;
  final String phoneNumber;
  final String? userId;
  final bool isVerified;
  final String? walletAddress;

  UserModel({
    required this.id,
    required this.role,
    required this.firstName,
    required this.lastName,
    required this.phoneNumber,
    this.userId,
    this.isVerified = false,
    this.walletAddress,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['_id'] ?? '',
      role: json['role'] ?? '',
      firstName: json['firstName'] ?? '',
      lastName: json['lastName'] ?? '',
      phoneNumber: json['phoneNumber'] ?? '',
      userId: json['userId'],
      isVerified: json['isVerified'] ?? false,
      walletAddress: json['walletAddress'],
    );
  }
}
