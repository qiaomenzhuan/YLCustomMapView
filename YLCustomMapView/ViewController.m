//
//  ViewController.m
//  YLCustomMapView
//
//  Created by 杨磊 帅™ on 2017/12/5.
//  Copyright © 2017年 csda_Chinadance. All rights reserved.
//

#import "ViewController.h"

#import <AMapFoundationKit/AMapFoundationKit.h>
#import <MAMapKit/MAMapKit.h>
#import <AMapLocationKit/AMapLocationKit.h>
#import "CustomInTurnAnnotationView.h"
#import "CustomInTurnAnnotationModel.h"
@interface ViewController ()<MAMapViewDelegate,AMapLocationManagerDelegate>
@property (weak, nonatomic) IBOutlet MAMapView *mapView;
@property (weak, nonatomic) IBOutlet UIButton  *northBtn;
@property (nonatomic,strong) MAAnnotationView  *userLocationAnnotationView;//当前位置的自定义view
@property (nonatomic,strong) NSMutableArray    *dataSourceAnnotations;//处理过的坐标数组
@property (nonatomic,strong) NSMutableArray    *lines;//虚线数组
@property (nonatomic,assign) BOOL isFirst;
@end

@implementation ViewController

- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
    self.mapView.showsUserLocation = NO;
    self.mapView.delegate = nil;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [self customMap];
}
- (void)customMap
{
    self.dataSourceAnnotations  = [NSMutableArray array];
    self.lines                  = [NSMutableArray array];
    
    self.mapView.autoresizingMask         = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    self.mapView.rotateCameraEnabled      = NO;
    self.mapView.rotateEnabled            = NO;
    self.mapView.showsIndoorMap           = NO;
    self.mapView.zoomLevel                = 18;
    self.mapView.showsScale               = NO;
    self.mapView.showsCompass             = NO;
    self.mapView.delegate                 = self;
    self.mapView.userTrackingMode         = MAUserTrackingModeFollow;
    self.mapView.showsUserLocation        = YES;

    MAUserLocationRepresentation *r   = [[MAUserLocationRepresentation alloc] init];
    r.showsAccuracyRing               = NO;
    r.showsHeadingIndicator           = NO;
    r.fillColor                       = [[UIColor whiteColor] colorWithAlphaComponent:0.3];
    r.strokeColor                     = [UIColor whiteColor];
    r.lineWidth                       = 1;
    r.image = [UIImage imageNamed:@"none"];
    [self.mapView updateUserLocationRepresentation:r];
}
- (IBAction)myLocation:(id)sender {
    if(self.mapView.userLocation.updating && self.mapView.userLocation.location)
    {
        self.mapView.zoomLevel = 18;             //缩放级别（默认3-19)
        [self.mapView setCenterCoordinate:self.mapView.userLocation.location.coordinate animated:YES];
        [self zoomData];
    }
}
#pragma mark - MAMapViewDelegate

- (void)mapView:(MAMapView *)mapView didUpdateUserLocation:(MAUserLocation *)userLocation updatingLocation:(BOOL)updatingLocation
{
    if (!updatingLocation && self.userLocationAnnotationView != nil)
    {
        [UIView animateWithDuration:0.1 animations:^{
            double degreeS = userLocation.heading.magneticHeading;
            self.northBtn.transform = CGAffineTransformMakeRotation(-degreeS * M_PI / 180.f );//指南针旋转
            double degree = userLocation.heading.trueHeading - self.mapView.rotationDegree;
            self.userLocationAnnotationView.imageView.transform = CGAffineTransformMakeRotation(degree * M_PI / 180.f );//当前位置旋转
        }];
    }
    
    if (mapView.userLocation.coordinate.latitude != 0 && !self.isFirst)
    {//添加数据
        self.isFirst = YES;
        [self locationData];
    }
}
//绘制虚线
//- (MAOverlayRenderer *)mapView:(MAMapView *)mapView rendererForOverlay:(id <MAOverlay>)overlay
//{
//    if ([overlay isKindOfClass:[MAPolyline class]])
//    {//连线 虚线
//        MAPolylineRenderer *polylineRenderer = [[MAPolylineRenderer alloc] initWithPolyline:(MAPolyline *)overlay];
//        polylineRenderer.lineWidth   = 1;
//        polylineRenderer.strokeColor = [UIColor purpleColor];
//        polylineRenderer.lineCapType = kCGLineCapSquare;
//        polylineRenderer.lineDash    = YES;
//        return polylineRenderer;
//    }
//    return nil;
//}

