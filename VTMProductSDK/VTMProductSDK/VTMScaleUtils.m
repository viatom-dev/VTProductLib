//
//  VTMScaleUtils.m
//  VTMProductSDKDemo
//
//  Created by Viatom3 on 2021/2/23.
//  Copyright © 2021 viatom. All rights reserved.
//

#import "VTMScaleUtils.h"

@implementation VTMScaleUtils

+ (u_char)parserBitRange:(u_char)value offset:(u_char)offset andLen:(u_char)len{
    return (value >> offset) & ((u_char)pow(2, len) - 1);
}

+(CGFloat)getRealWeightFormOriginal:(VTMScaleData)scaleData{
    CGFloat weight = (CGFloat)scaleData.weight;
    DLog(@"original weight %.1f",weight);
    //bit0-3:unit ,0:kg, 1:LB, 2:ST, 3:LB-ST, 4:斤
    //bit4-7:multiple,  (weight was magnified 10^n)
//    int weightUnit = [VTMScaleUtils parserBitRange:scaleData.precision_uint offset:0 andLen:4];
    int multiple = [VTMScaleUtils parserBitRange:scaleData.precision_uint offset:4 andLen:4];
    multiple  =   pow(10, multiple);
    weight = weight/multiple;
    
    return weight;
}

@end
