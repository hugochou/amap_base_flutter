//
// Created by Yohom Bao on 2018/11/25.
//

#import "AMapViewFactory.h"
#import "MAMapView.h"
#import "MapModels.h"
#import "AMapBasePlugin.h"
#import "UnifiedAssets.h"
#import "MJExtension.h"
#import "NSString+Color.h"
#import "FunctionRegistry.h"
#import "MapHandlers.h"
#import "MamAnnotationView.h"

static NSString *mapChannelName = @"me.yohom/map";
static NSString *markerClickedChannelName = @"me.yohom/marker_clicked";
static NSString *markerDeselectChannelName = @"me.yohom/marker_deselect";
static NSString *cameraChangeChannelName = @"me.yohom/camera_change";
static NSString *cameraChangeFinishChannelName = @"me.yohom/camera_change_finished";

@interface MarkerEventHandler : NSObject <FlutterStreamHandler>
@property(nonatomic) FlutterEventSink sink;
@end

@implementation MarkerEventHandler {
}

- (FlutterError *_Nullable)onListenWithArguments:(id _Nullable)arguments
                                       eventSink:(FlutterEventSink)events {
  _sink = events;
  return nil;
}

- (FlutterError *_Nullable)onCancelWithArguments:(id _Nullable)arguments {
  return nil;
}
@end

@implementation AMapViewFactory {
}

- (NSObject <FlutterMessageCodec> *)createArgsCodec {
  return [FlutterStandardMessageCodec sharedInstance];
}

- (NSObject <FlutterPlatformView> *)createWithFrame:(CGRect)frame
                                     viewIdentifier:(int64_t)viewId
                                          arguments:(id _Nullable)args {
  UnifiedAMapOptions *options = [UnifiedAMapOptions mj_objectWithKeyValues:(NSString *) args];

  AMapView *view = [[AMapView alloc] initWithFrame:frame
                                           options:options
                                    viewIdentifier:viewId];
  return view;
}

@end

@interface AMapView()<UIGestureRecognizerDelegate>
@property (nonatomic, strong) MAMapView *mapView;
@property (nonatomic, strong) MAAnnotationView *annotationView; // 选中的
@end
@implementation AMapView {
  CGRect _frame;
  int64_t _viewId;
  UnifiedAMapOptions *_options;
  FlutterMethodChannel *_methodChannel;
  FlutterEventChannel *_markerClickedEventChannel;
  FlutterEventChannel *_markerDeselectEventChannel;
  FlutterEventChannel *_cameraChangeEventChannel;
  FlutterEventChannel *_cameraChangeFinishEventChannel;
  MarkerEventHandler *_eventHandler;
  MarkerEventHandler *_markerDeselectHandler;
  MarkerEventHandler *_cameraChangeHandler;
  MarkerEventHandler *_cameraChangeFinishHandler;
  MarkerAnnotation *_centerAnnotation;
}

- (instancetype)initWithFrame:(CGRect)frame
                      options:(UnifiedAMapOptions *)options
               viewIdentifier:(int64_t)viewId {
  self = [super init];
  if (self) {
    _frame = frame;
    _viewId = viewId;
    _options = options;

    _mapView = [[MAMapView alloc] initWithFrame:_frame];
    [self setup];
  }
  return self;
}

- (UIView *)view {
  return _mapView;
}

