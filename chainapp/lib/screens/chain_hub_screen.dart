import 'package:chainapp/screens/login_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // 🔥 EKLENDİ
import '../services/chain_service.dart';
import '../services/firebase_auth_service.dart';
import '../services/firestore_service.dart'; // 🔥 EKLENDİ
import 'create_chain_screen.dart';
import 'join_chain_screen.dart';
import 'home_screen.dart';

// 🔥 ARTIK STATEFUL WIDGET (Başlangıçta kontrol yapmak için)
class ChainHubScreen extends StatefulWidget {
  const ChainHubScreen({super.key});

  @override
  State<ChainHubScreen> createState() => _ChainHubScreenState();
}


class _ChainHubScreenState extends State<ChainHubScreen> {
  final chainService = ChainService();
  final authService = FirebaseAuthService();
  late String? userId;

  @override
  void initState() {
    super.initState();
    userId = authService.currentUserId();

    //  UYGULAMA AÇILINCA ZİNCİR KONTROLÜ YAP (XP CEZA SİSTEMİ)
    if (userId != null) {
      FirestoreService().checkChainsOnAppStart(userId!);
    }
  }

    Future<void> _logout(BuildContext context) async {
    await FirebaseAuth.instance.signOut();
    if (!context.mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  // 🔥 ROZET TASARIMI WIDGET'I (Sadece görsellik için yardımcı fonksiyon)
  Widget _buildBadgeList(List<dynamic> badges) {
    if (badges.isEmpty) return const SizedBox();
    return Wrap(
      spacing: 8.0,
      runSpacing: 8.0,
      alignment: WrapAlignment.center,
      children: badges.map((badge) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            gradient:
                const LinearGradient(colors: [Colors.blueAccent, Colors.cyan]),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(color: Colors.blue.withOpacity(0.5), blurRadius: 5)
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.auto_awesome, color: Colors.white, size: 14),
              const SizedBox(width: 4),
              Text(
                badge.toString(),
                style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 12),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.logout, color: Colors.white),
          onPressed: () => _logout(context),
        ),
        automaticallyImplyLeading: false,
        title: const Text(
          "Your Chains",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          //  BACKGROUND
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
            child: Column(
              children: [
                const SizedBox(height: 20),

                // 🔥 EKLEDİĞİMİZ ROZET BÖLÜMÜ (Firestore'dan anlık çeker)
                if (userId != null)
                  StreamBuilder<DocumentSnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('users')
                        .doc(userId)
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) return const SizedBox();

                      var userData =
                          snapshot.data!.data() as Map<String, dynamic>?;
                      List<dynamic> badges = userData?['badges'] ?? [];

                      if (badges.isEmpty) return const SizedBox();

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 20),
                        child: Column(
                          children: [
                            Text(
                              "Achievements",
                              style: TextStyle(
                                  color: Colors.white.withOpacity(0.6),
                                  fontSize: 12,
                                  letterSpacing: 1.2,
                                  fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 10),
                            _buildBadgeList(badges),
                          ],
                        ),
                      );
                    },
                  ),

                //  MY CHAINS (VERTICAL LIST)
                // ===============================
                Expanded(
                  child: userId == null
                      ? const Center(
                          child: Text("User not logged in",
                              style: TextStyle(color: Colors.white)))
                      : StreamBuilder<List<Map<String, dynamic>>>(
                          stream: chainService.getUserChains(userId!),
                          builder: (context, snapshot) {
                            if (snapshot.connectionState ==
                                ConnectionState.waiting) {
                              return const Center(
                                  child: CircularProgressIndicator(
                                      color: Color(0xFFA68FFF)));
                            }

                            final chains = snapshot.data ?? [];

                            // ❗ BOŞ DURUM
                            if (chains.isEmpty) {
                              return Center(
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 32),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.link_off,
                                          size: 60,
                                          color: Colors.white.withOpacity(0.3)),
                                      const SizedBox(height: 20),
                                      Text(
                                        "You haven’t joined any chains yet.\nCreate one or join with an invite code.",
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                            color:
                                                Colors.white.withOpacity(0.7),
                                            fontSize: 14),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            }

                            // ✅ ZİNCİR LİSTESİ
                            return ListView.builder(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 20, vertical: 10),
                              itemCount: chains.length,
                              itemBuilder: (context, index) {
                                final chain = chains[index];

                                // 🔥 GÜVENLİ VERİ ÇEKME
                                final String chainId =
                                    chain['id']?.toString() ?? '';
                                final String chainName =
                                    chain['name']?.toString() ??
                                        'Unnamed Chain';
                                final String period =
                                    chain['period']?.toString() ?? 'daily';

                                // Zincir durumu (Kırık mı?)
                                final String status =
                                    chain['status']?.toString() ?? 'active';
                                final bool isBroken = status == 'broken';

                                if (chainId.isEmpty) return const SizedBox();

                                return GestureDetector(
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => HomeScreen(
                                          chainId: chainId,
                                          chainName: chainName,
                                        ),
                                      ),
                                    );
                                  },
                                  child: Container(
                                    margin: const EdgeInsets.only(bottom: 14),
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      // Kırık zincirleri kırmızımsı, normal zincirleri şeffaf yap
                                      color: isBroken
                                          ? Colors.red.withOpacity(0.1)
                                          : Colors.white.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(
                                          color: isBroken
                                              ? Colors.redAccent
                                                  .withOpacity(0.3)
                                              : Colors.white.withOpacity(0.15)),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.1),
                                          blurRadius: 10,
                                          offset: const Offset(0, 4),
                                        )
                                      ],
                                    ),
                                    child: Row(
                                      children: [
                                        // İkon
                                        Container(
                                          padding: const EdgeInsets.all(12),
                                          decoration: BoxDecoration(
                                            color: isBroken
                                                ? Colors.redAccent
                                                    .withOpacity(0.2)
                                                : const Color(0xFFA68FFF)
                                                    .withOpacity(0.2),
                                            shape: BoxShape.circle,
                                          ),
                                          child: Icon(
                                              isBroken
                                                  ? Icons.broken_image
                                                  : Icons.link,
                                              color: isBroken
                                                  ? Colors.redAccent
                                                  : const Color(0xFFA68FFF)),
                                        ),
                                        const SizedBox(width: 16),

                                        // Yazılar
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                chainName,
                                                style: TextStyle(
                                                    color: isBroken
                                                        ? Colors.red[200]
                                                        : Colors.white,
                                                    fontSize: 18,
                                                    decoration: isBroken
                                                        ? TextDecoration
                                                            .lineThrough
                                                        : null,
                                                    fontWeight:
                                                        FontWeight.bold),
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                isBroken
                                                    ? "CHAIN BROKEN!"
                                                    : period.toUpperCase(),
                                                style: TextStyle(
                                                    color: isBroken
                                                        ? Colors.redAccent
                                                        : Colors.white
                                                            .withOpacity(0.6),
                                                    fontSize: 12,
                                                    fontWeight: isBroken
                                                        ? FontWeight.bold
                                                        : FontWeight.normal,
                                                    letterSpacing: 1),
                                              ),
                                            ],
                                          ),
                                        ),
                                        Icon(Icons.arrow_forward_ios,
                                            color: isBroken
                                                ? Colors.redAccent
                                                    .withOpacity(0.5)
                                                : Colors.white38,
                                            size: 16),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            );
                          },
                        ),
                ),

                // ➕ BUTONLAR
                // ===============================
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 30),
                  child: Row(
                    children: [
                      // CREATE CHAIN
                      Expanded(
                        child: GestureDetector(
                          onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => const CreateChainScreen())),
                          child: Container(
                            height: 56,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(16),
                              color: const Color(0xFFA68FFF),
                              boxShadow: [
                                BoxShadow(
                                    color: const Color(0xFFA68FFF)
                                        .withOpacity(0.4),
                                    blurRadius: 12,
                                    offset: const Offset(0, 4))
                              ],
                            ),
                            child: const Center(
                              child: Text("Create Chain",
                                  style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold)),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      // JOIN CHAIN
                      Expanded(
                        child: GestureDetector(
                          onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => const JoinChainScreen())),
                          child: Container(
                            height: 56,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(16),
                              color: Colors.white.withOpacity(0.05),
                              border: Border.all(
                                  color: Colors.white.withOpacity(0.3)),
                            ),
                            child: const Center(
                              child: Text("Join Chain",
                                  style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold)),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
