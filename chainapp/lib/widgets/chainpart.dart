import 'package:flutter/material.dart';

class chainpart extends StatelessWidget {
  double rotationAngle;
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
              color: Colors.black,
              width: 8,
            ),
          ),
          child: Stack(children: [
            Container(
              width: 310,
              height: 190,
              decoration: BoxDecoration(
                color: Colors.transparent,
                borderRadius: BorderRadius.all(Radius.circular(150)),
                border: Border.all(
                  color: Colors.blueAccent,
                  width: 28,
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
                    color: Colors.black,
                    width: 8,
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
