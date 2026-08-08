import 'participant_model.dart';

class CaseModel {
  final String id;
  final String caseNumber;
  final String title;
  final String description;
  final String courtName;
  final String status;
  final String adminWallet;
  final List<ParticipantModel> participants;
  final DateTime createdAt;

  CaseModel({
    required this.id,
    required this.caseNumber,
    required this.title,
    required this.description,
    required this.courtName,
    required this.status,
    required this.adminWallet,
    required this.participants,
    required this.createdAt,
  });

  factory CaseModel.fromJson(Map<String, dynamic> json) {
    var list = json['participants'] as List? ?? [];
    List<ParticipantModel> participantList = list.map((i) => ParticipantModel.fromJson(i)).toList();

    return CaseModel(
      id: json['_id'] ?? json['id'] ?? '',
      caseNumber: json['caseNumber'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      courtName: json['courtName'] ?? '',
      status: json['status'] ?? 'active',
      adminWallet: json['adminWallet'] ?? '',
      participants: participantList,
      createdAt: json['createdAt'] != null 
          ? DateTime.parse(json['createdAt']) 
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'caseNumber': caseNumber,
      'title': title,
      'description': description,
      'courtName': courtName,
      'status': status,
      'adminWallet': adminWallet,
      'participants': participants.map((e) => e.toJson()).toList(),
      'createdAt': createdAt.toIso8601String(),
    };
  }
}
