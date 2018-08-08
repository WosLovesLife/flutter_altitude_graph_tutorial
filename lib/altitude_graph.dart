import 'package:flutter/material.dart';
import 'dart:ui' as ui;

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
  void paint(Canvas canvas, Size size) {
    // 30 是给上下留出的距离, 这样竖轴的最顶端的字就不会被截断, 下方可以用来显示横轴的字
    Size availableSize = Size(size.width, size.height - 30);

    // 50 是给左右留出间距, 避免标签上的文字被截断, 同时避免线图覆盖竖轴的字
    Size pathSize = Size(availableSize.width - 50, availableSize.height);

    // 向下滚动15的距离给顶部留出空间
    canvas.translate(0.0, 15.0);

    // 绘制竖轴
    _drawVerticalAxis(canvas, availableSize);

    // 绘制线图
    canvas.save();
    // 剪裁绘制的窗口, 节省绘制的开销. -24 是为了避免覆盖纵轴
    canvas.clipRect(Rect.fromPoints(Offset.zero, Offset(size.width - 24, size.height)));
    // _offset.dx通常都是向左偏移的量 +15 是为了避免关键点 Label 的文字被截断
    canvas.translate(15.0, 0.0);
    _drawLines(canvas, pathSize);
    canvas.restore();
  }

  /// =========== 绘制纵轴部分

  /// 绘制背景数轴
  /// 根据最大高度和间隔值计算出需要把纵轴分成几段
  void _drawVerticalAxis(Canvas canvas, Size size) {
    var nodeCount = (_maxVerticalAxisValue - _minVerticalAxisValue) / _verticalAxisInterval;

    var interval = size.height / nodeCount;

    canvas.save();
    for (int i = 0; i <= nodeCount; i++) {
      var label = (_maxVerticalAxisValue - (_verticalAxisInterval * i)).toInt();
      _drawVerticalAxisLine(canvas, size, label.toString(), i * interval);
    }
    canvas.restore();
  }

  /// 绘制数轴的一行
  void _drawVerticalAxisLine(Canvas canvas, Size size, String text, double height) {
    var tp = _newVerticalAxisTextPainter(text)..layout();

    // 绘制虚线
    // 虚线的宽度 = 可用宽度 - 文字宽度 - 文字宽度的左右边距
    var dottedLineWidth = size.width - 25.0;
    canvas.drawPath(_newDottedLine(dottedLineWidth, height, 2.0, 2.0), _levelLinePaint);

    // 绘制虚线右边的Text
    // Text的绘制起始点 = 可用宽度 - 文字宽度 - 左边距
    var textLeft = size.width - tp.width - 3;
    tp.paint(canvas, Offset(textLeft, height - tp.height / 2));
  }

  /// 生成虚线的Path
  Path _newDottedLine(double width, double y, double cutWidth, double interval) {
    var path = Path();
    var d = width / (cutWidth + interval);
    path.moveTo(0.0, y);
    for (int i = 0; i < d; i++) {
      path.relativeLineTo(cutWidth, 0.0);
      path.relativeMoveTo(interval, 0.0);
    }
    return path;
  }

  TextPainter textPainter = TextPainter(
    textDirection: TextDirection.ltr,
    maxLines: 1,
  );

  /// 生成纵轴文字的TextPainter
  TextPainter _newVerticalAxisTextPainter(String text) {
    return textPainter
      ..text = TextSpan(
        text: text,
        style: TextStyle(
          color: axisTextColor,
          fontSize: 8.0,
        ),
      );
  }

  /// 绘制海拔图连线部分
  void _drawLines(Canvas canvas, Size size) {
    var pointList = _altitudePointList;
    if (pointList == null || pointList.isEmpty) return;

    double ratioX = size.width / pointList.last.point.dx;
    double ratioY = size.height / (_maxVerticalAxisValue - _minVerticalAxisValue);

    var path = Path();

    var calculateDy = (double dy) {
      return size.height - (dy - _minVerticalAxisValue) * ratioY;
    };

    var firstPoint = pointList.first.point;
    path.moveTo(firstPoint.dx * ratioX, calculateDy(firstPoint.dy));
    for (var p in pointList) {
      path.lineTo(p.point.dx * ratioX, calculateDy(p.point.dy));
    }

    // 绘制线条下面的渐变部分
    double gradientTop = size.height - ratioY * (_maxAltitude - _minVerticalAxisValue);
    _gradualPaint.shader = ui.Gradient.linear(Offset(0.0, gradientTop), Offset(0.0, size.height), gradientColors);
    _drawGradualShadow(path, size, canvas);

    // 先绘制渐变再绘制线,避免线被遮挡住
    canvas.drawPath(path, _linePaint);
  }

  void _drawGradualShadow(Path path, Size size, Canvas canvas) {
    var gradualPath = Path.from(path);
    gradualPath.lineTo(gradualPath.getBounds().width, size.height);
    gradualPath.relativeLineTo(-gradualPath.getBounds().width, 0.0);

    canvas.drawPath(gradualPath, _gradualPaint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) {
    return true;
  }
}
