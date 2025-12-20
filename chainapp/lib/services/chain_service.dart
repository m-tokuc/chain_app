import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../screens/home_screen.dart';
q
class ChainService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// 🔥 Aktif kullanıcı ID'si
  String? currentUserId() {
    return FirebaseAuth.instance.currentUser?.uid;
  }

  // -----------------------------------------------------------
  // 🔥 GÜVENİLİR VE ÇAKIŞMASIZ INVITE CODE ÜRETİCİSİ
  // -----------------------------------------------------------

  final Random _rand = Random.secure();
  static const String _chars = "ABCDEFGHJKLMNPQRSTUVWXYZ23456789";

  /// 6 haneli benzersiz davet kodu oluşturur (çakışma kontrolü içerir)
  Future<String> generateUniqueInviteCode() async {
    while (true) {
      final code =
          List.generate(6, (_) => _chars[_rand.nextInt(_chars.length)]).join();

      final exists = await _db
          .collection("chains")
          .where("inviteCode", isEqualTo: code)
          .limit(1)
          .get();

      if (exists.docs.isEmpty) {
        return code; // ✔ eşsiz kod bulundu
      }
    }
  }

  // -----------------------------------------------------------
  // 🔥 Kullanıcının CHAIN listesini getir (HomeScreen için)
  // -----------------------------------------------------------

  Stream<List<Map<String, dynamic>>> getUserChains(String userId) {
    return _db
        .collection("chains")
        .where("members", arrayContains: userId)
        .snapshots()
        .map((snap) =>
            snap.docs.map((doc) => {"id": doc.id, ...doc.data()}).toList());
  }

  // Eski fonksiyon → uyumluluk için burada bırakıldı
  Stream<List<Map<String, dynamic>>> getUserChainsStream(String userId) {
    return getUserChains(userId);
  }

  // -----------------------------------------------------------
  // 🔥 Yeni Chain oluşturma
  // -----------------------------------------------------------

  Future<String?> createChain({
    required String name,
    required String description,
    required String period,
    required List<String> members,
    List<String> days = const [],
  }) async {
    try {
      final userId = currentUserId();
      if (userId == null) return null;

      final inviteCode = await generateUniqueInviteCode();

      final doc = await _db.collection("chains").add({
        "name": name,
        "description": description,
        "period": period,
        "members": members,
        "days": days,
        "inviteCode": inviteCode, // ✔ eşsiz kod
        "createdBy": userId,
        "status": "active",
        "brokenBy": null,
        "brokenAt": null,
        "createdAt": Timestamp.now(),
        "startDate": Timestamp.now(),
      });

      return doc.id;
    } catch (e) {
      print("🔥 CREATE CHAIN ERROR: $e");
      return null;
    }
  }

  // -----------------------------------------------------------
  // 🔥 Kullanıcı kaç CHAIN'de → sayı döner
  // -----------------------------------------------------------

  Future<int> getNumberOfChains(String userId) async {
    try {
      final q = await _db
          .collection("chains")
          .where("members", arrayContains: userId)
          .get();
      return q.docs.length;
    } catch (e) {
      print("🔥 GET NUMBER OF CHAINS ERROR: $e");
      return 0;
    }
  }

  // -----------------------------------------------------------
  // 🔥 Invite code ile CHAIN'e katılma
  // -----------------------------------------------------------

  Future<String?> joinChain(String inviteCode, String userId) async {
    try {
      final snap = await _db
          .collection("chains")
          .where("inviteCode", isEqualTo: inviteCode.toUpperCase())
          .limit(1)
          .get();

      if (snap.docs.isEmpty) {
        return "Chain not found";
      }

      final doc = snap.docs.first;
      final List members = List.from(doc["members"] ?? []);

      if (members.contains(userId)) {
        return "Already in this chain";
      }

      members.add(userId);

      await _db.collection("chains").doc(doc.id).update({
        "members": members,
      });

      return null; // ✔ Success
    } catch (e) {
      print("🔥 JOIN CHAIN ERROR: $e");
      return "Error joining chain";
    }
  }
}
