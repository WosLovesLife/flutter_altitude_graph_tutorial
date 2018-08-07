import 'package:flutter/material.dart';
import 'package:flutter_altitude_graph/altitude_graph.dart';
import 'package:flutter_altitude_graph/altitude_point_data.dart';

void main() => runApp(new MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return new MaterialApp(
      title: 'Flutter Altitude Graph',
      home: new MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  @override
  _MyHomePageState createState() => new _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  List<AltitudePoint> _altitudePointList;

  @override
  void initState() {
    super.initState();

    _loadData();
  }

  _loadData() {
    parseGeographyData('assets/raw/HUANQINGHAIHU.json').then((list) {
      setState(() {
        _altitudePointList = list;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return new Scaffold(
      appBar: new AppBar(
        title: new Text('Flutter Altitude Graph'),
      ),
      body: AltitudeGraphView(_altitudePointList),
    );
  }
}
