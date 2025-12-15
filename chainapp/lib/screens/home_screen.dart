import 'dart:ui';
import 'package:chainapp/screens/detailedstatisticsforchains.dart';
import 'package:chainapp/screens/invite_code_screen.dart';
import 'package:chainapp/screens/join_chain_screen.dart';
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
    // final userEmail = authService.getCurrentUserEmail(); // Kullanılmıyorsa uyarı vermemesi için kapattım
    final userId = authService.currentUserId();
    final chainService = ChainService();

    // Ekran boyutlarını alalım
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      floatingActionButton: SizedBox(
        height: 65,
        width: 65,
        child: FloatingActionButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => InviteCodeScreen(
                  chainId: 'exampleChainId',
                  inviteCode: 'ABC123',
                ),
              ),
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
        leading: IconButton(
          icon: const Icon(Icons.menu, color: Colors.white),
          onPressed: ()  {}
          
        ),
        automaticallyImplyLeading: false,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            bottom: Radius.circular(20),
          ),
        ),
        backgroundColor: Colors.black.withOpacity(0.9),
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

          // Zincir Başlığı
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
                  fontWeight: FontWeight.bold),
            ),
          ),

          // 2. ZİNCİR LİSTESİ (Chain Visualization)
          // Burası senin mevcut kodun, dokunmadım.
          Positioned(
            top: screenHeight / 5,
            left: -120,
            right: 0,
            height: 400,
            child: FutureBuilder<int>(
              future: chainService.getNumberOfChains(userId ?? ""),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                      child: CircularProgressIndicator(color: Colors.white));
                }
                final count = snapshot.data ?? 0;
                const double linkWidth = 310.0;
                const double shiftAmount = 200.0;
                const double myWidthFactor = shiftAmount / linkWidth;

                return ListView.builder(
                  cacheExtent: 1000,
                  scrollDirection: Axis.horizontal,
                  clipBehavior: Clip.none,
                  padding: const EdgeInsets.only(left: 40, right: 100),
                  itemCount: count + 10,
                  itemBuilder: (context, index) {
                    final bool isEven = index % 2 == 0;
                    final double currentAngle = isEven ? -0.3 : 0.1;
                    final double currentTop = isEven ? 80.0 : 0.0;
                    final double prevAngle = isEven ? 0.1 : -0.3;
                    final double prevTop = isEven ? 0.0 : 80.0;
                    final double topDiff = prevTop - currentTop;

                    return Align(
                      alignment: Alignment.topLeft,
                      widthFactor: myWidthFactor,
                      child: Transform.translate(
                        offset: Offset(0, currentTop),
                        child: Stack(
                          clipBehavior: Clip.none,
                          children: [
                            chainpart(rotationAngle: currentAngle),
                            if (index > 0)
                              Positioned(
                                left: -(shiftAmount),
                                top: topDiff,
                                child: ClipRect(
                                  clipper: AreaClipper(
                                      const Rect.fromLTWH(190, 0, 120, 120)),
                                  child: chainpart(rotationAngle: prevAngle),
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

          // 3. YENİ KISIM: Arkadaşlar (Story) ve Açıklama (Description)
          // Zincirin bittiği yerden itibaren başlasın diye top değerini ayarladık.
          Positioned(
            top: (screenHeight / 5) +
                300, // Zincirin altına denk gelecek şekilde ayarladım
            bottom: 90, // BottomNavigationBar için alttan boşluk
            left: 0,
            right: 0,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // --- INSTAGRAM STORY TARZI ARKADAŞ LİSTESİ ---
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
                  height: MediaQuery.of(context).size.height /
                      9, // Story alanı yüksekliği
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: 10, // Örnek sayı
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    itemBuilder: (context, index) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8.0),
                        child: Column(
                          children: [
                            // Çerçeve (Story Halkası)
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
                                padding: const EdgeInsets.all(
                                    4), // Çerçeve kalınlığı
                                child: Container(
                                  decoration: const BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Colors
                                        .white, // Resim gelene kadar beyaz
                                  ),
                                  // İleride buraya Image.network koyacaksın
                                  child: const Icon(Icons.person,
                                      color: Colors.grey),
                                ),
                              ),
                            ),
                            const SizedBox(height: 4),
                            // İsim (Kısa)
                            Text(
                              "User $index",
                              style: const TextStyle(
                                  color: Colors.white, fontSize: 18),
                            )
                          ],
                        ),
                      );
                    },
                  ),
                ),

                const SizedBox(height: 15),

                // --- DESCRIPTION BOX (Açıklama Kutusu) ---
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      // İstatistik sayfasına git
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const StatisticsScreen(),
                        ),
                      );
                    },
                    child: Container(
                      width: double.infinity,
                      margin: const EdgeInsets.symmetric(horizontal: 20),
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white
                            .withOpacity(0.1), // Glassmorphism etkisi
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
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                "Zincir Hedefi",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Icon(
                                Icons.arrow_forward_ios_rounded,
                                color: Colors.white.withOpacity(0.7),
                                size: 16,
                              )
                            ],
                          ),
                          const SizedBox(height: 10),
                          Text(
                            "Bu zincirin amacı her gün düzenli kitap okumaktır. Buraya tıklayarak zincirinin detaylı istatistiklerini, kimin ne zaman zinciri kırdığını ve performans grafiklerini görebilirsin.",
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.8),
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
                // Alt tarafta biraz boşluk bırakalım ki en alta yapışmasın
                const SizedBox(height: 20),
              ],
            ),
          ),
        ],
      ),
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
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const CreateChainScreen(),
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
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const JoinChainScreen(),
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
