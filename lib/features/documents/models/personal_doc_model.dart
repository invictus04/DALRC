class PersonalDocModel {
  final String id;
  final String title;
  final String description;
  final String fileType;
  final int fileSize;
  final String ipfsCid;
  final bool encrypted;
  final String? owner;
  final DateTime createdAt;

  PersonalDocModel({
    required this.id,
    required this.title,
    required this.description,
    required this.fileType,
    required this.fileSize,
    required this.ipfsCid,
    required this.encrypted,
    required this.createdAt,
    this.owner
  });

  factory PersonalDocModel.fromJson(Map<String, dynamic> json) {
    return PersonalDocModel(
      id: json['_id'] ?? json['id'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      fileType: json['fileType'] ?? '',
      fileSize: json['fileSize'] ?? 0,
      ipfsCid: json['ipfsCid'] ?? '',
      owner: json['owner'],
      encrypted: json['encrypted'] ?? false,
      createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt']) : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'description': description,
      'fileType': fileType,
      'fileSize': fileSize,
      'ipfsCid': ipfsCid,
      'encrypted': encrypted,
      'owner': owner
    };
  }
}
