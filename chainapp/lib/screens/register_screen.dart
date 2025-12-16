import 'dart:ui';
import 'package:flutter/material.dart';
import '../services/firebase_auth_service.dart';
import 'login_screen.dart';
import 'home_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();

  // Şifre görünürlük durumları
  bool hidePassword = true;
  bool hideConfirmPassword = true;

  final FirebaseAuthService _authService = FirebaseAuthService();
  bool isLoading = false;
  bool isGoogleLoading = false;

  // ---------------- REGISTER LOGIC ----------------
  void registerUser() async {
    String email = emailController.text.trim();
    String password = passwordController.text.trim();
    String confirmPassword = confirmPasswordController.text.trim();

    if (email.isEmpty || password.isEmpty || confirmPassword.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("All fields are required")),
      );
      return;
    }

    if (password != confirmPassword) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Passwords do not match")),
      );
      return;
    }

    setState(() => isLoading = true);

    final user = await _authService.register(email, password);

    setState(() => isLoading = false);

    if (user != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Account created successfully!")),
      );

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Register failed")),
      );
    }
  }

  // ---------------- GOOGLE SIGN-IN ----------------
  Future<void> signInWithGoogle() async {
    setState(() => isGoogleLoading = true);
    final user = await _authService.signInWithGoogle();
    setState(() => isGoogleLoading = false);

    if (user != null && mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const HomeScreen()),
      );
    }
  }

  // ---------------- INPUT DECORATION (Login Style) ----------------
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
    // Panda'nın göz durumu: Herhangi bir şifre alanı gizliyse kapalı olsun
    // veya sadece ana şifreye göre de yapabilirsin. Burada ana şifreye bağladım.
    final bool isPandaEyesClosed = hidePassword;

    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          // 1. ---- BACKGROUND IMAGE ----
          Positioned.fill(
            child: Image.asset(
              'assets/images/hsl.login/hsl.jpg', // Login'deki resim
              fit: BoxFit.cover,
            ),
          ),
          // 2. ---- BLUR FILTER ----
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
                    // =========================================================
                    //                        HEADER
                    // =========================================================
                    const Icon(
                      Icons.link_rounded,
                      color: Color(0xFFA68FFF),
                      size: 40,
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      "Join the Chain",
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const Text(
                      "Start your journey today 🚀",
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white70,
                      ),
                    ),

                    const SizedBox(height: 180), // Panda için yukarıdan boşluk

                    // =========================================================
                    //                  PANDA + REGISTER CARD
                    // =========================================================
                    Stack(
                      clipBehavior: Clip.none,
                      children: [
                        // ---- CARD ----
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
                                    'Create Account',
                                    style: TextStyle(
                                      fontSize: 22,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white.withOpacity(0.95),
                                    ),
                                  ),
                                  const SizedBox(height: 16),

                                  // EMAIL INPUT
                                  TextField(
                                    controller: emailController,
                                    style: const TextStyle(color: Colors.white),
                                    decoration: _inputDecoration("Email"),
                                  ),

                                  const SizedBox(height: 16),

                                  // PASSWORD INPUT
                                  TextField(
                                    controller: passwordController,
                                    obscureText: hidePassword,
                                    style: const TextStyle(color: Colors.white),
                                    decoration: _inputDecoration(
                                      "Password",
                                      suffix: IconButton(
                                        icon: Icon(
                                          hidePassword
                                              ? Icons.visibility_off
                                              : Icons.visibility,
                                          color: Colors.white70,
                                        ),
                                        onPressed: () {
                                          setState(() {
                                            hidePassword = !hidePassword;
                                          });
                                        },
                                      ),
                                    ),
                                  ),

                                  const SizedBox(height: 16),

                                  // CONFIRM PASSWORD INPUT
                                  TextField(
                                    controller: confirmPasswordController,
                                    obscureText: hideConfirmPassword,
                                    style: const TextStyle(color: Colors.white),
                                    decoration: _inputDecoration(
                                      "Confirm Password",
                                      suffix: IconButton(
                                        icon: Icon(
                                          hideConfirmPassword
                                              ? Icons.visibility_off
                                              : Icons.visibility,
                                          color: Colors.white70,
                                        ),
                                        onPressed: () {
                                          setState(() {
                                            hideConfirmPassword =
                                                !hideConfirmPassword;
                                          });
                                        },
                                      ),
                                    ),
                                  ),

                                  const SizedBox(height: 24),

                                  // REGISTER BUTTON
                                  SizedBox(
                                    height: 50,
                                    width: double.infinity,
                                    child: ElevatedButton(
                                      onPressed:
                                          isLoading ? null : registerUser,
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor:
                                            const Color(0xFFA68FFF),
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(18),
                                        ),
                                      ),
                                      child: isLoading
                                          ? const CircularProgressIndicator(
                                              color: Colors.white,
                                              strokeWidth: 2)
                                          : const Text(
                                              "Sign Up",
                                              style: TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.w600,
                                                color: Colors
                                                    .white, // Yazı rengi eklendi
                                              ),
                                            ),
                                    ),
                                  ),

                                  const SizedBox(height: 16),

                                  // GOOGLE SIGN UP
                                  SizedBox(
                                    height: 48,
                                    width: double.infinity,
                                    child: OutlinedButton.icon(
                                      onPressed: isGoogleLoading
                                          ? null
                                          : signInWithGoogle,
                                      icon: isGoogleLoading
                                          ? const SizedBox(
                                              height: 22,
                                              width: 22,
                                              child: CircularProgressIndicator(
                                                  color: Colors.white,
                                                  strokeWidth: 2),
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
                                        isGoogleLoading
                                            ? "Signing up..."
                                            : "Sign up with Google",
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

                        // ---- PANDA IMAGE (Top) ----
                        Positioned(
                          top: -240, // Login'deki ile aynı konumlandırma
                          left: 0,
                          right: 0,
                          child: Center(
                            child: AnimatedSwitcher(
                              duration: const Duration(milliseconds: 300),
                              child: Image.asset(
                                isPandaEyesClosed
                                    ? 'assets/images/panda/panda_open.png'
                                    : 'assets/images/panda/panda_closed.png',
                                key: ValueKey(isPandaEyesClosed),
                                height: 500,
                                fit: BoxFit.contain,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // LOGIN REDIRECT
                    TextButton(
                      onPressed: () {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const LoginScreen()),
                        );
                      },
                      child: const Text(
                        "Already have an account? Login",
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
