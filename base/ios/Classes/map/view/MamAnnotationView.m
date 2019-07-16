//
//  CustomAnnotationView.m
//  Objection
//
//  Created by Eric on 16/5/25.
//  Copyright © 2016年 Eric. All rights reserved.
//

#import "MamAnnotationView.h"
#import "NSString+Color.h"

#define AnimationDuration 0.425
#define GAP 1.5
#define CIRCLE_R 30.0
#define ICON_WIDTH 21.0
#define VIEW_WIDTH 30.0
#define VIEW_HEIGHT 37.5

@interface MamAnnotationView()
@property(nonatomic,strong) UIView *detailView;
@property(nonatomic,strong) UIImageView *backImageView;
@property(nonatomic,strong) UIImageView *iconImageView;
@property(nonatomic,strong) UILabel *textLabel;
@property(nonatomic) CGFloat originalWidth;
@property(nonatomic) BOOL open;
@end
@implementation MamAnnotationView

-(instancetype)initWithAnnotation:(id)annotation reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithAnnotation:annotation reuseIdentifier:reuseIdentifier];
    if(self)
    {
        self.canShowCallout = NO;
        [self setExclusiveTouch:YES];
        [self setupViews];
        
    }
    return self;
}

-(void)setupBackImage:(UIImage*)backImage
            IconImage:(UIImage*)iconImage
           DetailText:(NSString*)detailText
{
    self.backImageView.image = backImage;
    self.iconImageView.image = iconImage;
    self.textLabel.text = detailText;
    if(!_open) [self refreshView];
    else {
        [_textLabel sizeToFit];
        self.open = NO;
        [self animateToShowAnnowtationViewDetail];
    }
}
-(void)refreshView
{
//    [_backImageView sizeToFit];
    [_textLabel sizeToFit];
    _backImageView.frame = CGRectMake(0, 0, VIEW_WIDTH, VIEW_HEIGHT);
    self.frame = CGRectMake(0, 0, _backImageView.frame.size.width, _backImageView.frame.size.height);
    self.originalWidth = self.frame.size.width;
    self.open = NO;
    self.centerOffset = CGPointMake(0, -self.frame.size.height/2);
    _detailView.frame = CGRectMake((self.frame.size.width - CIRCLE_R)/2 + GAP, 0, CIRCLE_R - GAP * 2, CIRCLE_R - GAP);
    _detailView.layer.cornerRadius = _detailView.frame.size.width/2 ;
    _detailView.layer.allowsEdgeAntialiasing = YES;
    _iconImageView.center = CGPointMake(_detailView.frame.size.width/2, _detailView.frame.size.height/2);
    _textLabel.center = _iconImageView.center;
    CGRect textLabelFrame = _textLabel.frame;
    textLabelFrame.origin.x = _iconImageView.frame.origin.x + _iconImageView.frame.size.width;
    _textLabel.frame = textLabelFrame;
    _textLabel.alpha = 0;
    
}
-(void)setupViews
{
    if(!_backImageView)
    {
        self.backImageView = [[UIImageView alloc]init];
        [self addSubview:_backImageView];
    }
    if(!_detailView)
    {
        self.detailView = [[UIView alloc]init];
        _detailView.backgroundColor = [@"FF2D2D2D" hexStringToColor];
        [self addSubview:_detailView];
        _detailView.clipsToBounds = YES;
        self.iconImageView = [[UIImageView alloc]initWithFrame:CGRectMake(0, 0, ICON_WIDTH, ICON_WIDTH)];
        
        [_detailView addSubview:_iconImageView];
        self.textLabel = [[UILabel alloc]init];
        [_detailView addSubview:_textLabel];
        _textLabel.textColor = [UIColor whiteColor];
        _textLabel.font = [UIFont systemFontOfSize:15];
    }
    
}
-(void)animateToShowAnnowtationViewDetail
{
    if(!_open)
    {
        CGFloat targetWidth =0.6 * ICON_WIDTH /2 + _textLabel.frame.size.width + CIRCLE_R - 4;
        
        [UIView animateKeyframesWithDuration:AnimationDuration delay:0 options:0 animations:^{
            [UIView addKeyframeWithRelativeStartTime:0 relativeDuration:0.35 animations:^{
                _iconImageView.transform = CGAffineTransformScale(CGAffineTransformIdentity, 0.6, 0.6);
            }];
            
            [UIView addKeyframeWithRelativeStartTime:0.35 relativeDuration:0.65 animations:^{
                self.frame = CGRectMake(self.frame.origin.x - (targetWidth - self.frame.size.width)/2, self.frame.origin.y, targetWidth, self.frame.size.height);
                _detailView.frame = CGRectMake(0, 0, self.frame.size.width, _detailView.frame.size.height);
                _backImageView.frame = CGRectMake((self.frame.size.width - _backImageView.frame.size.width)/2, 0, _backImageView.frame.size.width, _backImageView.frame.size.height);
            }];
            
            [UIView addKeyframeWithRelativeStartTime:0.5 relativeDuration:0.5 animations:^{
                _textLabel.alpha = 1;
            }];
            
        } completion:nil];
        self.open = YES;
    }
}
-(void)animateToHideAnnowtationViewDetail
{
    if(_open)
    {
        [UIView animateKeyframesWithDuration:AnimationDuration delay:0 options:0 animations:^{
            
            [UIView addKeyframeWithRelativeStartTime:0 relativeDuration:0.3 animations:^{
                _textLabel.alpha = 0;
            }];
            
            [UIView addKeyframeWithRelativeStartTime:0.2 relativeDuration:0.5 animations:^{
                self.frame = CGRectMake(self.frame.origin.x + (self.frame.size.width - _originalWidth)/2, self.frame.origin.y, _originalWidth, self.frame.size.height);
                _detailView.frame = CGRectMake((self.frame.size.width - CIRCLE_R)/2 + GAP , 0,CIRCLE_R - GAP * 2 ,CIRCLE_R - GAP);
                _backImageView.frame = CGRectMake(0, 0, _backImageView.frame.size.width, _backImageView.frame.size.height);
            }];
            
            [UIView addKeyframeWithRelativeStartTime:0.7 relativeDuration:0.3 animations:^{
                _iconImageView.transform = CGAffineTransformIdentity;
            }];
        } completion:nil];
        self.open = NO;
    }
}

- (UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event {
    if ([self pointInside:point withEvent:event]) {
        return self;
    }
    else {
        return [super hitTest:point withEvent:event];
    }
}
@end
