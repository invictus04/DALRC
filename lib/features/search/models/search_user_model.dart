  /*
    {
    "_id": "6a6f1b504a4dcf08be531999",
    "role": "Judge",
    "userId": null,
    "employeeId": "judge03",
    "phoneNumber": "+917999505831",
    "walletAddress": "0x1a8afdce8c65840a04575fff7c6896673ad0d6cj",
    "fullName": "judge somsa"
  }
  */

class SearchUserModel {
  final String id;
  final String role;
  final String userId;
  final String employeeId;
  final String phoneNumber;
  final String walletAddress;
  final String fullName;

  SearchUserModel({
    required this.id,
    required this.role,
    required this.userId,
    required this.employeeId,
    required this.phoneNumber,
    required this.walletAddress,
    required this.fullName,
  });

  factory SearchUserModel.fromJson(Map<String, dynamic> json) {
    return SearchUserModel(
      id: json['_id'] ?? '',
      role: json['role'] ?? '',
      userId: json['userId'] ?? '',
      employeeId: json['employeeId'] ?? '',
      phoneNumber: json['phoneNumber'] ?? '',
      walletAddress: json['walletAddress'] ?? '',
      fullName: json['fullName'] ?? '',
    );
  }
}