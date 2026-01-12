import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/Timer_service.dart';
import 'home_screen.dart';
import 'profile_screen.dart';
import 'chain_hub_screen.dart';

class ChainTimerScreen extends StatelessWidget {
  final String chainId;
  final String chainName;

  const ChainTimerScreen({
    super.key,
    required this.chainId,
    required this.chainName,
  });

  String _formatTime(int seconds) {
    int m = seconds ~/ 60;
    int s = seconds % 60;
    return "${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}";
  }

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
          IconButton(
            onPressed: () => Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (_) =>
                    HomeScreen(chainId: chainId, chainName: chainName),
              ),
            ),
            icon:
                const Icon(Icons.home_filled, color: Colors.white70, size: 32),
          ),
          Container(
            width: 55,
            height: 55,
            decoration: BoxDecoration(
              color: const Color(0xFF1F3D78),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                    color: const Color(0xFFA68FFF).withOpacity(0.3),
                    blurRadius: 10)
              ],
            ),
            child: const Icon(Icons.timer, color: Colors.white, size: 28),
          ),
          IconButton(
            onPressed: () => Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (_) => ProfileScreen(
                    selectedChainId: chainId, selectedChainName: chainName),
              ),
            ),
            icon: const Icon(Icons.person, color: Colors.white70, size: 32),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final timerProvider = context.watch<TimerProvider>();

    return Scaffold(
      backgroundColor: const Color(0xFF0A0E25),
      bottomNavigationBar: _buildBottomBar(context),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text("Focus Mode"),
        leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.pop(context)),
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
                    icon: const Icon(Icons.remove_circle_outline,
                        color: Colors.cyanAccent, size: 35),
                    onPressed: () => timerProvider
                        .setMinutes(timerProvider.selectedMinutes - 1),
                  ),
                  Text("${timerProvider.selectedMinutes} Minutes",
                      style:
                          const TextStyle(color: Colors.white, fontSize: 18)),
                  IconButton(
                    icon: const Icon(Icons.add_circle_outline,
                        color: Colors.cyanAccent, size: 35),
                    onPressed: () => timerProvider
                        .setMinutes(timerProvider.selectedMinutes + 1),
                  ),
                ],
              ),
            const SizedBox(height: 40),
            Text(_formatTime(timerProvider.remainingSeconds),
                style: const TextStyle(
                    fontSize: 80,
                    color: Colors.white,
                    fontWeight: FontWeight.bold)),
            const SizedBox(height: 60),
            GestureDetector(
              onTap: () => timerProvider.toggleTimer(),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 50, vertical: 15),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(30),
                  gradient: const LinearGradient(
                      colors: [Colors.cyanAccent, Colors.blueAccent]),
                ),
                child: Text(timerProvider.isRunning ? "PAUSE" : "START",
                    style: const TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.bold,
                        fontSize: 18)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
