import 'package:flutter/material.dart';

class StatisticsScreen extends StatelessWidget {
  const StatisticsScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        appBar: AppBar(title: const Text("Zincir İstatistikleri")),
        body: const Center(child: Text("Detaylı istatistikler burada olacak.")),
      ),
    );
  }
}
