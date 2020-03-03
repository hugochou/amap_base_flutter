import 'package:amap_base/amap_base.dart';
import 'package:amap_base_example/utils/misc.dart';
import 'package:amap_base_example/utils/view.dart';
import 'package:flutter/material.dart';

class DrawCircleScreen extends StatefulWidget {
  DrawCircleScreen();

  factory DrawCircleScreen.forDesignTime() => DrawCircleScreen();

  @override
  _DrawCircleScreenState createState() => _DrawCircleScreenState();
}

class _DrawCircleScreenState extends State<DrawCircleScreen> {
  AMapController _controller;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('绘制圆'),
        backgroundColor: Colors.black,
        centerTitle: true,
      ),
      body: AMapView(
        onAMapViewCreated: (controller) {
          final center = LatLng(22.57574, 113.923214);
          controller.changeLatLng(center);
          controller.setZoomLevel(15);
          _controller = controller;

          loading(
            context,
            controller.addCircle(CircleOptions(
              center: center,
              radius: 500,
              fillColor: const Color(0x331D586B),
              strokeColor: const Color(0xFF66C4E1),
              strokeWidth: 0.5,
            )),
          ).catchError((e) => showError(context, e.toString()));
        },
        amapOptions: AMapOptions(),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}
