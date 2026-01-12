import 'package:chainapp/services/Timer_service.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:chainapp/firebase_options.dart';
import 'package:provider/provider.dart';
import 'screens/login_screen.dart';
import 'screens/chain_hub_screen.dart';
import 'services/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(MultiProvider(
    providers: [
      ChangeNotifierProvider(create: (_) => TimerProvider()),
    ],
    child: const MyApp(),
  ));
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
        // Koyu tema tercihi (isteğe bağlı)
        scaffoldBackgroundColor: const Color(0xFF0A0E25),
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
        // 1. Bekleme Durumu
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            backgroundColor: Color(0xFF0A0E25),
            body: Center(child: CircularProgressIndicator(color: Colors.white)),
          );
        }

        // 2. Giriş Yapılmışsa
        if (snapshot.hasData && snapshot.data != null) {
          // 🔥 DÜZELTME: init fonksiyonunu doğrudan burada çağırmak yerine
          // bu işi yapacak olan 'NotificationInitWrapper' widget'ına gönderiyoruz.
          return NotificationInitWrapper(
            userId: snapshot.data!.uid,
            child: const ChainHubScreen(),
          );
        }

        // 3. Giriş Yapılmamışsa
        return const LoginScreen();
      },
    );
  }
}

// 🔥 YENİ WIDGET: Servisi Sadece 1 Kez Başlatır
class NotificationInitWrapper extends StatefulWidget {
  final String userId;
  final Widget child;

  const NotificationInitWrapper({
    super.key,
    required this.userId,
    required this.child,
  });

  @override
  State<NotificationInitWrapper> createState() => _NotificationInitWrapperState();
}

class _NotificationInitWrapperState extends State<NotificationInitWrapper> {
  @override
  void initState() {
    super.initState();
    // ✅ Sayfa oluştuğunda SADECE BİR KEZ çalışır.
    _initializeService();
  }

  Future<void> _initializeService() async {
    print("🚀 Main: Bildirim servisi başlatılıyor... UserID: ${widget.userId}");
    await NotificationService().init(widget.userId);
  }

  @override
  Widget build(BuildContext context) {
    // İşlem bitse de bitmese de kullanıcıyı bekletmeden ana ekranı gösterir
    return widget.child;
  }
}