// import 'package:flutter/material.dart';
// import 'package:firebase_core/firebase_core.dart'; // firebase_core'u eklediğinizden emin olun

// // flutterfire configure ile oluşturulan ve bağlantı bilgilerini içeren dosya
// import 'firebase_options.dart';

// void main() async {
//   // Flutter motorunun (binding) başlatılmasını bekle
//   WidgetsFlutterBinding.ensureInitialized();

//   // Firebase'i başlat
//   await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

//   runApp(const MyApp());
// }
// //H: öncesini silme otomatik olarak firebase i̇nitialize ediyor

import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'screens/login_screen.dart';
import 'screens/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const ChainApp());
}

class ChainApp extends StatelessWidget {
  const ChainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: AuthGate(),
    );
  }
}

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
          return const HomeScreen();
        }

        // Kullanıcı giriş yapmamışsa → LoginScreen
        return const LoginScreen();
      },
    );
  }
}
