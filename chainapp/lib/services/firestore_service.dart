import 'package:cloud_firestore/cloud_firestore.dart'; // FieldValue için gerekli

import '../models/user_model.dart';
import '../models/chain_model.dart';
import '../models/chain_log_model.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ------------------------------------
  // I. KULLANICI İŞLEMLERİ (UserModel)
  // ------------------------------------

  // 1. Yeni kullanıcıyı Firestore'a ekler
  Future<void> createUser(UserModel user) async {
    try {
      await _db.collection('users').doc(user.uid).set(user.toMap());
    } catch (e) {
      print('Kullanıcı oluşturma hatası: $e');
    }
  }

  // 2. Kullanıcı bilgisini gerçek zamanlı okur
  Stream<UserModel> streamUser(String uid) {
    return _db.collection('users').doc(uid).snapshots().map((snapshot) {
      if (!snapshot.exists || snapshot.data() == null) {
        // Belge yoksa veya null ise hatalı varsayılan bir kullanıcı döndür
        return const UserModel(
            uid: 'HATA', email: '', username: 'Hata', groupIds: []);
      }
      return UserModel.fromMap(snapshot.data()!, snapshot.id);
    });
  }

  // ------------------------------------
  // II. ZİNCİR/GRUP İŞLEMLERİ (ChainModel)
  // ------------------------------------

  // 3. Yeni bir grup/zincir oluşturur
  Future<void> createChain(ChainModel chain) async {
    try {
      // Modeldeki id alanını belge ID'si olarak kullanır
      await _db.collection('chains').doc(chain.id).set(chain.toMap());
    } catch (e) {
      print('Zincir oluşturma hatası: $e');
    }
  }

  // 4. Grup/Zincir bilgisini gerçek zamanlı okur
  Stream<ChainModel> streamChain(String chainId) {
    return _db.collection('chains').doc(chainId).snapshots().map((snapshot) {
      // Modelinizdeki fromMap metodunu kullanır
      return ChainModel.fromMap(snapshot.id, snapshot.data()!);
    });
  }

  // ------------------------------------
  // III. CHECK-IN İŞLEMLERİ (ChainLog)
  // ------------------------------------

  // 5. Günlük Check-in işlemini yapar ve Log kaydı oluşturur (Çok Önemli!)
  // Bu metot, projenizin ana özelliğine doğrudan bağlıdır.
  Future<void> performCheckIn(
      String chainId, String userId, ChainLog logData) async {
    try {
      // a) ChainLog koleksiyonuna giriş kaydını ekle
      // Bu, check-in geçmişinin kaydıdır.
      await _db
          .collection('chains')
          .doc(chainId)
          .collection('logs')
          .add(logData.toMap());

      // b) ChainModel'deki ilgili alanları güncelle
      // membersCompletedToday: O gün check-in yapanları takip eden geçici bir liste.
      // Bu liste, Cloud Function ile her gün sıfırlanmalıdır.
      await _db.collection('chains').doc(chainId).update({
        // Geçici bir alan: Bugün tamamlayanlar listesine kullanıcıyı ekle.
        'membersCompletedToday': FieldValue.arrayUnion([userId]),
      });
    } catch (e) {
      print('Check-in işlemi hatası: $e');
    }
  }

  // ------------------------------------
  // IV. EK BİR FONKSİYON: Gruba Katılma
  // ------------------------------------

  // 6. Bir kullanıcıyı gruba ekler (Gruba Katılma İşlemi)
  Future<void> joinChain(String chainId, String userId) async {
    // 1. Kullanıcının userModel'ini güncelle
    await _db.collection('users').doc(userId).update({
      'groupIds': FieldValue.arrayUnion([chainId]),
    });

    // 2. Grubun chainModel'ini güncelle
    await _db.collection('chains').doc(chainId).update({
      'members': FieldValue.arrayUnion([userId]),
    });
  }

  // GÜNLÜK ZİNCİR KONTROLÜ (Telefon Saatiyle)
  Future<void> checkChainsOnAppStart(String userId) async {
    try {
      // DİKKAT: Buradaki ismi '_db' yaptık çünkü senin projende böyle tanımlı.
      final snapshot = await _db
          .collection('chains')
          .where('members', arrayContains: userId)
          .get();

      final now = DateTime.now();
      final String todayStr =
          "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";

      final yesterday = now.subtract(const Duration(days: 1));
      final String yesterdayStr =
          "${yesterday.year}-${yesterday.month.toString().padLeft(2, '0')}-${yesterday.day.toString().padLeft(2, '0')}";

      for (var doc in snapshot.docs) {
        final data = doc.data();
        final String status = data['status'] ?? 'active';
        final String? lastCheckIn = data['lastCheckInDate'];

        if (status == 'broken') continue;

        if (lastCheckIn == null) continue;

        if (lastCheckIn == todayStr) {
          if (status == 'warning') {
            await doc.reference.update({'status': 'active'});
          }
          continue;
        }

        if (lastCheckIn == yesterdayStr) {
          if (now.hour >= 12) {
            if (status != 'broken') {
              await doc.reference.update({
                'status': 'broken',
                'streakCount': 0,
                'brokenAt': FieldValue.serverTimestamp(),
              });
              print("${doc.id} zinciri kırıldı (Öğlen 12'yi geçti).");
            }
          } else {
            if (status != 'warning') {
              await doc.reference.update({'status': 'warning'});
              print("${doc.id} zinciri uyarı moduna geçti.");
            }
          }
        } else {
          if (status != 'broken') {
            await doc.reference.update({
              'status': 'broken',
              'streakCount': 0,
              'brokenAt': FieldValue.serverTimestamp(),
            });
          }
        }
      }
    } catch (e) {
      print("Günlük kontrol hatası: $e");
    }
  }
}
