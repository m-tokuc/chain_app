import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String uid;
  final String email;
  final String name;
  final String avatarSeed;
  final int xp;

  final bool hasChangedName;
  final bool hasChangedAvatar;

  final List<String> earnedBadges;

  UserModel({
    required this.uid,
    required this.email,
    required this.name,
    this.avatarSeed = "default_user_seed",
    this.xp = 0,
    this.hasChangedName = false,
    this.hasChangedAvatar = false,
    this.earnedBadges = const ['Newbie'],
  });

  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return UserModel(
      uid: doc.id,
      email: data['email'] ?? '',
      name: data['name'] ?? 'New Chain User',
      avatarSeed: data['avatarSeed'] ?? 'default_user_seed',
      xp: data['xp'] ?? 0,
      hasChangedName: data['hasChangedName'] ?? false,
      hasChangedAvatar: data['hasChangedAvatar'] ?? false,
      earnedBadges: List<String>.from(data['earnedBadges'] ?? ['Newbie']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'email': email,
      'name': name,
      'avatarSeed': avatarSeed,
      'xp': xp,
      'hasChangedName': hasChangedName,
      'hasChangedAvatar': hasChangedAvatar,
      'earnedBadges': earnedBadges,
    };
  }

  // --- GAMIFICATION LOGIC ---

  int get level {
    if (xp < 100) return 1;
    int currentLvl = 1;
    double reqXp = 100;

    while (true) {
      double nextLevelReq = reqXp + (100 * pow(1.5, currentLvl));
      if (xp < nextLevelReq) {
        return currentLvl;
      }
      reqXp = nextLevelReq;
      currentLvl++;
    }
  }

  int get xpRequiredForNextLevel {
    int currentLvl = level;
    double totalReq = 0;
    for (int i = 0; i < currentLvl; i++) {
      totalReq += (100 * pow(1.5, i));
    }
    return totalReq.toInt();
  }

  int get xpStartCurrentLevel {
    if (level == 1) return 0;
    int currentLvl = level;
    double totalReq = 0;
    for (int i = 0; i < currentLvl - 1; i++) {
      totalReq += (100 * pow(1.5, i));
    }
    return totalReq.toInt();
  }

  String get badge {
    final lvl = level;
    if (lvl >= 50) return "The Legend 🔥";
    if (lvl >= 30) return "Time Lord ⏳";
    if (lvl >= 20) return "Unbreakable 🛡️";
    if (lvl >= 15) return "Habit Hunter 🏹";
    if (lvl >= 10) return "Consistent Link 🔗";
    if (lvl >= 5) return "Novice Chain ⛓️";
    return "Newbie 🥚";
  }
}
