import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';

class ChainService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final Uuid _uuid = const Uuid();

  // 1. CREATE CHAIN (Updated with creatorId)
  Future<String?> createChain({
    required String name,
    required String description,
    required String purpose,
    int? duration,
    required String period,
    required List<String> members,
    required List<String> days,
    required String creatorId, // 🔥 FIXED: Now tracks who created the chain
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
        'creatorId':
            creatorId, // 🔥 SAVED: Critical for the 'Delete' button to show up
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

  // 2. FETCH USER CHAINS
  Stream<List<Map<String, dynamic>>> getUserChains(String userId) {
    return _db
        .collection('chains')
        .where('members', arrayContains: userId)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => doc.data()).toList();
    });
  }

  // 3. JOIN CHAIN VIA CODE
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

      if (currentMembers.contains(userId)) return false; // Already a member

      await _db.collection('chains').doc(chainId).update({
        'members': FieldValue.arrayUnion([userId])
      });

      return true;
    } catch (e) {
      print("Error joining chain: $e");
      return false;
    }
  }

  // 🔥 4. AUTOMATIC BADGE SYSTEM (Revised to English)
  // Call this after every successful check-in/completion
  Future<void> updateAutoBadges(String userId, int currentStreak) async {
    try {
      final userDoc = _db.collection('users').doc(userId);
      List<String> earnedBadges = [];

      // Logic aligned with ProfileScreen categories
      if (currentStreak >= 1) earnedBadges.add("Newbie 🥚");
      if (currentStreak >= 3) earnedBadges.add("3-Day Spark ✨");
      if (currentStreak >= 7) earnedBadges.add("Weekly Warrior 🛡️");
      if (currentStreak >= 30) earnedBadges.add("The Legend 🏆");

      // Blue Zone Criterion: If streak 5+ and completed between 05:00-10:00 AM
      int hour = DateTime.now().hour;
      if (currentStreak >= 5 && (hour >= 5 && hour <= 10)) {
        earnedBadges.add("Longevity Master 🌿");
      }

      if (earnedBadges.isNotEmpty) {
        await userDoc.update({
          // arrayUnion: Adds only if not already present in the list
          'earnedBadges': FieldValue.arrayUnion(earnedBadges)
        });
        print("Badges updated in Firestore: $earnedBadges");
      }
    } catch (e) {
      print("Error updating badges: $e");
    }
  }
}
