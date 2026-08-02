import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:reown_appkit/reown_appkit.dart';
import '../services/api_service.dart';
import '../models/user_model.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class AuthProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  UserModel? _user;
  bool _isLoading = false;
  String? _error;
  bool _needsWalletConnection = false;

  UserModel? get user => _user;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get needsWalletConnection => _needsWalletConnection;

  bool get isAuthenticated => _user != null;

  ReownAppKitModal? _appKitModal;
  ReownAppKitModal? get appKitModal => _appKitModal;

  Future<void> initAppKit(BuildContext context) async {
    if (_appKitModal != null) return;
    _appKitModal = ReownAppKitModal(
      context: context,
      projectId: 'ff261773380c8b4378cba48bc91260aa',
      metadata: const PairingMetadata(
        name: 'DALRC',
        description: 'Decentralized Legal Document Storage',
        url: 'https://dalrc.com',
        icons: ['https://dalrc.com/logo.png'],
        redirect: Redirect(
          native: 'dalrc://',
          universal: 'https://dalrc.com/wallet',
          linkMode: true,
        ),
      ),
    );
    await _appKitModal!.init();
  }

  Future<void> login(String role, String identifier, String password) async {
    log('Login called with role: $role, identifier: $identifier, password: $password');
    _setLoading(true);
    _needsWalletConnection = false;
    try {
      final response = await _apiService.dio.post('/api/v1/user/signin', data: {
        'role': role,
        'identifier': identifier,
        'password': password,
      });
      log(response.toString());
      if (response.statusCode == 200) {
        final data = response.data;
        if (data['token'] != null) {
          await _secureStorage.write(key: 'jwt', value: data['token']);
          // After storing token, fetch user details via /me endpoint
          log(data.toString());
          await _fetchUserProfile();
        } else if (data['user'] != null) {
          _user = UserModel.fromJson(data['user']);
        }
        _error = null;
      }
    } on DioException catch (e) {
      if (e.response != null) {
        final data = e.response?.data;
        _error = data is Map ? (data['message'] ?? data['error'] ?? 'Login failed: ${e.response?.statusCode}') : 'Login failed';
      } else {
        _error = 'Network error: Cannot reach server (check localhost/IP).';
      }
      log('Login Error: ${e.message} | Data: ${e.response?.data}');
      _user = null;
    } catch (e) {
      _error = 'An unexpected error occurred: $e';
      log('Unknown login error: $e');
      _user = null;
    }
    _setLoading(false);
  }

  Future<bool> signup({
    required String role,
    required String firstName,
    required String lastName,
    required String aadharNumber,
    required String phoneNumber,
    required String userId,
    required String password,
  }) async {
    _setLoading(true);
    try {
      final response = await _apiService.dio.post('/api/v1/user/signup', data: {
        'role': role,
        'firstName': firstName,
        'lastName': lastName,
        'aadharNumber': aadharNumber,
        'phoneNumber': phoneNumber,
        'userId': userId,
        'password': password,
      });

      if (response.statusCode == 200 || response.statusCode == 201) {
        _error = null;
        _setLoading(false);
        return true;
      }
    } on DioException catch (e) {
      if (e.response != null) {
        final data = e.response?.data;
        _error = data is Map ? (data['message'] ?? data['error'] ?? 'Signup failed: ${e.response?.statusCode}') : 'Signup failed';
      } else {
        _error = 'Network error: Cannot reach server (check localhost/IP).';
      }
      log('Signup Error: ${e.message} | Data: ${e.response?.data}');
    } catch (e) {
      _error = 'An unexpected error occurred. ${e.toString()}';
      log('Unknown signup error: $e');
    }
    _setLoading(false);
    return false;
  }

  Future<bool> verifyOtp({required String phoneNumber, required String otp}) async {
    _setLoading(true);
    try {
      final response = await _apiService.dio.patch('/api/v1/user/verify-otp', data: {
        'phoneNumber': phoneNumber,
        'otp': otp,
      });

      if (response.statusCode == 200 || response.statusCode == 201) {
        _error = null;
        _setLoading(false);
        return true;
      }
    } on DioException catch (e) {
      if (e.response != null) {
        final data = e.response?.data;
        _error = data is Map ? (data['message'] ?? data['error'] ?? 'OTP Verification failed: ${e.response?.statusCode}') : 'OTP Verification failed';
      } else {
        _error = 'Network error: Cannot reach server (check localhost/IP).';
      }
      log('Verify OTP Error: ${e.message} | Data: ${e.response?.data}');
    } catch (e) {
      _error = 'An unexpected error occurred. ${e.toString()}';
      log('Unknown Verify OTP error: $e');
    }
    _setLoading(false);
    return false;
  }

  Future<bool> resendOtp({required String phoneNumber}) async {
    _setLoading(true);
    try {
      final response = await _apiService.dio.patch('/api/v1/user/resend-otp', data: {
        'phoneNumber': phoneNumber,
      });

      if (response.statusCode == 200 || response.statusCode == 201) {
        _error = null;
        _setLoading(false);
        return true;
      }
    } on DioException catch (e) {
      if (e.response != null) {
        final data = e.response?.data;
        _error = data is Map ? (data['message'] ?? data['error'] ?? 'Failed to resend OTP: ${e.response?.statusCode}') : 'Failed to resend OTP';
      } else {
        _error = 'Network error: Cannot reach server (check localhost/IP).';
      }
      log('Resend OTP Error: ${e.message} | Data: ${e.response?.data}');
    } catch (e) {
      _error = 'An unexpected error occurred. ${e.toString()}';
      log('Unknown Resend OTP error: $e');
    }
    _setLoading(false);
    return false;
  }

  Future<bool> _fetchUserProfile() async {
    try {
      final response = await _apiService.dio.get('/api/v1/user/me');
      log(response.toString());
      if (response.statusCode == 200) {
        final rawData = response.data;
        final userData = (rawData is Map && rawData.containsKey('user'))
            ? rawData['user']
            : ((rawData is Map && rawData.containsKey('data')) ? rawData['data'] : rawData);
        _user = UserModel.fromJson(userData);
        log(rawData.toString());
        _needsWalletConnection = false;
        notifyListeners();
        return true;
      }
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        log('401 response on /user/me: ${e.response?.data}');
        _needsWalletConnection = true;
        notifyListeners();
        return false;
      }
      log('Error fetching user profile: ${e.message}');
    } catch (e) {
      log('Error fetching user profile: $e');
    }
    return false;
  }

  Future<void> checkAuthStatus() async {
    _setLoading(true);
    try {
      final token = await _secureStorage.read(key: 'jwt');
      if (token != null) {
        final success = await _fetchUserProfile();
        if (!success && !_needsWalletConnection) {
          await logout();
        }
      }
    } catch (e) {
      await logout();
    }
    _setLoading(false);
  }

  Future<void> logout() async {
    await _secureStorage.delete(key: 'jwt');
    _user = null;
    _needsWalletConnection = false;
    notifyListeners();
  }

  Future<bool> linkWallet(String walletAddress) async {
    _setLoading(true);
    try {
      final response = await _apiService.dio.patch('/api/v1/user/update-wallet', data: {
        'walletAddress': walletAddress,
      });
      if (response.statusCode == 200) {
        _needsWalletConnection = false;
        // Refresh user profile to get the updated wallet
        await _fetchUserProfile();
        _setLoading(false);
        return true;
      }
    } on DioException catch (e) {
      log('linkWallet error: ${e.response?.data}');
      _error = e.response?.data?['message'] ?? 'Failed to link wallet.';
    } catch (e) {
      _error = 'Failed to link wallet.';
    }
    _setLoading(false);
    return false;
  }

  Future<bool> requestPasswordReset({required String phoneNumber}) async {
    _setLoading(true);
    try {
      final response = await _apiService.dio.post('/api/v1/user/forgot-password/request-reset', data: {
        'phoneNumber': phoneNumber,
      });
      if (response.statusCode == 200) {
        _error = null;
        _setLoading(false);
        return true;
      }
    } on DioException catch (e) {
      log('requestPasswordReset error: ${e.response?.data}');
      _error = e.response?.data?['message'] ?? 'Failed to request password reset.';
    } catch (e) {
      _error = 'Failed to request password reset.';
    }
    _setLoading(false);
    return false;
  }

  Future<bool> resetPassword({required String phoneNumber, required String resetCode, required String newPassword}) async {
    _setLoading(true);
    try {
      final response = await _apiService.dio.post('/api/v1/user/forgot-password/reset', data: {
        'phoneNumber': phoneNumber,
        'resetCode': resetCode,
        'newPassword': newPassword,
      });
      if (response.statusCode == 200) {
        _error = null;
        _setLoading(false);
        return true;
      }
    } on DioException catch (e) {
      log('resetPassword error: ${e.response?.data}');
      _error = e.response?.data?['message'] ?? 'Failed to reset password.';
    } catch (e) {
      _error = 'Failed to reset password.';
    }
    _setLoading(false);
    return false;
  }

  Future<bool> updatePassword({required String password, required String newPassword}) async {
    _setLoading(true);
    try {
      final response = await _apiService.dio.put('/api/v1/user/reset-pw', data: {
        'password': password,
        'newPassword': newPassword,
      });
      if (response.statusCode == 200) {
        _error = null;
        _setLoading(false);
        return true;
      }
    } on DioException catch (e) {
      log('updatePassword error: ${e.response?.data}');
      _error = e.response?.data?['message'] ?? 'Failed to update password.';
    } catch (e) {
      _error = 'Failed to update password.';
    }
    _setLoading(false);
    return false;
  }

  Future<List<UserModel>> searchUsers(String filter) async {
    try {
      final response = await _apiService.dio.get('/api/v1/user/bulk', queryParameters: {
        'filter': filter,
      });
      if (response.statusCode == 200) {
        final data = response.data;
        if (data['users'] != null) {
          return (data['users'] as List)
              .map((u) => UserModel.fromJson(u))
              .toList();
        }
      }
    } on DioException catch (e) {
      log('searchUsers error: ${e.response?.data}');
    } catch (e) {
      log('Failed to search users: $e');
    }
    return [];
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
}
