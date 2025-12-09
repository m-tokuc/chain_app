import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/user_model.dart';
import '../models/chain_model.dart';
import '../models/chain_log_model.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  Future<void> saveDeviceToken(String userId) async {
    try {
      // 1. İzin İste (iOS için zorunlu, Android için iyi pratik)
      FirebaseMessaging messaging = FirebaseMessaging.instance;
      NotificationSettings settings = await messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );

      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        // 2. Token'ı Al (Telefonun dijital adresi)
        String? token = await messaging.getToken();

        if (token != null) {
          // 3. Veritabanına Kaydet
          await _db.collection('users').doc(userId).update({
            'fcmToken': token, // UserModel'deki alanla aynı isimde olmalı
          });
          print("Bildirim Tokenı Kaydedildi: $token");
        }
      } else {
        print('Kullanıcı bildirim izni vermedi.');
      }
    } catch (e) {
      print("Token hatası: $e");
    }
  }
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
      await _db.collection('chains').doc(chain.id).set(chain.toMap());
    } catch (e) {
      print('Zincir oluşturma hatası: $e');
    }
  }

  // 4. Grup/Zincir bilgisini gerçek zamanlı okur
  Stream<ChainModel> streamChain(String chainId) {
    return _db.collection('chains').doc(chainId).snapshots().map((snapshot) {
      return ChainModel.fromMap(snapshot.id, snapshot.data()!);
    });
  }

  // 📌 EKLENDİ (home_screen.dart'ın talep ettiği metot)
  // Kullanıcının üye olduğu tüm zincirleri gerçek zamanlı okur.
  Stream<List<ChainModel>> streamUserChains(String userId) {
    return _db
        .collection('chains')
        .where('members', arrayContains: userId)
        .snapshots()
        .map((snapshot) {
      // Gelen belgeler listesini (QuerySnapshot), ChainModel listesine çevirir.
      return snapshot.docs.map((doc) {
        return ChainModel.fromMap(doc.id, doc.data());
      }).toList();
    });
  }

  // ------------------------------------
  // III. CHECK-IN İŞLEMLERİ (ChainLog)
  // ------------------------------------

  // 5. Günlük Check-in işlemini yapar ve Log kaydı oluşturur
  Future<void> performCheckIn(
      String chainId, String userId, ChainLog logData) async {
    try {
      // a) ChainLog koleksiyonuna giriş kaydını ekle
      await _db
          .collection('chains')
          .doc(chainId)
          .collection('logs')
          .add(logData.toMap());

      // b) ChainModel'deki ilgili alanları güncelle
      await _db.collection('chains').doc(chainId).update({
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
