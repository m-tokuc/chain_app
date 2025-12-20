import 'dart:ui';
import 'package:flutter/material.dart';

import '../services/chain_service.dart';
import '../services/firebase_auth_service.dart';
import 'invite_code_screen.dart';

class CreateChainScreen extends StatefulWidget {
  const CreateChainScreen({super.key});

  @override
  State<CreateChainScreen> createState() => _CreateChainScreenState();
}

class _CreateChainScreenState extends State<CreateChainScreen> {
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();

  final ChainService _chainService = ChainService();
  final FirebaseAuthService _authService = FirebaseAuthService();

  bool _isLoading = false;
  String _period = "daily";

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _createChain() async {
    final name = _nameController.text.trim();
    final description = _descriptionController.text.trim();
    final userId = _authService.currentUserId();

    if (name.isEmpty || userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter a chain name")),
      );
      return;
    }

    setState(() => _isLoading = true);

    final inviteCode = await _chainService.generateUniqueInviteCode();

    await _chainService.createChain(
      name: name,
      description: description,
      period: _period,
      members: [userId],
    );

    setState(() => _isLoading = false);

    if (!mounted) return;

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => InviteCodeScreen(inviteCode: inviteCode),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text(
          "Create Chain",
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Stack(
        children: [
          // BACKGROUND
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Color(0xFF0A0E25),
                    Color(0xFF6C5ECF),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
          ),

          SafeArea(
            child: Center(
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
                        border: Border.all(color: Colors.white24),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "Chain Name",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextField(
                            controller: _nameController,
                            style: const TextStyle(color: Colors.white),
                            decoration: _inputDecoration("e.g. Daily Reading"),
                          ),
                          const SizedBox(height: 20),
                          const Text(
                            "Description (optional)",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextField(
                            controller: _descriptionController,
                            style: const TextStyle(color: Colors.white),
                            decoration:
                                _inputDecoration("What is this chain about?"),
                          ),
                          const SizedBox(height: 20),
                          const Text(
                            "Period",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          DropdownButtonFormField<String>(
                            value: _period,
                            dropdownColor: const Color(0xFF1F3D78),
                            items: const [
                              DropdownMenuItem(
                                  value: "daily", child: Text("Daily")),
                              DropdownMenuItem(
                                  value: "weekly", child: Text("Weekly")),
                            ],
                            onChanged: (value) {
                              setState(() {
                                _period = value ?? "daily";
                              });
                            },
                            decoration: _inputDecoration(""),
                            style: const TextStyle(color: Colors.white),
                          ),
                          const SizedBox(height: 30),
                          SizedBox(
                            width: double.infinity,
                            height: 52,
                            child: ElevatedButton(
                              onPressed: _isLoading ? null : _createChain,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFA68FFF),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(18),
                                ),
                              ),
                              child: _isLoading
                                  ? const CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2,
                                    )
                                  : const Text(
                                      "Create Chain",
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
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
          ),
        ],
      ),
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: Colors.white.withOpacity(0.6)),
      filled: true,
      fillColor: Colors.white.withOpacity(0.08),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: BorderSide.none,
      ),
    );
  }
}
