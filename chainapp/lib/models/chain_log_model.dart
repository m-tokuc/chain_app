import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ChainLog {
  String userId;
  bool done;
  Timestamp periodStart;
  Timestamp periodEnd;
  Timestamp createdAt;

  ChainLog({
    required this.userId,
    required this.done,
    required this.periodStart,
    required this.periodEnd,
    required this.createdAt,
  });

  factory ChainLog.fromMap(Map<String, dynamic> data) {
    return ChainLog(
      userId: data['userId'],
      done: data['done'],
      periodStart: data['periodStart'],
      periodEnd: data['periodEnd'],
      createdAt: data['createdAt'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'done': done,
      'periodStart': periodStart,
      'periodEnd': periodEnd,
      'createdAt': createdAt,
    };
  }
}
