import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:chainapp/firebase_options.dart';
import 'screens/login_screen.dart';
import 'screens/chain_hub_screen.dart';
import 'services/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

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
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      home: const AuthGate(),
    );
  }
}

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            backgroundColor: Color(0xFF0A0E25),
            body: Center(child: CircularProgressIndicator(color: Colors.white)),
          );
        }

        // Giriş yapılmışsa
        if (snapshot.hasData && snapshot.data != null) {
          // 🔥 KRİTİK ADIM: Kullanıcı giriş yaptığı an bildirim servisini başlat
          NotificationService().init(snapshot.data!.uid);

          return const ChainHubScreen();
        }

        // Giriş yapılmamışsa Login Ekranına
        return const LoginScreen();
      },
    );
  }
}
