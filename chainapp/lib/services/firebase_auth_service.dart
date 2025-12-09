import 'package:firebase_auth/firebase_auth.dart';

class FirebaseAuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<User?> register(String email, String password) async {
    try {
      UserCredential credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      return credential.user;
    } catch (e) {
      print("REGISTER ERROR: $e");
      return null;
    }
  }

  Future<User?> login(String email, String password) async {
    try {
      UserCredential credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      return credential.user;
    } catch (e) {
      print("LOGIN ERROR: $e");
      return null;
    }
  }

  Future<void> logout() async {
    await _auth.signOut();
  }

  String? getCurrentUserEmail() {
    return _auth.currentUser?.email;
  }

  // 🔥 EKLENEN KISIM — ŞART!
  String currentUserId() {
    return _auth.currentUser!.uid;
  }
}
