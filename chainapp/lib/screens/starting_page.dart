import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/firebase_auth_service.dart';
import '../services/chain_service.dart';
import 'create_chain_screen.dart';
import 'chain_hub_screen.dart'; // ChainHubScreen import edildi

class StartingPage extends StatelessWidget {
  late final String userId;
  final authService = FirebaseAuthService();
  final chainService = ChainService();

  StartingPage({super.key}) {
    userId = authService.currentUserId()!;
    print("StartingPage Başlatıldı - Kullanıcı ID: $userId");
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      // DÜZELTME: Metod ismi service dosyasındaki ile aynı yapıldı (getUserChains)
      stream: chainService.getUserChains(userId),
      builder: (BuildContext context, AsyncSnapshot snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
              backgroundColor: Color(0xFF0A0E25),
              body: Center(child: CircularProgressIndicator()));
        }

        if (snapshot.hasError) {
          return Scaffold(body: Center(child: Text("Hata: ${snapshot.error}")));
        }

        if (snapshot.hasData) {
          var data = snapshot.data;
          int veriSayisi = 0;

          // Veri tipine göre kontrol
          if (data is List) {
            veriSayisi = data.length;
            print("Gelen veri tipi: List, Adet: $veriSayisi");
          } else if (data is QuerySnapshot) {
            veriSayisi = data.docs.length;
            print("Gelen veri tipi: QuerySnapshot, Adet: $veriSayisi");
          }

          if (veriSayisi > 0) {
            print("Zincir var, ChainHubScreen'e gidiliyor.");
            return const ChainHubScreen();
          }
        }

        print("Zincir yok, CreateChainScreen'e gidiliyor.");
        return const CreateChainScreen();
      },
    );
  }
}
