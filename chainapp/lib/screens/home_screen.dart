import 'dart:ui';
import 'package:chainapp/widgets/chainpart.dart';
<<<<<<< HEAD
import 'package:flutter/material.dart';
import '../models/chain_model.dart';
=======
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
>>>>>>> origin/main
import '../services/firebase_auth_service.dart';
import '../services/firestore_service.dart';

import 'login_screen.dart';
import 'create_chain_screen.dart';

// Custom Clipper sınıfı
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
<<<<<<< HEAD
  State<HomeScreen> createState() => _HomeScreenState();
}
=======
  Widget build(BuildContext context) {
    final authService = FirebaseAuthService();
    final userEmail = authService.getCurrentUserEmail();
    final userId = authService.currentUserId();
    final chainService = ChainService();
>>>>>>> origin/main

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

    _gunlukKontroluYap();
    if (userId.isNotEmpty) {
      _firestoreService.saveDeviceToken(userId);
    }
  }

  Future<void> _gunlukKontroluYap() async {
    if (userId.isNotEmpty) {
      await _firestoreService.checkChainsOnAppStart(userId);
      if (mounted) {
        setState(() {});
      }
    }
  }

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
      floatingActionButton: SizedBox(
        height: 65,
        width: 65,
        child: FloatingActionButton(
          onPressed: () {},
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
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            bottom: Radius.circular(20),
          ),
        ),
<<<<<<< HEAD
        backgroundColor: Colors.black,
=======
        backgroundColor: Colors.black.withOpacity(0.9),
>>>>>>> origin/main
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
<<<<<<< HEAD
          IconButton(
            icon: const Icon(Icons.add, color: Colors.white),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const CreateChainScreen()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            onPressed: () async {
              await _authService.logout();
=======
          // Logout
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            onPressed: () async {
              await authService.logout();
>>>>>>> origin/main
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

          // 2. Dinamik Zincir Listesi
<<<<<<< HEAD
          Positioned(
            top: 220,
            left: 0,
            right: 0,
            height: 400,
            // 📌 DÜZELTME: ChainModel listesi bekliyoruz ve FirestoreService çağırıyoruz.
            child: StreamBuilder<List<ChainModel>>(
              stream: _firestoreService.streamUserChains(userId),
=======
          // ... Stack'in içindeki diğer kodlar (Arkaplan vs.)

          // ZİNCİR LİSTESİ
          Positioned(
            top: MediaQuery.of(context).size.height /
                5, // Listenin genel yüksekliği
            left: 0,
            right: 0,
            height: 400, // Zincirlerin taşmaması için geniş alan
            child: FutureBuilder<int>(
              future: chainService.getNumberOfChains(userId ?? ""),
>>>>>>> origin/main
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                      child: CircularProgressIndicator(color: Colors.white));
                }

<<<<<<< HEAD
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
=======
                final count = snapshot.data ?? 0;

                // AYARLAR (Buradan ince ayar yapabilirsin)
                const double linkWidth = 310.0; // Senin container genişliğin
                const double shiftAmount =
                    185.0; // Her halkanın ne kadar kayacağı (Overlap ayarı)
                // widthFactor hesabı: (Kayma Miktarı / Genişlik)
>>>>>>> origin/main
                const double myWidthFactor = shiftAmount / linkWidth;

                return ListView.builder(
                  scrollDirection: Axis.horizontal,
<<<<<<< HEAD
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
=======
                  clipBehavior:
                      Clip.none, // Çok önemli: Zincirlerin kesilmemesini sağlar
                  padding: const EdgeInsets.only(
                      left: 40, right: 100), // İlk baştaki boşluk
                  itemCount: count + 2,
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
>>>>>>> origin/main
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
<<<<<<< HEAD

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
=======
          Positioned(
              top: MediaQuery.of(context).size.height / 2,
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
                          child: Container(
                            width: MediaQuery.of(context).size.width - 20,
                            padding: const EdgeInsets.all(20),
                            color: Colors.black.withOpacity(0.5),
                            child: Text(
                              "Welcome, $userEmail",
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
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
>>>>>>> origin/main
      ),
      bottomNavigationBar: SizedBox(
        height: 80,
        child: BottomAppBar(
          color: Colors.black,
          shape: const CircularNotchedRectangle(),
          notchMargin: 6.0,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              IconButton(
                icon: const Icon(Icons.home, color: Colors.white),
                onPressed: () {},
              ),
              IconButton(
                icon: const Icon(Icons.settings, color: Colors.white),
                onPressed: () {},
              ),
            ],
          ),
        ),
      ),
    );
  }
}
