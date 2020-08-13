//
//  CustomAnnotationView.h
//  amap_base
//
//  Created by Chris on 2020/8/13.
//

#import <MAMapKit/MAMapKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface NormalAnnotationView : MAAnnotationView

-(instancetype)initWithAnnotation:(id)annotation reuseIdentifier:(NSString *)reuseIdentifier;
@end

NS_ASSUME_NONNULL_END
