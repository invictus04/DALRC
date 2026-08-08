class CaseDocAccessControl {
  final String wallet;
  final bool canView;
  final bool canDelete;

  CaseDocAccessControl({
    required this.wallet,
    required this.canView,
    required this.canDelete,
  });

  factory CaseDocAccessControl.fromJson(Map<String, dynamic> json) {
    return CaseDocAccessControl(
      wallet: json['wallet'] ?? '',
      canView: json['canView'] ?? false,
      canDelete: json['canDelete'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'wallet': wallet,
      'canView': canView,
      'canDelete': canDelete,
    };
  }
}

class CaseDocModel {
  final String id;
  final String caseId;
  final String title;
  final String fileType;
  final int fileSize;
  final String ipfsCid;
  final bool encrypted;
  final String uploader;
  final List<CaseDocAccessControl> accessControl;
  final DateTime createdAt;

  CaseDocModel({
    required this.id,
    required this.caseId,
    required this.title,
    required this.fileType,
    required this.fileSize,
    required this.ipfsCid,
    required this.encrypted,
    required this.uploader,
    required this.accessControl,
    required this.createdAt,
  });

  factory CaseDocModel.fromJson(Map<String, dynamic> json) {
    var list = json['accessControl'] as List? ?? [];
    List<CaseDocAccessControl> accessList = list.map((i) => CaseDocAccessControl.fromJson(i)).toList();

    return CaseDocModel(
      id: json['_id'] ?? json['id'] ?? '',
      caseId: json['caseId'] ?? '',
      title: json['title'] ?? '',
      fileType: json['fileType'] ?? '',
      fileSize: json['fileSize'] ?? 0,
      ipfsCid: json['ipfsCid'] ?? '',
      encrypted: json['encrypted'] ?? false,
      uploader: json['uploader'] ?? '',
      accessControl: accessList,
      createdAt: json['createdAt'] != null 
          ? DateTime.parse(json['createdAt']) 
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'caseId': caseId,
      'title': title,
      'fileType': fileType,
      'fileSize': fileSize,
      'ipfsCid': ipfsCid,
      'encrypted': encrypted,
      'uploader': uploader,
      'accessControl': accessControl.map((e) => e.toJson()).toList(),
      'createdAt': createdAt.toIso8601String(),
    };
  }
}
