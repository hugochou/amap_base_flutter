import 'dart:io';
import 'dart:math';

import 'package:amap_base/amap_base.dart';
import 'package:flutter/material.dart';

const markerList = const [
  LatLng(30.308802, 120.071179),
  LatLng(30.2412, 120.00938),
  LatLng(30.296945, 120.35133),
  LatLng(30.328955, 120.365063),
  LatLng(30.181862, 120.369183),
];

class DrawPointScreen extends StatefulWidget {
  DrawPointScreen();

  factory DrawPointScreen.forDesignTime() => DrawPointScreen();

  @override
  DrawPointScreenState createState() => DrawPointScreenState();
}

class DrawPointScreenState extends State<DrawPointScreen>
    with SingleTickerProviderStateMixin {
  AMapController _controller;
  MarkerOptions _markerOptions;

  GlobalKey<_HalfViewState> _halfViewKey = GlobalKey<_HalfViewState>();
  double _mapHeight = 0;
  bool _needRequest = true;
  AnimationController _animCtrl;
  Animation<double> _positionAnim;
  Animation<double> _opacityTween;

  @override
  void initState() {
    super.initState();
    _animCtrl =
    AnimationController(duration: Duration(milliseconds: 250), vsync: this)
      ..addListener(() {
        setState(() {});
      });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('绘制点标记'),
        backgroundColor: Colors.black,
        centerTitle: true,
      ),
      body: Builder(
        builder: (context) {
          return Stack(
            fit: StackFit.expand,
            children: [
              LayoutBuilder(
                builder: (context, constraints) {
                  _mapHeight = constraints.maxHeight;
                  return AMapView(
                    onAMapViewCreated: (controller) {
                      _controller = controller;
                      _controller.markerClickedEvent.listen((marker) {
                        _needRequest = false;
                        _showInfo(marker);
                      });
                      _controller.markerDeselectEvent.listen((marker) {
                        _hideInfo();
                      });
                      _controller.cameraChangeEvent.listen((data) {
                        if (_needRequest) _hideInfo();
                      });
                      _controller.cameraChangeFinishedEvent.listen((data) {
                        if (_needRequest)
                          _hideInfo();
                        else
                          _needRequest = true;
                      });
                      controller.addMarkers(
                        markerList
                            .map((latLng) =>
                            MarkerOptions(
                              position: latLng,
                              title: '哈哈',
                              object: {
                                'id': '123',
                                'type': Random().nextInt(2) + 1
                              },
                              infoWindowEnable: Platform.isAndroid,
                            ))
                            .toList(),
                      );

                      controller.changeLatLng(markerList.first);
                      controller.setZoomLevel(12);
                    },
                    amapOptions: AMapOptions(),
                  );
                },
              ),
              Positioned(
                left: 15,
                right: 15,
                bottom: _positionAnim?.value ?? 15.0,
                child: Opacity(
                  opacity: _opacityTween?.value ?? 0.0,
                  child: _HalfView(key: _halfViewKey),
                ),
              ),
            ],
          );
        },
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: FloatingActionButton(
        child: Icon(Icons.add),
        onPressed: () async {
          final nextLatLng = _nextLatLng();
          final type = Random().nextInt(2) + 1;
          await _controller.addMarker(MarkerOptions(
              position: nextLatLng, object: {'type': type}, title: '哈哈哈哈哈'));
          await _controller.changeLatLng(nextLatLng);
        },
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    _animCtrl?.dispose();
    super.dispose();
  }

  LatLng _nextLatLng() {
    final _random = Random();
    double nextLat = (301818 + _random.nextInt(303289 - 301818)) / 10000;
    double nextLng = (1200093 + _random.nextInt(1203691 - 1200093)) / 10000;
    return LatLng(nextLat, nextLng);
  }

  void _showInfo(MarkerOptions marker) {
    _markerOptions = marker;
    _halfViewKey.currentState.content = marker.toString();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final height = _halfViewKey.currentContext.size.height;
      _positionAnim =
          Tween(begin: -(height ?? 0.0), end: 15.0).animate(_animCtrl);
      _opacityTween = Tween(begin: 0.0, end: 1.0).animate(_animCtrl);
      _animCtrl.forward();
    });

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final mapWidth = MediaQuery
          .of(context)
          .size
          .width;
      final center = Offset(mapWidth / 2, _mapHeight / 2);
      final point = await _controller.convertToPoint(marker.position);
      final size = _halfViewKey.currentContext.size;
      final dx = mapWidth / 2 - point.dx;
      final dy = _mapHeight - size.height - 15 - point.dy;
      final latlng =
      await _controller.convertToCoordinate(center.translate(-dx, -dy));

      _controller.changeLatLng(latlng);
    });
  }

  void _hideInfo() {
    if (_animCtrl != null && _animCtrl.status == AnimationStatus.completed) {
      _animCtrl.reverse();
    }
    _controller.hideInfoWindow();
  }
}

class _HalfView extends StatefulWidget {
  _HalfView({Key key}) : super(key: key);

  @override
  _HalfViewState createState() => _HalfViewState();
}

class _HalfViewState extends State<_HalfView> {
  String _content = '';

  String get content => _content;

  set content(String content) {
    _content = content;
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.all(Radius.circular(8))),
      child: Text(content),
    );
  }
}
