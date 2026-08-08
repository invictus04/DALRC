class ParticipantModel {
  final String wallet;
  final String role;
  final bool canView;
  final bool canUpload;
  final DateTime joinedAt;

  ParticipantModel({
    required this.wallet,
    required this.role,
    required this.canView,
    required this.canUpload,
    required this.joinedAt,
  });

  factory ParticipantModel.fromJson(Map<String, dynamic> json) {
    return ParticipantModel(
      wallet: json['wallet'] ?? '',
      role: json['role'] ?? 'civilian',
      canView: json['permissions']?['canView'] ?? false,
      canUpload: json['permissions']?['canUpload'] ?? false,
      joinedAt: json['joinedAt'] != null 
          ? DateTime.parse(json['joinedAt']) 
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'wallet': wallet,
      'role': role,
      'permissions': {
        'canView': canView,
        'canUpload': canUpload,
      },
      'joinedAt': joinedAt.toIso8601String(),
    };
  }
}
