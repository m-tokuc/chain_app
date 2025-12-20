import 'package:flutter/material.dart';

class ChainPart extends StatelessWidget {
  final double rotationAngle;

  // 1. Yeni Alanlar (Artık ChainPart olarak adlandırdık)
  final String chainName; // Zincir Adı
  final int streakCount; // Zincir Sayısı
  final Color statusColor; // Renk Bilgisi (Durum rengi: Yeşil/Kırmızı/Gri)

  // 2. Kurucuyu const olarak ve required parametrelerle güncelleyin
  const ChainPart({
    super.key,
    required this.rotationAngle,
    required this.chainName,
    required this.streakCount,
    required this.statusColor,
  });

  @override
  Widget build(BuildContext context) {
    // Zincir Halka Genişlik ve Yükseklikleri (Sizin HEAD'inizden aldık)
    const double linkWidth = 310.0;
    const double linkHeight = 190.0;
    const double linkBorderWidth = 28.0; // Kalınlık

    // Transform.rotate kullanarak rotasyonu sağlayın (HEAD mantığı)
    return Transform.rotate(
      angle: rotationAngle,
      child: Container(
        width: linkWidth,
        height: linkHeight,
        child: Stack(
          children: [
            // Dış Çerçeve (HEAD'den)
            Container(
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.all(Radius.circular(150)),
                border: Border.all(
                  color: Colors.black, // Dış Siyah Çerçeve
                  width: 8,
                ),
              ),
            ),

            // Ana Renkli Halka (HEAD ve Arkadaşınızın Gradient Mantığı Birleştirildi)
            // Arkadaşınızın Gradient tasarımını koruyup, StatusColor'ı fallback olarak kullanıyoruz.
            ShaderMask(
              shaderCallback: (Rect bounds) {
                // Burada arkadaşınızın modern Gradient renkleri kullanılıyor
                return const LinearGradient(
                  colors: [
                    Color(0xFF6C5ECF), // Mor
                    Color(0xFF3B82F6), // Mavi
                    Colors.purpleAccent // Açık Mor
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ).createShader(bounds);
              },
              blendMode: BlendMode.srcATop,
              child: Container(
                width: linkWidth,
                height: linkHeight,
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.all(Radius.circular(150)),
                  border: Border.all(
                    // Burada StatusColor kullanılacak, ancak gradyanın üzerine geleceği için görünmez olabilir.
                    // Bu katman için kalınlık ve durumu HEAD'den alalım:
                    color: statusColor.withOpacity(0.8),
                    width: linkBorderWidth,
                  ),
                ),
              ),
            ),

            // İç Siyah Çerçeve (Ortayı belirler - HEAD'den)
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.all(Radius.circular(150)),
                  border: Border.all(
                    color: Colors.white,
                    width: 4,
                  ),
                ),
              ),
            ),

            // Veri Alanları (Halkanın Ortası - HEAD mantığı)
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
                    style: const TextStyle(
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

// AreaClipper sınıfı (Çakışma çözüldü ve korundu)
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
