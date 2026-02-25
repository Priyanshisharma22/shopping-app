import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:math';

class AuthProvider with ChangeNotifier {
  bool _isAuthenticated = false;
  String? _userId;
  String? _userName;
  String? _userPhone;
  String? _userEmail;

  // OTP related
  String? _generatedOtp;
  String? _otpPhone;
  DateTime? _otpExpiry;

  bool get isAuthenticated => _isAuthenticated;
  String? get userId => _userId;
  String? get userName => _userName;
  String? get userPhone => _userPhone;
  String? get userEmail => _userEmail;

  AuthProvider() {
    _loadUserData();
  }

  // Load user data from SharedPreferences
  Future<void> _loadUserData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _isAuthenticated = prefs.getBool('isAuthenticated') ?? false;
      _userId = prefs.getString('userId');
      _userName = prefs.getString('userName');
      _userPhone = prefs.getString('userPhone');
      _userEmail = prefs.getString('userEmail');
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading user data: $e');
    }
  }

  // Generate and send OTP
  Future<bool> sendOtp({required String phone}) async {
    try {
      // Simulate API call
      await Future.delayed(const Duration(seconds: 1));

      // Generate 6-digit OTP
      _generatedOtp = _generateOtp();
      _otpPhone = phone;
      _otpExpiry = DateTime.now().add(const Duration(minutes: 5));

      // In production, send OTP via SMS API (Twilio, Firebase Auth, etc.)
      debugPrint('OTP sent to $phone: $_generatedOtp'); // Remove in production

      return true;
    } catch (e) {
      debugPrint('Error sending OTP: $e');
      return false;
    }
  }

  // Verify OTP and login
  Future<bool> verifyOtpAndLogin({
    required String phone,
    required String otp,
  }) async {
    try {
      // Validate phone matches
      if (phone != _otpPhone) {
        debugPrint('Phone number mismatch');
        return false;
      }

      // Check OTP expiry
      if (_otpExpiry == null || DateTime.now().isAfter(_otpExpiry!)) {
        debugPrint('OTP expired');
        return false;
      }

      // Verify OTP
      if (otp != _generatedOtp) {
        debugPrint('Invalid OTP');
        return false;
      }

      // Simulate API call to check if user exists
      await Future.delayed(const Duration(seconds: 1));

      // Check if user exists in your backend
      final userExists = await _checkUserExists(phone);

      if (userExists) {
        // Existing user - login
        await _loginUser(phone);
      } else {
        // New user - needs registration
        // Clear OTP data but don't log in yet
        _clearOtpData();
        return false; // Indicate registration needed
      }

      _clearOtpData();
      return true;
    } catch (e) {
      debugPrint('OTP verification error: $e');
      return false;
    }
  }

  // Complete registration after OTP verification
  Future<bool> completeRegistration({
    required String phone,
    required String name,
    String? email,
  }) async {
    try {
      // Simulate API call
      await Future.delayed(const Duration(seconds: 1));

      _userId = 'user_${DateTime.now().millisecondsSinceEpoch}';
      _userName = name;
      _userPhone = phone;
      _userEmail = email;
      _isAuthenticated = true;

      // Save to SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('isAuthenticated', true);
      await prefs.setString('userId', _userId!);
      await prefs.setString('userName', name);
      await prefs.setString('userPhone', phone);
      if (email != null && email.isNotEmpty) {
        await prefs.setString('userEmail', email);
      }

      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Registration error: $e');
      return false;
    }
  }

  // Private method to login existing user
  Future<void> _loginUser(String phone) async {
    // In production, fetch user data from your API
    final prefs = await SharedPreferences.getInstance();

    // Simulate fetching user data
    _userId = prefs.getString('userId') ?? 'user_${DateTime.now().millisecondsSinceEpoch}';
    _userName = prefs.getString('userName') ?? 'User';
    _userPhone = phone;
    _userEmail = prefs.getString('userEmail');
    _isAuthenticated = true;

    // Save to SharedPreferences
    await prefs.setBool('isAuthenticated', true);
    await prefs.setString('userId', _userId!);
    await prefs.setString('userName', _userName!);
    await prefs.setString('userPhone', phone);

    notifyListeners();
  }

  // Check if user exists (mock - replace with actual API call)
  Future<bool> _checkUserExists(String phone) async {
    // In production, call your API to check if user exists
    final prefs = await SharedPreferences.getInstance();
    final savedPhone = prefs.getString('userPhone');
    return savedPhone == phone;
  }

  // Generate random 6-digit OTP
  String _generateOtp() {
    final random = Random();
    return (100000 + random.nextInt(900000)).toString();
  }

  // Clear OTP data
  void _clearOtpData() {
    _generatedOtp = null;
    _otpPhone = null;
    _otpExpiry = null;
  }

  // Resend OTP
  Future<bool> resendOtp({required String phone}) async {
    return await sendOtp(phone: phone);
  }

  // Logout user
  Future<void> logout() async {
    try {
      _isAuthenticated = false;
      _userId = null;
      _userName = null;
      _userPhone = null;
      _userEmail = null;
      _clearOtpData();

      // Clear SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();

      notifyListeners();
    } catch (e) {
      debugPrint('Logout error: $e');
    }
  }

  // Update user profile
  Future<bool> updateProfile({
    String? name,
    String? email,
  }) async {
    try {
      if (name != null) _userName = name;
      if (email != null) _userEmail = email;

      final prefs = await SharedPreferences.getInstance();
      if (name != null) await prefs.setString('userName', name);
      if (email != null) await prefs.setString('userEmail', email);

      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Update profile error: $e');
      return false;
    }
  }
}