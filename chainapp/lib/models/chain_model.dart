import 'package:cloud_firestore/cloud_firestore.dart';

class ChainModel {
  final String id;
  final String name;
  final String purpose;
  final String description;
  final int? duration;
  final String creatorId;
  final String? inviteCode; // ✅ EKLENDİ
  final List<String> members;
  final List<String> membersCompletedToday;
  final String status;
  final int streakCount;
  final DateTime createdAt;
  final List<String> completedDates;

  ChainModel({
    required this.id,
    required this.name,
    this.purpose = '',
    required this.description,
    this.duration,
    required this.creatorId,
    this.inviteCode, // ✅ EKLENDİ
    required this.members,
    required this.membersCompletedToday,
    this.status = 'active',
    this.streakCount = 0,
    required this.createdAt,
    this.completedDates = const [],
  });

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'purpose': purpose,
      'description': description,
      'duration': duration,
      'creatorId': creatorId,
      'inviteCode': inviteCode, // ✅ EKLENDİ
      'members': members,
      'membersCompletedToday': membersCompletedToday,
      'status': status,
      'streakCount': streakCount,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  factory ChainModel.fromMap(String id, Map<String, dynamic> map) {
    return ChainModel(
      id: id,
      name: map['name'] ?? '',
      purpose: map['purpose'] ?? '',
      description: map['description'] ?? '',
      duration: map['duration'],
      creatorId: map['creatorId'] ?? '',
      inviteCode: map['inviteCode'], // ✅ EKLENDİ
      members: List<String>.from(map['members'] ?? []),
      membersCompletedToday:
          List<String>.from(map['membersCompletedToday'] ?? []),
      status: map['status'] ?? 'active',
      streakCount: map['streakCount'] ?? 0,
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      completedDates: List<String>.from(map['completedDates'] ?? []),
    );
  }
}
