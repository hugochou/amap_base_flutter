//
//  CustomAnnotationView.h
//  Objection
//
//  Created by Eric on 16/5/25.
//  Copyright © 2016年 Eric. All rights reserved.
//

#import "MAMapKit.h"

@interface MamAnnotationView : MAAnnotationView
+ (CGFloat)animationDuration;
-(void)animateToShowAnnowtationViewDetail;
-(void)animateToHideAnnowtationViewDetail;
-(void)setupBackImage:(UIImage*)backImage
            IconImage:(UIImage*)iconImage
           DetailText:(NSString*)detailText;
-(instancetype)initWithAnnotation:(id)annotation reuseIdentifier:(NSString *)reuseIdentifier;
@end
