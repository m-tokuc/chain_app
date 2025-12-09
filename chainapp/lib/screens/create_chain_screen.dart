import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../services/chain_service.dart';
import 'invite_code_screen.dart';

class CreateChainScreen extends StatefulWidget {
  const CreateChainScreen({super.key});

  @override
  State<CreateChainScreen> createState() => _CreateChainScreenState();
}

class _CreateChainScreenState extends State<CreateChainScreen> {
  final nameController = TextEditingController();
  final descriptionController = TextEditingController();

  String selectedPeriod = "daily";
  bool isLoading = false;

  final ChainService _chainService = ChainService();

  Future<void> createChain() async {
    final name = nameController.text.trim();
    final description = descriptionController.text.trim();

    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter a chain name")),
      );
      return;
    }

    setState(() => isLoading = true);

    final userId = _chainService.currentUserId();
    if (userId == null) {
      setState(() => isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Error: User not logged in")),
      );
      return;
    }

    final chainId = await _chainService.createChain(
      name: name,
      description: description.isEmpty ? "No description" : description,
      period: selectedPeriod,
      members: [userId], // şimdilik sadece kendini ekliyoruz
    );
    if (!mounted) return;

    setState(() => isLoading = false);

    if (chainId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Failed to create chain")),
      );
      return;
    }

    // 🔥 Firestore'dan inviteCode çek
    final snapshot = await FirebaseFirestore.instance
        .collection("chains")
        .doc(chainId)
        .get();

    final inviteCode = snapshot.data()?["inviteCode"] ?? "";

    if (!mounted) return;

    // 🔥 InviteCode ekranına git
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => InviteCodeScreen(
          chainId: chainId,
          inviteCode: inviteCode,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text(
          "New Chain",
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Stack(
        children: [
          // GRADIENT BACKGROUND
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0xFF0A0E25),
                    Color(0xFF142A52),
                    Color(0xFF1F3D78),
                    Color(0xFF6C5ECF),
                  ],
                ),
              ),
            ),
          ),

          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  child: Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.25),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Create a new Chain",
                          style: TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),

                        const SizedBox(height: 24),

                        // CHAIN NAME
                        TextField(
                          controller: nameController,
                          style: const TextStyle(color: Colors.white),
                          decoration: _input("Chain Name"),
                        ),

                        const SizedBox(height: 16),

                        // DESCRIPTION
                        TextField(
                          controller: descriptionController,
                          style: const TextStyle(color: Colors.white),
                          maxLines: 2,
                          decoration: _input("Description"),
                        ),

                        const SizedBox(height: 16),

                        // PERIOD DROPDOWN
                        const Text(
                          "Period",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                          ),
                        ),
                        const SizedBox(height: 8),

                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.25),
                            ),
                          ),
                          child: DropdownButton<String>(
                            value: selectedPeriod,
                            dropdownColor: Colors.black87,
                            icon: const Icon(Icons.arrow_drop_down,
                                color: Colors.white),
                            underline: Container(),
                            style: const TextStyle(color: Colors.white),
                            items: const [
                              DropdownMenuItem(
                                  value: "daily", child: Text("Daily")),
                              DropdownMenuItem(
                                  value: "weekly", child: Text("Weekly")),
                            ],
                            onChanged: (value) {
                              setState(() => selectedPeriod = value!);
                            },
                          ),
                        ),

                        const SizedBox(height: 24),

                        // CREATE BUTTON
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: isLoading ? null : createChain,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFA68FFF),
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            child: isLoading
                                ? const CircularProgressIndicator(
                                    color: Colors.white,
                                  )
                                : const Text(
                                    "Create Chain",
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white,
                                    ),
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  InputDecoration _input(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(color: Colors.white.withOpacity(0.8)),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Colors.white, width: 1.5),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: Colors.white.withOpacity(0.3)),
      ),
    );
  }
}
