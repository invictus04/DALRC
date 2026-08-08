import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:dapp/core/services/api_service.dart';
import 'package:dapp/features/cases/models/case_model.dart';
import 'package:dapp/features/cases/models/case_details_model.dart';
import 'dart:developer';

class CaseProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();

  List<CaseModel> _cases = [];
  bool _isLoading = false;
  String? _error;

  List<CaseModel> get cases => _cases;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> fetchCases() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _apiService.dio.get('/api/v1/cases/get-cases');
      if (response.statusCode == 200) {
        final List<dynamic> data = response.data['cases'] ?? response.data['data'] ?? [];
        _cases = data.map((e) => CaseModel.fromJson(e)).toList();
      }
    } on DioException catch (e) {
      _error = e.response?.data?['message'] ?? 'Failed to fetch cases';
      log('Error fetching cases: $_error');
    } catch (e) {
      _error = 'An unexpected error occurred';
      log('Unexpected error: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> createCase(String title, String description, String courtName) async {
    try {
      final response = await _apiService.dio.post('/api/v1/cases/create', data: {
        'title': title,
        'description': description,
        'courtName': courtName,
      });

      if (response.statusCode == 200 || response.statusCode == 201) {
        await fetchCases();
        return true;
      }
    } catch (e) {
      log('Failed to create case: $e');
    }
    return false;
  }

  Future<bool> grantAccess(String caseId, String wallet, String role, bool canView, bool canUpload) async {
    try {
      final response = await _apiService.dio.patch('/api/v1/cases/$caseId/grant-access', data: {
        'wallet': wallet,
        'role': role,
        'permissions': {
          'canView': canView,
          'canUpload': canUpload,
        }
      });

      if (response.statusCode == 200 || response.statusCode == 201) {
        await fetchCases();
        return true;
      }
    } catch (e) {
      log('Failed to grant access: $e');
    }
    return false;
  }

  Future<bool> revokeAccess(String caseId, String wallet) async {
    try {
      final response = await _apiService.dio.delete('/api/v1/cases/$caseId/revoke-access/$wallet');
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        await fetchCases();
        return true;
      }
    } catch (e) {
      log('Failed to revoke access: $e');
    }
    return false;
  }

  Future<bool> migrateAdmin(String caseId, String newAdminWallet, String roleOfNewAdmin) async {
    try {
      final response = await _apiService.dio.patch('/api/v1/cases/$caseId/migrate-admin', data: {
        'newAdminWallet': newAdminWallet,
        'roleOfNewAdmin': roleOfNewAdmin,
      });

      if (response.statusCode == 200 || response.statusCode == 201) {
        await fetchCases();
        return true;
      }
    } catch (e) {
      log('Failed to migrate admin: $e');
    }
    return false;
  }

  Future<CaseDetailsModel?> fetchCaseDetails(String caseId) async {
    try {
      final response = await _apiService.dio.get('/api/v1/cases/$caseId');
      if (response.statusCode == 200) {
        final caseDetails = CaseDetailsModel.fromJson(response.data);
        
        final index = _cases.indexWhere((c) => c.id == caseId);
        if (index != -1) {
          _cases[index] = caseDetails.caseData;
          notifyListeners();
        }
        
        return caseDetails;
      }
    } catch (e) {
      log('Failed to fetch case details: $e');
    }
    return null;
  }
}
