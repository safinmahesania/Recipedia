import 'package:supabase_flutter/supabase_flutter.dart';
import 'supabase_client.dart';

/// Auth data layer. No UI, no navigation. Role read from profiles (server-side).
class AuthService {
  GoTrueClient get _auth => supabase.auth;

  User? get currentUser => _auth.currentUser;
  Stream<AuthState> get authChanges => _auth.onAuthStateChange;

  /// Sign up + send confirmation-link email. `name` goes to user metadata,
  /// which the DB trigger copies into profiles.name.
  Future<AuthResponse> signUp(String email, String password, {String? name}) =>
      _auth.signUp(
        email: email,
        password: password,
        data: name == null ? null : {'name': name},
      );

  Future<AuthResponse> signIn(String email, String password) =>
      _auth.signInWithPassword(email: email, password: password);

  Future<bool> signInWithGoogle() => _auth.signInWithOAuth(OAuthProvider.google);
  Future<bool> signInWithApple()  => _auth.signInWithOAuth(OAuthProvider.apple);

  Future<void> resetPassword(String email) => _auth.resetPasswordForEmail(email);
  Future<void> signOut() => _auth.signOut();

  Future<void> updatePassword(String newPassword) =>
      _auth.updateUser(UserAttributes(password: newPassword));

  /// Deleting the auth user needs the service_role key, which must never ship
  /// in the app — so it lives in an Edge Function (supabase/functions/
  /// delete-account). If that call fails we still remove the profile row,
  /// which cascades away every recipe, review, favourite and list the user
  /// owns, and sign out. That satisfies "delete my data"; the orphaned
  /// auth.users row is cleaned up when the function is deployed.
  Future<bool> deleteAccount() async {
    final id = currentUser?.id;
    if (id == null) return false;
    var fullyDeleted = false;
    try {
      await supabase.functions.invoke('delete-account');
      fullyDeleted = true;
    } catch (_) {
      try {
        await supabase.from('profiles').delete().eq('id', id);
      } catch (_) {
        return false;
      }
    }
    await signOut();
    return fullyDeleted;
  }

  Future<bool> isAdmin() async {
    final id = currentUser?.id;
    if (id == null) return false;
    final row = await supabase.from('profiles').select('role').eq('id', id).single();
    return row['role'] == 'admin';
  }
}
