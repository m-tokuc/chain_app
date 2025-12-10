import 'dart:ui';
import 'package:flutter/material.dart';
import '../services/chain_service.dart';
import '../services/firebase_auth_service.dart';
import 'home_screen.dart';

class JoinChainScreen extends StatefulWidget {
  const JoinChainScreen({super.key});

  @override
  State<JoinChainScreen> createState() => _JoinChainScreenState();
}

class _JoinChainScreenState extends State<JoinChainScreen> {
  final ChainService chainService = ChainService();
  final FirebaseAuthService authService = FirebaseAuthService();

  List<String> codeChars = List.filled(6, "");
  int currentIndex = 0;

  bool isLoading = false;
  bool errorState = false;

  // -------------------------------
  // JOIN CHAIN LOGIC
  // -------------------------------
  Future<void> joinChain() async {
    final code = codeChars.join();

    if (codeChars.any((c) => c.isEmpty)) {
      triggerError();
      return;
    }

    final userId = authService.currentUserId();
    if (userId == null) {
      triggerError();
      return;
    }

    setState(() => isLoading = true);

    final result = await chainService.joinChain(code, userId);

    setState(() => isLoading = false);

    if (result != null) {
      triggerError();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result)),
      );
      return;
    }

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const HomeScreen()),
    );
  }

  void triggerError() {
    setState(() => errorState = true);
    Future.delayed(const Duration(milliseconds: 700), () {
      if (mounted) setState(() => errorState = false);
    });
  }

  void addChar(String char) {
    if (currentIndex < 6) {
      setState(() {
        codeChars[currentIndex] = char.toUpperCase();
        currentIndex++;
      });
    }
  }

  void removeChar() {
    if (currentIndex > 0) {
      setState(() {
        currentIndex--;
        codeChars[currentIndex] = "";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;

    double boxW = width * 0.125;
    if (boxW < 50) boxW = 50;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title:
            const Text("Join a Chain", style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF0A0E25), Color(0xFF6C5ECF)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
          ),
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                child: Container(
                  margin: const EdgeInsets.all(24),
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: Colors.white24),
                  ),
                  child: Column(
                    children: [
                      const Text(
                        "Enter Invite Code",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: 30),

                      // -------------------------
                      // INPUT BOXES (Shake removed)
                      // -------------------------
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: List.generate(6, (i) {
                          final filled = codeChars[i].isNotEmpty;
                          final focused = i == currentIndex;

                          return AnimatedContainer(
                            duration: const Duration(milliseconds: 180),
                            width: boxW,
                            height: 70,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                width: focused ? 2.5 : 1.3,
                                color: errorState
                                    ? Colors.redAccent
                                    : (focused ? Colors.white : Colors.white54),
                              ),
                              color: Colors.white
                                  .withOpacity(focused ? 0.25 : 0.10),
                              boxShadow: filled
                                  ? [
                                      BoxShadow(
                                        color: const Color(0xFFA68FFF)
                                            .withOpacity(0.6),
                                        blurRadius: 12,
                                        spreadRadius: 2,
                                      )
                                    ]
                                  : [],
                            ),
                            child: Text(
                              codeChars[i],
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 28,
                              ),
                            ),
                          );
                        }),
                      ),

                      const SizedBox(height: 30),

                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: isLoading ? null : joinChain,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFA68FFF),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: isLoading
                              ? const CircularProgressIndicator(
                                  color: Colors.white)
                              : const Text(
                                  "Join Chain",
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                        ),
                      ),

                      const SizedBox(height: 20),

                      TextField(
                        autofocus: true,
                        maxLength: 6,
                        keyboardType: TextInputType.text,
                        textCapitalization: TextCapitalization.characters,
                        style: const TextStyle(color: Colors.transparent),
                        cursorColor: Colors.transparent,
                        decoration: const InputDecoration(
                          counterText: "",
                          border: InputBorder.none,
                        ),
                        onChanged: (value) {
                          if (value.length > currentIndex &&
                              value.length <= 6) {
                            addChar(value[value.length - 1]);
                          } else if (value.length < currentIndex) {
                            removeChar();
                          }
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
