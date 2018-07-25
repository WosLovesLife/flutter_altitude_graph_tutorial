import 'package:flutter/material.dart';

const Color kLabelTextColor = Colors.white;

class AltitudePoint {
  /// 当前点的名字, 例如: xx镇
  String name;

  /// 当前点的级别, 用于根据缩放级别展示不同的地标标签.
  int level;

  /// `point.x`表示当前点距离上一个点的距离. `point.y`表示当前点的海拔
  Offset point;

  /// 地标标签的背景色
  Color color;

  /// 用于绘制文字, 存在这里是为了避免每次绘制重复创建.
  TextPainter textPainter;

  AltitudePoint(this.name, this.level, this.point, this.color, {this.textPainter}) {
    if (name == null || name.isEmpty || textPainter != null) return;

    // 向String插入换行符使文字竖向绘制
    var splitMapJoin = name.splitMapJoin('', onNonMatch: (m) {
      return m.isNotEmpty ? "$m\n" : "";
    });
    splitMapJoin = splitMapJoin.substring(0, splitMapJoin.length - 1);

    this.textPainter = TextPainter(
      textDirection: TextDirection.ltr,
      text: TextSpan(
        text: splitMapJoin,
        style: TextStyle(
          color: kLabelTextColor,
          fontSize: 8.0,
        ),
      ),
    )..layout();
  }
}

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

class AltitudePainter extends CustomPainter {
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
