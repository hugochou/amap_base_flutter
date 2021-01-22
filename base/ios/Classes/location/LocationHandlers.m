//
// Created by Yohom Bao on 2018-12-15.
//

#import "LocationHandlers.h"
#import "MJExtension.h"
#import "AMapBasePlugin.h"
#import "LocationModels.h"

static AMapLocationManager *_locationManager;

@implementation Init

- (instancetype)init {
    self = [super init];
    if (self) {
        _locationManager = [[AMapLocationManager alloc] init];
        if (@available(iOS 14.0, *)) {
            _locationManager.locationAccuracyMode = AMapLocationFullAndReduceAccuracy;
        }
    }
    
    return self;
}


- (void)onMethodCall:(FlutterMethodCall *)call :(FlutterResult)result {
    result(@"成功");
}

@end


#pragma 开始定位

@interface StartLocate()
@property (nonatomic, copy) FlutterEventSink sink;
@property (nonatomic, copy) NSString *purposeKey;
@end

@implementation StartLocate {
    FlutterEventChannel *_locationEventChannel;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        _locationEventChannel = [FlutterEventChannel eventChannelWithName:@"me.yohom/location_event"
                                                          binaryMessenger:[[AMapBasePlugin registrar] messenger]];
        [_locationEventChannel setStreamHandler:self];
    }
    return self;
}


- (void)onMethodCall:(FlutterMethodCall *)call :(FlutterResult)result {
    NSDictionary *params = call.arguments;
    NSString *optionJson = params[@"options"];
    NSLog(@"startLocate ios端: options.toJsonString() -> %@", optionJson);
    
    UnifiedLocationClientOptions *options = [UnifiedLocationClientOptions mj_objectWithKeyValues:optionJson];
    _locationManager.delegate = self;
    
    self.purposeKey = options.purposeKey;
    [options applyTo:_locationManager];
    
    if (options.isOnceLocation) {
        __weak typeof(self) weakSelf = self;
        [_locationManager requestLocationWithReGeocode:YES completionBlock:^(CLLocation *location, AMapLocationReGeocode *regeocode, NSError *error) {
            if (error) {
                result([FlutterError errorWithCode:[NSString stringWithFormat:@"%ld", error.code]
                                           message:error.localizedDescription
                                           details:error.localizedDescription]);
            } else {
                result(@"开始定位");
            }
            
            weakSelf.sink([[[UnifiedAMapLocation alloc] initWithLocation:location
                                                           withRegoecode:regeocode
                                                               withError:error] mj_JSONString]);
        }];
    } else {
        [_locationManager startUpdatingLocation];
    }
}

- (void)amapLocationManager:(AMapLocationManager *)manager didUpdateLocation:(CLLocation *)location reGeocode:(AMapLocationReGeocode *)reGeocode {
    NSLog(@"location:{lat:%f; lon:%f; accuracy:%f}", location.coordinate.latitude, location.coordinate.longitude, location.horizontalAccuracy);
    if (_sink) {
        _sink([[[UnifiedAMapLocation alloc] initWithLocation:location
                                               withRegoecode:reGeocode
                                                   withError:nil] mj_JSONString]);
    }
}

- (void)amapLocationManager:(AMapLocationManager *)manager doRequireLocationAuth:(CLLocationManager *)locationManager {
    [locationManager requestWhenInUseAuthorization];
}

- (void)amapLocationManager:(AMapLocationManager *)manager doRequireTemporaryFullAccuracyAuth:(CLLocationManager *)locationManager completion:(void (^)(NSError *))completion {
    if(@available(iOS 14.0,*)){
        if (_purposeKey) {
          [locationManager requestTemporaryFullAccuracyAuthorizationWithPurposeKey: self.purposeKey completion:^(NSError* _Nullable error) {
              if(completion){
                 completion(error);
              }
          }];
        }
   }
}

- (FlutterError *_Nullable)onListenWithArguments:(id _Nullable)arguments eventSink:(FlutterEventSink)events {
    _sink = events;
    return nil;
}

- (FlutterError *_Nullable)onCancelWithArguments:(id _Nullable)arguments {
    return nil;
}


+ (BOOL)locationServiceAvailable {
    // 查询是否有禁掉查看地理位置信息
    if (![CLLocationManager locationServicesEnabled]) {
        return NO;
    }
    else {
        CLAuthorizationStatus status = [CLLocationManager authorizationStatus];
        if (status == kCLAuthorizationStatusRestricted || status == kCLAuthorizationStatusDenied) {
            return NO;
        }
    }
    return YES;
}
@end


#pragma 结束定位

@implementation StopLocate

- (void)onMethodCall:(FlutterMethodCall *)call :(FlutterResult)result {
    [_locationManager stopUpdatingLocation];
}

@end
