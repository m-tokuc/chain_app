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
}
