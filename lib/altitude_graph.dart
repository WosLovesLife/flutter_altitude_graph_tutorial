import 'package:flutter/material.dart';

class AltitudeGraphView extends StatefulWidget {
  @override
  _AltitudeGraphViewState createState() => new _AltitudeGraphViewState();
}

class _AltitudeGraphViewState extends State<AltitudeGraphView> {
  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.max,
      children: <Widget>[
        // 主视图
        Expanded(
          child: SizedBox.expand(
            child: GestureDetector(
              child: CustomPaint(
                painter: AltitudePainter(),
              ),
            ),
          ),
        ),

        // 底部控制Bar
        Container(
          width: double.infinity,
          height: 48.0,
          color: Colors.lightGreen,
        ),
      ],
    );
  }
}

class AltitudePainter extends CustomPainter{
  Paint linePaint = Paint()..color = Colors.red;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Rect.fromLTWH(0.0, 0.0, size.width, size.height), linePaint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) {
    return true;
  }
}