//
//  CustomInTurnAnnotationModel.h
//  YLCustomMapView
//
//  Created by 杨磊 帅™ on 2017/12/5.
//  Copyright © 2017年 csda_Chinadance. All rights reserved.
//

#import <MAMapKit/MAMapKit.h>

@interface CustomInTurnAnnotationModel : MAPointAnnotation

@property (nonatomic, assign) BOOL      isSel;//是否选中
@property (nonatomic, assign) BOOL      isRadius;//0不动 1动画
@property (nonatomic,   copy) NSString  *titleStr;//点标的文字
@property (nonatomic, assign) NSInteger scoreWid;
@end
