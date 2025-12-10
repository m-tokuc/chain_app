import 'dart:ui';
import 'package:chainapp/widgets/chainpart.dart';
import 'package:flutter/material.dart';
import '../models/chain_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../services/firebase_auth_service.dart';
import '../services/firestore_service.dart';
import 'login_screen.dart';
import 'create_chain_screen.dart';

// Custom Clipper sınıfı (Zincir kesişimi için gerekli)
class AreaClipper extends CustomClipper<Rect> {
  final Rect clipRect;
  const AreaClipper(this.clipRect);
  @override
  Rect getClip(Size size) => clipRect;
  @override
  bool shouldReclip(covariant CustomClipper<Rect> oldClipper) => false;
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // Servisleri tanımlıyoruz
  final FirebaseAuthService _authService = FirebaseAuthService();
  final FirestoreService _firestoreService = FirestoreService();

  late String userId;
  String? userEmail;

  @override
  void initState() {
    super.initState();
    userId = _authService.currentUserId() ?? "";
    userEmail = _authService.getCurrentUserEmail();

    // Zincir kontrolünü ve token kaydetme (arkadaşınızdan gelen) mantığını başlat
    _gunlukKontroluYap();
    // if (userId.isNotEmpty) {
    //   _firestoreService.saveDeviceToken(userId); // Eğer bu metot tanımlıysa
    // }
  }

  // Zincir Kontrol Mantığı (Telefon saati ile)
  Future<void> _gunlukKontroluYap() async {
    if (userId.isNotEmpty) {
      await _firestoreService.checkChainsOnAppStart(userId);
      if (mounted) {
        setState(() {});
      }
    }
  }

  // Status String'ine göre renk döndüren helper fonksiyon
  Color _getStatusColor(String status) {
    switch (status) {
      case "active":
        return Colors.greenAccent;
      case "warning":
        return Colors.orangeAccent;
      case "broken":
        return Colors.redAccent;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Yeni FloatingActionButton ve Konumu (Arkadaşınızdan geldi)
      floatingActionButton: SizedBox(
        height: 65,
        width: 65,
        child: FloatingActionButton(
          onPressed: () {
            // Butona basıldığında yeni chain oluşturma ekranına gider
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const CreateChainScreen()),
            );
          },
          backgroundColor: const Color(0xFF6C5ECF),
          elevation: 10,
          shape: const CircleBorder(),
          child: const Icon(Icons.add, size: 35, color: Colors.white),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      extendBodyBehindAppBar: true,

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
          // Logout Butonu
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

      extendBody: true,
      body: Stack(
        children: [
          // 1. Gradient Arka Plan
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Color(0xFF0A0E25),
                    Color(0xFF142A52),
                    Color(0xFF1F3D78),
                    Color(0xFF6C5ECF)
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
          ),

          // 2. Dinamik Zincir Listesi (StreamBuilder)
          Positioned(
            top: 220,
            left: 0,
            right: 0,
            height: 400,
            // DÜZELTME: ChainModel listesi bekliyoruz ve FirestoreService çağırıyoruz.
            child: StreamBuilder<List<ChainModel>>(
              stream: _firestoreService.streamUserChains(userId), // Doğru metot
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                      child: CircularProgressIndicator(color: Colors.white));
                }

                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(
                    child: Text(
                      "No Chains Found. Create one!",
                      style: TextStyle(color: Colors.white54, fontSize: 18),
                    ),
                  );
                }

                final chains = snapshot.data!;
                const double linkWidth = 310.0;
                const double shiftAmount = 185.0;
                const double myWidthFactor = shiftAmount / linkWidth;

                return ListView.builder(
                  scrollDirection: Axis.horizontal,
                  clipBehavior: Clip.none,
                  padding: const EdgeInsets.only(left: 40, right: 100),
                  itemCount: chains.length,
                  itemBuilder: (context, index) {
                    final ChainModel chainData = chains[index];

                    // Zincir Sıralama Mantığı
                    final bool isEven = index % 2 == 0;
                    final double currentAngle = isEven ? -0.3 : 0.1;
                    final double currentTop = isEven ? 80.0 : 0.0;
                    final double prevTop = isEven ? 0.0 : 80.0;
                    final double topDiff = prevTop - currentTop;

                    final Color linkColor = _getStatusColor(chainData.status);

                    return Align(
                      alignment: Alignment.topLeft,
                      widthFactor: myWidthFactor,
                      child: Transform.translate(
                        offset: Offset(0, currentTop),
                        child: Stack(
                          clipBehavior: Clip.none,
                          children: [
                            // 1. KATMAN: ASIL ZİNCİR
                            chainpart(
                              rotationAngle: currentAngle,
                              chainName: chainData.name,
                              streakCount: chainData.streakCount,
                              statusColor: linkColor,
                            ),

                            // 2. KATMAN: YAMA (Kesişim efekti)
                            if (index > 0)
                              Positioned(
                                left: -shiftAmount,
                                top: topDiff,
                                child: ClipRect(
                                  clipper: AreaClipper(
                                      const Rect.fromLTWH(190, 0, 120, 120)),
                                  child: chainpart(
                                    rotationAngle: isEven ? 0.1 : -0.3,
                                    chainName: "",
                                    streakCount: 0,
                                    statusColor: Colors.grey,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),

          // 3. Kullanıcı Bilgileri
          Positioned(
              top: 460,
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Container(
                  width: MediaQuery.of(context).size.width - 20,
                  padding: const EdgeInsets.all(20),
                  color: Colors.black.withOpacity(0.5),
                  child: Text(
                    "Welcome, ${userEmail ?? 'Guest'}",
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              )),
        ],
      ),

      // Alt Navigasyon Çubuğu (BottomAppBar)
      bottomNavigationBar: Container(
        // Arkadaşınızdan gelen şık stil
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 10,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
          child: BottomAppBar(
            color: Colors.black.withOpacity(0.9),
            shape: const CircularNotchedRectangle(),
            notchMargin: 10.0,
            height: 70,
            padding: EdgeInsets.zero,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.home_rounded, size: 30),
                        color: Colors.white.withOpacity(0.9),
                        onPressed: () {},
                        tooltip: 'Ana Sayfa',
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.settings_rounded, size: 30),
                        color: Colors.white.withOpacity(0.9),
                        onPressed: () {},
                        tooltip: 'Ayarlar',
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
