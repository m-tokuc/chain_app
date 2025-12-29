import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Klavye formatlayıcılar için
import '../services/chain_service.dart';
import '../services/firebase_auth_service.dart';
import 'chain_hub_screen.dart';

class JoinChainScreen extends StatefulWidget {
  const JoinChainScreen({super.key});

  @override
  State<JoinChainScreen> createState() => _JoinChainScreenState();
}

class _JoinChainScreenState extends State<JoinChainScreen> {
  // Kontrolcü
  final TextEditingController _codeController = TextEditingController();
  final FocusNode _focusNode = FocusNode(); // Klavyeyi açmak için odak yönetimi

  final ChainService _chainService = ChainService();
  final FirebaseAuthService _authService = FirebaseAuthService();

  bool _isLoading = false;

  @override
  void dispose() {
    _codeController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _joinChain() async {
    final code = _codeController.text.trim().toUpperCase();
    final userId = _authService.currentUserId();

    if (code.length != 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Code must be 6 characters")),
      );
      return;
    }

    if (userId == null) return;

    setState(() => _isLoading = true);

    final success = await _chainService.joinChainWithCode(code, userId);

    setState(() => _isLoading = false);

    if (!mounted) return;

    if (success) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const ChainHubScreen()),
        (route) => false,
      );
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Successfully joined! 🎉"),
          backgroundColor: Color(0xFFA68FFF),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Invalid invite code or already joined."),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  // 🔥 SİHİRLİ KISIM: 6'lı Kutucuk Tasarımı
  Widget _buildCodeInputDisplay() {
    return GestureDetector(
      // Kutulara basınca klavyeyi aç
      onTap: () {
        FocusScope.of(context).requestFocus(_focusNode);
      },
      child: Container(
        color: Colors.transparent, // Tıklamayı yakalamak için
        child: Stack(
          alignment: Alignment.center,
          children: [
            // 1. GÖRÜNMEZ TEXTFIELD (Asıl işi bu yapıyor)
            // Kullanıcı buna yazar, ama biz bunu görmeyiz.
            Opacity(
              opacity: 0.0,
              child: TextField(
                controller: _codeController,
                focusNode: _focusNode,
                maxLength: 6,
                keyboardType: TextInputType.visiblePassword, // Klavye tipi
                textCapitalization:
                    TextCapitalization.characters, // Klavye büyük harf açılır
                style: const TextStyle(color: Colors.transparent),
                cursorColor: Colors.transparent,
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  counterText: "", // Alttaki sayaç yazısını gizle
                ),
                // Sadece Harf ve Sayı izni + Otomatik Büyütme
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9]')),
                  UpperCaseTextFormatter(), // Aşağıda yazdığımız özel sınıf
                ],
                onChanged: (value) {
                  // Her harf yazıldığında ekranı yenile ki kutular dolsun
                  setState(() {});
                },
              ),
            ),

            // 2. GÖRÜNEN KUTUCUKLAR (Süs vitrini)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: List.generate(6, (index) {
                // Bu kutunun içinde harf var mı?
                String char = "";
                if (_codeController.text.length > index) {
                  char = _codeController.text[index];
                }

                // Kutu şu an seçili mi? (Yanıp sönme efekti için)
                bool isFocused = _focusNode.hasFocus &&
                    (index == _codeController.text.length);
                if (index == 5 && _codeController.text.length == 6)
                  isFocused = false;

                return _buildSingleGlassBox(char, isFocused);
              }),
            ),
          ],
        ),
      ),
    );
  }

  // Tek bir baloncuk tasarımı (Cam Efektli)
  Widget _buildSingleGlassBox(String char, bool isFocused) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: 50, // Baloncuk genişliği
          height: 60, // Baloncuk yüksekliği
          decoration: BoxDecoration(
            color: isFocused
                ? const Color(0xFFA68FFF)
                    .withOpacity(0.25) // Seçiliyse biraz daha mor
                : Colors.white.withOpacity(0.1), // Değilse şeffaf
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isFocused
                  ? const Color(0xFFA68FFF)
                  : Colors.white.withOpacity(0.2),
              width: isFocused ? 2 : 1,
            ),
            boxShadow: isFocused
                ? [
                    BoxShadow(
                        color: const Color(0xFFA68FFF).withOpacity(0.3),
                        blurRadius: 12)
                  ]
                : [],
          ),
          child: Center(
            child: Text(
              char,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text("Join Chain"),
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
          // BACKGROUND
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Color(0xFF0A0E25),
                  Color(0xFF142A52),
                  Color(0xFF1F3D78),
                  Color(0xFF6C5ECF)
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),

          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: 40),

                  // ICON
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: const Color(0xFFA68FFF).withOpacity(0.2),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                            color: const Color(0xFFA68FFF).withOpacity(0.3),
                            blurRadius: 30)
                      ],
                    ),
                    child: const Icon(Icons.link,
                        color: Color(0xFFA68FFF), size: 50),
                  ),

                  const SizedBox(height: 30),

                  const Text(
                    "Enter Invite Code",
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    "Enter the 6-character code shared by your friend.",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        color: Colors.white.withOpacity(0.6), fontSize: 14),
                  ),

                  const SizedBox(height: 50),

                  // 🔥 YENİ 6'LI BALONCUK SİSTEMİ BURADA
                  _buildCodeInputDisplay(),

                  const SizedBox(height: 50),

                  // JOIN BUTTON
                  SizedBox(
                    width: double.infinity,
                    height: 60,
                    child: ElevatedButton(
                      onPressed: _isLoading
                          ? null
                          : (_codeController.text.length == 6
                              ? _joinChain
                              : null), // 6 karakter dolmadan basılamasın
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFA68FFF),
                        disabledBackgroundColor:
                            Colors.white.withOpacity(0.1), // Pasif renk
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20)),
                      ),
                      child: _isLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : Text(
                              "Join Chain",
                              style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: _codeController.text.length == 6
                                      ? Colors.white
                                      : Colors.white38),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// 🔥 KÜÇÜK HARFLERİ OTOMATİK BÜYÜTEN YARDIMCI SINIF
class UpperCaseTextFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    return TextEditingValue(
      text: newValue.text.toUpperCase(),
      selection: newValue.selection,
    );
  }
}
