import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';

class FirebaseAuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // --- REGISTER (EMAIL) ---
// firebase_auth_service.dart içindeki register metodu

Future<User?> register(String email, String password) async {
  try {
    UserCredential credential = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
    
    if (credential.user != null) {
      await _saveUserToFirestore(credential.user!);
    }
    return credential.user;
  } catch (e) {
    // 🔥 KRİTİK DÜZELTME:
    // Eğer Pigeon hatası alıyorsak ama Firebase arka planda kullanıcıyı oluşturduysa
    if (e.toString().contains('PigeonUserDetails') || _auth.currentUser != null) {
      print("İç hata oluştu ama kullanıcı oluşturuldu, devam ediliyor...");
      
      // Kullanıcı oluşmuşsa Firestore kaydını manuel tetikle
      if (_auth.currentUser != null) {
        await _saveUserToFirestore(_auth.currentUser!);
      }
      return _auth.currentUser;
    }
    
    print("Register Service Error: $e");
    rethrow;
  }
}

  // --- LOGIN (EMAIL) ---
  Future<User?> login(String email, String password) async {
    try {
      UserCredential credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return credential.user;
    } catch (e) {
      print("Login Service Error: $e");
      rethrow;
    }
  }

  // --- GOOGLE SIGN IN (DÜZELTİLDİ) ---
  Future<User?> signInWithGoogle() async {
    try {
      // 🔥 KRİTİK DÜZELTME:
      // Önceki yarım kalan veya askıda kalan oturumları zorla kapatır.
      // Bu sayede her seferinde hesap seçme ekranı temiz bir şekilde açılır.
      await _googleSignIn.signOut();

      // 1. Google ile oturum açma penceresini başlat
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      if (googleUser == null) {
        // Kullanıcı pencereyi çarpıdan kapattıysa null döner, işlem biter.
        return null;
      }

      // 2. Kimlik doğrulama detaylarını al
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      // 3. Firebase için yeni bir kimlik oluştur
      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // 4. Firebase'e giriş yap
      UserCredential userCredential =
          await _auth.signInWithCredential(credential);

      // 5. Firestore'a kaydet
      if (userCredential.user != null) {
        await _saveUserToFirestore(userCredential.user!);
      }

      return userCredential.user;
    } catch (e) {
      print("Google Sign-In Service Error: $e");
      return null;
    }
  }

  // --- YARDIMCI: KULLANICIYI FIRESTORE'A KAYDET ---
  Future<void> _saveUserToFirestore(User user) async {
    try {
      final userRef = _firestore.collection('users').doc(user.uid);

      // Eğer kullanıcı zaten varsa üzerine yazma (merge: true)
      await userRef.set({
        'uid': user.uid,
        'email': user.email,
        'name': user.displayName ??
            user.email!.split('@')[0], // İsim yoksa mailin başını al
        'avatarSeed': user.uid, // Avatar için seed
        'xp': 0,
        'badge': 'Rookie',
        'createdAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      print("Firestore Save Error: $e");
      // Firestore hatası olsa bile giriş yapılmış sayılsın diye hata fırlatmıyoruz
    }
  }

  // --- LOGOUT ---
  Future<void> logout() async {
    // Hem Google'dan hem Firebase'den çıkış yap
    await _googleSignIn.signOut();
    await _auth.signOut();
  }

  // --- CURRENT USER ID ---
  String? currentUserId() {
    return _auth.currentUser?.uid;
  }
}
