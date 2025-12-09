import 'package:flutter/material.dart';

class chainpart extends StatelessWidget {
  final double rotationAngle;

  // 1. Yeni Alanları Tanımlayın (home_screen.dart'tan gelen veriler)
  final String chainName; // Zincir Adı
  final int streakCount; // Zincir Sayısı
  final Color statusColor; // Renk Bilgisi (Durum rengi: Yeşil/Kırmızı/Gri)

  // 2. Kurucuyu const olarak ve required parametrelerle güncelleyin
  const chainpart({
    super.key,
    required this.rotationAngle,
    required this.chainName,
    required this.streakCount,
    required this.statusColor,
  });

  @override
  Widget build(BuildContext context) {
    // Zincir Halka Genişlik ve Yükseklikleri
    const double linkWidth = 310.0;
    const double linkHeight = 190.0;
    const double linkBorderWidth = 28.0;

    return Transform.rotate(
      // rotationZ, Transform.rotate yerine Matrix4.rotationZ kullanıldığı için kaldırıldı.
      // Ancak orijinal kodunuz Matrix4.rotationZ'yi zaten transform: içinde kullanıyordu.
      // Düzgün çalışması için onu kaldırıp bu widget'ı Transform.rotate ile sarmaladım.
      angle: rotationAngle,
      child: Container(
        width: linkWidth,
        height: linkHeight,

        // Bu iç içe Stack, zincir halkasının 3 boyutlu/kalın görünümünü oluşturur.
        child: Stack(
          children: [
            // Dış Çerçeve (Gölge veya dış katman)
            Container(
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.all(Radius.circular(150)),
                border: Border.all(
                  color: Colors.black, // Dış Siyah Çerçeve
                  width: 8,
                ),
              ),
            ),

            // Ana Renkli Halka (BlueAccent)
            Container(
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.all(Radius.circular(150)),
                border: Border.all(
                  color: statusColor, // Artık statusColor'ı kullanıyoruz
                  width: linkBorderWidth,
                ),
              ),
            ),

            // İç Siyah Çerçeve (Ortayı belirler)
            Padding(
              padding:
                  const EdgeInsets.all(20.0), // Dış çerçeveden içerideki boşluk
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.all(Radius.circular(150)),
                  border: Border.all(
                    color: Colors.black,
                    width: 8,
                  ),
                ),
              ),
            ),

            // 3. Veri Alanları (Halkanın Ortası)
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    // Zincir Adı
                    chainName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    // Streak Sayısı ve Renk
                    '$streakCount Days',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// AreaClipper sınıfı, çakışmanın dışında olduğu için olduğu gibi kalabilir.
class AreaClipper extends CustomClipper<Rect> {
  final Rect clipRect;
  const AreaClipper(this.clipRect); // const ekledim

  @override
  Rect getClip(Size size) {
    return clipRect;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Rect> oldClipper) =>
      false; // Bunu false yapalım, daha performanslı olur.
}
