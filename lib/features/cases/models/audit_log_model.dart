class AuditLogModel {
  final String id;
  final String action;
  final String userWallet;
  final String userRole;
  final String ipAddress;
  final DateTime timestamp;

  AuditLogModel({
    required this.id,
    required this.action,
    required this.userWallet,
    required this.userRole,
    required this.ipAddress,
    required this.timestamp,
  });

  factory AuditLogModel.fromJson(Map<String, dynamic> json) {
    return AuditLogModel(
      id: json['_id'] ?? json['id'] ?? '',
      action: json['action'] ?? '',
      userWallet: json['userWallet'] ?? '',
      userRole: json['userRole'] ?? '',
      ipAddress: json['ipAddress'] ?? '',
      timestamp: json['timestamp'] != null 
          ? DateTime.parse(json['timestamp']) 
          : DateTime.now(),
    );
  }
}
