import 'dart:convert';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:trainings_app/models/profile.dart';

class AuthService {
  final SupabaseClient supabase;

  AuthService(this.supabase);

  User? get currentUser => supabase.auth.currentUser;

  Stream<AuthState> get authStateChanges => supabase.auth.onAuthStateChange;

  Future<bool> get isOnline async {
    final connectivityResult = await Connectivity().checkConnectivity();
    return connectivityResult != ConnectivityResult.none;
  }

  Future<Session?> getCachedSession() async {
    final prefs = await SharedPreferences.getInstance();
    final sessionJson = prefs.getString('supabase_session');
    if (sessionJson != null) {
      try {
        final sessionData = Map<String, dynamic>.from(jsonDecode(sessionJson));
        return Session.fromJson(sessionData);
      } catch (e) {
        print('Ошибка при восстановлении сессии: $e');
        return null;
      }
    }
    return null;
  }

  Future<void> saveSession(Session? session) async {
    final prefs = await SharedPreferences.getInstance();
    if (session != null) {
      await prefs.setString('supabase_session', jsonEncode(session.toJson()));
    } else {
      await prefs.remove('supabase_session');
    }
  }

  Future<Session?> getCurrentSession() async {
    final cachedSession = await getCachedSession();
    if (!await isOnline) {
      return cachedSession;
    }

    if (await isOnline) {
      try {
        final session = supabase.auth.currentSession;
        if (session != null) {
          await saveSession(session);
        }
        return session ?? cachedSession;
      } catch (e) {
        print('Ошибка при получении сессии с сервера: $e');
      }
    }
    return cachedSession;
  }

  Future<void> signOut() async {
    if (await isOnline) {
      try {
        await supabase.auth.signOut();
      } catch (e) {
        print('Ошибка при выходе из аккаунта: $e');
      }
    }
    await saveSession(null);
    await _clearProfileCache();
  }

  Future<void> _clearProfileCache() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('user_profile');
  }

  Future<Profile?> getCachedProfile() async {
    final prefs = await SharedPreferences.getInstance();
    final profileJson = prefs.getString('user_profile');
    if (profileJson != null) {
      try {
        final profileData = Map<String, dynamic>.from(jsonDecode(profileJson));
        return Profile.fromJson(profileData);
      } catch (e) {
        print('Ошибка при восстановлении профиля: $e');
        return null;
      }
    }
    return null;
  }

  Future<void> _saveProfileToCache(Profile profile) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_profile', jsonEncode(profile.toJson()));
  }

  Future<Profile?> getUserProfile() async {
    if (currentUser == null) return null;

    Profile? profile = await getCachedProfile();

    if (!await isOnline) {
      return profile;
    }

    if (await isOnline) {
      try {
        final response = await supabase
            .from('profiles')
            .select('first_name, last_name')
            .eq('user_id', currentUser!.id)
            .single();
        profile = Profile.fromJson(response);
        await _saveProfileToCache(profile);
      } catch (e) {
        print('Ошибка загрузки профиля с Supabase: $e');
        return profile;
      }
    }
    return profile;
  }

  Future<bool> updateUserProfile(String firstName, String lastName) async {
    if (currentUser == null) return false;
    try {
      await supabase.from('profiles').update({
        'first_name': firstName,
        'last_name': lastName,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('user_id', currentUser!.id);
      return true;
    } catch (e) {
      print('Ошибка обновления профиля: $e');
      return false;
    }
  }
}

final authService = AuthService(Supabase.instance.client);