- (MAAnnotationView *)mapView:(MAMapView *)mapView viewForAnnotation:(id<MAAnnotation>)annotation
{
    /* 自定义userLocation对应的annotationView. */
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
        annotationView.zIndex = 100;
        self.userLocationAnnotationView = annotationView;
        return annotationView;
    }else if ([annotation isKindOfClass:[MAPointAnnotation class]])
    {//多个标注点
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
- (void)mapView:(MAMapView *)mapView mapDidZoomByUser:(BOOL)wasUserAction
{
    if (wasUserAction) {
        [self zoomData];
    }
}
- (void)zoomData
{
    if (self.dataSourceAnnotations.count > 0)
    {
        [self.mapView removeAnnotations:self.dataSourceAnnotations];
    }
    
    for (CustomInTurnAnnotationModel *pointAnnotation in self.dataSourceAnnotations) {
        pointAnnotation.scoreWid    = self.mapView.zoomLevel*4;
    }
    [self.mapView addAnnotations:self.dataSourceAnnotations];
}
#pragma  mark - 构造数据
- (void)locationData
{
    if (self.dataSourceAnnotations.count > 0)
    {
        [self.mapView removeAnnotations:self.dataSourceAnnotations];
    }
    if (self.lines.count>0)
    {
        [self.mapView removeOverlays:self.lines];
    }
    [self.dataSourceAnnotations removeAllObjects];
    
    [self.lines removeAllObjects];
    
    double lat = self.mapView.userLocation.coordinate.latitude;
    double lng = self.mapView.userLocation.coordinate.longitude;
    NSArray *titleArr = @[@"高",@"德",@"地",@"图",@"很",@"牛",@"逼",@"🐂",@"B",@"🍌",@"55",@"我",@"要",@"消",@"灭",@"你"];
    NSMutableArray *arrLine = [NSMutableArray array];

    for (int i = 0; i < titleArr.count; i ++) {
        double arcLat = lat + (double)(arc4random()%10 + 1)/6000.0f;
        double arcLng = lng + (double)(arc4random()%10 + 1)/6000.0f;
        NSLog(@"sdsd  %f %f %f %f",lat,lng,arcLat,arcLng);
        CustomInTurnAnnotationModel *pointAnnotation = [[CustomInTurnAnnotationModel alloc] init];
        CLLocationCoordinate2D coor = CLLocationCoordinate2DMake(arcLat, arcLng);
        if (i == 0) {
            coor = self.mapView.userLocation.coordinate;
        }
        pointAnnotation.coordinate  = coor;
        pointAnnotation.titleStr    = [titleArr objectAtIndex:i];
        pointAnnotation.scoreWid    = self.mapView.zoomLevel*4;
        [self.dataSourceAnnotations addObject:pointAnnotation];
    }
    
    for (int i = 0; i < self.dataSourceAnnotations.count; i ++) {
        if (i == self.dataSourceAnnotations.count - 1)break;
        CustomInTurnAnnotationModel *pointAnnotation = [self.dataSourceAnnotations objectAtIndex:i];
        CustomInTurnAnnotationModel *pointAnnotation1 = [self.dataSourceAnnotations objectAtIndex:i+1];
        CLLocationCoordinate2D line1Points[2];
        line1Points[0] = pointAnnotation.coordinate;
        line1Points[1] = pointAnnotation1.coordinate;
        MAPolyline *line1 = [MAPolyline polylineWithCoordinates:line1Points count:2];
        [arrLine addObject:line1];
    }
    [self.mapView addAnnotations:self.dataSourceAnnotations];
    [self.lines addObjectsFromArray:arrLine];
    [self.mapView addOverlays:self.lines];
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self.mapView showAnnotations:self.dataSourceAnnotations animated:YES];
    });
    
}
- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}


@end