- (void)setup {
  //region 初始化地图配置
  // 尽可能地统一android端的api了, ios这边的配置选项多很多, 后期再观察吧
  // 因为android端的mapType从1开始, 所以这里减去1
  _mapView.mapType = (MAMapType) (_options.mapType - 1);
  _mapView.showsScale = _options.scaleControlsEnabled;
  _mapView.zoomEnabled = _options.zoomGesturesEnabled;
  _mapView.showsCompass = _options.compassEnabled;
  _mapView.scrollEnabled = _options.scrollGesturesEnabled;
  _mapView.cameraDegree = _options.camera.tilt;
  _mapView.rotateEnabled = _options.rotateGesturesEnabled;
  if (_options.camera.target) {
    _mapView.centerCoordinate = [_options.camera.target toCLLocationCoordinate2D];
  }
  _mapView.zoomLevel = _options.camera.zoom;
  // fixme: logo位置设置无效
  CGPoint logoPosition = CGPointMake(0, _mapView.bounds.size.height);
  if (_options.logoPosition == 0) { // 左下角
    logoPosition = CGPointMake(0, _mapView.bounds.size.height);
  } else if (_options.logoPosition == 1) { // 底部中央
    logoPosition = CGPointMake(_mapView.bounds.size.width / 2, _mapView.bounds.size.height);
  } else if (_options.logoPosition == 2) { // 底部右侧
    logoPosition = CGPointMake(_mapView.bounds.size.width, _mapView.bounds.size.height);
  }
  _mapView.logoCenter = logoPosition;
  _mapView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(mapViewDidTaped:)];
    tap.delegate = self;
    [self.mapView addGestureRecognizer:tap];
    
  //endregion

  _methodChannel = [FlutterMethodChannel methodChannelWithName:[NSString stringWithFormat:@"%@%lld", mapChannelName, _viewId]
                                               binaryMessenger:[AMapBasePlugin registrar].messenger];
  __weak __typeof__(self) weakSelf = self;
  [_methodChannel setMethodCallHandler:^(FlutterMethodCall *call, FlutterResult result) {
    __typeof__(self) strongSelf = weakSelf;
    if ([call.method isEqualToString:@"map#setCenterMarkerId"]) {
      NSDictionary *paramDic = call.arguments;
      NSString *markerId = (NSString *) paramDic[@"markerId"];
        NSUInteger index = [strongSelf->_mapView.annotations indexOfObjectPassingTest:^BOOL(MarkerAnnotation *obj, NSUInteger idx, BOOL * _Nonnull stop) {
            return [obj.markerOptions.ID isEqualToString:markerId];
        }];
      if (index != NSNotFound) {
        strongSelf->_centerAnnotation = [strongSelf->_mapView.annotations objectAtIndex:index];
      } else {
        strongSelf->_centerAnnotation = nil;
      }
    } else if ([call.method isEqualToString:@"map#hideInfoWindow"]) {
        if (strongSelf.annotationView != nil && [strongSelf.annotationView isKindOfClass:MamAnnotationView.class]) {
            [((MamAnnotationView *)strongSelf.annotationView) animateToHideAnnowtationViewDetail];
            strongSelf.annotationView = nil;
        }
    } else {
      NSObject <MapMethodHandler> *handler = [MapFunctionRegistry mapMethodHandler][call.method];
      if (handler) {
          [[handler initWith:strongSelf.mapView] onMethodCall:call :result];
      } else {
          result(FlutterMethodNotImplemented);
      }
    }
  }];
  _mapView.delegate = weakSelf;

  _eventHandler = [[MarkerEventHandler alloc] init];
  _markerClickedEventChannel = [FlutterEventChannel eventChannelWithName:[NSString stringWithFormat:@"%@%lld", markerClickedChannelName, _viewId] binaryMessenger:[AMapBasePlugin registrar].messenger];
  [_markerClickedEventChannel setStreamHandler:_eventHandler];
    
  // 取消选中标注事件注册(add by Chris)
  _markerDeselectHandler = [[MarkerEventHandler alloc] init];
  _markerDeselectEventChannel = [FlutterEventChannel eventChannelWithName:[NSString stringWithFormat:@"%@%lld", markerDeselectChannelName, _viewId] binaryMessenger:[AMapBasePlugin registrar].messenger];
  [_markerDeselectEventChannel setStreamHandler:_markerDeselectHandler];

  // 改变地图可视范围事件注册(add by Chris)
  _cameraChangeHandler = [[MarkerEventHandler alloc] init];
  _cameraChangeEventChannel = [FlutterEventChannel eventChannelWithName:[NSString stringWithFormat:@"%@%lld", cameraChangeChannelName, _viewId] binaryMessenger:[AMapBasePlugin registrar].messenger];
  [_cameraChangeEventChannel setStreamHandler:_cameraChangeHandler];
    
  // 改变地图可视范围事件注册(add by Chris)
  _cameraChangeFinishHandler = [[MarkerEventHandler alloc] init];
  _cameraChangeFinishEventChannel = [FlutterEventChannel eventChannelWithName:[NSString stringWithFormat:@"%@%lld", cameraChangeFinishChannelName, _viewId] binaryMessenger:[AMapBasePlugin registrar].messenger];
  [_cameraChangeFinishEventChannel setStreamHandler:_cameraChangeFinishHandler];
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer {
    return YES;
}

