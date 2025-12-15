import 'package:flutter/material.dart';

class chainpart extends StatelessWidget {
  final double rotationAngle;
  chainpart({super.key, required this.rotationAngle});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(
          transform: Matrix4.rotationZ(rotationAngle),
          width: 310,
          height: 190,
          decoration: BoxDecoration(
            color: Colors.transparent,
            borderRadius: BorderRadius.all(Radius.circular(150)),
            border: Border.all(
              color: Colors.white,
              width: 4,
            ),
          ),
          child: Stack(children: [
            ShaderMask(
              shaderCallback: (Rect bounds) {
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
                width: 310,
                height: 190,
                decoration: BoxDecoration(
                  color: Colors.transparent,
                  borderRadius: BorderRadius.all(Radius.circular(150)),
                  border: Border.all(
                    color: Colors.blueAccent.withOpacity(0.8),
                    width: 24,
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Container(
                width: 310,
                height: 190,
                decoration: BoxDecoration(
                  color: Colors.transparent,
                  borderRadius: BorderRadius.all(Radius.circular(150)),
                  border: Border.all(
                    color: Colors.white,
                    width: 4,
                  ),
                ),
              ),
            ),
          ]),
        ),
      ],
    );
  }
}

class AreaClipper extends CustomClipper<Rect> {
  final Rect clipRect;
  AreaClipper(this.clipRect);

  @override
  Rect getClip(Size size) {
    return clipRect;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Rect> oldClipper) => true;
}
