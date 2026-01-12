import 'dart:ui'; // Glassmorphism için
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_model.dart';
import '../services/firestore_service.dart';
import 'edit_profile_screen.dart';
import 'login_screen.dart';
import 'chain_hub_screen.dart'; // Listeye dönüş için
import 'settings_screen.dart'; // Ayarlar ekranı için

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  Future<void> _logout(BuildContext context) async {
    await FirebaseAuth.instance.signOut();
    if (!context.mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  // --- ALT BAR (NAVIGATION) ---
  Widget _buildBottomBar(BuildContext context) {
    return Container(
      height: 80,
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A),
        border: Border(top: BorderSide(color: Colors.white.withOpacity(0.1))),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // 1. HOME: Listeye (Hub) Götürür
          IconButton(
            onPressed: () => Navigator.pushReplacement(context,
                MaterialPageRoute(builder: (_) => const ChainHubScreen())),
            icon:
                const Icon(Icons.home_filled, color: Colors.white70, size: 32),
          ),

          // 2. TIMER: Profilde pasif
          Container(
            width: 55,
            height: 55,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05), // Sönük
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.timer, color: Colors.white24, size: 28),
          ),

          // 3. PROFILE: Aktif Sayfa
          IconButton(
            onPressed: () {}, // Zaten buradayız
            icon: const Icon(Icons.person, color: Color(0xFFA68FFF), size: 32),
          ),
        ],
      ),
    );
  }

  // --- CAM KONTEYNER YARDIMCISI ---
  Widget _buildGlassContainer(
      {required Widget child, EdgeInsetsGeometry? padding}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white.withOpacity(0.08)),
          ),
          child: child,
        ),
      ),
    );
  }

  Widget _buildGlassStatCard(String title, String value) {
    return _buildGlassContainer(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Text(value,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
          Text(title,
              style: TextStyle(
                  color: Colors.white.withOpacity(0.6), fontSize: 14)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return const Scaffold(body: Center(child: Text("Error")));

    return SafeArea(
      child: Scaffold(
        backgroundColor: const Color(0xFF0F172A),
        extendBodyBehindAppBar: true,

        // 🔥 ALT BAR EKLENDİ
        bottomNavigationBar: _buildBottomBar(context),

        appBar: AppBar(
          title: const Text("Profile",
              style:
                  TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          backgroundColor: Colors.transparent,
          elevation: 0,
          centerTitle: true,
          // 🔥 SOL ÜST: AYARLAR İKONU
          leading: IconButton(
            icon: const Icon(Icons.settings, color: Colors.white70),
            onPressed: () {
              Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const SettingsScreen()));
            },
          ),
          // SAĞ ÜST: ÇIKIŞ YAP
          actions: [
            IconButton(
              icon: const Icon(Icons.logout, color: Colors.redAccent),
              onPressed: () => _logout(context),
            ),
          ],
        ),
        body: Stack(
          fit: StackFit.expand,
          children: [
            // 1. GRADYAN ARKA PLAN
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFF0A0E25), // Uyumlu olması için güncelledim
                    Color(0xFF1E1B4B),
                    Color(0xFF312E81)
                  ],
                ),
              ),
            ),

            // 2. İÇERİK
            SafeArea(
              child: StreamBuilder<DocumentSnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('users')
                    .doc(uid)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return const Center(
                        child: Text("Something went wrong",
                            style: TextStyle(color: Colors.white)));
                  }
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                        child: CircularProgressIndicator(
                            color: Color(0xFFA68FFF)));
                  }

                  if (!snapshot.hasData || !snapshot.data!.exists) {
                    return Center(
                      child: _buildGlassContainer(
                        padding: const EdgeInsets.all(30),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.error_outline,
                                color: Color(0xFFA68FFF), size: 50),
                            const SizedBox(height: 16),
                            const Text("Profile not found!",
                                style: TextStyle(
                                    color: Colors.white, fontSize: 18)),
                            const SizedBox(height: 24),
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFFA68FFF),
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16))),
                              onPressed: () async {
                                final currentUser =
                                    FirebaseAuth.instance.currentUser;
                                if (currentUser != null) {
                                  final newUser = UserModel(
                                      uid: currentUser.uid,
                                      email: currentUser.email ?? "",
                                      name: "New Chain User");
                                  await FirestoreService().createUser(newUser);
                                }
                              },
                              child: const Text("Create Profile",
                                  style: TextStyle(color: Colors.white)),
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  UserModel user = UserModel.fromFirestore(snapshot.data!);
                  int currentLevel = user.level;
                  int xpForNext = user.xpRequiredForNextLevel;
                  int xpStart = user.xpStartCurrentLevel;
                  double progress = (user.xp - xpStart) / (xpForNext - xpStart);
                  if (progress.isNaN || progress.isInfinite) progress = 0;

                  return SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      children: [
                        // AVATAR
                        Stack(
                          alignment: Alignment.bottomRight,
                          children: [
                            Container(
                              width: 150,
                              height: 150,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                    color: const Color(0xFFA68FFF)
                                        .withOpacity(0.5),
                                    width: 4),
                                boxShadow: [
                                  BoxShadow(
                                      color: const Color(0xFFA68FFF)
                                          .withOpacity(0.3),
                                      blurRadius: 20)
                                ],
                                image: DecorationImage(
                                  image: NetworkImage(
                                      "https://api.dicebear.com/9.x/adventurer/png?seed=${user.avatarSeed}&backgroundColor=b6e3f4"),
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                            FloatingActionButton.small(
                              onPressed: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (_) =>
                                          EditProfileScreen(user: user))),
                              backgroundColor: const Color(0xFFA68FFF),
                              child:
                                  const Icon(Icons.edit, color: Colors.white),
                            ),
                          ],
                        ),

                        const SizedBox(height: 16),
                        Text(user.name,
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 28,
                                fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),

                        // ROZET
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: const Color(0xFFA68FFF).withOpacity(0.2),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                                color:
                                    const Color(0xFFA68FFF).withOpacity(0.5)),
                          ),
                          child: Text(user.badge,
                              style: const TextStyle(
                                  color: Color(0xFFA68FFF),
                                  fontWeight: FontWeight.w600,
                                  fontSize: 16)),
                        ),

                        const SizedBox(height: 40),

                        // LEVEL PROGRESS
                        _buildGlassContainer(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text("Level $currentLevel",
                                      style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold)),
                                  Text("${user.xp} / $xpForNext XP",
                                      style: TextStyle(
                                          color:
                                              Colors.white.withOpacity(0.6))),
                                ],
                              ),
                              const SizedBox(height: 16),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(10),
                                child: LinearProgressIndicator(
                                  value: progress,
                                  backgroundColor:
                                      Colors.white.withOpacity(0.1),
                                  color: const Color(0xFFA68FFF),
                                  minHeight: 12,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text("${xpForNext - user.xp} XP to next level",
                                  style: TextStyle(
                                      color: Colors.white.withOpacity(0.4),
                                      fontSize: 12)),
                            ],
                          ),
                        ),

                        const SizedBox(height: 24),

                        // ISTATISTIKLER (GÜNCELLENMİŞ KISIM)
                        Row(
                          children: [
                            // Total XP
                            Expanded(
                                child: _buildGlassStatCard(
                                    "Total XP", "${user.xp} ✨")),
                            const SizedBox(width: 15),

                            // Chain Rank - ARTIK CANLI VERİ
                            Expanded(
                              child: FutureBuilder<int>(
                                future: FirestoreService().getUserRank(user.xp),
                                builder: (context, rankSnapshot) {
                                  String rankText = "...";
                                  if (rankSnapshot.hasData) {
                                    rankText = "#${rankSnapshot.data} 🏆";
                                  }
                                  return _buildGlassStatCard(
                                      "Chain Rank", rankText);
                                },
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 30),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
