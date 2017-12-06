//
//  CustomInTurnAnnotationView.m
//  YLCustomMapView
//
//  Created by 杨磊 帅™ on 2017/12/5.
//  Copyright © 2017年 csda_Chinadance. All rights reserved.
//

#import "CustomInTurnAnnotationView.h"
#import "CustomInTurnAnnotationModel.h"
#import <Masonry.h>

@interface CustomInTurnAnnotationView()

@property (nonatomic, strong) UILabel               *nameLabel;
@property (nonatomic, strong) UIImageView           *scorePic;//圆图
@property (nonatomic, strong) UIImageView           *backPic;//带尖的背景图

@property (nonatomic, strong) CAKeyframeAnimation   *animation;

@end

@implementation CustomInTurnAnnotationView

- (id)initWithAnnotation:(id<MAAnnotation>)annotation reuseIdentifier:(NSString *)reuseIdentifier
{
    CustomInTurnAnnotationModel *ann = (CustomInTurnAnnotationModel *)annotation;
    self = [super initWithAnnotation:annotation reuseIdentifier:reuseIdentifier];
    if (self)
    {
        self.backgroundColor = [UIColor clearColor];
        [self initializeAnnotation:ann];
    }
    return self;
}

- (void)initializeAnnotation:(CustomInTurnAnnotationModel *)ann
{
    [self setupAnnotation:ann];
}

- (void)setAnnotation:(id<MAAnnotation>)annotation
{
    [super setAnnotation:annotation];
    CustomInTurnAnnotationModel *ann = (CustomInTurnAnnotationModel *)self.annotation;
    if (ann)
    {
        [self setupAnnotation:ann];
    }
}

- (void)setupAnnotation:(CustomInTurnAnnotationModel *)ann
{
    float width = ann.scoreWid;
    float scale = width/35;
    self.bounds            = CGRectMake(0.f, 0.f, width, width);
    self.backPic.frame = CGRectMake(2*scale, 0, width - 4*scale, width);
    self.nameLabel.frame = CGRectMake(0,
                                      0,
                                      CGRectGetWidth(self.backPic.frame),
                                      CGRectGetHeight(self.backPic.frame) - 10*scale);
    
    self.scorePic.frame = CGRectMake(6*scale,
                                     3*scale,
                                     CGRectGetWidth(self.backPic.frame) - 12*scale,
                                     CGRectGetHeight(self.backPic.frame) - 16*scale);

    self.centerOffset      = CGPointMake(0 , -(width/2 - 5));
    UIImage *imageCicle = [UIImage imageNamed:@"running_point_icon_db_red"];// running_point_icon_db_grex
    if (ann.isSel)
    {
        imageCicle  = [UIImage imageNamed:@"running_point_icon_db_grex"];
    }
    if (!ann.isSel && ann.isRadius==1)
    {//开始动画
        [self.layer removeAnimationForKey:@"topbottom"];
        [self.layer addAnimation:self.animation forKey:@"topbottom"];
    }else
    {//结束动画
        [self.layer removeAnimationForKey:@"topbottom"];
    }
    
    self.nameLabel.text               = [NSString stringWithFormat:@"%@",ann.titleStr];
    
    self.scorePic.image               = imageCicle;
    
    [self.backPic bringSubviewToFront:self.nameLabel];
    
}

- (UILabel *)nameLabel
{
    if (!_nameLabel)
    {
        _nameLabel = [[UILabel alloc] init];
        _nameLabel.backgroundColor    = [UIColor clearColor];
        _nameLabel.textAlignment      = NSTextAlignmentCenter;
        _nameLabel.textColor          = [UIColor whiteColor];
        _nameLabel.font               = [UIFont systemFontOfSize:12.0];
        [self.backPic addSubview:_nameLabel];
    }
    return _nameLabel;
}
- (UIImageView *)scorePic
{
    if (!_scorePic) {
        _scorePic = [[UIImageView alloc]init];
        [self.backPic addSubview:_scorePic];
    }
    return _scorePic;
}

- (UIImageView *)backPic
{
    if (!_backPic) {
        _backPic = [[UIImageView alloc] init];
        _backPic.image = [UIImage imageNamed:@"running_clock_point"];
        [self addSubview:_backPic];
    }
    return _backPic;
}

- (CAKeyframeAnimation *)animation
{
    if (!_animation)
    {
        CGFloat duration = 0.8f;
        CGFloat height = 10.f;
        _animation = [CAKeyframeAnimation animationWithKeyPath:@"transform.translation.y"];
        CGFloat currentTy = self.transform.ty;
        _animation.duration = duration;
        _animation.values = @[@(currentTy), @(currentTy - height), @(currentTy)];
        _animation.keyTimes = @[ @(0), @(0.5), @(0.8) ];
        _animation.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
        _animation.repeatCount = CGFLOAT_MAX;
    }
    return _animation;
}

+ (UIColor *)getColor:(NSString*)hexColor {
    if([hexColor hasPrefix:@"#"]) {
        hexColor = [hexColor substringFromIndex:1];
    }
    
    NSScanner*scanner = [NSScanner scannerWithString:hexColor];
    unsigned hexNum;
    if(![scanner scanHexInt:&hexNum]) {
        return nil;
    }
    return [[self class] colorWithRGBHex:hexNum];
}

+ (UIColor *)colorWithRGBHex:(UInt32)hex{
    int r = (hex >>16) &0xFF;
    int g = (hex >>8) &0xFF;
    int b = (hex) &0xFF;
    return[UIColor colorWithRed:r /255.0f
                          green:g /255.0f
                           blue:b /255.0f
                          alpha:1.0f];
}
@end
