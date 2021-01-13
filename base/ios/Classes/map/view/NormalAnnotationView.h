//
//  CustomAnnotationView.h
//  amap_base
//
//  Created by Chris on 2020/8/13.
//

#import <MAMapKit/MAMapKit.h>
#import "MapModels.h"

NS_ASSUME_NONNULL_BEGIN

@interface NormalAnnotationView : MAAnnotationView

-(instancetype)initWithAnnotation:(id)annotation reuseIdentifier:(NSString *)reuseIdentifier;
- (void)refresh:(MarkerAnnotation *)annotation;
@end

NS_ASSUME_NONNULL_END