- (void)mapViewDidTaped:(UITapGestureRecognizer *)gestureRecognizer {
    CGPoint point = [gestureRecognizer locationInView:self.mapView];
    if (self.annotationView != nil && CGRectContainsPoint(self.annotationView.frame, point)) {
        return;
    }
    
    if (self.annotationView != nil && [self.annotationView isKindOfClass:MamAnnotationView.class]) {
        [self mapView:self.mapView didDeselectAnnotationView:self.annotationView];
    }
}

#pragma MAMapViewDelegate

/// 点击annotation回调
- (void)mapView:(MAMapView *)mapView didSelectAnnotationView:(MAAnnotationView *)view {
    if (self.annotationView != nil && self.annotationView.annotation == view.annotation) {
        return;
    }

    if ([view.annotation isKindOfClass:[MarkerAnnotation class]] && _eventHandler.sink) {
        MarkerAnnotation *annotation = (MarkerAnnotation *) view.annotation;
        _eventHandler.sink([annotation.markerOptions mj_JSONString]);
    }
    
    if ([view isKindOfClass:[MamAnnotationView class]]) {
        if (self.annotationView != nil && [self.annotationView isKindOfClass:MamAnnotationView.class]) {
            [((MamAnnotationView *)self.annotationView) animateToHideAnnowtationViewDetail];
        }
        self.annotationView = view;
        MamAnnotationView *annotationView = (MamAnnotationView*)view;
        [annotationView animateToShowAnnowtationViewDetail];
    }
}

-(void)mapView:(MAMapView *)mapView didDeselectAnnotationView:(MAAnnotationView *)view {
    // 地图范围改变也会触发此方法，且此方法与didSelectAnnotationView是配对出现的
    // 所以避免点击地图空白处无法触发此方法，前面为地图加了tap手势解决
    if ([view.annotation isKindOfClass:[MarkerAnnotation class]] && _markerDeselectHandler.sink) {
        MarkerAnnotation *annotation = (MarkerAnnotation *) view.annotation;
        _markerDeselectHandler.sink([annotation.markerOptions mj_JSONString]);
    }
}

/// 渲染overlay回调
- (MAOverlayRenderer *)mapView:(MAMapView *)mapView rendererForOverlay:(id <MAOverlay>)overlay {
  // 绘制折线
  if ([overlay isKindOfClass:[PolylineOverlay class]]) {
    PolylineOverlay *polyline = (PolylineOverlay *) overlay;

    MAPolylineRenderer *polylineRenderer = [[MAPolylineRenderer alloc] initWithPolyline:polyline];

    UnifiedPolylineOptions *options = [polyline options];

    polylineRenderer.lineWidth = (CGFloat) (options.width * 0.5); // 相同的值, Android的线比iOS的粗
    polylineRenderer.strokeColor = [options.color hexStringToColor];
    polylineRenderer.lineJoinType = (MALineJoinType) options.lineJoinType;
    polylineRenderer.lineCapType = (MALineCapType) options.lineCapType;
    if (options.isDottedLine) {
      polylineRenderer.lineDashType = (MALineDashType) ((MALineCapType) options.dottedLineType + 1);
    } else {
      polylineRenderer.lineDashType = kMALineDashTypeNone;
    }

    return polylineRenderer;
      
  } else if ([overlay isKindOfClass:[CircleOverlay class]]) {
    CircleOverlay *circle = (CircleOverlay *) overlay;
    UnifiedCircleOptions *options = [circle options];
    MACircleRenderer *circleRenderer = [[MACircleRenderer alloc] initWithCircle:circle];
    circleRenderer.lineWidth    = options.strokeWidth;
    circleRenderer.strokeColor  = [options.strokeColor hexStringToColor];
    circleRenderer.fillColor    = [options.fillColor hexStringToColor];
    return circleRenderer;
  }

  return nil;
}

