import 'package:flutter/material.dart';

const Color kLabelTextColor = Colors.white;
const Color kAxisTextColor = Colors.black;
const Color kVerticalAxisDottedLineColor = Colors.amber;
const Color kAltitudeThumbnailPathColor = Colors.grey;
const Color kAltitudeThumbnailGradualColor = Color(0xFFE0EFFB);
const Color kAltitudePathColor = Color(0xFF003c60);
const List<Color> kAltitudeGradientColors = [Color(0x821E88E5), Color(0x0C1E88E5)];

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
  final List<AltitudePoint> altitudePointList;

  AltitudeGraphView(this.altitudePointList);

  @override
  _AltitudeGraphViewState createState() => new _AltitudeGraphViewState();
}

class _AltitudeGraphViewState extends State<AltitudeGraphView> {
  // ==== 海拔图数据
  double _maxAltitude = 0.0;
  double _minAltitude = 0.0;
  double _maxVerticalAxisValue = 0.0;
  double _minVerticalAxisValue = 0.0;
  double _verticalAxisInterval = 0.0;

  @override
  void initState() {
    super.initState();

    _initData();
  }

  @override
  void didUpdateWidget(AltitudeGraphView oldWidget) {
    super.didUpdateWidget(oldWidget);

    _initData();
  }

  /// 遍历数据, 取得 最高海拔值, 最低海拔值, 最高Level, 最低Level.
  /// 根据最高海拔值和最低海拔值计算出纵轴最大值和最小值.
  _initData() {
    if (widget.altitudePointList?.isEmpty ?? true) return;

    var firstPoint = widget.altitudePointList.first.point;
    _maxAltitude = firstPoint.dy;
    _minAltitude = firstPoint.dy;
    for (AltitudePoint p in widget.altitudePointList) {
      if (p.point.dy > _maxAltitude) {
        _maxAltitude = p.point.dy;
      } else if (p.point.dy < _minAltitude) {
        _minAltitude = p.point.dy;
      }
    }

    var maxDivide = _maxAltitude - _minAltitude;
    if (maxDivide > 1000) {
      _maxVerticalAxisValue = (_maxAltitude / 1000.0).ceil() * 1000.0;
      _minVerticalAxisValue = (_minAltitude / 1000.0).floor() * 1000.0;
    } else if (maxDivide > 100) {
      _maxVerticalAxisValue = (_maxAltitude / 100.0).ceil() * 100.0;
      _minVerticalAxisValue = (_minAltitude / 100.0).floor() * 100.0;
    } else if (maxDivide > 10) {
      _maxVerticalAxisValue = (_maxAltitude / 10.0).ceil() * 10.0;
      _minVerticalAxisValue = (_minAltitude / 10.0).floor() * 10.0;
    }

    _verticalAxisInterval = (_maxVerticalAxisValue - _minVerticalAxisValue) / 5;
    var absVerticalAxisInterval = _verticalAxisInterval.abs();
    if (absVerticalAxisInterval > 1000) {
      _verticalAxisInterval = (_verticalAxisInterval / 1000.0).floor() * 1000.0;
    } else if (absVerticalAxisInterval > 100) {
      _verticalAxisInterval = (_verticalAxisInterval / 100.0).floor() * 100.0;
    } else if (absVerticalAxisInterval > 10) {
      _verticalAxisInterval = (_verticalAxisInterval / 10.0).floor() * 10.0;
    }
  }

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
                painter: AltitudePainter(
                  widget.altitudePointList,
                  _maxAltitude,
                  _minAltitude,
                  _maxVerticalAxisValue,
                  _minVerticalAxisValue,
                  _verticalAxisInterval,
                ),
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
  // ===== Data
  /// 海拔数据集合
  List<AltitudePoint> _altitudePointList;

  /// 最高海拔
  double _maxAltitude = 0.0;

  /// 最低海拔
  double _minAltitude = 0.0;

  /// 纵轴最大值
  double _maxVerticalAxisValue;

  /// 纵轴最小值
  double _minVerticalAxisValue;

  /// 纵轴点与点之间的间隔
  double _verticalAxisInterval;

  // ===== Paint
  /// 海拔线的画笔
  Paint _linePaint;

  /// 海拔线填充的画笔
  Paint _gradualPaint;

  /// 关键点的画笔
  Paint _signPointPaint;

  /// 纵轴水平虚线的画笔
  Paint _levelLinePaint;

  /// 文字颜色
  Color axisTextColor;

  /// 海拔线填充的梯度颜色
  List<Color> gradientColors;

  AltitudePainter(
    this._altitudePointList,
    this._maxAltitude,
    this._minAltitude,
    this._maxVerticalAxisValue,
    this._minVerticalAxisValue,
    this._verticalAxisInterval, {
    this.axisTextColor = kAxisTextColor,
    this.gradientColors = kAltitudeGradientColors,
    Color pathColor = kAltitudePathColor,
    Color axisLineColor = kVerticalAxisDottedLineColor,
  })  : _linePaint = Paint()
          ..strokeWidth = 1.0
          ..style = PaintingStyle.stroke
          ..color = pathColor,
        _gradualPaint = Paint()
          ..isAntiAlias = false
          ..style = PaintingStyle.fill,
        _signPointPaint = Paint(),
        _levelLinePaint = Paint()
          ..strokeWidth = 1.0
          ..isAntiAlias = false
          ..color = axisLineColor
          ..style = PaintingStyle.stroke;

  @override
  void paint(Canvas canvas, Size size) {}

  @override
  bool shouldRepaint(CustomPainter oldDelegate) {
    return true;
  }
}
