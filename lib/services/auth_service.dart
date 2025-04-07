import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService {
  final SupabaseClient supabase;

  AuthService(this.supabase);

  User? get currentUser => supabase.auth.currentUser;

  Stream<AuthState> get authStateChanges => supabase.auth.onAuthStateChange;

  Future<void> signOut() async {
    await supabase.auth.signOut();
  }
}

final authService = AuthService(Supabase.instance.client);