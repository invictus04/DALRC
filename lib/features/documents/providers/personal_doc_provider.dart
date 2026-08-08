import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:dapp/core/services/api_service.dart';
import 'package:dapp/features/documents/models/personal_doc_model.dart';
import 'package:dapp/features/cases/models/audit_log_model.dart';
import 'package:file_picker/file_picker.dart';

class PersonalDocProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();

  List<PersonalDocModel> _ownedDocs = [];
  List<PersonalDocModel> _sharedDocs = [];
  
  bool _isLoadingOwned = false;
  bool _isLoadingShared = false;
  bool _isUploading = false;
  
  String? _errorOwned;
  String? _errorShared;

  // For the upload dialog
  PlatformFile? _selectedFile;

  List<PersonalDocModel> get ownedDocs => _ownedDocs;
  List<PersonalDocModel> get sharedDocs => _sharedDocs;
  bool get isLoadingOwned => _isLoadingOwned;
  bool get isLoadingShared => _isLoadingShared;
  bool get isUploading => _isUploading;
  String? get errorOwned => _errorOwned;
  String? get errorShared => _errorShared;
  PlatformFile? get selectedFile => _selectedFile;

  void setSelectedFile(PlatformFile? file) {
    _selectedFile = file;
    notifyListeners();
  }

  void setUploading(bool value) {
    _isUploading = value;
    notifyListeners();
  }

  void clearUploadState() {
    _selectedFile = null;
    _isUploading = false;
    // We don't notifyListeners here unless needed, but it's safe to do so.
    notifyListeners();
  }

  Future<void> fetchOwnedDocs() async {
    _isLoadingOwned = true;
    _errorOwned = null;
    notifyListeners();

    try {
      final response = await _apiService.dio.get('/api/v1/personal-doc/owned');
      log("Response of fetchOwnedDocs: ${response.toString()}");
      if (response.statusCode == 200) {
        final List<dynamic> data = response.data['personalDocuments'] ?? response.data['data'] ?? [];
        _ownedDocs = data.map((e) => PersonalDocModel.fromJson(e)).toList();
      }
    } on DioException catch (e) {
      _errorOwned = e.response?.data?['message'] ?? 'Failed to fetch owned documents';
    } catch (e) {
      _errorOwned = 'An unexpected error occurred $e';
    } finally {
      _isLoadingOwned = false;
      notifyListeners();
    }
  }

  Future<void> fetchSharedDocs() async {
    _isLoadingShared = true;
    _errorShared = null;
    notifyListeners();

    try {
      final response = await _apiService.dio.get('/api/v1/personal-doc/shared');
      if (response.statusCode == 200) {
        final List<dynamic> data = response.data['sharedDocuments'];
        log(response.toString());
        _sharedDocs = data.map((e) => PersonalDocModel.fromJson(e)).toList();
      }
    } on DioException catch (e) {
      _errorShared = e.response?.data?['message'] ?? 'Failed to fetch shared documents';
    } catch (e) {
      _errorShared = 'An unexpected error occurred';
    } finally {
      _isLoadingShared = false;
      notifyListeners();
    }
  }

  Future<bool> uploadDocument({
    required String title,
    required String description,
    required String fileType,
    required int fileSize,
    required String ipfsCid,
    required bool encrypted,
  }) async {
    try {
      final response = await _apiService.dio.post('/api/v1/personal-doc/upload', data: {
        'title': title,
        'description': description,
        'fileType': fileType,
        'fileSize': fileSize,
        'ipfsCid': ipfsCid,
        'encrypted': encrypted,
      });

      if (response.statusCode == 200 || response.statusCode == 201) {
        // Refresh owned docs after successful upload
        await fetchOwnedDocs();
        return true;
      }
    } catch (e) {
      // Error handling is handled by the caller or we can store an upload error
    }
    return false;
  }

  Future<bool> shareDocument(String docId, String targetWallet) async {
    try {
      final response = await _apiService.dio.post('/api/v1/personal-doc/share', data: {
        'docId': docId,
        'targetWallet': targetWallet,
      });
      log(response.toString());
      log("docid: ${docId}, target wallet: ${targetWallet}");
      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      return false;
    }
  }

  Future<bool> unshareDocument(String docId, String targetWallet) async {
    try {
      final response = await _apiService.dio.post('/api/v1/personal-doc/unshare', data: {
        'docId': docId,
        'targetWallet': targetWallet,
      });
      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      return false;
    }
  }

  Future<bool> deleteDocument(String docId) async {
    try {
      final response = await _apiService.dio.post('/api/v1/personal-doc/delete', data: {
        'docId': docId,
      });
      if (response.statusCode == 200 || response.statusCode == 201) {
        await fetchOwnedDocs(); // refresh list
        return true;
      }
    } catch (e) {
      return false;
    }
    return false;
  }

  Future<List<AuditLogModel>> fetchDocumentLogs(String docId) async {
    try {
      final response = await _apiService.dio.get('/api/v1/personal-doc/$docId/logs');
      if (response.statusCode == 200) {
        final List<dynamic> data = response.data['logs'] ?? response.data['data'] ?? [];
        return data.map((e) => AuditLogModel.fromJson(e)).toList();
      }
    } catch (e) {
      // Return empty list on error
    }
    return [];
  }
}
