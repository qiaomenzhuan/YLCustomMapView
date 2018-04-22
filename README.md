# YLCustomMapView
Mamapview custom 
本篇内容包括了高德地图自定义大头针自动布局及其动画、自定义UserLocation过程中遇到的问题。因篇幅有限，后续会追加运动轨迹等内容。

![自定义大头针](http://upload-images.jianshu.io/upload_images/6206716-d5fc38d9a3a5990f.gif?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)

##高德地图高度自定义使用场景：

1. 共享单车类应用

2. 跑步运动类应用

##集成方案:

项目需要集成地图，权衡下选择了高德地图，高德提供的API更友好，工单解答也能解决大多数开发问题。
关于地图的集成直接参考官方文档[高德地图API](http://lbs.amap.com)，步骤很简单。重点讲开发过程中遇到的坑以及解决方法。

##实现功能

1. 地图的初始化，我直接加在SB上了，但在项目里因为频繁用到地图，导致内存暴增，所以我选择了用单例创建，这里只给示范
```
 self.mapView.delegate                 = self;
 self.mapView.userTrackingMode         = MAUserTrackingModeFollow;
 self.mapView.showsUserLocation        = YES;
/**自定义当前位置，给了一张空图 后面会在地图的代理方法
- (MAAnnotationView *)mapView:(MAMapView *)mapView viewForAnnotation:(id<MAAnnotation>)annotation
里单独处理
*/
 MAUserLocationRepresentation *r   = [[MAUserLocationRepresentation alloc] init];
 r.image = [UIImage imageNamed:@"none"];
 [self.mapView updateUserLocationRepresentation:r];
```
2.实现MAMapViewDelegate

```
/**
这个方法只要用户设备方向发生变化就会触发 当然适合处理指北针和当前位置的旋转啦
*/
- (void)mapView:(MAMapView *)mapView didUpdateUserLocation:(MAUserLocation *)userLocation updatingLocation:(BOOL)updatingLocation
{
    if (!updatingLocation && self.userLocationAnnotationView != nil)
    {
        [UIView animateWithDuration:0.1 animations:^{
            double degreeS = userLocation.heading.magneticHeading;
            self.northBtn.transform = CGAffineTransformMakeRotation(-degreeS * M_PI / 180.f );//指北针旋转
            double degree = userLocation.heading.trueHeading - self.mapView.rotationDegree;
            self.userLocationAnnotationView.imageView.transform = CGAffineTransformMakeRotation(degree * M_PI / 180.f );//当前位置旋转
        }];
    }
}
```
接下来是往地图上添加大头针,CustomInTurnAnnotationView继承MAAnnotationView单独一个view类,
CustomInTurnAnnotationModel里存放数据
```
- (MAAnnotationView *)mapView:(MAMapView *)mapView viewForAnnotation:(id<MAAnnotation>)annotation
{
    if ([annotation isKindOfClass:[MAUserLocation class]])
    {//当前位置
        static NSString *userLocationStyleReuseIndetifier = @"userLocationStyleReuseIndetifier";
        MAAnnotationView *annotationView = [mapView dequeueReusableAnnotationViewWithIdentifier:userLocationStyleReuseIndetifier];
        if (annotationView == nil)
        {
            annotationView    = [[MAAnnotationView alloc] initWithAnnotation:annotation
                                                             reuseIdentifier:userLocationStyleReuseIndetifier];
        }
        annotationView.image  = [UIImage imageNamed:@"icon_dqd2_b"];
        annotationView.zIndex = 100;//可以控制图层显示问题 谁的值大 谁在最上层
        self.userLocationAnnotationView = annotationView;
        return annotationView;
    }else if ([annotation isKindOfClass:[MAPointAnnotation class]])
    {//多个大头针
        CustomInTurnAnnotationModel *cusAnnotation = (CustomInTurnAnnotationModel *)annotation;
        static NSString *pointReuseIndentifier = @"pointReuseIndentifier";
        CustomInTurnAnnotationView *annotationView = (CustomInTurnAnnotationView*)[mapView dequeueReusableAnnotationViewWithIdentifier:pointReuseIndentifier];
        if (annotationView == nil)
        {
            annotationView = [[CustomInTurnAnnotationView alloc] initWithAnnotation:annotation reuseIdentifier:pointReuseIndentifier];
        }
        //配置模型数据
        annotationView.annotation = cusAnnotation;
        annotationView.zIndex = 10;
        return annotationView;
    }
    return nil;
}
```
显示在地图上的数据是我用当前定位随机出来的,大致效果如下
![喏 效果图](http://upload-images.jianshu.io/upload_images/6206716-8bf85b3fc630fc9e.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)
3. 看一下自定义MAAnnotationView里的处理
重写了- (void)setAnnotation:(id<MAAnnotation>)annotation方法
```
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
    float width = ann.scoreWid;//这个view的大小是model返回的 地图缩放大小可以变化
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
    if (ann.isRadius==1)
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
```
大头针跳动动画是给layer加的很简单的基础动画
```
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
```
大头针的大小根据地图缩放在这里处理
```
- (void)mapView:(MAMapView *)mapView mapDidZoomByUser:(BOOL)wasUserAction
{
    if (wasUserAction) {
        [self zoomData];//这里改变model数据就可以了
    }
}
```
地图的zoomlevel变小，大头针是不是变小了！当然同样的原理可以做点聚合，我这里只是改变了大头针的尺寸，点聚合可以从减少点的个数下手
![屏幕快照 2017-12-07 12.02.29.png](http://upload-images.jianshu.io/upload_images/6206716-3568c55cef5c4577.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)

以上。
