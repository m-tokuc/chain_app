import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Sadece sayı girişi için gerekli
import '../services/chain_service.dart';
import '../services/firebase_auth_service.dart';
import 'invite_code_screen.dart';

class CreateChainScreen extends StatefulWidget {
  const CreateChainScreen({super.key});

  @override
  State<CreateChainScreen> createState() => _CreateChainScreenState();
}

class _CreateChainScreenState extends State<CreateChainScreen> {
  final _chainService = ChainService();
  final _authService = FirebaseAuthService();

  // Kontrolcüler
  final nameController = TextEditingController();
  final purposeController = TextEditingController();
  final descriptionController = TextEditingController();
  final durationController =
      TextEditingController(); // ✅ YENİ: Süre Kontrolcüsü

  int? selectedDuration; // Seçilen süre (dk)

  String selectedPeriod = "daily";
  final List<String> selectedDays = [];
  final List<String> weekDays = [
    "Mon",
    "Tue",
    "Wed",
    "Thu",
    "Fri",
    "Sat",
    "Sun"
  ];
  bool isLoading = false;

  void toggleDay(String day) {
    setState(() {
      if (selectedDays.contains(day)) {
        selectedDays.remove(day);
      } else {
        selectedDays.add(day);
      }
    });
  }

  Future<void> createChain() async {
    FocusScope.of(context).unfocus();
    final userId = _authService.currentUserId();

    if (userId == null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text("Please login first")));
      return;
    }

    if (nameController.text.trim().isEmpty ||
        purposeController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Chain name and Purpose are required")));
      return;
    }

    if (selectedPeriod == "weekly" && selectedDays.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text("Select at least one day for weekly habit")));
      return;
    }

    // ✅ SÜRE KONTROLÜ
    int? finalDuration = selectedDuration;

    // Eğer manuel giriş yapıldıysa onu önceliklendir
    if (durationController.text.isNotEmpty) {
      int? manualVal = int.tryParse(durationController.text);
      if (manualVal != null) {
        if (manualVal > 1440) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
              content: Text("Duration cannot exceed 1440 minutes (24 hours)")));
          return;
        }
        finalDuration = manualVal;
      }
    }

    setState(() => isLoading = true);

    final inviteCode = await _chainService.createChain(
      name: nameController.text.trim(),
      purpose: purposeController.text.trim(),
      description: descriptionController.text.trim(),
      duration: finalDuration, // ✅ Servise gönderiyoruz
      period: selectedPeriod,
      members: [userId],
      days: selectedPeriod == "weekly" ? selectedDays : [],
    );

    if (!mounted) return;
    setState(() => isLoading = false);

    if (inviteCode == null) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Failed to create chain. Try again.")));
    } else {
      Navigator.pushReplacement(
          context,
          MaterialPageRoute(
              builder: (_) => InviteCodeScreen(inviteCode: inviteCode)));
    }
  }

  // ✅ YENİ: Süre Seçim Butonları (Chips)
  Widget _buildDurationChip(int minutes) {
    // Eğer manuel kutu boşsa ve bu süre seçiliyse aktif göster
    bool isSelected =
        (selectedDuration == minutes && durationController.text.isEmpty);

    return GestureDetector(
      onTap: () {
        setState(() {
          selectedDuration = minutes;
          durationController.clear(); // Manuel yazıyı temizle ki çakışmasın
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFFA68FFF)
              : Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
              color: isSelected
                  ? const Color(0xFFA68FFF)
                  : Colors.white.withOpacity(0.1)),
        ),
        child: Text("$minutes m",
            style: TextStyle(
                color: isSelected ? Colors.white : Colors.white70,
                fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _buildGlassTextField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    int maxLines = 1,
    TextInputType keyboardType = TextInputType.text,
    List<TextInputFormatter>? formatters, // Sadece sayı girmek için ekledim
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white.withOpacity(0.08)),
          ),
          child: TextField(
            controller: controller,
            keyboardType: keyboardType,
            inputFormatters: formatters,
            style: const TextStyle(color: Colors.white),
            maxLines: maxLines,
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(color: Colors.white.withOpacity(0.4)),
              prefixIcon: Icon(icon, color: const Color(0xFFA68FFF)),
              border: InputBorder.none,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            ),
            onChanged: (val) {
              // Manuel giriş yapılırsa seçili chip'i iptal et
              if (val.isNotEmpty && selectedDuration != null) {
                setState(() => selectedDuration = null);
              }
            },
          ),
        ),
      ),
    );
  }

  Widget _buildGlassContainer(
      {required Widget child, EdgeInsetsGeometry? padding}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white.withOpacity(0.08)),
          ),
          child: child,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        backgroundColor: const Color(0xFF0F172A),
        extendBodyBehindAppBar: true,
        appBar: AppBar(
          title: const Text("Create New Chain",
              style:
                  TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          centerTitle: true,
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: Stack(
          fit: StackFit.expand,
          children: [
            // ARKA PLAN
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFF0F172A),
                    Color(0xFF1E1B4B),
                    Color(0xFF312E81)
                  ],
                ),
              ),
            ),

            // İÇERİK
            SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // NAME
                    Text("Chain Name",
                        style: TextStyle(
                            color: Colors.white.withOpacity(0.8),
                            fontSize: 16,
                            fontWeight: FontWeight.w600)),
                    const SizedBox(height: 10),
                    _buildGlassTextField(
                        controller: nameController,
                        hint: "e.g. Healthy Living",
                        icon: Icons.link),

                    const SizedBox(height: 25),

                    // PURPOSE
                    Text("Daily Goal (Purpose)",
                        style: TextStyle(
                            color: Colors.white.withOpacity(0.8),
                            fontSize: 16,
                            fontWeight: FontWeight.w600)),
                    const SizedBox(height: 10),
                    _buildGlassTextField(
                        controller: purposeController,
                        hint: "e.g. Read 20 pages",
                        icon: Icons.flag),

                    const SizedBox(height: 25),

                    // DESCRIPTION
                    Text("Description",
                        style: TextStyle(
                            color: Colors.white.withOpacity(0.8),
                            fontSize: 16,
                            fontWeight: FontWeight.w600)),
                    const SizedBox(height: 10),
                    _buildGlassTextField(
                        controller: descriptionController,
                        hint: "Why is this important?",
                        icon: Icons.description,
                        maxLines: 2),

                    const SizedBox(height: 25),

                    // ✅ SÜRE SEÇİMİ (YENİ)
                    Text("Duration (Minutes)",
                        style: TextStyle(
                            color: Colors.white.withOpacity(0.8),
                            fontSize: 16,
                            fontWeight: FontWeight.w600)),
                    const SizedBox(height: 12),
                    // Hazır Butonlar
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: [15, 30, 45, 60, 90]
                          .map((m) => _buildDurationChip(m))
                          .toList(),
                    ),
                    const SizedBox(height: 12),
                    // Manuel Giriş
                    _buildGlassTextField(
                      controller: durationController,
                      hint: "Custom duration (Max 1440)",
                      icon: Icons.timer,
                      keyboardType: TextInputType.number,
                      formatters: [
                        FilteringTextInputFormatter.digitsOnly
                      ], // Sadece sayı
                    ),

                    const SizedBox(height: 35),

                    // FREQUENCY
                    Text("Frequency",
                        style: TextStyle(
                            color: Colors.white.withOpacity(0.8),
                            fontSize: 16,
                            fontWeight: FontWeight.w600)),
                    const SizedBox(height: 12),
                    _buildGlassContainer(
                      child: Column(
                        children: [
                          RadioListTile<String>(
                            title: const Text("Daily",
                                style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold)),
                            subtitle: Text("Every day streak",
                                style: TextStyle(
                                    color: Colors.white.withOpacity(0.5))),
                            value: "daily",
                            groupValue: selectedPeriod,
                            activeColor: const Color(0xFFA68FFF),
                            onChanged: (v) => setState(() {
                              selectedPeriod = v!;
                              selectedDays.clear();
                            }),
                          ),
                          Divider(
                              height: 1, color: Colors.white.withOpacity(0.1)),
                          RadioListTile<String>(
                            title: const Text("Weekly",
                                style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold)),
                            subtitle: Text("Specific days only",
                                style: TextStyle(
                                    color: Colors.white.withOpacity(0.5))),
                            value: "weekly",
                            groupValue: selectedPeriod,
                            activeColor: const Color(0xFFA68FFF),
                            onChanged: (v) =>
                                setState(() => selectedPeriod = v!),
                          ),
                        ],
                      ),
                    ),

                    AnimatedCrossFade(
                      firstChild: Container(),
                      secondChild: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 25),
                          Text("Select Days:",
                              style: TextStyle(
                                  color: Colors.white.withOpacity(0.8),
                                  fontWeight: FontWeight.w500)),
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 10,
                            runSpacing: 10,
                            children: weekDays.map((day) {
                              final isSelected = selectedDays.contains(day);
                              return GestureDetector(
                                onTap: () => toggleDay(day),
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 200),
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 20, vertical: 12),
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? const Color(0xFFA68FFF)
                                        : Colors.white.withOpacity(0.05),
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                        color: isSelected
                                            ? const Color(0xFFA68FFF)
                                            : Colors.white.withOpacity(0.1)),
                                  ),
                                  child: Text(day,
                                      style: TextStyle(
                                          color: isSelected
                                              ? Colors.white
                                              : Colors.white.withOpacity(0.7),
                                          fontWeight: isSelected
                                              ? FontWeight.bold
                                              : FontWeight.normal)),
                                ),
                              );
                            }).toList(),
                          ),
                        ],
                      ),
                      crossFadeState: selectedPeriod == "weekly"
                          ? CrossFadeState.showSecond
                          : CrossFadeState.showFirst,
                      duration: const Duration(milliseconds: 300),
                    ),

                    const SizedBox(height: 50),

                    SizedBox(
                      width: double.infinity,
                      height: 60,
                      child: ElevatedButton(
                        onPressed: isLoading ? null : createChain,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFA68FFF),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(24)),
                          elevation: 0,
                          shadowColor: Colors.transparent,
                        ),
                        child: Container(
                          decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(24),
                              boxShadow: [
                                BoxShadow(
                                    color: const Color(0xFFA68FFF)
                                        .withOpacity(0.4),
                                    blurRadius: 20,
                                    offset: const Offset(0, 5))
                              ]),
                          alignment: Alignment.center,
                          child: isLoading
                              ? const CircularProgressIndicator(
                                  color: Colors.white)
                              : const Text("Create Chain",
                                  style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white)),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
