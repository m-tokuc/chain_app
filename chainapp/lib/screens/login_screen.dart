import 'dart:ui';
import 'package:flutter/material.dart';

import '../services/firebase_auth_service.dart';
import 'home_screen.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _authService = FirebaseAuthService();

  bool _isEmailLoading = false;
  bool _isGoogleLoading = false;
  bool _obscurePassword = true; // panda göz açık / kapalı

  // ---------------- EMAIL LOGIN ----------------
  Future<void> _loginWithEmail() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please fill in email and password.")),
      );
      return;
    }

    setState(() => _isEmailLoading = true);
    final user = await _authService.login(email, password);
    setState(() => _isEmailLoading = false);

    if (user != null && mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const HomeScreen()),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Login failed. Try again.")),
      );
    }
  }

  // ---------------- GOOGLE LOGIN ----------------
  Future<void> _loginWithGoogle() async {
    setState(() => _isGoogleLoading = true);
    final user = await _authService.signInWithGoogle();
    setState(() => _isGoogleLoading = false);

    if (user != null && mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const HomeScreen()),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Google sign-in failed")),
      );
    }
  }

  // ---------------- INPUT DECORATION ----------------
  InputDecoration _inputDecoration(String label, {Widget? suffix}) {
    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(color: Colors.white.withOpacity(0.8)),
      filled: true,
      fillColor: Colors.white.withOpacity(0.08),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(20),
        borderSide: BorderSide(color: Colors.white.withOpacity(0.3)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(20),
        borderSide: const BorderSide(color: Colors.white, width: 1.5),
      ),
      suffixIcon: suffix,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          // ---- BACKGROUND ----
          Positioned.fill(
            child: Image.asset(
              'assets/images/hsl.login/hsl.jpg',
              fit: BoxFit.cover,
            ),
          ),
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
              child: Container(color: Colors.black.withOpacity(0.15)),
            ),
          ),

          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  children: [
                    // ================================================================
                    //                         TITLE AREA
                    // ================================================================
                    const Icon(
                      Icons.link_rounded,
                      color: Color(0xFFA68FFF),
                      size: 40,
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      "Chain App",
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      "Don’t break the chain 👣",
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white70,
                      ),
                    ),

                    const SizedBox(height: 200),

                    // ================================================================
                    //                     PANDA + LOGIN CARD
                    // ================================================================
                    Stack(
                      clipBehavior: Clip.none,
                      children: [
                        // ---- LOGIN CARD BELOW ----
                        ClipRRect(
                          borderRadius: BorderRadius.circular(24),
                          child: BackdropFilter(
                            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                            child: Container(
                              padding:
                                  const EdgeInsets.fromLTRB(20, 80, 20, 20),
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.25),
                                borderRadius: BorderRadius.circular(24),
                                border: Border.all(
                                  color: Colors.white.withOpacity(0.25),
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Login',
                                    style: TextStyle(
                                      fontSize: 22,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white.withOpacity(0.95),
                                    ),
                                  ),
                                  const SizedBox(height: 16),

                                  // EMAIL INPUT
                                  TextField(
                                    controller: _emailController,
                                    style: const TextStyle(color: Colors.white),
                                    decoration: _inputDecoration("Email"),
                                  ),

                                  const SizedBox(height: 16),

                                  // PASSWORD INPUT + EYE ICON
                                  TextField(
                                    controller: _passwordController,
                                    obscureText: _obscurePassword,
                                    style: const TextStyle(color: Colors.white),
                                    decoration: _inputDecoration(
                                      "Password",
                                      suffix: IconButton(
                                        icon: Icon(
                                          _obscurePassword
                                              ? Icons.visibility_off
                                              : Icons.visibility,
                                          color: Colors.white70,
                                        ),
                                        onPressed: () {
                                          setState(() {
                                            _obscurePassword =
                                                !_obscurePassword;
                                          });
                                        },
                                      ),
                                    ),
                                  ),

                                  const SizedBox(height: 20),

                                  // LOGIN BUTTON
                                  SizedBox(
                                    height: 50,
                                    width: double.infinity,
                                    child: ElevatedButton(
                                      onPressed: _isEmailLoading
                                          ? null
                                          : _loginWithEmail,
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor:
                                            const Color(0xFFA68FFF),
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(18),
                                        ),
                                      ),
                                      child: _isEmailLoading
                                          ? const CircularProgressIndicator(
                                              color: Colors.white,
                                              strokeWidth: 2)
                                          : const Text(
                                              "Login",
                                              style: TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                    ),
                                  ),

                                  const SizedBox(height: 16),

                                  // GOOGLE LOGIN
                                  SizedBox(
                                    height: 48,
                                    width: double.infinity,
                                    child: OutlinedButton.icon(
                                      onPressed: _isGoogleLoading
                                          ? null
                                          : _loginWithGoogle,
                                      icon: _isGoogleLoading
                                          ? const SizedBox(
                                              height: 22,
                                              width: 22,
                                              child: CircularProgressIndicator(
                                                color: Colors.white,
                                                strokeWidth: 2,
                                              ),
                                            )
                                          : const Icon(Icons.g_mobiledata,
                                              color: Colors.white, size: 28),
                                      style: OutlinedButton.styleFrom(
                                        side: BorderSide(
                                          color: Colors.white.withOpacity(0.5),
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(18),
                                        ),
                                      ),
                                      label: Text(
                                        _isGoogleLoading
                                            ? "Signing in..."
                                            : "Continue with Google",
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),

                        // ================================================================
                        //                           PANDA
                        // ================================================================
                        Positioned(
                          top: -240,
                          left: 0,
                          right: 0,
                          child: Center(
                            child: AnimatedSwitcher(
                              duration: const Duration(milliseconds: 300),
                              child: Image.asset(
                                _obscurePassword
                                    ? 'assets/images/panda/panda_open.png'
                                    : 'assets/images/panda/panda_closed.png',
                                key: ValueKey(_obscurePassword),
                                height: 500,
                                fit: BoxFit.contain,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // REGISTER BUTTON
                    TextButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const RegisterScreen(),
                          ),
                        );
                      },
                      child: const Text(
                        "Create an account",
                        style: TextStyle(
                          color: Colors.white,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    )
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
