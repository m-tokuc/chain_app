import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'screens/login_screen.dart';
import 'firebase_options.dart';
import 'screens/home_screen.dart';

void main() async {
  // Firebase kullanacaksan bu iki satır main içinde şarttır:
  WidgetsFlutterBinding.ensureInitialized();
  // Firebase'i başlatırken, flutterfire configure ile oluşturulan options'ı kullanın
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
// ... (MyApp widget'ının geri kalanı)

  const MyApp({super.key});

  @override
  // chainapp/lib/main.dart
// ... (MyApp sınıfının üst kısmı)

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Chain App',
      theme: ThemeData(primarySwatch: Colors.blue),
      // HATA: home: const Scaffold(body: Center(child: Text('Merhaba Chain App!'))),
      // ÇÖZÜM:
      home: AuthGate(), // AuthGate'i ana sayfa olarak ayarla
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
          return HomeScreen();
        }

        // Kullanıcı giriş yapmamışsa → LoginScreen
        return const LoginScreen();
      },
    );
  }
}
