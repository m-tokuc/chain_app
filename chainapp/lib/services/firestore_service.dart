import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';
import '../models/chain_model.dart';
import '../models/chain_log_model.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // --- 1. KULLANICI OLUŞTURMA ---
  Future<void> createUser(UserModel user) async {
    await _db.collection('users').doc(user.uid).set(user.toMap());
  }

  // --- 2. KULLANICI TAKİBİ (STREAM) ---
  Stream<UserModel> streamUser(String uid) {
    return _db.collection('users').doc(uid).snapshots().map((snapshot) {
      if (!snapshot.exists)
        return UserModel(uid: 'error', email: '', name: 'Error');
      return UserModel.fromFirestore(snapshot);
    });
  }

  // --- 3. ZİNCİR KONTROL ROBOTU (AÇILIŞTA ÇALIŞIR) ---
  Future<void> checkChainsOnAppStart(String userId) async {
    try {
      final snapshot = await _db
          .collection('chains')
          .where('members', arrayContains: userId)
          .get();
      final now = DateTime.now();

      for (var doc in snapshot.docs) {
        final chainId = doc.id;
        final data = doc.data();
        final String status = data['status'] ?? 'active';

        // Kırıksa atla
        if (status == 'broken') continue;

        // Son logu bul
        final logsSnapshot = await _db
            .collection('chains')
            .doc(chainId)
            .collection('logs')
            .where('userId', isEqualTo: userId)
            .orderBy('logDate', descending: true)
            .limit(1)
            .get();

        DateTime? lastCheckIn;
        if (logsSnapshot.docs.isNotEmpty) {
          lastCheckIn =
              (logsSnapshot.docs.first['logDate'] as Timestamp).toDate();
        }

        if (lastCheckIn == null) continue; // Yeni zincir, henüz işlem yok

        // Gün farkı hesapla
        final difference = now.difference(lastCheckIn).inDays;

        if (difference == 0) continue; // Bugün yapılmış

        // CEZA MANTIĞI
        if (difference == 2) {
          // 2 gün girmemiş -> -30 XP Ceza
          await _applyXPChange(userId, -30);
          print("⚠️ Uyarı: $chainId için 2 gün atlandı! -30 XP");
        } else if (difference >= 3) {
          // 3+ gün -> ZİNCİR KIRILDI
          await _db.collection('chains').doc(chainId).update({
            'status': 'broken',
            'brokenAt': FieldValue.serverTimestamp(),
          });
          print("☠️ Zincir Kırıldı: $chainId");
        }
      }
    } catch (e) {
      print("Zincir kontrol hatası: $e");
    }
  }

  // --- 4. CHECK-IN YAPMA ---
  Future<void> performCheckIn(
      String chainId, String userId, ChainLog logData) async {
    // Log ekle
    await _db
        .collection('chains')
        .doc(chainId)
        .collection('logs')
        .add(logData.toMap());

    // Zinciri güncelle (Bugün yapıldı olarak işaretle ve streak artır)
    await _db.collection('chains').doc(chainId).update({
      'membersCompletedToday': FieldValue.arrayUnion([userId]),
      'streakCount': FieldValue.increment(1),
    });

    // Kullanıcıya XP ver (+10)
    await _applyXPChange(userId, 10);
  }

  // --- YARDIMCI: XP EKLE/ÇIKAR VE ROZET GÜNCELLE ---
  Future<void> _applyXPChange(String userId, int amount) async {
    final userRef = _db.collection('users').doc(userId);

    await _db.runTransaction((transaction) async {
      final snapshot = await transaction.get(userRef);
      if (!snapshot.exists) return;

      int currentXp = snapshot.data()?['xp'] ?? 0;
      int newXp = currentXp + amount;
      if (newXp < 0) newXp = 0; // Eksiye düşmesin

      // Rozet Hesapla
      String newBadge = "Rookie";
      if (newXp >= 10000)
        newBadge = "Legend";
      else if (newXp >= 5000)
        newBadge = "Master";
      else if (newXp >= 2500)
        newBadge = "Elite";
      else if (newXp >= 1000)
        newBadge = "Warrior";
      else if (newXp >= 500) newBadge = "Scout";

      transaction.update(userRef, {
        'xp': newXp,
        'badge': newBadge,
      });
    });
  }

  // --- DİĞER METOTLAR ---
  Stream<List<ChainModel>> streamUserChains(String userId) {
    return _db
        .collection('chains')
        .where('members', arrayContains: userId)
        .snapshots()
        .map((s) =>
            s.docs.map((d) => ChainModel.fromMap(d.id, d.data())).toList());
  }

  // --- ZİNCİRDEN ÜYE ATMA (KICK MEMBER) ---
  Future<void> removeMember(String chainId, String memberId) async {
    // Zincirin 'members' listesinden bu ID'yi sil
    await _db.collection('chains').doc(chainId).update({
      'members': FieldValue.arrayRemove([memberId])
    });
  }

  // --- 5. DÜRTME (NUDGE) SİSTEMİ ---
  Future<void> sendNudge(String senderId, String receiverId, String chainId,
      String chainName) async {
    try {
      // 1. Önce "Bugün zaten dürttüm mü?" kontrolü yapalım (Spam engelleme)
      final today = DateTime.now().toString().split(' ')[0];
      final nudgeId = "${senderId}_${receiverId}_$chainId\_$today";

      final docRef = _db.collection('notifications').doc(nudgeId);
      final docSnap = await docRef.get();

      if (docSnap.exists) {
        // Zaten dürtmüş, bir şey yapma (veya hata fırlat)
        throw Exception("Bu arkadaşını bugün zaten dürttün! ⏳");
      }

      // 2. Bildirimi Kaydet
      await docRef.set({
        'type': 'nudge',
        'senderId': senderId,
        'receiverId': receiverId,
        'chainId': chainId,
        'title': "Hadi ama! ⏳",
        'body': "Zinciri kırma! $chainName için bekleniyorsun.",
        'createdAt': FieldValue.serverTimestamp(),
        'isRead': false,
      });

      print("Dürtme gönderildi! 🔔");
    } catch (e) {
      print("Dürtme hatası: $e");
      rethrow; // Hatayı ekrana basmak için fırlatıyoruz
    }
  }

  // --- 6. SIRALAMA HESAPLAMA (RANK) ---
  // Mantık: Benden daha yüksek XP'ye sahip kaç kişi var? + 1
  Future<int> getUserRank(int myXp) async {
    try {
      // XP'si benim XP'mden büyük olan kullanıcıları say
      AggregateQuerySnapshot query = await _db
          .collection('users')
          .where('xp', isGreaterThan: myXp)
          .count()
          .get();

      int count = query.count ?? 0;

      // Sıralamam = Benden iyilerin sayısı + 1
      return count + 1;
    } catch (e) {
      print("Sıralama hatası: $e");
      return 0; // Hata olursa 0 dönsün
    }
  }
}
