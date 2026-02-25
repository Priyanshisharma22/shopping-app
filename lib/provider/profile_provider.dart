import 'package:flutter/material.dart';
import '../models/user_profile_model.dart';

class ProfileProvider with ChangeNotifier {
  UserProfile? _userProfile;
  bool _isLoading = false;
  String? _errorMessage;

  UserProfile? get userProfile => _userProfile;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // Fetch user profile
  Future<void> fetchUserProfile(String userId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // TODO: Replace with actual API call
      await Future.delayed(const Duration(seconds: 1));

      // Mock data
      _userProfile = UserProfile(
        id: userId,
        name: 'John Doe',
        email: 'john.doe@example.com',
        phone: '+91 9876543210',
        profilePicture: null,
        createdAt: DateTime.now().subtract(const Duration(days: 365)),
      );

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  // Update user profile
  Future<bool> updateUserProfile({
    required String name,
    required String email,
    required String phone,
    String? profilePicture,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // TODO: Replace with actual API call
      await Future.delayed(const Duration(seconds: 1));

      _userProfile = _userProfile?.copyWith(
        name: name,
        email: email,
        phone: phone,
        profilePicture: profilePicture,
      );

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Upload profile picture
  Future<bool> uploadProfilePicture(String imagePath) async {
    _isLoading = true;
    notifyListeners();

    try {
      // TODO: Implement image upload to server
      await Future.delayed(const Duration(seconds: 2));

      _userProfile = _userProfile?.copyWith(profilePicture: imagePath);

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  void clearProfile() {
    _userProfile = null;
    _errorMessage = null;
    notifyListeners();
  }
}