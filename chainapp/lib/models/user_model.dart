class UserModel {
  // 1. Alan Tanımlamaları

  final String uid; // Firebase Authentication UID'si
  final String email;
  final String username;
  final String? fcmToken; // Bildirimler için eklendi (Çok Önemli!)
  final List<String> groupIds; // Kullanıcının üye olduğu grup ID'leri

  const UserModel({
    required this.uid,
    required this.email,
    required this.username,
    this.fcmToken,
    required this.groupIds,
  });
  // 3. Firestore'dan Veri Okuma Metodu (fromMap)
  factory UserModel.fromMap(Map<String, dynamic> data, String id) {
    List<String> groups = List<String>.from(data['groupIds'] ?? []);

    return UserModel(
      uid: id,
      email: data['email'] as String? ?? '',
      username: data['username'] as String? ?? 'Misafir',
      fcmToken: data['fcmToken'] as String?,
      groupIds: groups,
    );
  }
  // 4. Firestore'a Veri Yazma Metodu (toMap)
  Map<String, dynamic> toMap() {
    return {
      'email': email,
      'username': username,
      'fcmToken': fcmToken,
      'groupIds': groupIds,
      // UID'yi genellikle Firestore'a yazmayız çünkü belge ID'si olarak kullanılır.
    };
  }
}
