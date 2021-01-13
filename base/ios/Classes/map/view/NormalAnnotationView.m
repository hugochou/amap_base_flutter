//
//  CustomAnnotationView.m
//  amap_base
//
//  Created by Chris on 2020/8/13.
//

#import "NormalAnnotationView.h"
#import "UnifiedAssets.h"

@interface NormalAnnotationView()
@property (nonatomic, strong) UnifiedMarkerOptions *options;
@end

@implementation NormalAnnotationView


-(instancetype)initWithAnnotation:(id)annotation reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithAnnotation:annotation reuseIdentifier:reuseIdentifier];
    if(self)
    {
        self.options = ((MarkerAnnotation *) self.annotation).markerOptions;
        [self setupViews];
    }
    return self;
}

- (void)setSelected:(BOOL)selected {
  [self setupImage:selected];
}

- (void)refresh:(MarkerAnnotation *)annotation {
    self.annotation = annotation;
    self.options = annotation.markerOptions;
    [self setupViews];
}

-(void)setupViews {
  UnifiedMarkerOptions *options = self.options;
  self.zIndex = (NSInteger) options.zIndex;
  NSInteger type = 0;
  if ([options.object isKindOfClass:[NSDictionary class]]) {
      type = [[options.object objectForKey:@"type"] integerValue];
  }

  [self setupImage:self.isSelected];

  self.calloutOffset = CGPointMake(options.infoWindowOffsetX, options.infoWindowOffsetY);
  self.draggable = options.draggable;
  self.canShowCallout = options.infoWindowEnable;
  self.enabled = options.enabled;
  self.highlighted = options.highlighted;
  self.selected = options.selected;
}

- (void)setupImage:(BOOL)selected {
  NSString *imagePath;
  if (self.options.icon != nil) {
    imagePath = [UnifiedAssets getAssetPath:self.options.icon];
    NSString *selectedPath;
    if (selected && (selectedPath = [self getSelectedIconPath])) {
      imagePath=[UnifiedAssets getAssetPath:selectedPath];
    }
  } else {
    imagePath=[UnifiedAssets getDefaultAssetPath:@"images/default_marker.png"];
  }
  
  // 根据图片所在文件夹，获取图片scale
  CGFloat imageScale = [self getImageScale:imagePath];
  
  // 设置大头针图片
  NSData* data = [NSData dataWithContentsOfFile:imagePath];
  UIImage *image = [[UIImage alloc] initWithData:data scale:imageScale];
  self.image = image;
  
  // 设置大头针中心点偏移
  CGFloat scale = [UIScreen mainScreen].scale;
  CGSize size = CGSizeMake(self.image.size.width / scale, self.image.size.height / scale);
  CGPoint anchor = CGPointMake(size.width * self.options.anchorU, size.height * self.options.anchorV);
  self.centerOffset = anchor;
}

- (NSString *)getSelectedIconPath {
  NSString *selectedIcon;
  if ([self.options.object isKindOfClass:[NSDictionary class]]) {
      selectedIcon = [self.options.object objectForKey:@"selectedIcon"];
  }
  return selectedIcon;
}

- (CGFloat)getImageScale:(NSString *)imagePath {
  CGFloat imageScale = 1.0;
  NSError *error;
  NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:@"/flutter_assets/.+/(\\d+(\\.?\\d+)?)x/" options:NSRegularExpressionCaseInsensitive error:&error];
  NSArray *matches = [regex matchesInString:imagePath options:0 range:NSMakeRange(0, [imagePath length])];
  if (matches.count>0 && [matches.firstObject numberOfRanges] >= 2) {
    NSRange matchRange = [[matches firstObject] rangeAtIndex:1];
    NSString *matchString = [imagePath substringWithRange:matchRange];
    imageScale = [matchString floatValue];
  }
  return imageScale;
}
@end
