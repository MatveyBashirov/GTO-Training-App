import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:trainings_app/models/profile.dart';

class AuthService {
  final SupabaseClient supabase;

  AuthService(this.supabase);

  User? get currentUser => supabase.auth.currentUser;

  Stream<AuthState> get authStateChanges => supabase.auth.onAuthStateChange;

  Future<void> signOut() async {
    await supabase.auth.signOut();
  }

  Future<Profile?> getUserProfile() async {
    if (currentUser == null) return null;

    try {
      final response = await supabase
          .from('profiles')
          .select('first_name, last_name')
          .eq('user_id', currentUser!.id)
          .single();

      return Profile.fromJson(response);
    } catch (e) {
      print('Ошибка загрузки профиля: $e');
      return null;
    }
  }
  
  Future<bool> updateUserProfile(String firstName, String lastName) async {
    if (currentUser == null) return false;

    try {
      await supabase
          .from('profiles')
          .update({
            'first_name': firstName,
            'last_name': lastName,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('user_id', currentUser!.id);
      return true;
    } catch (e) {
      print('Ошибка обновления профиля: $e');
      return false;
    }
  }
}

final authService = AuthService(Supabase.instance.client);