import 'dart:ui';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';

class EditProfileScreen extends StatefulWidget {
  final UserModel user;
  const EditProfileScreen({super.key, required this.user});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  late TextEditingController _nameController;
  late String _currentAvatarSeed;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.user.name);
    _currentAvatarSeed = widget.user.avatarSeed;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _generateNewAvatar() {
    setState(() {
      _currentAvatarSeed = Random().nextInt(999999).toString();
    });
  }

  Future<void> _saveProfile() async {
    if (_nameController.text.trim().isEmpty) return;
    setState(() => _isLoading = true);
    int bonusXp = 0;
    bool newHasChangedName = widget.user.hasChangedName;
    bool newHasChangedAvatar = widget.user.hasChangedAvatar;
    List<String> rewards = [];

    if (_nameController.text.trim() != widget.user.name &&
        !widget.user.hasChangedName) {
      bonusXp += 50;
      newHasChangedName = true;
      rewards.add("Name change bonus: +50 XP!");
    }
    if (_currentAvatarSeed != widget.user.avatarSeed &&
        !widget.user.hasChangedAvatar) {
      bonusXp += 50;
      newHasChangedAvatar = true;
      rewards.add("Avatar change bonus: +50 XP!");
    }

    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.user.uid)
          .update({
        'name': _nameController.text.trim(),
        'avatarSeed': _currentAvatarSeed,
        'xp': widget.user.xp + bonusXp,
        'hasChangedName': newHasChangedName,
        'hasChangedAvatar': newHasChangedAvatar,
      });
      if (!mounted) return;
      Navigator.pop(context);
      if (rewards.isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(rewards.join("\n")),
            backgroundColor: const Color(0xFFA68FFF)));
      }
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Error: $e")));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Widget _buildGlassTextField(
      {required TextEditingController controller,
      required String label,
      required IconData icon}) {
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
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              labelText: label,
              labelStyle: TextStyle(color: Colors.white.withOpacity(0.6)),
              prefixIcon: Icon(icon, color: const Color(0xFFA68FFF)),
              border: InputBorder.none,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        backgroundColor: const Color(0xFF0F172A), // 🔥 GARANTİ: Arka plan rengi
        extendBodyBehindAppBar: true,
        appBar: AppBar(
          title: const Text("Edit Profile",
              style:
                  TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => Navigator.pop(context)),
        ),
        body: Stack(
          fit: StackFit.expand, // 🔥 ÇÖZÜM: Ekranı tam kapla
          children: [
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
            SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    const SizedBox(height: 20),
                    Center(
                      child: Stack(
                        alignment: Alignment.bottomRight,
                        children: [
                          Container(
                            width: 160,
                            height: 160,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                  color:
                                      const Color(0xFFA68FFF).withOpacity(0.6),
                                  width: 4),
                              boxShadow: [
                                BoxShadow(
                                    color: const Color(0xFFA68FFF)
                                        .withOpacity(0.3),
                                    blurRadius: 25)
                              ],
                              image: DecorationImage(
                                image: NetworkImage(
                                    "https://api.dicebear.com/9.x/adventurer/png?seed=$_currentAvatarSeed&backgroundColor=b6e3f4"),
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                          FloatingActionButton.small(
                            onPressed: _generateNewAvatar,
                            backgroundColor: const Color(0xFFA68FFF),
                            child:
                                const Icon(Icons.casino, color: Colors.white),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text("Tap dice to randomize",
                        style: TextStyle(
                            color: Colors.white.withOpacity(0.5),
                            fontSize: 12)),
                    const SizedBox(height: 50),
                    _buildGlassTextField(
                        controller: _nameController,
                        label: "Display Name",
                        icon: Icons.person),
                    const SizedBox(height: 50),
                    SizedBox(
                      width: double.infinity,
                      height: 60,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _saveProfile,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFA68FFF),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(24)),
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
                          child: _isLoading
                              ? const CircularProgressIndicator(
                                  color: Colors.white)
                              : const Text("Save Changes",
                                  style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white)),
                        ),
                      ),
                    ),
                    if (!widget.user.hasChangedName ||
                        !widget.user.hasChangedAvatar)
                      Padding(
                        padding: const EdgeInsets.only(top: 20.0),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.amber.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                                color: Colors.amber.withOpacity(0.3)),
                          ),
                          child: Text("✨ Bonus: +50 XP for first changes!",
                              style: TextStyle(
                                  color: Colors.amber[300],
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600)),
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
