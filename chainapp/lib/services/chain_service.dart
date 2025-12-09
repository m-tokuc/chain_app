import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ChainService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  String? currentUserId() {
    return FirebaseAuth.instance.currentUser?.uid;
  }

  // 🔥 6 karakterlik davet kodu üret
  String generateInviteCode() {
    const letters = "ABCDEFGHJKLMNPQRSTUVWXYZ123456789";
    return List.generate(6, (index) {
      return letters[(letters.length *
              (index + DateTime.now().millisecondsSinceEpoch) %
              letters.length) %
          letters.length];
    }).join();
  }

  // 🔥 DÜZELTME BURADA YAPILDI: Fonksiyon adı getUserChainsStream olarak güncellendi
  // StartingPage bu ismi arıyor.
  Stream<List<Map<String, dynamic>>> getUserChainsStream(String userId) {
    return _db
        .collection("chains")
        .where("members", arrayContains: userId)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return {
          "id": doc.id,
          ...doc.data(),
        };
      }).toList();
    });
  }

  // 🔥 Chain oluştur
  Future<String?> createChain({
    required String name,
    required String description,
    required String period,
    required List<String> members,
  }) async {
    try {
      final userId = currentUserId();
      if (userId == null) {
        print("❌ ERROR: No authenticated user!");
        return null;
      }

      // 🎯 Davet kodu oluştur
      final code = generateInviteCode();

      final doc = await _db.collection("chains").add({
        "name": name,
        "description": description,
        "period": period,
        "members": members, // ✅ Doğru: Üye listesi kaydediliyor
        "inviteCode": code, 
        "createdBy": userId,
        "status": "active",
        "brokenBy": null,
        "brokenAt": null,
        "createdAt": Timestamp.now(),
        "startDate": Timestamp.now(),
      });

      return doc.id;
    } catch (e) {
      print("🔥 CHAIN CREATE ERROR: $e");
      return null;
    }
  }
  // 🔥 Kullanıcının zincir sayısını al
  Future<int> getNumberOfChains(String userId) async {
    try {
      final querySnapshot = await _db
          .collection("chains")
          .where("members", arrayContains: userId)
          .get();

      return querySnapshot.docs.length;
    } catch (e) {
      print("🔥 GET NUMBER OF CHAINS ERROR: $e");
      return 0;
    }
  }
}


  