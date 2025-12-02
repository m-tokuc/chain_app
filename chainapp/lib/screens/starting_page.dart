import 'dart:ui';
import 'package:chainapp/screens/home_screen.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // QuerySnapshot tipini kullanabilmek için
import '../services/firebase_auth_service.dart';
import '../services/chain_service.dart';
import 'create_chain_screen.dart';

class StartingPage extends StatelessWidget {
  late final String userId;
  final authService = FirebaseAuthService();
  final chainService = ChainService();

  StartingPage({super.key}) {
    userId = authService.currentUserId();
    // 1. KONTROL: ID doğru geliyor mu? Konsola bak.
    print("StartingPage Başlatıldı - Kullanıcı ID: $userId");
  }

  @override
  Widget build(BuildContext context) {
    // Scaffold içinde Scaffold döndürmek UI hatalarına yol açabilir.
    // Bu yüzden buradaki Scaffold'u kaldırıp sadece StreamBuilder döndürmen daha temiz olabilir
    // (Eğer HomeScreen ve CreateChainScreen kendi Scaffold'larına sahipse).
    return StreamBuilder(
      stream: chainService.getUserChainsStream(userId),
      builder: (BuildContext context, AsyncSnapshot snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          // Yükleniyor ekranı için Scaffold gerekli olabilir
          return const Scaffold(
              body: Center(child: CircularProgressIndicator()));
        }

        if (snapshot.hasError) {
          return Scaffold(body: Center(child: Text("Hata: ${snapshot.error}")));
        }

        // 2. KONTROL: Veri ne geliyor?
        if (snapshot.hasData) {
          // Gelen verinin tipini ve içeriğini konsola yazdıralım
          // Eğer bu sayı 0 ise, veritabanında bu ID ile kayıtlı veri yok demektir.
          // Eğer QuerySnapshot ise .docs.length, Liste ise .length kullanılır.

          // Dinamik kontrol (Hata almamak için):
          var data = snapshot.data;
          int veriSayisi = 0;

          if (data is QuerySnapshot) {
            veriSayisi = data.docs.length;
            print("Gelen veri tipi: QuerySnapshot, Adet: $veriSayisi");
          } else if (data is List) {
            veriSayisi = data.length;
            print("Gelen veri tipi: List, Adet: $veriSayisi");
          } else {
            print("Gelen veri tipi bilinmiyor: $data");
          }

          if (veriSayisi > 0) {
            print("Zincir var, Home'a gidiliyor.");
            return const HomeScreen();
          }
        }

        print("Zincir yok veya veri boş, CreateChain'e gidiliyor.");
        // Veri yoksa veya boşsa:
        return const CreateChainScreen();
      },
    );
  }
}
