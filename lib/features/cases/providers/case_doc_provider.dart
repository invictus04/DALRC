import 'dart:io';
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:dapp/core/services/api_service.dart';
import 'package:dapp/core/services/pinata_service.dart';
import 'package:dapp/features/cases/models/case_doc_model.dart';
import 'package:dapp/features/documents/models/get_document_model.dart';
import 'package:dapp/features/cases/models/audit_log_model.dart';
import 'dart:developer';

class CaseDocProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();

  List<Document> _documents = [];
  Pagination? _pagination;
  Filters? _filters;
  bool _isLoading = false;
  String? _error;

  List<Document> get documents => _documents;
  Pagination? get pagination => _pagination;
  Filters? get filters => _filters;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> fetchCaseDocs(String caseId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _apiService.dio.get('/api/v1/case-doc/$caseId');
      // log('response: ${response.data}');
      // log('case id :${caseId}');
      if (response.statusCode == 200) {
        final getDocModel = GetDocumentModel.fromJson(response.data);
        if (getDocModel.success) {
          _documents = getDocModel.documents;
          _pagination = getDocModel.pagination;
          _filters = getDocModel.filters;
        } else {
          _documents = [];
          _error = getDocModel.message;
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

  Future<bool> uploadCaseDocument( String caseId, String title, File file, List<Map<String, dynamic>> accessControl) async {
    try {

      log('Uploading file to Pinata IPFS...');
      final cid = await PinataService.uploadFileToPinata(file);
      if (cid == null) throw Exception('Failed to upload file to IPFS');
      log('File uploaded to Pinata IPFS with CID: $cid');


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
        final docData = response.data['sanitizedDocument'] ?? response.data;
        final cid = docData['ipfsCid'] ?? response.data['url'] ?? '';
        if (cid.isNotEmpty && !cid.startsWith('http')) {
          return PinataService.getFileUrl(cid);
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
