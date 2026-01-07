import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/firestore_service.dart';
import '../services/notification_service.dart';
import '../models/chain_model.dart';
import '../models/chain_log_model.dart';
import 'chain_hub_screen.dart';
import 'profile_screen.dart';
import 'timer_screen.dart';
import 'chain_detail_screen.dart';

class HomeScreen extends StatefulWidget {
  final String chainId;
  final String chainName;

  const HomeScreen({
    super.key,
    required this.chainId,
    required this.chainName,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _firestoreService = FirestoreService();
  final _auth = FirebaseAuth.instance;
  TimeOfDay? _notificationTime;

  // --- ANA AKSİYON (CHECK-IN / REPAIR) ---
  Future<void> _handleAction(ChainModel chain) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return;

    // --- DURUM 1: ZİNCİR KIRIKSA (TAMİR ET) ---
    if (chain.status == 'broken') {
      try {
        final batch = FirebaseFirestore.instance.batch();

        // A. Zinciri Aktif Yap ve Bugünü Temizle
        DocumentReference chainRef =
            FirebaseFirestore.instance.collection('chains').doc(chain.id);
        batch.set(
            chainRef,
            {
              'status': 'active',
              'streakCount': 0,
              'membersCompletedToday':
                  [], // Tamir edildiğinde listeyi boşaltıyoruz
            },
            SetOptions(merge: true));

        // B. Kullanıcıdan XP Düş (-50)
        // .set(merge: true) kullanıyoruz ki döküman yoksa hata vermesin, oluştursun
        DocumentReference userRef =
            FirebaseFirestore.instance.collection('users').doc(userId);
        batch.set(
            userRef,
            {
              'xp': FieldValue.increment(-50),
            },
            SetOptions(merge: true));

        await batch.commit(); // İki işlemi aynı anda onayla

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text("Chain Repaired! 50 XP used. 🛠️"),
            backgroundColor: Colors.blue));
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text("Repair Error: $e"), backgroundColor: Colors.red));
      }
      return; // Tamir bittikten sonra fonksiyonun geri kalanını (check-in) çalıştırma
    }

    // --- DURUM 2: ZİNCİR AKTİFSE (NORMAL CHECK-IN) ---
    bool? confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1F3D78),
        title: const Text("Daily Goal?", style: TextStyle(color: Colors.white)),
        content: const Text("Mark today as completed?",
            style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text("Cancel")),
          ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text("Confirm")),
        ],
      ),
    );

    if (confirm == true) {
      try {
        final newLog = ChainLog(
            userId: userId, logDate: DateTime.now(), note: "Manual Check-in");
        await _firestoreService.performCheckIn(chain.id, userId, newLog);
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red));
      }
    }
  }

  // --- BİLDİRİM SAATİ SEÇME ---
  Future<void> _pickTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: const ColorScheme.dark(
              primary: Color(0xFFA68FFF),
              onPrimary: Colors.white,
              surface: Color(0xFF142A52),
              onSurface: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() => _notificationTime = picked);
      await NotificationService().scheduleDailyNotification(
        id: widget.chainId.hashCode,
        title: "Keep the streak alive! 🔥",
        body: "Don't forget to check in for ${widget.chainName}",
        time: picked,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text("Daily reminder set for ${picked.format(context)} ⏰")));
    }
  }

  // --- ZİNCİR HALKASI GÖRÜNÜMÜ ---
  Widget _buildChainNode(
      String dayNum, bool isDone, bool isToday, bool isLast) {
    return Container(
      width: 60,
      child: Stack(
        alignment: Alignment.center,
        children: [
          if (!isLast)
            Positioned(
              right: 0,
              left: 30,
              child: Container(
                  height: 4,
                  color: isDone ? Colors.greenAccent : Colors.white24),
            ),
          Container(
            width: 45,
            height: 45,
            decoration: BoxDecoration(
              color: isDone
                  ? Colors.green
                  : (isToday
                      ? Colors.white.withOpacity(0.1)
                      : Colors.transparent),
              shape: BoxShape.circle,
              border: Border.all(
                color: isDone
                    ? Colors.greenAccent
                    : (isToday ? Colors.white : Colors.white24),
                width: isToday ? 2 : 1,
              ),
              boxShadow: isDone
                  ? [
                      BoxShadow(
                          color: Colors.green.withOpacity(0.5), blurRadius: 10)
                    ]
                  : [],
            ),
            child: Center(
              child: isDone
                  ? const Icon(Icons.check, color: Colors.white, size: 24)
                  : Text(dayNum,
                      style: TextStyle(
                          color: isToday ? Colors.white : Colors.white54,
                          fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }

  // 🔥 GÜNCELLENMİŞ AVATAR VE DÜRTME BUTONU
  Widget _buildMemberAvatar(
      String memberId, bool isCompleted, String chainId, String chainName) {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;
    // Kendimizi dürtmeyelim :)
    final isMe = memberId == currentUserId;

    return FutureBuilder<DocumentSnapshot>(
      future:
          FirebaseFirestore.instance.collection('users').doc(memberId).get(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox();
        final data = snapshot.data!.data() as Map<String, dynamic>?;
        final avatarSeed = data?['avatarSeed'] ?? 'user';
        final userName = data?['name'] ?? 'User';

        return Padding(
          padding: const EdgeInsets.only(right: 12.0),
          child: Column(
            children: [
              Stack(
                children: [
                  // 1. AVATAR (Kendisi)
                  Container(
                    padding: const EdgeInsets.all(3),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                          // Yapıldıysa YEŞİL, Yapılmadıysa KIRMIZIMSI
                          color: isCompleted
                              ? Colors.greenAccent
                              : Colors.redAccent.withOpacity(0.6),
                          width: 2.5),
                      boxShadow: isCompleted
                          ? [
                              BoxShadow(
                                  color: Colors.green.withOpacity(0.3),
                                  blurRadius: 8)
                            ]
                          : [],
                    ),
                    child: CircleAvatar(
                      radius: 24,
                      backgroundColor: Colors.black26,
                      backgroundImage: NetworkImage(
                          "https://api.dicebear.com/9.x/adventurer/png?seed=$avatarSeed&backgroundColor=b6e3f4"),
                    ),
                  ),

                  // 2. DÜRTME BUTONU (Sadece yapılmadıysa ve başkasıysa göster)
                  if (!isCompleted && !isMe)
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: GestureDetector(
                        onTap: () async {
                          try {
                            await FirestoreService().sendNudge(
                                currentUserId!, memberId, chainId, chainName);

                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text("$userName dürtüldü! 👋"),
                                backgroundColor: Colors.orangeAccent,
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          } catch (e) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                    e.toString().replaceAll("Exception: ", "")),
                                backgroundColor: Colors.grey,
                              ),
                            );
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(blurRadius: 4, color: Colors.black26)
                              ]),
                          child: const Icon(Icons.waving_hand,
                              size: 14, color: Colors.orange),
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildBottomBar(BuildContext context, ChainModel chain) {
    return Container(
      height: 80,
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A),
        border: Border(top: BorderSide(color: Colors.white.withOpacity(0.1))),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          IconButton(
            onPressed: () => Navigator.pushReplacement(context,
                MaterialPageRoute(builder: (_) => const ChainHubScreen())),
            icon:
                const Icon(Icons.home_filled, color: Colors.white70, size: 32),
          ),
          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const ChainTimerScreen(),
                ),
              );
            }, // Fonksiyon burada bitmeli
            child: Container(
              width: 55,
              height: 55,
              decoration: BoxDecoration(
                color: const Color(0xFF1F3D78),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white24),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFA68FFF).withOpacity(0.3),
                    blurRadius: 10,
                  ),
                ],
              ),
              child: const Icon(Icons.timer, color: Colors.white, size: 28),
            ),
          ), // GestureDetector burada bitmeli
          IconButton(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ProfileScreen()),
            ),
            icon: const Icon(Icons.person, color: Colors.white70, size: 32),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentUserId = _auth.currentUser?.uid;

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('chains')
          .doc(widget.chainId)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || !snapshot.data!.exists) {
          return const Scaffold(
              backgroundColor: Color(0xFF0A0E25),
              body: Center(
                  child: CircularProgressIndicator(color: Colors.white)));
        }

        final chainData = snapshot.data!.data() as Map<String, dynamic>;
        final chain = ChainModel.fromMap(snapshot.data!.id, chainData);

        final bool isCompletedToday =
            chain.membersCompletedToday.contains(currentUserId);
        final bool isBroken = chain.status == 'broken';

        return Scaffold(
          backgroundColor: const Color(0xFF0A0E25),
          bottomNavigationBar: _buildBottomBar(context, chain),
          extendBodyBehindAppBar: true,
          appBar: AppBar(
            title: Text(chain.name,
                style: const TextStyle(
                    fontWeight: FontWeight.bold, color: Colors.white)),
            centerTitle: true,
            backgroundColor: Colors.transparent,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
            actions: [
              IconButton(
                icon: Icon(Icons.notifications_active,
                    color: _notificationTime != null
                        ? Colors.amber
                        : Colors.white54),
                onPressed: _pickTime,
              )
            ],
          ),
          body: Stack(
            fit: StackFit.expand,
            children: [
              Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Color(0xFF0A0E25),
                      Color(0xFF1F3D78),
                      Color(0xFF6C5ECF)
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
              ),
              SafeArea(
                child: SingleChildScrollView(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 1. ZİNCİR
                      SizedBox(
                        height: 60,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: 7,
                          itemBuilder: (context, index) {
                            final date = DateTime.now()
                                .subtract(Duration(days: 3 - index));
                            final dayNum = DateFormat('d').format(date);
                            final isToday = index == 3;
                            final isFuture = index > 3;

                            bool isDone = false;
                            if (isToday)
                              isDone = isCompletedToday;
                            else if (!isFuture &&
                                index >= (3 - chain.streakCount)) isDone = true;

                            return _buildChainNode(
                                dayNum, isDone, isToday, index == 6);
                          },
                        ),
                      ),

                      const SizedBox(height: 30),

                      // 2. 🔥 AKSİYON BUTONU (GÜNCELLENMİŞ TASARIM)
                      GestureDetector(
                        // Yapıldıysa Tıklanmasın, Kırıksa Tamir, Değilse Check-in
                        onTap: (isBroken || !isCompletedToday)
                            ? () => _handleAction(chain)
                            : null, // Sadece hem aktif hem de yapıldıysa kilitli kalır.
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(20),
                          child: BackdropFilter(
                            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                            child: Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                    color: Colors.white.withOpacity(0.1)),
                              ),
                              child: Row(
                                children: [
                                  // BUTON
                                  AnimatedContainer(
                                    duration: const Duration(milliseconds: 300),
                                    width: 55,
                                    height: 55,
                                    decoration: BoxDecoration(
                                      // 🔥 YAPILDIYSA: YEŞİL
                                      // 🔥 KIRIKSA: KIRMIZI
                                      // 🔥 YAPILMADIYSA: ŞEFFAF
                                      color: isBroken
                                          ? Colors.red
                                          : (isCompletedToday
                                              ? Colors.green
                                              : Colors.transparent),
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                          // Çerçeve Rengi
                                          color: isBroken
                                              ? Colors.redAccent
                                              : (isCompletedToday
                                                  ? Colors.green
                                                  : Colors
                                                      .white54), // Beyaz/Gri Çerçeve
                                          width: 2),
                                      boxShadow: isCompletedToday
                                          ? [
                                              BoxShadow(
                                                  color: Colors.green
                                                      .withOpacity(0.5),
                                                  blurRadius: 15)
                                            ]
                                          : [],
                                    ),
                                    child: Center(
                                      child: isBroken
                                          ? const Icon(Icons.build,
                                              color: Colors.white)
                                          : (isCompletedToday
                                              // 🔥 TİK İKONU ARKA PLAN RENGİNDE (DELİK GİBİ GÖRÜNSÜN)
                                              ? const Icon(Icons.check,
                                                  color: Color(0xFF0A0E25),
                                                  size: 30,
                                                  weight: 800)
                                              : null), // YAPILMADIYSA BOŞ
                                    ),
                                  ),

                                  const SizedBox(width: 16),

                                  // YAZILAR
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                            isBroken
                                                ? "Chain Broken!"
                                                : "Daily Goal",
                                            style: TextStyle(
                                                color: isBroken
                                                    ? Colors.redAccent
                                                    : Colors.white54,
                                                fontSize: 12)),
                                        Text(
                                          isBroken
                                              ? "Tap to Repair (50 XP)"
                                              : (chain.purpose.isNotEmpty
                                                  ? chain.purpose
                                                  : chain.name),
                                          style: TextStyle(
                                            color: isCompletedToday
                                                ? Colors.white.withOpacity(
                                                    0.5) // Yapıldıysa sönük
                                                : Colors.white,
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                            decoration: isCompletedToday
                                                ? TextDecoration.lineThrough
                                                : null,
                                            decorationColor: Colors.white54,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 30),

                      // 3. ÜYELER
                      const Text("Team Status",
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w600)),
                      const SizedBox(height: 12),
                      SizedBox(
                        height: 90,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: chain.members.length,
                          itemBuilder: (context, index) {
                            final memberId = chain.members[index];
                            final isMemCompleted =
                                chain.membersCompletedToday.contains(memberId);
                            return _buildMemberAvatar(
                                memberId, isMemCompleted, chain.id, chain.name);
                          },
                        ),
                      ),

                      const SizedBox(height: 20),

                      // 4. DESCRIPTION
                      GestureDetector(
                        onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) =>
                                    ChainDetailScreen(chain: chain))),
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.05),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: Colors.white10),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text("About this Chain",
                                      style: TextStyle(
                                          color: Colors.white54,
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold)),
                                  Icon(Icons.arrow_forward_ios,
                                      color: Colors.white.withOpacity(0.3),
                                      size: 14),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                chain.description.isNotEmpty
                                    ? chain.description
                                    : "No description provided.",
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 14,
                                    height: 1.4),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 50),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
