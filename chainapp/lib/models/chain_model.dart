import 'package:cloud_firestore/cloud_firestore.dart';

class ChainModel {
  String id;
  String name;
  String description;
  String period; // daily / weekly / custom
  //List<String> members;
  //String status; // active / broken
  String? brokenBy;
  Timestamp? brokenAt;
  Timestamp createdAt;
  Timestamp startDate;
  final List<String> members;
  final int streakCount;
  final String status;

  ChainModel({
    required this.id,
    required this.name,
    required this.description,
    required this.period,
    required this.members,
    required this.status, // Bu alanın 'required' olması önemli
    required this.streakCount, // Yeni eklenen zincir sayacı
    this.brokenBy,
    this.brokenAt,
    required this.createdAt,
    required this.startDate,
  });

  // Firestore’dan model oluşturma
  factory ChainModel.fromMap(String id, Map<String, dynamic> data) {
    // StreakCount değeri yoksa 0 (sıfır) varsayımı yapıyoruz.
    final int streakCount = data['streakCount'] as int? ?? 0;

    return ChainModel(
      id: id,
      name: data['name'],
      description: data['description'],
      period: data['period'],
      members:
          List<String>.from(data['members'] ?? []), // Null kontrolü ekledik
      status: data['status'],

      streakCount: streakCount, // <--- Hata çözüldü! Yeni zorunlu alan eklendi.

      brokenBy: data['brokenBy'],
      brokenAt: data['brokenAt'],
      createdAt: data['createdAt'],
      startDate: data['startDate'],
    );
  }

  // Modele göre Firestore’a yazılabilir map
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'description': description,
      'period': period,
      'members': members,
      'status': status,

      'streakCount': streakCount, // <--- Kaydetme işlemi için eklendi.

      'brokenBy': brokenBy,
      'brokenAt': brokenAt,
      'createdAt': createdAt,
      'startDate': startDate,
    };
  }
}
