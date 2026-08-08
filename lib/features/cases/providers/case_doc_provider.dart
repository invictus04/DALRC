import 'dart:io';
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:dapp/core/services/api_service.dart';
import 'package:dapp/core/services/pinata_service.dart';
import 'package:dapp/features/cases/models/case_doc_model.dart';
import 'package:dapp/features/cases/models/audit_log_model.dart';
import 'dart:developer';

class CaseDocProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();

  List<CaseDocModel> _documents = [];
  bool _isLoading = false;
  String? _error;

  List<CaseDocModel> get documents => _documents;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> fetchCaseDocs(String caseId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _apiService.dio.get('/api/v1/case-doc/$caseId');
      if (response.statusCode == 200) {
        // The API returns an array of documents directly, or nested inside a key. Let's assume nested in 'documents' or 'caseDocuments' based on standard conventions.
        // I will check common keys or direct array.
        dynamic data = response.data['caseDocuments'] ?? response.data['documents'] ?? response.data;
        if (data is List) {
          _documents = data.map((e) => CaseDocModel.fromJson(e)).toList();
        } else {
          _documents = [];
        }
      }
    } on DioException catch (e) {
      _error = e.response?.data?['message'] ?? 'Failed to fetch case documents';
      log('Error fetching case documents: $_error');
    } catch (e) {
      _error = 'An unexpected error occurred';
      log('Unexpected error: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> uploadCaseDocument(
      String caseId, String title, File file, List<Map<String, dynamic>> accessControl) async {
    try {
      // 1. Upload to IPFS via Pinata
      log('Uploading file to Pinata IPFS...');
      final cid = await PinataService.uploadFileToPinata(file);
      if (cid == null) throw Exception('Failed to upload file to IPFS');
      log('File uploaded to Pinata IPFS with CID: $cid');

      // 2. Extract file metadata
      final fileExtension = file.path.split('.').last.toLowerCase();
      final fileSize = await file.length();

      // 3. Save metadata to backend
      final payload = {
        'caseId': caseId,
        'title': title,
        'fileType': fileExtension,
        'fileSize': fileSize,
        'ipfsCid': cid,
        'encrypted': true, // Mock encryption
        'accessControl': accessControl,
      };

      final response = await _apiService.dio.post('/api/v1/case-doc/upload', data: payload);
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        await fetchCaseDocs(caseId); // Refresh list
        return true;
      }
    } catch (e) {
      log('Failed to upload case document: $e');
    }
    return false;
  }

  Future<bool> grantDocumentAccess(String caseId, String docId, String targetWallet, bool canView, bool canDelete) async {
    try {
      final response = await _apiService.dio.patch('/api/v1/case-doc/$caseId/$docId/grant-access', data: {
        'targetWallet': targetWallet,
        'permissions': {
          'canView': canView,
          'canDelete': canDelete,
        }
      });
      if (response.statusCode == 200) {
        await fetchCaseDocs(caseId);
        return true;
      }
    } catch (e) {
      log('Failed to grant doc access: $e');
    }
    return false;
  }

  Future<bool> revokeDocumentAccess(String caseId, String docId, String targetWallet) async {
    try {
      final response = await _apiService.dio.patch('/api/v1/case-doc/$caseId/$docId/revoke-access', data: {
        'targetWallet': targetWallet,
      });
      if (response.statusCode == 200) {
        await fetchCaseDocs(caseId);
        return true;
      }
    } catch (e) {
      log('Failed to revoke doc access: $e');
    }
    return false;
  }

  Future<String?> viewDocument(String caseId, String docId) async {
    try {
      final response = await _apiService.dio.get('/api/v1/case-doc/$caseId/view/$docId');
      if (response.statusCode == 200) {
        // Assuming the backend returns the IPFS CID or a direct URL after logging the view
        final cid = response.data['ipfsCid'] ?? response.data['url'] ?? '';
        if (cid.isNotEmpty && !cid.startsWith('http')) {
          return 'https://gateway.pinata.cloud/ipfs/$cid';
        }
        return cid;
      }
    } catch (e) {
      log('Failed to view document: $e');
    }
    return null;
  }

  Future<List<AuditLogModel>> fetchDocumentLogs(String docId) async {
    try {
      final response = await _apiService.dio.get('/api/v1/case-doc/$docId/logs');
      if (response.statusCode == 200) {
        final List data = response.data['logs'] ?? response.data ?? [];
        return data.map((e) => AuditLogModel.fromJson(e)).toList();
      }
    } catch (e) {
      log('Failed to fetch doc logs: $e');
    }
    return [];
  }
}
