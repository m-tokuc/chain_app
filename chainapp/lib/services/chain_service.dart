import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';

class ChainService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final Uuid _uuid = const Uuid();

  // 1. ZİNCİR OLUŞTURMA
  Future<String?> createChain({
    required String name,
    required String description,
    required String purpose,
    int? duration,
    required String period,
    required List<String> members,
    required List<String> days,
  }) async {
    try {
      String chainId = _uuid.v4();
      String inviteCode = _uuid.v4().substring(0, 6).toUpperCase();

      await _db.collection('chains').doc(chainId).set({
        'id': chainId,
        'name': name,
        'purpose': purpose,
        'description': description,
        'duration': duration,
        'period': period,
        'members': members,
        'membersCompletedToday': [],
        'days': days,
        'inviteCode': inviteCode,
        'streakCount': 0,
        'createdAt': FieldValue.serverTimestamp(),
        'status': 'active',
      });

      return inviteCode;
    } catch (e) {
      print("Error creating chain: $e");
      return null;
    }
  }

  // 2. KULLANICININ ZİNCİRLERİNİ GETİRME
  Stream<List<Map<String, dynamic>>> getUserChains(String userId) {
    return _db
        .collection('chains')
        .where('members', arrayContains: userId)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => doc.data()).toList();
    });
  }

  // 3. KOD İLE KATILMA (Bu eksikti, eklendi)
  Future<bool> joinChainWithCode(String code, String userId) async {
    try {
      final querySnapshot = await _db
          .collection('chains')
          .where('inviteCode', isEqualTo: code)
          .limit(1)
          .get();

      if (querySnapshot.docs.isEmpty) return false;

      final doc = querySnapshot.docs.first;
      final String chainId = doc.id;
      final List<dynamic> currentMembers = doc['members'];

      if (currentMembers.contains(userId)) return false; // Zaten üye

      await _db.collection('chains').doc(chainId).update({
        'members': FieldValue.arrayUnion([userId])
      });

      return true;
    } catch (e) {
      print("Error joining chain: $e");
      return false;
    }
  }
}
