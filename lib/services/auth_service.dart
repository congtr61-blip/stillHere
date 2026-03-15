import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  
  // 加个锁，防止重复点击触发 Future already completed
  bool _isSigningIn = false;

  Stream<User?> get userChanges => _auth.userChanges();

  Future<UserCredential?> signInWithGoogle() async {
    if (_isSigningIn) return null; // 如果正在登录，直接拦截
    _isSigningIn = true;

    try {
      // Web 端有时需要先登出一下以确保清除之前的状态残留
      if (await _googleSignIn.isSignedIn()) {
        await _googleSignIn.signOut();
      }

      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        _isSigningIn = false;
        return null;
      }

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final result = await _auth.signInWithCredential(credential);
      _isSigningIn = false;
      return result;
    } catch (e) {
      _isSigningIn = false;
      print("Google Auth Error: $e");
      return null;
    }
  }

  Future<void> signOut() async {
    await _googleSignIn.signOut();
    await _auth.signOut();
  }
}