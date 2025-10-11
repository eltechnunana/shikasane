import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';

// import '../core/config.dart';

class AuthState {
  final bool isAuthenticated;
  final String? email;
  final String? displayName;
  final String? photoUrl;

  const AuthState({
    required this.isAuthenticated,
    this.email,
    this.displayName,
    this.photoUrl,
  });

  AuthState copyWith({
    bool? isAuthenticated,
    String? email,
    String? displayName,
    String? photoUrl,
  }) {
    return AuthState(
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      photoUrl: photoUrl ?? this.photoUrl,
    );
  }

  Map<String, dynamic> toJson() => {
        'isAuthenticated': isAuthenticated,
        'email': email,
        'displayName': displayName,
        'photoUrl': photoUrl,
      };

  static AuthState fromJson(Map<String, dynamic> json) => AuthState(
        isAuthenticated: json['isAuthenticated'] == true,
        email: json['email'] as String?,
        displayName: json['displayName'] as String?,
        photoUrl: json['photoUrl'] as String?,
      );
}

class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier() : super(const AuthState(isAuthenticated: false));

  Future<void> loadSession() async {
    if (Firebase.apps.isNotEmpty) {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        state = AuthState(
          isAuthenticated: true,
          email: user.email,
          displayName: user.displayName,
          photoUrl: user.photoURL,
        );
        return;
      }
    }
    {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString('session');
      if (raw != null) {
        final data = jsonDecode(raw) as Map<String, dynamic>;
        state = AuthState.fromJson(data);
      }
    }
  }

  Future<void> _persistSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('session', jsonEncode(state.toJson()));
  }

  // Email/Password via Firebase Auth

  Future<String?> signUpLocal({
    required String email,
    required String password,
    String? displayName,
  }) async {
    if (Firebase.apps.isEmpty) {
      return 'Firebase not configured. Provide Firebase options to enable sign up.';
    }
    try {
      final cred = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      if (displayName != null && displayName.isNotEmpty) {
        await cred.user?.updateDisplayName(displayName);
      }
      final user = FirebaseAuth.instance.currentUser;
      state = AuthState(
        isAuthenticated: true,
        email: user?.email,
        displayName: user?.displayName ?? displayName ?? email.split('@').first,
        photoUrl: user?.photoURL,
      );
      await _persistSession();
      return null;
    } on FirebaseAuthException catch (e) {
      return e.message;
    } catch (_) {
      return 'Sign up failed';
    }
  }

  Future<String?> loginLocal({
    required String email,
    required String password,
  }) async {
    if (Firebase.apps.isEmpty) {
      return 'Firebase not configured. Provide Firebase options to enable login.';
    }
    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      final user = FirebaseAuth.instance.currentUser;
      state = AuthState(
        isAuthenticated: true,
        email: user?.email,
        displayName: user?.displayName ?? email.split('@').first,
        photoUrl: user?.photoURL,
      );
      await _persistSession();
      return null;
    } on FirebaseAuthException catch (e) {
      return e.message;
    } catch (_) {
      return 'Login failed';
    }
  }

  // Google Sign-In removed.

  Future<void> signOut() async {
    try {
      if (Firebase.apps.isNotEmpty) {
        await FirebaseAuth.instance.signOut();
      }
    } catch (_) {}
    state = const AuthState(isAuthenticated: false);
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('session');
  }
}

final authNotifierProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final notifier = AuthNotifier();
  // Eagerly load session on provider creation
  notifier.loadSession();
  return notifier;
});

final isAuthenticatedProvider = Provider<bool>((ref) {
  final auth = ref.watch(authNotifierProvider);
  return auth.isAuthenticated;
});