import 'dart:ui';
import 'package:chainapp/screens/chain_hub_screen.dart';
import 'package:chainapp/screens/detailedstatisticsforchains.dart';
import 'package:chainapp/screens/join_chain_screen.dart';
import 'package:chainapp/widgets/chainpart.dart';
import 'package:flutter/material.dart';

// Sizin (HEAD) tarafınızdan eklenen importlar
import '../models/chain_model.dart';
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
  // Sizin (HEAD) tarafınızdan tanımlanan Servisler ve State'ler
  final FirebaseAuthService _authService = FirebaseAuthService();
  final FirestoreService _firestoreService = FirestoreService();

  late String userId;
  String? userEmail;

  @override
  void initState() {
    super.initState();
    userId = _authService.currentUserId() ?? "";
    userEmail = _authService.getCurrentUserEmail();

    // Zincir kontrolünü başlat
    _gunlukKontroluYap();
  }

  // Zincir Kontrol Mantığı (HEAD'den)
  Future<void> _gunlukKontroluYap() async {
    if (userId.isNotEmpty) {
      await _firestoreService.checkChainsOnAppStart(userId);
      if (mounted) {
        setState(() {});
      }
    }
  }

  // Status String'ine göre renk döndüren helper fonksiyon (HEAD'den)
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
    // Ekran boyutlarını alalım (Arkadaşınızdan geldi)
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      // FloatingActionButton (Arkadaşınızdan gelen şık FAB)
      floatingActionButton: SizedBox(
        height: 65,
        width: 65,
        child: FloatingActionButton(
          onPressed: () {
            // ❗ const kaldırıldı
            Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => CreateChainScreen(),
                ));
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
        leading: IconButton(
          icon: const Icon(Icons.menu, color: Colors.white),
          onPressed: () {
            // ❗ const kaldırıldı
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ChainHubScreen(),
              ),
            );
          },
        ),
        automaticallyImplyLeading: false,
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
          // Logout Butonu (HEAD ve Arkadaşınızın kodu birleştirildi)
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
          const Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
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

          // Zincir Başlığı (Arkadaşınızdan gelen başlık)
          Positioned(
            top: screenHeight / 8,
            left: 0,
            right: 0,
            child: const Text(
              textAlign: TextAlign.center,
              "Your Chain",
              style: TextStyle(
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),

          // 2. Dinamik Zincir Listesi (StreamBuilder) - HEAD Mantığı KORUNDU
          Positioned(
            top: 220,
            left: 0,
            right: 0,
            height: 400,
            child: StreamBuilder<List<ChainModel>>(
              stream: _firestoreService.streamUserChains(userId),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(color: Colors.white),
                  );
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
                const double shiftAmount = 190.0;
                const double myWidthFactor = shiftAmount / linkWidth;

                return ListView.builder(
                  cacheExtent: 1000,
                  scrollDirection: Axis.horizontal,
                  clipBehavior: Clip.none,
                  padding: const EdgeInsets.only(left: 40, right: 100),
                  itemCount: chains.length,
                  itemBuilder: (context, index) {
                    final ChainModel chainData = chains[index];

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
                            ChainPart(
                              rotationAngle: currentAngle,
                              chainName: chainData.name,
                              streakCount: chainData.streakCount,
                              statusColor: linkColor,
                            ),
                            if (index > 0)
                              Positioned(
                                left: -shiftAmount,
                                top: topDiff,
                                child: ClipRect(
                                  clipper: AreaClipper(
                                    const Rect.fromLTWH(190, 0, 120, 120),
                                  ),
                                  child: ChainPart(
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

          // 3. Story + Description (Arkadaşınızdan gelen)
          Positioned(
            top: (screenHeight / 7) + 300,
            bottom: 90,
            left: 0,
            right: 0,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(left: 16.0, bottom: 8.0),
                  child: Text(
                    "Zincirdekiler",
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.8),
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                SizedBox(
                  height: MediaQuery.of(context).size.height / 8,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: 10,
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    itemBuilder: (context, index) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8.0),
                        child: Column(
                          children: [
                            Container(
                              width: 80,
                              height: 80,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: const LinearGradient(
                                  colors: [
                                    Color(0xFF6C5ECF),
                                    Colors.purpleAccent
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.2),
                                    blurRadius: 5,
                                    offset: const Offset(0, 2),
                                  )
                                ],
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(4),
                                child: Container(
                                  decoration: const BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Colors.white,
                                  ),
                                  child: const Icon(Icons.person,
                                      color: Colors.grey),
                                ),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              "User $index",
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                              ),
                            )
                          ],
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 15),
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      // ❗ const kaldırıldı
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => StatisticsScreen(),
                        ),
                      );
                    },
                    child: Container(
                      width: double.infinity,
                      margin: const EdgeInsets.symmetric(horizontal: 20),
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.2),
                          width: 1,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                "Zincir Hedefi",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Icon(
                                Icons.arrow_forward_ios_rounded,
                                color: Colors.white,
                                size: 16,
                              )
                            ],
                          ),
                          SizedBox(height: 10),
                          Text(
                            "Bu zincirin amacı her gün düzenli kitap okumaktır. Buraya tıklayarak zincirinin detaylı istatistiklerini, kimin ne zaman zinciri kırdığını ve performans grafiklerini görebilirsin.",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              height: 1.5,
                            ),
                            maxLines: 4,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ],
      ),

      // BottomAppBar
      bottomNavigationBar: Container(
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
                        onPressed: () {
                          // ❗ const kaldırıldı
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => CreateChainScreen(),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.person, size: 30),
                        color: Colors.white.withOpacity(0.9),
                        onPressed: () {
                          // ❗ const kaldırıldı
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => JoinChainScreen(),
                            ),
                          );
                        },
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
