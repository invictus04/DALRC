import 'dart:async';
import 'package:flutter/material.dart';
import 'package:dapp/features/search/models/search_user_model.dart';
import 'package:dapp/features/auth/models/user_model.dart';
import 'package:dapp/features/auth/providers/auth_provider.dart';

class UserSearchProvider with ChangeNotifier {
  AuthProvider? _authProvider;

  List<SearchUserModel> _users = [];
  bool _isLoading = false;
  Timer? _debounce;
  String _query = '';

  List<SearchUserModel> get users => _users;
  bool get isLoading => _isLoading;
  String get query => _query;

  void updateAuth(AuthProvider authProvider) {
    _authProvider = authProvider;
  }

  void onSearchChanged(String query) {
    _query = query;
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      if (query.trim().isNotEmpty) {
        _searchUsers(query.trim());
      } else {
        _users = [];
        notifyListeners();
      }
    });
    notifyListeners();
  }

  void clearSearch() {
    _query = '';
    _users = [];
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    notifyListeners();
  }

  Future<void> _searchUsers(String query) async {
    if (_authProvider == null) return;
    
    _isLoading = true;
    notifyListeners();

    final users = await _authProvider!.searchUsers(query);

    _users = users;
    _isLoading = false;
    notifyListeners();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }
}
