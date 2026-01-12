import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/chain_model.dart';
import '../services/firestore_service.dart';

class ChainDetailScreen extends StatefulWidget {
  final ChainModel chain;
  const ChainDetailScreen({super.key, required this.chain});

  @override
  State<ChainDetailScreen> createState() => _ChainDetailScreenState();
}

class _ChainDetailScreenState extends State<ChainDetailScreen> {
  final _firestoreService = FirestoreService();
  final _currentUser = FirebaseAuth.instance.currentUser;

  // --- ÜYE ATMA İŞLEMİ ---
  Future<void> _kickMember(String memberId, String memberName) async {
    bool? confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1F3D78),
        title:
            const Text("Remove Member?", style: TextStyle(color: Colors.white)),
        content: Text(
            "Are you sure you want to remove $memberName from this chain?",
            style: const TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child:
                const Text("Cancel", style: TextStyle(color: Colors.white54)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text("Remove", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _firestoreService.removeMember(widget.chain.id, memberId);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text("$memberName removed."),
            backgroundColor: Colors.redAccent),
      );
    }
  }

  // --- TAKVİM GÖRÜNÜMÜ ---
  Widget _buildCalendarView(BuildContext context, int streakCount) {
    final now = DateTime.now();
    final daysInMonth = DateUtils.getDaysInMonth(now.year, now.month);
    final firstDayOffset = DateUtils.firstDayOffset(
        now.year, now.month, MaterialLocalizations.of(context));

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white10)),
      child: Column(
        children: [
          Text("${DateFormat('MMMM yyyy').format(now)}",
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: ["M", "T", "W", "T", "F", "S", "S"]
                .map((d) => Text(d,
                    style: const TextStyle(
                        color: Color(0xFFA68FFF), fontWeight: FontWeight.bold)))
                .toList(),
          ),
          const SizedBox(height: 10),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 7, childAspectRatio: 1),
            itemCount: daysInMonth + firstDayOffset - 1,
            itemBuilder: (context, index) {
              if (index < firstDayOffset - 1) return const SizedBox();
              final day = index - (firstDayOffset - 1) + 1;
              bool isDone = (day <= now.day && (now.day - day) < streakCount);
              return Container(
                margin: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                    color: isDone
                        ? const Color(0xFFA68FFF).withOpacity(0.3)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                        color:
                            isDone ? const Color(0xFFA68FFF) : Colors.white10)),
                child: Center(
                    child: Text("$day",
                        style: TextStyle(
                            color: isDone ? Colors.white : Colors.white38))),
              );
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Bu ekranı canlı (Stream) yapıyoruz ki birini atınca liste hemen güncellensin
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('chains')
          .doc(widget.chain.id)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData)
          return const Scaffold(
              backgroundColor: Color(0xFF0A0E25),
              body: Center(child: CircularProgressIndicator()));

        // Güncel Zincir Verisi
        final chainData = snapshot.data!.data() as Map<String, dynamic>;
        final currentChain = ChainModel.fromMap(snapshot.data!.id, chainData);

        // Yönetici miyim?
        final bool isCreator = _currentUser?.uid == currentChain.creatorId;

        return SafeArea(
          child: Scaffold(
            backgroundColor: const Color(0xFF0A0E25),
            appBar: AppBar(
              title: Text(currentChain.name,
                  style: const TextStyle(
                      color: Colors.white, fontWeight: FontWeight.bold)),
              centerTitle: true,
              backgroundColor: Colors.transparent,
              iconTheme: const IconThemeData(color: Colors.white),
            ),
            body: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // İSTATİSTİKLER
                  Row(
                    children: [
                      Expanded(
                          child: _buildStatCard("Current Streak",
                              "${currentChain.streakCount} 🔥", Colors.orange)),
                      const SizedBox(width: 15),
                      Expanded(
                          child: _buildStatCard("Total Members",
                              "${currentChain.members.length} 👥", Colors.blue)),
                    ],
                  ),
                  const SizedBox(height: 30),
          
                  // DESCRIPTION
                  const Text("Purpose & Description",
                      style: TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                          fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text(
                      currentChain.purpose.isNotEmpty
                          ? currentChain.purpose
                          : "Goal: ${currentChain.name}",
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text(currentChain.description,
                      style: const TextStyle(
                          color: Colors.white70, fontSize: 15, height: 1.5)),
          
                  const SizedBox(height: 30),
          
                  // DAVET KODU (Herkes Görebilir)
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(colors: [
                        const Color(0xFFA68FFF).withOpacity(0.2),
                        const Color(0xFFA68FFF).withOpacity(0.05)
                      ]),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                          color: const Color(0xFFA68FFF).withOpacity(0.3)),
                    ),
                    child: Column(
                      children: [
                        const Text("Invite Code",
                            style: TextStyle(color: Colors.white70)),
                        const SizedBox(height: 10),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(currentChain.inviteCode ?? "----",
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 32,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 4)),
                            const SizedBox(width: 15),
                            IconButton(
                              icon: const Icon(Icons.copy,
                                  color: Color(0xFFA68FFF)),
                              onPressed: () {
                                Clipboard.setData(ClipboardData(
                                    text: currentChain.inviteCode ?? ""));
                                ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                        content:
                                            Text("Code copied to clipboard!")));
                              },
                            )
                          ],
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFA68FFF),
                                padding:
                                    const EdgeInsets.symmetric(vertical: 12)),
                            onPressed: () {
                              try {
                                Share.share(
                                    'Join my "${currentChain.name}" chain on ChainApp! 🚀\nUse code: ${currentChain.inviteCode}');
                              } catch (e) {
                                print("Share error: $e");
                              }
                            },
                            icon: const Icon(Icons.share, color: Colors.white),
                            label: const Text("Share Code",
                                style: TextStyle(color: Colors.white)),
                          ),
                        )
                      ],
                    ),
                  ),
          
                  const SizedBox(height: 30),
          
                  // TAKVİM
                  _buildCalendarView(context, currentChain.streakCount),
          
                  const SizedBox(height: 30),
          
                  // 🔥 YENİ: ÜYE LİSTESİ (Sadece Admin Silebilir)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text("Members List",
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold)),
                      if (isCreator)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                              color: Colors.amber.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(10)),
                          child: const Text("Admin Mode 👑",
                              style: TextStyle(
                                  color: Colors.amber,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold)),
                        )
                    ],
                  ),
                  const SizedBox(height: 10),
          
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: currentChain.members.length,
                    itemBuilder: (context, index) {
                      final memberId = currentChain.members[index];
                      return FutureBuilder<DocumentSnapshot>(
                        future: FirebaseFirestore.instance
                            .collection('users')
                            .doc(memberId)
                            .get(),
                        builder: (context, userSnap) {
                          if (!userSnap.hasData) return const SizedBox();
                          final userData =
                              userSnap.data!.data() as Map<String, dynamic>?;
                          final name = userData?['name'] ?? 'User';
                          final avatarSeed = userData?['avatarSeed'] ?? 'user';
          
                          // Yöneticinin kendisi mi?
                          final bool isSelf = memberId == _currentUser?.uid;
                          // Bu kişi Yönetici mi? (Tac ikonu koymak için)
                          final bool isThisMemberAdmin =
                              memberId == currentChain.creatorId;
          
                          return Container(
                            margin: const EdgeInsets.only(bottom: 10),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.05),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                    color: Colors.white.withOpacity(0.1))),
                            child: Row(
                              children: [
                                CircleAvatar(
                                  radius: 20,
                                  backgroundColor: Colors.black26,
                                  backgroundImage: NetworkImage(
                                      "https://api.dicebear.com/9.x/adventurer/png?seed=$avatarSeed&backgroundColor=b6e3f4"),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Text(name,
                                              style: TextStyle(
                                                  color: isSelf
                                                      ? const Color(0xFFA68FFF)
                                                      : Colors.white,
                                                  fontWeight: FontWeight.bold)),
                                          if (isThisMemberAdmin)
                                            const Padding(
                                                padding: EdgeInsets.only(left: 6),
                                                child: Icon(Icons.star,
                                                    color: Colors.amber,
                                                    size: 16)),
                                        ],
                                      ),
                                      Text(isSelf ? "You" : "Member",
                                          style: TextStyle(
                                              color:
                                                  Colors.white.withOpacity(0.5),
                                              fontSize: 12)),
                                    ],
                                  ),
                                ),
          
                                // 🔥 SİLME BUTONU: Sadece YÖNETİCİ görsün ve KENDİNİ SİLEMESİN
                                if (isCreator && !isSelf)
                                  IconButton(
                                    icon: const Icon(Icons.delete_outline,
                                        color: Colors.redAccent),
                                    onPressed: () => _kickMember(memberId, name),
                                  )
                              ],
                            ),
                          );
                        },
                      );
                    },
                  ),
          
                  const SizedBox(height: 50),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatCard(String title, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white10)),
      child: Column(
        children: [
          Text(value,
              style: TextStyle(
                  color: color, fontSize: 22, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(title,
              style: const TextStyle(color: Colors.white54, fontSize: 12)),
        ],
      ),
    );
  }
}
