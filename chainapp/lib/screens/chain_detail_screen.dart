import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/chain_model.dart';
import '../services/firestore_service.dart';
import 'chain_hub_screen.dart';

class ChainDetailScreen extends StatefulWidget {
  final ChainModel chain;
  const ChainDetailScreen({super.key, required this.chain});

  @override
  State<ChainDetailScreen> createState() => _ChainDetailScreenState();
}

class _ChainDetailScreenState extends State<ChainDetailScreen> {
  final _firestoreService = FirestoreService();
  final _currentUser = FirebaseAuth.instance.currentUser;

  // --- 🔥 DELETE CHAIN LOGIC ---
  Future<void> _deleteChain() async {
    bool? confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: AlertDialog(
          backgroundColor: const Color(0xFF0A0E25).withOpacity(0.9),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
              side: BorderSide(color: Colors.redAccent.withOpacity(0.2))),
          title: const Text("Delete Chain?",
              style:
                  TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          content: const Text(
            "Are you sure? This chain will be permanently deleted for everyone.",
            style: TextStyle(color: Colors.white70),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child:
                  const Text("Cancel", style: TextStyle(color: Colors.white54)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFCF6679), // Muted pale red
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text("Delete",
                  style: TextStyle(
                      color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );

    if (confirm == true) {
      try {
        await FirebaseFirestore.instance
            .collection('chains')
            .doc(widget.chain.id)
            .delete();
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text("Chain deleted."),
              backgroundColor: Color(0xFFCF6679)),
        );
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const ChainHubScreen()),
          (route) => false,
        );
      } catch (e) {
        print("Error: $e");
      }
    }
  }

  // --- KICK MEMBER LOGIC ---
  Future<void> _kickMember(String memberId, String memberName) async {
    bool? confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1F3D78),
        title:
            const Text("Remove Member?", style: TextStyle(color: Colors.white)),
        content: Text("Remove $memberName?",
            style: const TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text("Cancel")),
          ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text("Remove")),
        ],
      ),
    );

    if (confirm == true) {
      await _firestoreService.removeMember(widget.chain.id, memberId);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text("$memberName removed."),
          backgroundColor: Colors.redAccent));
    }
  }

  // --- 🟢 SYNCED CALENDAR UI ---
  Widget _buildCalendarView(BuildContext context, int streakCount) {
    final now = DateTime.now();
    final daysInMonth = DateUtils.getDaysInMonth(now.year, now.month);
    final firstDayOffset = DateUtils.firstDayOffset(
        now.year, now.month, MaterialLocalizations.of(context));

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.white.withOpacity(0.08))),
      child: Column(
        children: [
          Text(DateFormat('MMMM yyyy').format(now),
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
                      ? Colors.green.withOpacity(0.4)
                      : Colors.transparent, // 🔥 Yeşil Takvim
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                      color: isDone
                          ? Colors.greenAccent.withOpacity(0.5)
                          : Colors.white10),
                ),
                child: Center(
                  child: Text("$day",
                      style: TextStyle(
                          color: isDone ? Colors.white : Colors.white38,
                          fontWeight:
                              isDone ? FontWeight.bold : FontWeight.normal)),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.white.withOpacity(0.08))),
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

  @override
  Widget build(BuildContext context) {
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
        if (!snapshot.data!.exists)
          return const Scaffold(
              backgroundColor: Color(0xFF0A0E25),
              body: Center(
                  child: Text("Chain not found",
                      style: TextStyle(color: Colors.white))));

        final chainData = snapshot.data!.data() as Map<String, dynamic>;
        final currentChain = ChainModel.fromMap(snapshot.data!.id, chainData);
        final bool isCreator = (_currentUser?.uid == currentChain.creatorId);

        return SafeArea(
          child: Scaffold(
            backgroundColor: const Color(0xFF0A0E25),
            appBar: AppBar(
              title: Text(currentChain.name,
                  style: const TextStyle(
                      color: Colors.white, fontWeight: FontWeight.bold)),
              centerTitle: true,
              backgroundColor: Colors.transparent,
              elevation: 0,
              iconTheme: const IconThemeData(color: Colors.white),
            ),
            body: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                          child: _buildStatCard("Streak",
                              "${currentChain.streakCount} 🔥", Colors.orange)),
                      const SizedBox(width: 15),
                      Expanded(
                          child: _buildStatCard(
                              "Members",
                              "${currentChain.members.length} 👥",
                              Colors.blue)),
                    ],
                  ),
                  const SizedBox(height: 32),
                  const Text("Goal & Description",
                      style: TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                          fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  Text(
                      currentChain.purpose.isNotEmpty
                          ? currentChain.purpose
                          : "Goal: ${currentChain.name}",
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text(currentChain.description,
                      style: const TextStyle(
                          color: Colors.white60, fontSize: 15, height: 1.5)),
                  const SizedBox(height: 32),

                  // INVITE CODE BOX
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                        gradient: LinearGradient(colors: [
                          const Color(0xFFA68FFF).withOpacity(0.15),
                          const Color(0xFFA68FFF).withOpacity(0.05)
                        ]),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                            color: const Color(0xFFA68FFF).withOpacity(0.2))),
                    child: Column(
                      children: [
                        const Text("Invite Code",
                            style:
                                TextStyle(color: Colors.white54, fontSize: 13)),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(currentChain.inviteCode ?? "----",
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 34,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 6)),
                            const SizedBox(width: 15),
                            IconButton(
                                icon: const Icon(Icons.copy_rounded,
                                    color: Color(0xFFA68FFF)),
                                onPressed: () {
                                  Clipboard.setData(ClipboardData(
                                      text: currentChain.inviteCode ?? ""));
                                  ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                          content: Text("Code copied!"),
                                          behavior: SnackBarBehavior.floating));
                                }),
                          ],
                        ),
                        const SizedBox(height: 20),
                        SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFFA68FFF),
                                    shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(16)),
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 14)),
                                onPressed: () => Share.share(
                                    'Join my "${currentChain.name}" chain! 🚀 Code: ${currentChain.inviteCode}'),
                                icon: const Icon(Icons.share_rounded,
                                    color: Colors.white, size: 20),
                                label: const Text("Share Invite",
                                    style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold)))),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),

                  _buildCalendarView(context, currentChain.streakCount),
                  const SizedBox(height: 32),

                  // MEMBERS SECTION
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text("Members",
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold)),
                      if (isCreator)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                              color: Colors.amber.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                  color: Colors.amber.withOpacity(0.3))),
                          child: const Text("Admin 👑",
                              style: TextStyle(
                                  color: Colors.amber,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold)),
                        )
                    ],
                  ),
                  const SizedBox(height: 16),
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
                          final bool isSelf = memberId == _currentUser?.uid;
                          final bool isAdmin =
                              memberId == currentChain.creatorId;

                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.03),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                    color: Colors.white.withOpacity(0.05))),
                            child: Row(
                              children: [
                                CircleAvatar(
                                    radius: 22,
                                    backgroundColor: Colors.black26,
                                    backgroundImage: NetworkImage(
                                        "https://api.dicebear.com/9.x/adventurer/png?seed=$avatarSeed")),
                                const SizedBox(width: 12),
                                Expanded(
                                    child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                      Row(children: [
                                        Text(name,
                                            style: TextStyle(
                                                color: isSelf
                                                    ? const Color(0xFFA68FFF)
                                                    : Colors.white,
                                                fontWeight: FontWeight.bold)),
                                        if (isAdmin)
                                          const Padding(
                                              padding: EdgeInsets.only(left: 6),
                                              child: Icon(Icons.star,
                                                  color: Colors.amber,
                                                  size: 14))
                                      ]),
                                      Text(isSelf ? "You" : "Member",
                                          style: TextStyle(
                                              color: Colors.white38,
                                              fontSize: 12))
                                    ])),
                                if (isCreator && !isSelf)
                                  IconButton(
                                      icon: const Icon(
                                          Icons.remove_circle_outline,
                                          color: Colors.redAccent,
                                          size: 20),
                                      onPressed: () =>
                                          _kickMember(memberId, name))
                              ],
                            ),
                          );
                        },
                      );
                    },
                  ),

                  const SizedBox(height: 30),

                  // 🔥 BURASI YENİ: SOL ALTA, ÜYELERİN ALTINA, SOLUK KIRMIZI SİLME BUTONU
                  if (isCreator)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 50),
                      child: GestureDetector(
                        onTap: _deleteChain,
                        child: Container(
                          width: 50,
                          height: 50,
                          decoration: BoxDecoration(
                            // Senin temana uygun soluk bir kırmızı tonu
                            color: const Color(0xFFCF6679).withOpacity(0.15),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                                color:
                                    const Color(0xFFCF6679).withOpacity(0.3)),
                          ),
                          child: const Icon(
                            Icons.delete_outline_rounded,
                            color: Color(0xFFCF6679), // Soluk kırmızı ikon
                            size: 26,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
