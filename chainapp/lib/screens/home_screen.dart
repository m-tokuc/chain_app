import 'dart:async'; // StreamSubscription için gerekli
import 'dart:ui'; // Glassmorphism efektleri için
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

// Servisler ve Modeller
import '../services/firestore_service.dart';
import '../services/notification_service.dart';
import '../models/chain_model.dart';
import '../models/chain_log_model.dart';

// Diğer Sayfalar
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

  // Bildirim saati
  TimeOfDay? _notificationTime;

  // 🔥 CANLI BİLDİRİM DİNLEYİCİSİ İÇİN DEĞİŞKEN
  StreamSubscription? _nudgeSubscription;

  @override
  void initState() {
    super.initState();
    // 🔥 Uygulama açılınca gelen dürtmeleri dinlemeye başla
    _listenForNudges();
  }

  @override
  void dispose() {
    // 🔥 Sayfadan çıkınca dinlemeyi durdur (Performans için)
    _nudgeSubscription?.cancel();
    super.dispose();
  }

  // 🔥 CANLI DÜRTME DİNLEYİCİSİ (UYGULAMA AÇIKKEN ÇALIŞIR)
  void _listenForNudges() {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return;

    _nudgeSubscription = FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('notifications')
        .where('isRead', isEqualTo: false) // Sadece okunmamışları getir
        .limit(1)
        .snapshots()
        .listen((snapshot) {
      for (var change in snapshot.docChanges) {
        if (change.type == DocumentChangeType.added) {
          final data = change.doc.data() as Map<String, dynamic>;
          final msg = data['message'] ?? "Seni dürttü!";

          // Ekranda mesajı göster
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Row(
                  children: [
                    const Icon(Icons.waving_hand, color: Colors.white),
                    const SizedBox(width: 10),
                    Expanded(child: Text("Biri seni dürttü: \"$msg\"")),
                  ],
                ),
                backgroundColor: const Color(0xFFA68FFF), // Mor renk
                duration: const Duration(seconds: 4),
                action: SnackBarAction(
                  label: "TAMAM",
                  textColor: Colors.white,
                  onPressed: () {
                    change.doc.reference.update({'isRead': true});
                  },
                ),
              ),
            );
            // Görüldü işaretle
            change.doc.reference.update({'isRead': true});
          }
        }
      }
    });
  }

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
              'membersCompletedToday': [],
            },
            SetOptions(merge: true));

        // B. Kullanıcıdan XP Düş (-50)
        DocumentReference userRef =
            FirebaseFirestore.instance.collection('users').doc(userId);
        batch.set(
            userRef,
            {
              'xp': FieldValue.increment(-50),
            },
            SetOptions(merge: true));

        await batch.commit();

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text("Chain Repaired! 50 XP used. 🛠️"),
            backgroundColor: Colors.blue));
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text("Repair Error: $e"), backgroundColor: Colors.red));
      }
      return;
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
      initialTime: _notificationTime ?? TimeOfDay.now(),
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: const ColorScheme.dark(
              primary: Color(0xFFA68FFF),
              onPrimary: Colors.white,
              surface: Color(0xFF142A52),
              onSurface: Colors.white,
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFFA68FFF),
              ),
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() => _notificationTime = picked);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Hatırlatıcı ayarlanıyor..."),
          duration: Duration(milliseconds: 500),
        ),
      );

      try {
        await NotificationService().scheduleDailyNotification(
          id: widget.chainId.hashCode,
          title: "Zinciri Kırma! 🔥",
          body: "${widget.chainName} hedefini tamamlama vakti!",
          time: picked,
        );

        if (!mounted) return;
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              "Hatırlatıcı her gün ${picked.format(context)} saati için kuruldu ⏰",
              style: const TextStyle(color: Colors.white),
            ),
            backgroundColor: Colors.green.shade600,
            behavior: SnackBarBehavior.floating,
          ),
        );
      } catch (e) {
        print("PickTime Hatası: $e");
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Hata oluştu: $e"),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  // 🔥 MESAJ YAZMA PENCERESİ (YENİ EKLENDİ)
  void _showNudgeDialog(
      String memberId, String userName, String chainId, String chainName) {
    final TextEditingController messageController = TextEditingController();
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1F3D78),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(Icons.waving_hand, color: Colors.orangeAccent),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                "$userName kişisini dürt",
                style: const TextStyle(color: Colors.white, fontSize: 18),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              "Ona kısa bir motivasyon mesajı gönder! 🚀",
              style: TextStyle(color: Colors.white70, fontSize: 14),
            ),
            const SizedBox(height: 15),
            TextField(
              controller: messageController,
              style: const TextStyle(color: Colors.white),
              maxLength: 50,
              decoration: InputDecoration(
                hintText: "Örn: Hadi, yapabilirsin!",
                hintStyle: TextStyle(color: Colors.white.withOpacity(0.3)),
                filled: true,
                fillColor: Colors.black26,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                counterStyle: const TextStyle(color: Colors.white54),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child:
                const Text("Vazgeç", style: TextStyle(color: Colors.white54)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFA68FFF),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () async {
              Navigator.pop(ctx);

              String msg = messageController.text.trim();
              if (msg.isEmpty) msg = "Seni bekliyoruz! 👋";

              try {
                // 🔥 Servisi mesaj parametresiyle çağırıyoruz
                await FirestoreService().sendNudge(
                    currentUserId!, memberId, chainId, chainName, msg);

                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text("$userName dürtüldü: \"$msg\""),
                      backgroundColor: Colors.green,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              } catch (e) {
                print("Dürtme hatası: $e");
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text("Hata: ${e.toString()}"),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            child: const Text("GÖNDER", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // --- ZİNCİR HALKASI GÖRÜNÜMÜ ---
  Widget _buildChainNode(
      String dayNum, bool isDone, bool isToday, bool isLast) {
    return SizedBox(
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

  // --- ÜYE AVATARI VE DÜRTME ---
  Widget _buildMemberAvatar(
      String memberId, bool isCompleted, String chainId, String chainName) {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;
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
                  // AVATAR
                  Container(
                    padding: const EdgeInsets.all(3),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
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

                  // DÜRTME BUTONU
                  if (!isCompleted && !isMe)
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: GestureDetector(
                        onTap: () {
                          // 🔥 PENCERE AÇ
                          _showNudgeDialog(
                              memberId, userName, chainId, chainName);
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

  // --- ALT MENÜ ---
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
            },
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
          ),
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

        return SafeArea(
          child: Scaffold(
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
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 1. TAKVİM
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
                                  index >= (3 - chain.streakCount))
                                isDone = true;

                              return _buildChainNode(
                                  dayNum, isDone, isToday, index == 6);
                            },
                          ),
                        ),

                        const SizedBox(height: 30),

                        // 2. AKSİYON BUTONU
                        GestureDetector(
                          onTap: (isBroken || !isCompletedToday)
                              ? () => _handleAction(chain)
                              : null,
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
                                    AnimatedContainer(
                                      duration:
                                          const Duration(milliseconds: 300),
                                      width: 55,
                                      height: 55,
                                      decoration: BoxDecoration(
                                        color: isBroken
                                            ? Colors.red
                                            : (isCompletedToday
                                                ? Colors.green
                                                : Colors.transparent),
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                            color: isBroken
                                                ? Colors.redAccent
                                                : (isCompletedToday
                                                    ? Colors.green
                                                    : Colors.white54),
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
                                                ? const Icon(Icons.check,
                                                    color: Color(0xFF0A0E25),
                                                    size: 30,
                                                    weight: 800)
                                                : null),
                                      ),
                                    ),
                                    const SizedBox(width: 16),
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
                                                  ? Colors.white
                                                      .withOpacity(0.5)
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

                        // 3. TAKIM DURUMU
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
                              final isMemCompleted = chain.membersCompletedToday
                                  .contains(memberId);
                              return _buildMemberAvatar(memberId,
                                  isMemCompleted, chain.id, chain.name);
                            },
                          ),
                        ),

                        const SizedBox(height: 20),

                        // 4. AÇIKLAMA KARTI
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
          ),
        );
      },
    );
  }
}
