import 'dart:ui';
import 'package:flutter/material.dart';

import '../services/firebase_auth_service.dart';
import '../services/chain_service.dart';
// FirestoreService'i eklemeyi unutma, çünkü kontrol fonksiyonu orada:
import '../services/firestore_service.dart';
import 'login_screen.dart';
import 'create_chain_screen.dart';

// 1. Değişiklik: Burası artık StatefulWidget oldu
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // Servisleri burada tanımlıyoruz ki her yerden erişelim
  final FirebaseAuthService _authService = FirebaseAuthService();
  final ChainService _chainService = ChainService();
  final FirestoreService _firestoreService =
      FirestoreService(); // Kontrol için bu lazım

  late String userId;
  String? userEmail;

  // 2. Değişiklik: initState (Ekran ilk açıldığında çalışan yer)
  @override
  void initState() {
    super.initState();

    // Kullanıcı bilgilerini al
    userId = _authService.currentUserId() ?? "";
    userEmail = _authService.getCurrentUserEmail();

    // ZİNCİR KONTROLÜNÜ BAŞLAT 🚀
    // Ekran çizilir çizilmez bu fonksiyon çalışacak.
    _gunlukKontroluYap();
  }

  // Bu fonksiyon arka planda saati kontrol edip zinciri kıracak veya uyaracak
  Future<void> _gunlukKontroluYap() async {
    if (userId.isNotEmpty) {
      await _firestoreService.checkChainsOnAppStart(userId);
      // İşlem bitince ekranı tazeleyelim ki kullanıcı sonucu görsün
      if (mounted) {
        setState(() {});
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // build metodu artık çok daha sade, servisler yukarıda tanımlı.

    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
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
              await _authService.logout();

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

          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Kullanıcı selamlama
                  Text(
                    "Welcome back,",
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.9),
                      fontSize: 18,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    userEmail ?? "Traveler",
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 28),

                  const Text(
                    "Your Chains",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 16),

                  // 📌 Kullanıcının chain listesi (StreamBuilder)
                  Expanded(
                    child: StreamBuilder<List<Map<String, dynamic>>>(
                      // userId artık initState'den geliyor
                      stream: _chainService.getUserChains(userId),
                      builder: (context, snapshot) {
                        if (!snapshot.hasData) {
                          return const Center(
                            child: CircularProgressIndicator(
                              color: Colors.white,
                            ),
                          );
                        }

                        final chains = snapshot.data!;

                        if (chains.isEmpty) {
                          return Center(
                            child: Text(
                              "You don't have any chains yet.\nTap + to create one!",
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.8),
                                fontSize: 16,
                              ),
                            ),
                          );
                        }

                        // LIST VIEW
                        return ListView.builder(
                          itemCount: chains.length,
                          itemBuilder: (context, index) {
                            final c = chains[index];

                            return Container(
                              margin: const EdgeInsets.only(bottom: 16),
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: Colors.white.withOpacity(0.25),
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    c["name"] ?? "Unnamed Chain",
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    "Period: ${c["period"]}",
                                    style: TextStyle(
                                      color: Colors.white.withOpacity(0.8),
                                      fontSize: 14,
                                    ),
                                  ),
                                  const SizedBox(height: 8),

                                  // 3. Değişiklik: Status Rengi Mantığı (Daha güvenli hale getirdim)
                                  Text(
                                    "Status: ${c["status"]}",
                                    style: TextStyle(
                                      // Status 'active' ise Yeşil, 'warning' ise Turuncu, 'broken' ise Kırmızı
                                      color: c["status"] == "active"
                                          ? Colors.greenAccent
                                          : c["status"] == "warning"
                                              ? Colors.orangeAccent
                                              : Colors.redAccent,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
