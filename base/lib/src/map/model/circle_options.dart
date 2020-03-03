import 'dart:convert';

import 'package:amap_base/amap_base.dart';
import 'package:amap_base/src/common/misc.dart';
import 'package:flutter/material.dart';
import 'package:meta/meta.dart';

class CircleOptions {
  /// 圆点 [Android, iOS]
  final LatLng center;

  /// 半径 [Android, iOS]
  final double radius;

  /// 填充颜色 [Android, iOS]
  final Color fillColor;

  /// 边框颜色 [Android, iOS]
  final Color strokeColor;

  /// 边框的宽度 [Android, iOS]
  final double strokeWidth;

  CircleOptions({
    @required this.center,
    @required this.radius,
    this.fillColor,
    this.strokeColor,
    this.strokeWidth = 1,
  });

  Map<String, Object> toJson() {
    return {
      'center': center?.toJson(),
      'radius': radius,
      'fillColor': colorToString(fillColor),
      'strokeColor': colorToString(strokeColor),
      'strokeWidth': strokeWidth,
    };
  }

  String toJsonString() => jsonEncode(toJson());

  @override
  String toString() {
    return 'CircleOptions{center: $center, radius: $radius, fillColor: $fillColor, strokeColor: $strokeColor, strokeWidth: $strokeWidth,';
  }
}
