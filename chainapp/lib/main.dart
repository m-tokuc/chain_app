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
import 'package:firebase_core/firebase_core.dart'; // firebase_core'u eklediğinizden emin olun

// flutterfire configure ile oluşturulan ve bağlantı bilgilerini içeren dosya
import 'firebase_options.dart';

void main() async {
  // Flutter motorunun (binding) başlatılmasını bekle
  WidgetsFlutterBinding.ensureInitialized();

  // Firebase'i başlat
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  runApp(const MyApp());
}
//H: öncesini silme otomatik olarak firebase i̇nitialize ediyor