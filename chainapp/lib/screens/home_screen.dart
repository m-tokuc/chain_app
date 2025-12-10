import 'dart:ui';
import 'package:chainapp/screens/invite_code_screen.dart';
import 'package:chainapp/screens/join_chain_screen.dart';
import 'package:chainapp/widgets/chainpart.dart';
import 'package:chainapp/widgets/homepagefriendbox.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
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
    final userId = authService.currentUserId();
    final chainService = ChainService();

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

      // Butonun yerleşimi: Ortada ve Bar'a gömülü
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
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

          // zincir adi
          Positioned(
            top: MediaQuery.of(context).size.height / 8,
            left: 0,
            right: 0,
            child: Text(
              textAlign: TextAlign.center,
              "Your Chain",
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.bold),
            ),
          ),

          // 2. Dinamik Zincir Listesi
          // ... Stack'in içindeki diğer kodlar (Arkaplan vs.)

          // ZİNCİR LİSTESİ
          Positioned(
            top: MediaQuery.of(context).size.height / 5,
            left: -50,
            right: 0,
            height: 400, // Zincirlerin taşmaması için geniş alan
            child: FutureBuilder<int>(
              future: chainService.getNumberOfChains(userId ?? ""),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                      child: CircularProgressIndicator(color: Colors.white));
                }

                final count = snapshot.data ?? 0;

                // AYARLAR (Buradan ince ayar yapabilirsin)
                const double linkWidth = 310.0; // Senin container genişliğin
                const double shiftAmount =
                    185.0; // Her halkanın ne kadar kayacağı (Overlap ayarı)
                // widthFactor hesabı: (Kayma Miktarı / Genişlik)
                const double myWidthFactor = shiftAmount / linkWidth;

                return ListView.builder(
                  scrollDirection: Axis.horizontal,
                  clipBehavior:
                      Clip.none, // Çok önemli: Zincirlerin kesilmemesini sağlar
                  padding: const EdgeInsets.only(
                      left: 40, right: 100), // İlk baştaki boşluk
                  itemCount: count + 1,
                  itemBuilder: (context, index) {
                    // Çiftler (0, 2, 4): Aşağıda, Sola Yatık (-0.3)
                    // Tekler (1, 3, 5): Yukarıda, Sağa Yatık (0.1)
                    final bool isEven = index % 2 == 0;

                    // Şu anki halkanın özellikleri
                    final double currentAngle = isEven ? -0.3 : 0.1;
                    final double currentTop = isEven ? 80.0 : 0.0;

                    // Bir önceki halkanın özellikleri (Yama yapmak için lazım)
                    final double prevAngle = isEven ? 0.1 : -0.3; // Tam tersi
                    final double prevTop = isEven ? 0.0 : 80.0; // Tam tersi

                    // İki halka arasındaki yükseklik farkı
                    // Eğer ben aşağıdaysam (80), önceki yukarıdadır (0). Fark: -80
                    final double topDiff = prevTop - currentTop;

                    return Align(
                      alignment: Alignment.topLeft,
                      widthFactor: myWidthFactor, // Elemanları iç içe geçirir
                      child: Transform.translate(
                        offset: Offset(
                            0, currentTop), // Aşağı/Yukarı zig-zag hareketi
                        child: Stack(
                          clipBehavior: Clip.none, // Taşmalara izin ver
                          children: [
                            // ------------------------------------------
                            // 1. KATMAN: ASIL ZİNCİR (Current Link)
                            // ------------------------------------------
                            chainpart(rotationAngle: currentAngle),

                            // ------------------------------------------
                            // 2. KATMAN: YAMA (Previous Link Patch)
                            // ------------------------------------------
                            // Sadece ilk eleman (index 0) hariç hepsine yama lazım
                            if (index > 0)
                              Positioned(
                                // Bir önceki halkayı, şu anki halkanın koordinatına göre
                                // tam olarak olması gereken yere (geriye) koyuyoruz.
                                left: -shiftAmount,
                                top: topDiff,
                                child: ClipRect(
                                  // SİHİRLİ KISIM: Burası "kesişim" noktasıdır.
                                  // Bir önceki halkanın SAĞ tarafını kesip alıyoruz.
                                  // Bu değerleri senin resmine göre hassas ayarladım.
                                  clipper: AreaClipper(
                                      // x: 200 -> Halkanın sağ tarafına odaklan
                                      // width: 110 -> Yeterince geniş bir alan al
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
          Positioned(
              top: MediaQuery.of(context).size.height / 2.5,
              bottom: 0,
              left: 0,
              right: 0,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Expanded(
                    child: ListView.builder(
                      itemCount: 10,
                      itemBuilder: (BuildContext context, int index) {
                        return Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: friendbox(),
                        );
                      },
                    ),
                  ),
                ],
              ))
        ],
      ),
      bottomNavigationBar: Container(
        // Barın üst köşelerini hafif yuvarlatarak daha yumuşak bir hava katalım
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 10,
              offset: const Offset(0, -5), // Yukarı doğru hafif gölge
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
                // SOL TARAFTAKİ İKONLAR
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

                // SAĞ TARAFTAKİ İKONLAR
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
