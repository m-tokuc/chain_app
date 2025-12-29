// class UserModel {
//   // 1. Alan Tanımlamaları

//   final String uid; // Firebase Authentication UID'si
//   final String email;
//   final String username;
//   final String? fcmToken; // Bildirimler için eklendi (Çok Önemli!)
//   final List<String> groupIds; // Kullanıcının üye olduğu grup ID'leri

//   const UserModel({
//     required this.uid,
//     required this.email,
//     required this.username,
//     this.fcmToken,
//     required this.groupIds,
//   });
//   // 3. Firestore'dan Veri Okuma Metodu (fromMap)
//   factory UserModel.fromMap(Map<String, dynamic> data, String id) {
//     List<String> groups = List<String>.from(data['groupIds'] ?? []);

//     return UserModel(
//       uid: id,
//       email: data['email'] as String? ?? '',
//       username: data['username'] as String? ?? 'Misafir',
//       fcmToken: data['fcmToken'] as String?,
//       groupIds: groups,
//     );
//   }
//   // 4. Firestore'a Veri Yazma Metodu (toMap)
//   Map<String, dynamic> toMap() {
//     return {
//       'email': email,
//       'username': username,
//       'fcmToken': fcmToken,
//       'groupIds': groupIds,
//       // UID'yi genellikle Firestore'a yazmayız çünkü belge ID'si olarak kullanılır.
//     };
//   }
// }

import 'dart:math'; // <--- DÜZELTME: Bu satır en tepede olmalı!
import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String uid;
  final String email;
  final String name;
  final String avatarSeed;
  final int xp;
  // İlk kez değiştirme ödüllerini takip etmek için:
  final bool hasChangedName;
  final bool hasChangedAvatar;

  UserModel({
    required this.uid,
    required this.email,
    required this.name,
    this.avatarSeed = "default_user_seed",
    this.xp = 0,
    this.hasChangedName = false,
    this.hasChangedAvatar = false,
  });

  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    Map data = doc.data() as Map<String, dynamic>;
    return UserModel(
      uid: doc.id,
      email: data['email'] ?? '',
      name: data['name'] ?? 'New Chain User',
      avatarSeed: data['avatarSeed'] ?? 'default_user_seed',
      xp: data['xp'] ?? 0,
      hasChangedName: data['hasChangedName'] ?? false,
      hasChangedAvatar: data['hasChangedAvatar'] ?? false,
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
    };
  }

  // --- GAMIFICATION MANTIĞI ---

  // Mevcut Seviyeyi Hesapla (Her seviye bir öncekinden %50 daha zorlaşır)
  // Formül: XP = 100 * (1.5 ^ (Level - 1))
  int get level {
    if (xp < 100) return 1;
    int currentLvl = 1;
    double reqXp = 100;

    // Sonsuz döngüye girmemesi için basit bir hesaplama
    while (true) {
      double nextLevelReq = reqXp + (100 * pow(1.5, currentLvl));
      if (xp < nextLevelReq) {
        return currentLvl;
      }
      reqXp = nextLevelReq;
      currentLvl++;
    }
  }

  // Bir sonraki seviye için gereken TOPLAM XP (Progress bar sonu için)
  int get xpRequiredForNextLevel {
    int currentLvl = level;
    double totalReq = 0;
    // Şu anki level dahil, bir sonraki levele geçmek için toplam ne kadar XP lazımdı?
    for (int i = 0; i < currentLvl; i++) {
      totalReq += (100 * pow(1.5, i));
    }
    return totalReq.toInt();
  }

  // Bulunduğumuz seviyenin başlangıç XP'si (Progress bar başı için)
  int get xpStartCurrentLevel {
    if (level == 1) return 0;
    int currentLvl = level;
    double totalReq = 0;
    // Bir önceki leveli bitirmek için gereken toplam XP
    for (int i = 0; i < currentLvl - 1; i++) {
      totalReq += (100 * pow(1.5, i));
    }
    return totalReq.toInt();
  }

  // Seviyeye göre Rozet (Badge) Getir
  String get badge {
    final lvl = level;
    if (lvl >= 50) return "The Legend 🔥";
    if (lvl >= 30) return "Time Lord ⏳";
    if (lvl >= 20) return "Unbreakable 🛡️";
    if (lvl >= 15) return "Habit Hunter 🏹";
    if (lvl >= 10) return "Consistent Link 🔗";
    if (lvl >= 5) return "Novice Chain ⛓️";
    return "Newbie 🥚"; // Seviye 1-4 arası
  }
}
