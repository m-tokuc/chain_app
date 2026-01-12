import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/Timer_service.dart';

class ChainTimerScreen extends StatelessWidget {
  const ChainTimerScreen({super.key});

  String _formatTime(int seconds) {
    int m = seconds ~/ 60;
    int s = seconds % 60;
    return "${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}";
  }

  @override
  Widget build(BuildContext context) {
    // Provider'ı dinliyoruz
    final timerProvider = context.watch<TimerProvider>();

    return Scaffold(
      backgroundColor: const Color(0xFF0A0E25),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text("Odaklanma"),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (!timerProvider.isRunning)
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    icon: const Icon(Icons.remove_circle_outline, color: Colors.cyanAccent, size: 35),
                    onPressed: () => timerProvider.setMinutes(timerProvider.selectedMinutes - 1),
                  ),
                  Text("${timerProvider.selectedMinutes} Dakika", 
                    style: const TextStyle(color: Colors.white, fontSize: 18)),
                  IconButton(
                    icon: const Icon(Icons.add_circle_outline, color: Colors.cyanAccent, size: 35),
                    onPressed: () => timerProvider.setMinutes(timerProvider.selectedMinutes + 1),
                  ),
                ],
              ),
            const SizedBox(height: 40),
            Text(
              _formatTime(timerProvider.remainingSeconds),
              style: const TextStyle(fontSize: 80, color: Colors.white, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 60),
            GestureDetector(
              onTap: () => timerProvider.toggleTimer(),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 15),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(30),
                  gradient: const LinearGradient(colors: [Colors.cyanAccent, Colors.blueAccent]),
                ),
                child: Text(
                  timerProvider.isRunning ? "DURAKLAT" : "BAŞLAT",
                  style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 18),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}