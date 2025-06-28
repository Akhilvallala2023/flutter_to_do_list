import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/calendar/v3.dart' as calendar;
import 'package:googleapis_auth/googleapis_auth.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

final googleAuthServiceProvider = Provider<GoogleAuthService>((ref) {
  return GoogleAuthService();
});

class GoogleAuthService {
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: [
      'email',
      'https://www.googleapis.com/auth/calendar',
      'https://www.googleapis.com/auth/calendar.events',
    ],
    signInOption: SignInOption.standard,
  );

  GoogleSignInAccount? _currentUser;
  http.Client? _authClient;
  bool _isInitialized = false;

  GoogleSignInAccount? get currentUser => _currentUser;
  http.Client? get authClient => _authClient;
  bool get isSignedIn => _currentUser != null;
  bool get isInitialized => _isInitialized;

  // Initialize the service
  Future<bool> init() async {
    try {
      // Try to sign in silently (using stored credentials)
      _currentUser = await _googleSignIn.signInSilently();
      if (_currentUser != null) {
        await _getAuthClient();
      }
      _isInitialized = true;
      return _currentUser != null;
    } catch (error) {
      debugPrint('Google Auth Init Error: $error');
      _isInitialized = true;
      return false;
    }
  }

  // Sign in with Google
  Future<bool> signIn() async {
    try {
      // First try to sign out to clear any stale sessions
      await _googleSignIn.signOut();
      
      // Now attempt to sign in
      final user = await _googleSignIn.signIn();
      if (user == null) return false;
      
      _currentUser = user;
      final success = await _getAuthClient() != null;
      
      if (success) {
        await _saveUserInfo();
      }
      
      return success;
    } catch (error) {
      debugPrint('Google Sign-In Error: $error');
      return false;
    }
  }

  // Sign out
  Future<void> signOut() async {
    try {
      await _googleSignIn.signOut();
      _currentUser = null;
      _authClient = null;
      
      // Clear saved user info
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('google_user_email');
      await prefs.remove('google_user_name');
      await prefs.remove('google_user_photo');
    } catch (e) {
      debugPrint('Sign out error: $e');
    }
  }

  // Check if authentication is working
  Future<bool> checkAuthStatus() async {
    if (_currentUser == null) return false;
    
    try {
      final client = await _getAuthClient();
      if (client == null) return false;
      
      // Try to access the calendar API as a test
      final calendarApi = calendar.CalendarApi(client);
      await calendarApi.calendarList.list(maxResults: 1);
      
      return true;
    } catch (e) {
      debugPrint('Auth check failed: $e');
      // If auth check fails, try to refresh the token
      _currentUser = null;
      _authClient = null;
      return false;
    }
  }

  // Get auth client for API calls
  Future<http.Client?> _getAuthClient() async {
    if (_currentUser == null) return null;
    
    try {
      final auth = await _currentUser!.authentication;
      final accessToken = auth.accessToken;
      
      if (accessToken != null) {
        final credentials = AccessCredentials(
          AccessToken(
            'Bearer',
            accessToken,
            DateTime.now().add(const Duration(hours: 1)),
          ),
          null, // No refresh token in this flow
          ['https://www.googleapis.com/auth/calendar'],
        );
        
        // Create a client with the access token
        _authClient = authenticatedClient(
          http.Client(),
          credentials,
        );
        
        return _authClient;
      }
    } catch (error) {
      debugPrint('Auth Client Error: $error');
    }
    
    return null;
  }

  // Save user info for persistence
  Future<void> _saveUserInfo() async {
    if (_currentUser == null) return;
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('google_user_email', _currentUser!.email);
    await prefs.setString('google_user_name', _currentUser!.displayName ?? '');
    await prefs.setString('google_user_photo', _currentUser!.photoUrl ?? '');
  }

  // Get calendar client
  Future<calendar.CalendarApi?> getCalendarApi() async {
    final client = await _getAuthClient();
    if (client == null) return null;
    
    return calendar.CalendarApi(client);
  }
} 