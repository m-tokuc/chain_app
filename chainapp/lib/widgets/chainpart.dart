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

    // Transform.rotate kullanarak rotasyonu sağlayın
    return Transform.rotate(
      angle: rotationAngle,
      child: Container(
        width: linkWidth,
        height: linkHeight,

        // Zincir halkasının 3 boyutlu/kalın görünümünü oluşturur.
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

            // Ana Renkli Halka (BlueAccent/Durum Rengi)
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
              padding: const EdgeInsets.all(20.0),
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

            // 3. Veri Alanları (Halkanın Ortası - SİZİN HEAD MANTIĞINIZ)
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    chainName, // Zincir Adı
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '$streakCount Days', // Streak Sayısı
                    style: TextStyle(
                      // Not: Streak rengini beyaz yaptım, çünkü ana halka rengini statusColor ile zaten belirledik.
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

// AreaClipper sınıfı (Çakışma çözüldü)
class AreaClipper extends CustomClipper<Rect> {
  final Rect clipRect;
  // const constructor'ı HEAD'den aldık
  const AreaClipper(this.clipRect);

  @override
  Rect getClip(Size size) {
    return clipRect;
  }

  @override
  // false yapmak daha performanslıdır (HEAD'den aldık)
  bool shouldReclip(covariant CustomClipper<Rect> oldClipper) => false;
}
