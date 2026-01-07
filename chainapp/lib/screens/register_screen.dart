import 'dart:ui';
import 'package:flutter/material.dart';
import '../services/firebase_auth_service.dart';
import 'login_screen.dart';
import 'chain_hub_screen.dart'; // Bu importu ekledik

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();

  bool hidePassword = true;
  bool hideConfirmPassword = true;

  final FirebaseAuthService _authService = FirebaseAuthService();
  bool isLoading = false;
  bool isGoogleLoading = false;

  // REGISTER
void registerUser() async {
  // ... (kontroller aynı)

  setState(() => isLoading = true);
  
  try {
    final user = await _authService.register(emailController.text, passwordController.text);
    
    // 🔥 KRİTİK: Firebase'den cevap geldikten sonra ekran hala oradaysa işlem yap
    if (!mounted) return; 

    if (user != null) {
      setState(() => isLoading = false);
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Account created successfully!")),
      );

      // Ağır grafik yükünü azaltmak için geçişi 100ms ertele
      await Future.delayed(const Duration(milliseconds: 100));
      
      if (mounted) {
        // Kayıt başarılıysa neden tekrar Login'e gidiyorsun? 
        // Direkt ana sayfaya (ChainHub) gitmek daha akıcı olur.
        Navigator.pushReplacement(
          context, 
          MaterialPageRoute(builder: (_) => const ChainHubScreen()),
        );
      }
    }
  } catch (e) {
    if (mounted) {
      setState(() => isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: ${e.toString()}")),
      );
    }
  }
}

  // GOOGLE SIGN-IN
  Future<void> signInWithGoogle() async {
    setState(() => isGoogleLoading = true);
    final user = await _authService.signInWithGoogle();
    setState(() => isGoogleLoading = false);

    if (user != null && mounted) {
      Navigator.pushReplacement(
        context,
        // DÜZELTME: 'const' kelimesini buradan kaldırdık.
        MaterialPageRoute(builder: (_) => const ChainHubScreen()),
      );
    }
  }

  // Input Style
  InputDecoration _inputDecoration(String label, {Widget? suffix}) {
    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(color: Colors.white.withOpacity(0.8)),
      filled: true,
      fillColor: Colors.white.withOpacity(0.08),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(20)),
      enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.3))),
      focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: const BorderSide(color: Colors.white, width: 1.5)),
      suffixIcon: suffix,
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isPandaEyesClosed = hidePassword && hideConfirmPassword;

    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          Positioned.fill(
              child: Image.asset('assets/images/hsl.login/hsl.jpg',
                  fit: BoxFit.cover)),
          Positioned.fill(
              child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
                  child: Container(color: Colors.black.withOpacity(0.15)))),
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  children: [
                    const Icon(Icons.link_rounded,
                        color: Color(0xFFA68FFF), size: 40),
                    const SizedBox(height: 8),
                    const Text("Join the Chain",
                        style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: Colors.white)),
                    const Text("Start your journey today 🚀",
                        style: TextStyle(fontSize: 14, color: Colors.white70)),
                    const SizedBox(height: 180),
                    Stack(
                      clipBehavior: Clip.none,
                      children: [
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
                                      color: Colors.white.withOpacity(0.25))),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Create Account',
                                      style: TextStyle(
                                          fontSize: 22,
                                          fontWeight: FontWeight.w600,
                                          color:
                                              Colors.white.withOpacity(0.95))),
                                  const SizedBox(height: 16),
                                  TextField(
                                      controller: emailController,
                                      style:
                                          const TextStyle(color: Colors.white),
                                      decoration: _inputDecoration("Email")),
                                  const SizedBox(height: 16),
                                  TextField(
                                      controller: passwordController,
                                      obscureText: hidePassword,
                                      style:
                                          const TextStyle(color: Colors.white),
                                      decoration: _inputDecoration("Password",
                                          suffix: IconButton(
                                              icon: Icon(
                                                  hidePassword
                                                      ? Icons.visibility_off
                                                      : Icons.visibility,
                                                  color: Colors.white70),
                                              onPressed: () => setState(() =>
                                                  hidePassword =
                                                      !hidePassword)))),
                                  const SizedBox(height: 16),
                                  TextField(
                                      controller: confirmPasswordController,
                                      obscureText: hideConfirmPassword,
                                      style:
                                          const TextStyle(color: Colors.white),
                                      decoration: _inputDecoration(
                                          "Confirm Password",
                                          suffix: IconButton(
                                              icon: Icon(
                                                  hideConfirmPassword
                                                      ? Icons.visibility_off
                                                      : Icons.visibility,
                                                  color: Colors.white70),
                                              onPressed: () => setState(() =>
                                                  hideConfirmPassword =
                                                      !hideConfirmPassword)))),
                                  const SizedBox(height: 24),
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
                                                      BorderRadius.circular(
                                                          18))),
                                          child: isLoading
                                              ? const CircularProgressIndicator(
                                                  color: Colors.white,
                                                  strokeWidth: 2)
                                              : const Text("Sign Up",
                                                  style: TextStyle(
                                                      fontSize: 16,
                                                      fontWeight:
                                                          FontWeight.w600,
                                                      color: Colors.white)))),
                                  const SizedBox(height: 16),
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
                                                      strokeWidth: 2))
                                              : const Icon(Icons.g_mobiledata,
                                                  color: Colors.white,
                                                  size: 28),
                                          style: OutlinedButton.styleFrom(
                                              side: BorderSide(
                                                  color: Colors.white
                                                      .withOpacity(0.5)),
                                              shape: RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                          18))),
                                          label: Text(
                                              isGoogleLoading ? "Signing up..." : "Sign up with Google",
                                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500)))),
                                ],
                              ),
                            ),
                          ),
                        ),
                        Positioned(
                            top: -240,
                            left: 0,
                            right: 0,
                            child: IgnorePointer(
                                child: Center(
                                    child: AnimatedSwitcher(
                                        duration:
                                            const Duration(milliseconds: 300),
                                        child: Image.asset(
                                            isPandaEyesClosed
                                                ? 'assets/images/panda/panda_open.png'
                                                : 'assets/images/panda/panda_closed.png',
                                            key: ValueKey(isPandaEyesClosed),
                                            height: 500,
                                            fit: BoxFit.contain))))),
                      ],
                    ),
                    const SizedBox(height: 16),
                    TextButton(
                        onPressed: () => Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                                builder: (_) => const LoginScreen())),
                        child: const Text("Already have an account? Login",
                            style: TextStyle(
                                color: Colors.white,
                                decoration: TextDecoration.underline))),
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
