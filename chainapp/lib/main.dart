import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
// BU SATIR ÖNEMLİ: Arkadaşınızın getirdiği Firebase yapılandırma dosyası
import 'firebase_options.dart';

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
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Chain App',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const Scaffold(body: Center(child: Text('Merhaba Chain App!'))),
    );
  }
}
