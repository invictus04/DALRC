import 'package:dapp/features/cases/models/case_model.dart';
import 'package:dapp/features/auth/models/user_model.dart';

class CasePermissionsModel {
  final bool isUserCaseAdmin;
  final bool hasUserViewAccess;
  final bool hasUserUploadAccess;

  CasePermissionsModel({
    required this.isUserCaseAdmin,
    required this.hasUserViewAccess,
    required this.hasUserUploadAccess,
  });

  factory CasePermissionsModel.fromJson(Map<String, dynamic> json) {
    return CasePermissionsModel(
      isUserCaseAdmin: json['isUserCaseAdmin'] ?? false,
      hasUserViewAccess: json['hasUserViewAccess'] ?? false,
      hasUserUploadAccess: json['hasUserUploadAccess'] ?? false,
    );
  }
}

class CaseDetailsModel {
  final CaseModel caseData;
  final CasePermissionsModel permissions;
  final UserModel? adminData;

  CaseDetailsModel({
    required this.caseData,
    required this.permissions,
    this.adminData,
  });

  factory CaseDetailsModel.fromJson(Map<String, dynamic> json) {
    return CaseDetailsModel(
      caseData: CaseModel.fromJson(json['case'] ?? {}),
      permissions: CasePermissionsModel.fromJson(json['permissions'] ?? {}),
      adminData: json['adminData'] != null ? UserModel.fromJson(json['adminData']) : null,
    );
  }
}
