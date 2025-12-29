import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:chainapp/models/chain_model.dart';
import 'package:chainapp/models/chain_log_model.dart';
import 'package:chainapp/services/firestore_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'profile_screen.dart'; // Profil için

class TimerScreen extends StatefulWidget {
  final ChainModel chain;
  const TimerScreen({super.key, required this.chain});

  @override
  State<TimerScreen> createState() => _TimerScreenState();
}

class _TimerScreenState extends State<TimerScreen> {
  late int remainingSeconds;
  late int totalSeconds;
  Timer? _timer;
  bool isRunning = false;

  @override
  void initState() {
    super.initState();
    // Chain'den gelen süreyi al, yoksa 30 dk varsayılan
    totalSeconds = (widget.chain.duration ?? 30) * 60;
    remainingSeconds = totalSeconds;
  }

  void startTimer() {
    if (_timer != null) return;
    setState(() => isRunning = true);
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (remainingSeconds > 0) {
        setState(() => remainingSeconds--);
      } else {
        completeTimer();
      }
    });
  }

  void stopTimer() {
    _timer?.cancel();
    _timer = null;
    setState(() => isRunning = false);
  }

  Future<void> completeTimer() async {
    stopTimer();
    final userId = FirebaseAuth.instance.currentUser?.uid;
    // Eğer bugün yapılmadıysa otomatik check-in
    if (userId != null &&
        !widget.chain.membersCompletedToday.contains(userId)) {
      final newLog = ChainLog(
          userId: userId, logDate: DateTime.now(), note: "Timer Completed ⏱️");
      await FirestoreService().performCheckIn(widget.chain.id, userId, newLog);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text("Timer finished! Task Completed! ✅"),
          backgroundColor: Colors.green));
      Navigator.pop(context); // Bitince Home'a dön
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String get timeString {
    int m = remainingSeconds ~/ 60;
    int s = remainingSeconds % 60;
    return "${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}";
  }

  // --- TIMER EKRANININ ALT BARI ---
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
          // 1. HOME: Buraya basınca Timer kapanır ve Home'a döner
          IconButton(
            onPressed: () {
              Navigator.pop(context);
            },
            icon:
                const Icon(Icons.home_filled, color: Colors.white70, size: 30),
          ),

          // 2. TIMER: Aktif olduğu için renkli
          GestureDetector(
            onTap: () {}, // Zaten buradayız
            child: Container(
              width: 55,
              height: 55,
              decoration: BoxDecoration(
                color: const Color(0xFF1F3D78),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white24),
                boxShadow: [
                  BoxShadow(
                      color: const Color(0xFFA68FFF).withOpacity(0.5),
                      blurRadius: 15)
                ],
              ),
              child: const Icon(Icons.timer, color: Colors.white, size: 28),
            ),
          ),

          // 3. PROFILE
          IconButton(
            onPressed: () {
              Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const ProfileScreen()));
            },
            icon: const Icon(Icons.person, color: Colors.white70, size: 30),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // İlerleme oranı (Ters orantı: süre azaldıkça bar dolsun istiyorsan 1 - (...) yap)
    // Yılanın dolması için:
    double progress = 1.0 - (remainingSeconds / totalSeconds);

    return Scaffold(
      backgroundColor: const Color(0xFF0A0E25),
      bottomNavigationBar: _buildBottomBar(context), // 🔥 ALT BAR EKLENDİ
      body: Stack(
        fit: StackFit.expand,
        children: [
          Container(
              decoration: const BoxDecoration(
                  gradient: LinearGradient(
                      colors: [Color(0xFF0A0E25), Color(0xFF1F3D78)],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter))),
          SafeArea(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(widget.chain.name,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),
                Text(widget.chain.purpose,
                    style: TextStyle(
                        color: Colors.white.withOpacity(0.7), fontSize: 16)),

                const SizedBox(height: 60),

                // --- 🐍 YILAN SAYAÇ ---
                Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      width: 260,
                      height: 260,
                      child: CircularProgressIndicator(
                        value: progress, // Yılan buradan ilerler
                        strokeWidth: 12,
                        backgroundColor: Colors.white10,
                        color: const Color(0xFFA68FFF),
                        strokeCap: StrokeCap.round,
                      ),
                    ),
                    Text(timeString,
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 52,
                            fontWeight: FontWeight.bold)),
                  ],
                ),

                const SizedBox(height: 60),

                GestureDetector(
                  onTap: isRunning ? stopTimer : startTimer,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 50, vertical: 18),
                    decoration: BoxDecoration(
                      color: isRunning
                          ? Colors.redAccent.withOpacity(0.2)
                          : Colors.greenAccent.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(30),
                      border: Border.all(
                          color: isRunning
                              ? Colors.redAccent
                              : Colors.greenAccent),
                    ),
                    child: Text(
                      isRunning ? "PAUSE" : "START",
                      style: TextStyle(
                          color:
                              isRunning ? Colors.redAccent : Colors.greenAccent,
                          fontSize: 18,
                          fontWeight: FontWeight.bold),
                    ),
                  ),
                )
              ],
            ),
          ),
        ],
      ),
    );
  }
}
