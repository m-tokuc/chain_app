import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'firebase_options.dart'; // <-- Burayı koruyoruz (Firebase init için şart)
import 'screens/login_screen.dart';
import 'screens/home_screen.dart';

void main() async {
  // Flutter motorunu başlat
  WidgetsFlutterBinding.ensureInitialized();

  // Firebase'i başlat (Arkadaşının getirdiği ayar dosyasıyla)
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Chain App',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF6C5ECF)),
        useMaterial3: true,
      ),
      // --- ANA KAPI ---
      // Burası kullanıcının giriş yapıp yapmadığını kontrol eder.
      // Giriş yaptıysa -> HomeScreen
      // Yapmadıysa -> LoginScreen
      home: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          // Eğer veri varsa (yani kullanıcı giriş yapmışsa)
          if (snapshot.hasData) {
            return const HomeScreen();
          }
          // Yoksa giriş ekranına gönder
          return const LoginScreen();
        },
      ),
    );
  }
}
