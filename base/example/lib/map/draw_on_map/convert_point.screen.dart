import 'package:amap_base/amap_base.dart';
import 'package:flutter/material.dart';

class ConvertPointScreen extends StatefulWidget {
  @override
  _ConvertPointScreenState createState() => _ConvertPointScreenState();
}

class _ConvertPointScreenState extends State<ConvertPointScreen> with SingleTickerProviderStateMixin {
  LatLng _latLng;
  MarkerOptions _targetMarker;
  AMapController _mapCtrl;
  List<String> _markerIds = [];

  AnimationController _animationCtrl;
  Animation<double> _positionAnim;
  Animation<double> _opacityAnim;

  GlobalKey _containerKey = GlobalKey();
  GlobalKey _centerKey = GlobalKey();

  @override
  void initState() {
    super.initState();

    _animationCtrl = AnimationController(duration: Duration(milliseconds: 300), vsync: this);
  }

  @override
  void dispose() {
    _mapCtrl?.dispose();
    _animationCtrl?.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('屏幕坐标转换'),
      ),
      body: Stack(
        fit: StackFit.expand,
        children: <Widget>[
          Column(
            children: <Widget>[
              Flexible(
                child: AMapView(
                  onAMapViewCreated: (controller) async {
                    _mapCtrl = controller;
                    await controller.showIndoorMap(true);
                    await controller.setZoomLevel(19);
                    final center = await _mapCtrl?.getCenterLatlng();

//                    _targetMarker = MarkerOptions(
//                      position: center,
//                      object: 1,
//                      title: '哈哈哈哈哈',
//                      infoWindowEnable: false,
////                      icon: 'images/map_pin_mam.png',
//                    );

                    _targetMarker = MarkerOptions(
                      position: center,
                      icon: 'images/ic_marker_store.png',
                      infoWindowEnable: false,
                      enabled: true,
                      object: {'selectedIcon': 'images/ic_marker_store_selected.png'},
                    );

                    final id = await _mapCtrl.addMarker(_targetMarker);
                    _markerIds = [id];
                    _mapCtrl.setCenterMarkerId(id);

                    _mapCtrl.cameraChangeEvent.listen((data) {
//                      print('======${data}');
                    });
                    _mapCtrl.cameraChangeFinishedEvent.listen((data) async {
                      print('======${data}');
//                      _mapCtrl.removeMarkers(_markerIds);
//                      _targetMarker.position = data;
//                      final id = await _mapCtrl.addMarker(_targetMarker);
//                      _markerIds = [id];
                      _showCenterInfo();
                    });
                  },
                  amapOptions: AMapOptions(),
                ),
              ),
            ],
          ),

//          Center(
//            child: Image.asset('images/home_map_icon_positioning_nor.png', key: _centerKey,),
//          ),

          Positioned(
            left: 0,
            right: 0,
            bottom: _positionAnim?.value ?? 0.0,
            child: Opacity(
              opacity: _opacityAnim?.value ?? 0.0,
              child: Container(
                key: _containerKey,
                padding: const EdgeInsets.all(15),
                color: Colors.white,
                child: Text('lat: ${_latLng?.latitude ?? 0}\nlon:${_latLng?.longitude ?? 0}'),
              ),
            ),
          )
        ],
      ),
    );
  }

//  void _showInfo(MarkerOptions options) async {
//    final containerHeight = 100 + MediaQuery.of(context).padding.bottom;
//
//    final size = _mapKey.currentContext?.size ?? MediaQuery.of(context).size;
//    double x = size.width / 2;
//    double y = size.height - containerHeight;
//    final target = Offset(x, y);
//    final origin = await _mapCtrl.convertToPoint(options.position);
//    final offset = target - origin;
//    final center = Offset(size.width / 2, size.height / 2);
//    final newCenter = center - offset;
//
//    _point = target;
//
//    final coordinate = await _mapCtrl.convertToCoordinate(newCenter);
//    await _mapCtrl.changeLatLng(coordinate);
//
//
//    final textSize = _key.currentContext?.size;
//    _animationCtrl = new AnimationController(duration: const Duration(milliseconds: 300), vsync: this);
//    _animation = new Tween(begin: 30.0, end: (textSize?.width ?? 100) + 20).animate(_animationCtrl)
//      ..addListener(() {
//        setState(() {});
//      });
//    Future.delayed(Duration(milliseconds: 500), () {
//      _animationCtrl.forward();
//    });
//  }

  void _showCenterInfo() async {
    // 获取屏幕中心点坐标
    final screenSize = MediaQuery.of(context).size;
    final center = Offset(screenSize.width / 2, screenSize.height / 2);
    _latLng = await _mapCtrl.convertToCoordinate(center);
    setState(() {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final height = _containerKey.currentContext.size.height;
        _positionAnim = Tween(begin: -(height ?? 0.0), end: 15.0).animate(_animationCtrl);
        _opacityAnim = Tween(begin: 0.0, end: 1.0).animate(_animationCtrl);
        _animationCtrl.forward();
      });
    });
  }
}
