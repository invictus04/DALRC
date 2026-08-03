import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import '../services/api_service.dart';
import '../models/personal_doc_model.dart';

class PersonalDocProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();

  List<PersonalDocModel> _ownedDocs = [];
  List<PersonalDocModel> _sharedDocs = [];
  
  bool _isLoadingOwned = false;
  bool _isLoadingShared = false;
  
  String? _errorOwned;
  String? _errorShared;

  List<PersonalDocModel> get ownedDocs => _ownedDocs;
  List<PersonalDocModel> get sharedDocs => _sharedDocs;
  bool get isLoadingOwned => _isLoadingOwned;
  bool get isLoadingShared => _isLoadingShared;
  String? get errorOwned => _errorOwned;
  String? get errorShared => _errorShared;

  Future<void> fetchOwnedDocs() async {
    _isLoadingOwned = true;
    _errorOwned = null;
    notifyListeners();

    try {
      final response = await _apiService.dio.get('/api/v1/personal-doc/owned');
      if (response.statusCode == 200) {
        final List<dynamic> data = response.data['documents'] ?? response.data['data'] ?? [];
        _ownedDocs = data.map((e) => PersonalDocModel.fromJson(e)).toList();
      }
    } on DioException catch (e) {
      _errorOwned = e.response?.data?['message'] ?? 'Failed to fetch owned documents';
    } catch (e) {
      _errorOwned = 'An unexpected error occurred';
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
        final List<dynamic> data = response.data['documents'] ?? response.data['data'] ?? [];
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
}
