import 'package:supabase_flutter/supabase_flutter.dart';
import 'supabase_client.dart';

/// All auth talks to Supabase through here. No UI, no navigation — pure data layer.
/// Role is read from the `profiles` table server-side (never a hardcoded string).
class AuthService {
  GoTrueClient get _auth => supabase.auth;

  User? get currentUser => _auth.currentUser;
  Stream<AuthState> get authChanges => _auth.onAuthStateChange;

  Future<AuthResponse> signUp(String email, String password) =>
      _auth.signUp(email: email, password: password);

  Future<AuthResponse> signIn(String email, String password) =>
      _auth.signInWithPassword(email: email, password: password);

  Future<bool> signInWithGoogle() =>
      _auth.signInWithOAuth(OAuthProvider.google);

  Future<bool> signInWithApple() =>
      _auth.signInWithOAuth(OAuthProvider.apple);

  Future<void> sendEmailOtp(String email) =>
      _auth.signInWithOtp(email: email);

  Future<AuthResponse> verifyEmailOtp(String email, String token) =>
      _auth.verifyOTP(email: email, token: token, type: OtpType.email);

  Future<void> resetPassword(String email) =>
      _auth.resetPasswordForEmail(email);

  Future<void> signOut() => _auth.signOut();

  /// Server-side role check — replaces the old hardcoded admin credentials.
  Future<bool> isAdmin() async {
    final id = currentUser?.id;
    if (id == null) return false;
    final row = await supabase
        .from('profiles')
        .select('role')
        .eq('id', id)
        .single();
    return row['role'] == 'admin';
  }
}