/// 渲染annotation, 就是Android中的marker
- (MAAnnotationView *)mapView:(MAMapView *)mapView viewForAnnotation:(id <MAAnnotation>)annotation {
  if ([annotation isKindOfClass:[MAUserLocation class]]) {
    return nil;
  }

  if ([annotation isKindOfClass:[MAPointAnnotation class]]) {
    static NSString *routePlanningCellIdentifier = @"RoutePlanningCellIdentifier";

    MAAnnotationView *annotationView = [_mapView dequeueReusableAnnotationViewWithIdentifier:routePlanningCellIdentifier];
    if (annotationView == nil) {
      annotationView = [[MAAnnotationView alloc] initWithAnnotation:annotation
                                                    reuseIdentifier:routePlanningCellIdentifier];
    }

    if ([annotation isKindOfClass:[MarkerAnnotation class]]) {
      UnifiedMarkerOptions *options = ((MarkerAnnotation *) annotation).markerOptions;
      annotationView.zIndex = (NSInteger) options.zIndex;
        NSInteger type = 0;
        if ([options.object isKindOfClass:[NSDictionary class]]) type = [[options.object objectForKey:@"type"] integerValue];
        if (options.icon == nil && (type == 1 || type == 2)){
            NSString *identity = @"evAnnotationView";
            MamAnnotationView *customAnnotationView = (MamAnnotationView *)[mapView dequeueReusableAnnotationViewWithIdentifier:identity];
            if (!customAnnotationView) {
                customAnnotationView = [[MamAnnotationView alloc] initWithAnnotation:annotation reuseIdentifier:identity];
            }
            UIImage *bgImg = [UIImage imageWithContentsOfFile:[UnifiedAssets getDefaultAssetPath:@"images/mam_pin_bg.png"]];
            UIImage *icon = [UIImage imageWithContentsOfFile:[UnifiedAssets getDefaultAssetPath:[NSString stringWithFormat:@"images/mam_pin_in_%@.png", @(type)]]];
            [customAnnotationView setupBackImage:bgImg IconImage:icon DetailText:options.title];
            [customAnnotationView setExclusiveTouch:YES];
            return customAnnotationView;
        }
        else {
          if (options.icon != nil) {
            annotationView.image = [UIImage imageWithContentsOfFile:[UnifiedAssets getAssetPath:options.icon]];
          } else {
            annotationView.image = [UIImage imageWithContentsOfFile:[UnifiedAssets getDefaultAssetPath:@"images/default_marker.png"]];
          }
          annotationView.centerOffset = CGPointMake(options.anchorU, options.anchorV);
          annotationView.calloutOffset = CGPointMake(options.infoWindowOffsetX, options.infoWindowOffsetY);
          annotationView.draggable = options.draggable;
          annotationView.canShowCallout = options.infoWindowEnable;
          annotationView.enabled = options.enabled;
          annotationView.highlighted = options.highlighted;
          annotationView.selected = options.selected;
        }
    } else {
      if ([[annotation title] isEqualToString:@"起点"]) {
        annotationView.image = [UIImage imageWithContentsOfFile:[UnifiedAssets getDefaultAssetPath:@"images/amap_start.png"]];
      } else if ([[annotation title] isEqualToString:@"终点"]) {
        annotationView.image = [UIImage imageWithContentsOfFile:[UnifiedAssets getDefaultAssetPath:@"images/amap_end.png"]];
      }
    }

    if (annotationView.image != nil) {
      CGSize size = annotationView.imageView.frame.size;
      annotationView.frame = CGRectMake(annotationView.center.x + size.width / 2, annotationView.center.y, 36, 36);
      annotationView.centerOffset = CGPointMake(0, -18);
    }

    return annotationView;
  }

  return nil;
}

- (void)mapView:(MAMapView *)mapView regionDidChangeAnimated:(BOOL)animated {
    if (_centerAnnotation) {
        _centerAnnotation.coordinate = mapView.centerCoordinate;
    }
    if (_cameraChangeFinishHandler.sink) {
        CLLocationCoordinate2D coor = mapView.centerCoordinate;
        LatLng *latlng = [LatLng new];
        latlng.latitude = coor.latitude;
        latlng.longitude = coor.longitude;
        _cameraChangeFinishHandler.sink([latlng mj_JSONString]);
    }
}

- (void)mapView:(MAMapView *)mapView regionWillChangeAnimated:(BOOL)animated {
    if (mapView.selectedAnnotations.count > 0) {
        [mapView deselectAnnotation:mapView.selectedAnnotations.lastObject animated:NO];
    }
}

- (void)mapViewRegionChanged:(MAMapView *)mapView {
    if (_centerAnnotation) {
        _centerAnnotation.coordinate = mapView.centerCoordinate;
    }
    if (_cameraChangeHandler.sink) {
        CLLocationCoordinate2D coor = mapView.centerCoordinate;
        LatLng *latlng = [LatLng new];
        latlng.latitude = coor.latitude;
        latlng.longitude = coor.longitude;
        _cameraChangeHandler.sink([latlng mj_JSONString]);
    }
}
@end
