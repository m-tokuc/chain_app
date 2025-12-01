import 'package:cloud_firestore/cloud_firestore.dart';

class ChainModel {
  String id;
  String name;
  String description;
  String period; // daily / weekly / custom
  List<String> members;
  String status; // active / broken
  String? brokenBy;
  Timestamp? brokenAt;
  Timestamp createdAt;
  Timestamp startDate;

  ChainModel({
    required this.id,
    required this.name,
    required this.description,
    required this.period,
    required this.members,
    required this.status,
    this.brokenBy,
    this.brokenAt,
    required this.createdAt,
    required this.startDate,
  });

  // Firestore’dan model oluşturma
  factory ChainModel.fromMap(String id, Map<String, dynamic> data) {
    return ChainModel(
      id: id,
      name: data['name'],
      description: data['description'],
      period: data['period'],
      members: List<String>.from(data['members']),
      status: data['status'],
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
      'brokenBy': brokenBy,
      'brokenAt': brokenAt,
      'createdAt': createdAt,
      'startDate': startDate,
    };
  }
}
