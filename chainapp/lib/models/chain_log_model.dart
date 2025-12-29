import 'package:cloud_firestore/cloud_firestore.dart';

class ChainLog {
  final String userId;
  final DateTime logDate; // HomeScreen bunu arıyor
  final String? note;
  final String? photoUrl;

  ChainLog({
    required this.userId,
    required this.logDate,
    this.note,
    this.photoUrl,
  });

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'logDate': Timestamp.fromDate(logDate),
      'note': note,
      'photoUrl': photoUrl,
    };
  }

  factory ChainLog.fromMap(Map<String, dynamic> map) {
    return ChainLog(
      userId: map['userId'] ?? '',
      logDate: (map['logDate'] as Timestamp).toDate(),
      note: map['note'],
      photoUrl: map['photoUrl'],
    );
  }
}
