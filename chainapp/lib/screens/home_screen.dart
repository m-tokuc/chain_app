import 'dart:ui';
import 'package:chainapp/widgets/chainpart.dart';
import 'package:flutter/material.dart';
import '../services/firebase_auth_service.dart';
import '../services/chain_service.dart';
import 'login_screen.dart';
import 'create_chain_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = FirebaseAuthService();
    final userEmail = authService.getCurrentUserEmail();
    final userId = authService.currentUserId(); // ← ARTIK TAM DOĞRU
    final chainService = ChainService();

    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            bottom: Radius.circular(20),
          ),
        ),
        backgroundColor: Colors.black,
        elevation: 0,
        title: const Text(
          "Chain App",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        actions: [
          // Yeni chain oluşturma
          IconButton(
            icon: const Icon(Icons.add, color: Colors.white),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const CreateChainScreen()),
              );
            },
          ),

          // Logout
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            onPressed: () async {
              await authService.logout();

              if (context.mounted) {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                  (route) => false,
                );
              }
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          // Gradient arka plan
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Color(0xFF0A0E25),
                    Color(0xFF142A52),
                    Color(0xFF1F3D78),
                    Color(0xFF6C5ECF),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
          ),
          //1. Zincir
          Positioned(
            top: 300,
            left: 40,
            child: chainpart(rotationAngle: -0.3),
          ),
          Positioned(
            top: 220,
            left: 270,
            child: chainpart(rotationAngle: -0.2),
          ),

          Positioned(
            top: 300, // 1. Zincirle AYNI KONUM
            left: 40, // 1. Zincirle AYNI KONUM
            child: ClipRect(
              // Burada deneme yanılma ile kesişim noktasını bulman lazım.
              // Örnek: (x: 200, y: 0, genişlik: 100, yükseklik: 100)
              // Bu değerleri halkanın neresinin üste çıkmasını istiyorsan ona göre ayarla.
              clipper: AreaClipper(const Rect.fromLTWH(220, 0, 110, 300)),
              child: chainpart(rotationAngle: -0.3), // 1. Zincirle AYNI AÇI
            ),
          ),
          Positioned(
            top: 250,
            left: -160,
            child: chainpart(rotationAngle: 0.1),
          ),
          Positioned(
            top: 300, // 1. Zincirle AYNI KONUM
            left: 40, // 1. Zincirle AYNI KONUM
            child: ClipRect(
              // Burada deneme yanılma ile kesişim noktasını bulman lazım.
              // Örnek: (x: 200, y: 0, genişlik: 100, yükseklik: 100)
              // Bu değerleri halkanın neresinin üste çıkmasını istiyorsan ona göre ayarla.
              clipper: AreaClipper(const Rect.fromLTWH(30, 40, 110, 300)),
              child: chainpart(rotationAngle: -0.3), // 1. Zincirle AYNI AÇI
            ),
          )
        ],
      ),
    );
  }
}
