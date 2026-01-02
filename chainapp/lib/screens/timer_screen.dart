import 'dart:async';
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart'; // Ses çalmak için gerekli paket

class ChainTimerScreen extends StatefulWidget {
  const ChainTimerScreen({super.key});

  @override
  State<ChainTimerScreen> createState() => _ChainTimerScreenState();
}

class _ChainTimerScreenState extends State<ChainTimerScreen> {
  int selectedMinutes = 25; // Kullanıcının seçtiği başlangıç süresi
  int remainingSeconds = 25 * 60;
  Timer? _timer;
  bool isRunning = false;

  // 🔥 SES ÇALAR NESNESİ
  final AudioPlayer _audioPlayer = AudioPlayer();

  // 🔥 SÜRE BİTTİĞİNDE ÇALIŞAN FONKSİYON
  void _onTimerFinished() async {
    _timer?.cancel();
    setState(() => isRunning = false);

    // 🔔 ALARM ÇALMA KODU (İstediğin yer tam burası)
    try {
      // AssetSource, pubspec.yaml'daki Assets/alarm.mp3 kaydıyla otomatik eşleşir
      await _audioPlayer.play(AssetSource('alarm.mp3'));
    } catch (e) {
      print("Alarm çalarken hata oluştu: $e");
    }

    // Kullanıcıya süre bittiğini gösteren pencere
    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF142A52),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title:
            const Text("Süre Doldu! 🔔", style: TextStyle(color: Colors.white)),
        content: const Text("Zamanlayıcı sona erdi.",
            style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () {
              _audioPlayer.stop(); // Alarmı durdurur
              Navigator.pop(context);
            },
            child: const Text("Alarmı Durdur",
                style: TextStyle(color: Colors.cyanAccent)),
          ),
        ],
      ),
    );
  }

  void _startTimer() {
    if (isRunning) {
      _timer?.cancel();
    } else {
      _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
        setState(() {
          if (remainingSeconds > 0) {
            remainingSeconds--;
          } else {
            _onTimerFinished();
          }
        });
      });
    }
    setState(() => isRunning = !isRunning);
  }

  String _formatTime(int seconds) {
    int m = seconds ~/ 60;
    int s = seconds % 60;
    return "${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}";
  }

  @override
  void dispose() {
    _timer?.cancel();
    _audioPlayer.dispose(); // Sayfadan çıkınca belleği temizler
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0E25),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Sadece duruyorsa süre değiştirilebilir
            if (!isRunning)
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    icon: const Icon(Icons.remove_circle_outline,
                        color: Colors.cyanAccent, size: 35),
                    onPressed: () => setState(() {
                      if (selectedMinutes > 1) {
                        selectedMinutes--;
                        remainingSeconds = selectedMinutes * 60;
                      }
                    }),
                  ),
                  const SizedBox(width: 10),
                  Text("$selectedMinutes Dakika",
                      style:
                          const TextStyle(color: Colors.white, fontSize: 18)),
                  const SizedBox(width: 10),
                  IconButton(
                    icon: const Icon(Icons.add_circle_outline,
                        color: Colors.cyanAccent, size: 35),
                    onPressed: () => setState(() {
                      selectedMinutes++;
                      remainingSeconds = selectedMinutes * 60;
                    }),
                  ),
                ],
              ),

            const SizedBox(height: 40),

            // Zaman Göstergesi
            Text(
              _formatTime(remainingSeconds),
              style: const TextStyle(
                  fontSize: 80,
                  color: Colors.white,
                  fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 60),

            // Başlat/Durdur Butonu
            GestureDetector(
              onTap: _startTimer,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 50, vertical: 15),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(30),
                  gradient: const LinearGradient(
                      colors: [Colors.cyanAccent, Colors.blueAccent]),
                ),
                child: Text(
                  isRunning ? "DURAKLAT" : "BAŞLAT",
                  style: const TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                      fontSize: 18),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
