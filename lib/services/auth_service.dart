import 'package:supabase_flutter/supabase_flutter.dart';

/// Wraps Supabase auth operations.
/// Google / Apple sign-in are prepared but require platform-specific setup —
/// see comments in each method.
class AuthService {
  static final _supabase = Supabase.instance.client;

  // ─── Email / Password ──────────────────────────────────────────────────────

  /// Returns null on success, or an error message string.
  static Future<String?> signInWithEmail(String email, String password) async {
    try {
      await _supabase.auth.signInWithPassword(email: email, password: password);
      return null;
    } on AuthException catch (e) {
      return e.message;
    } catch (_) {
      return 'Unexpected error. Please try again.';
    }
  }

  /// Returns null on success, or an error message string.
  static Future<String?> signUpWithEmail(
    String email,
    String password, {
    String? fullName,
  }) async {
    try {
      await _supabase.auth.signUp(
        email: email,
        password: password,
        data: fullName != null ? {'full_name': fullName} : null,
        emailRedirectTo: 'io.supabase.zodcwtfyulruixisdgqr://login-callback/',
      );
      return null;
    } on AuthException catch (e) {
      return e.message;
    } catch (_) {
      return 'Unexpected error. Please try again.';
    }
  }

  // ─── Google ────────────────────────────────────────────────────────────────
  //
  // Setup checklist:
  //  1. In Supabase Dashboard → Authentication → Providers → Google:
  //       enable Google, add your Client ID & Secret.
  //  2. Add your SHA-1 fingerprint in Google Cloud Console for Android.
  //  3. Add the redirect URL from Supabase to your Google OAuth app.
  //  4. For Web: add google_sign_in / supabase signInWithOAuth.
  //  5. For iOS/Android: use supabase signInWithOAuth + a custom URI scheme
  //       (configure app_links / deep link in AndroidManifest.xml / Info.plist).
  //
  // The implementation below works for Web. For mobile you need a redirect
  // deep-link — see: https://supabase.com/docs/guides/auth/social-login/auth-google

  static Future<String?> signInWithGoogle() async {
    try {
      await _supabase.auth.signInWithOAuth(
        OAuthProvider.google,
        redirectTo: 'io.supabase.zodcwtfyulruixisdgqr://login-callback/',
      );
      return null;
    } on AuthException catch (e) {
      return e.message;
    } catch (_) {
      return 'Google sign-in failed. Please try again.';
    }
  }

  // ─── Apple ────────────────────────────────────────────────────────────────
  //
  // Setup checklist:
  //  1. In Supabase Dashboard → Authentication → Providers → Apple:
  //       enable Apple, fill in Service ID, Team ID, Key ID, Private Key.
  //  2. In Apple Developer Console: create a Services ID with Sign In with Apple
  //       and add your Supabase callback URL as a return URL.
  //  3. For iOS native: add the Sign In with Apple capability in Xcode.
  //
  // The implementation below works for Web/iOS. For Android you need
  // sign_in_with_apple package — see supabase docs.

  static Future<String?> signInWithApple() async {
    try {
      await _supabase.auth.signInWithOAuth(
        OAuthProvider.apple,
        redirectTo: 'io.supabase.zodcwtfyulruixisdgqr://login-callback/',
      );
      return null;
    } on AuthException catch (e) {
      return e.message;
    } catch (_) {
      return 'Apple sign-in failed. Please try again.';
    }
  }

  // ─── Session helpers ───────────────────────────────────────────────────────

  static User? get currentUser => _supabase.auth.currentUser;

  static Session? get currentSession => _supabase.auth.currentSession;

  static Stream<AuthState> get authStateChanges =>
      _supabase.auth.onAuthStateChange;

  static Future<void> signOut() => _supabase.auth.signOut();
}
