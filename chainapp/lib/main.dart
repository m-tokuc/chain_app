<<<<<<< HEAD
=======
import 'package:chainapp/firebase_options.dart';
import 'package:chainapp/screens/home_screen.dart';
>>>>>>> 3b69c24d933ba64b6916622786e7f315d55e838b
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'firebase_options.dart';
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
<<<<<<< HEAD
=======

class AuthGate extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // Firebase login durumunu dinler
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // Firebase henüz hazır değil — loading gösterebiliriz
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        // Kullanıcı giriş yapmışsa → HomeScreen
        if (snapshot.hasData) {
          return HomeScreen();
        }

        // Kullanıcı giriş yapmamışsa → LoginScreen
        return const LoginScreen();
      },
    );
  }
}
>>>>>>> 3b69c24d933ba64b6916622786e7f315d55e838b
