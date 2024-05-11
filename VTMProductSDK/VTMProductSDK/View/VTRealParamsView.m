//
//  VTRealParamsView.m
//  VTMProductSDK
//
//  Created by yangweichao on 2023/8/9.
//  Copyright © 2023 viatom. All rights reserved.
//

#import "VTRealParamsView.h"

@interface VTRealParamsView ()




@end

@implementation VTRealParamsView

- (instancetype)init {
    self = [super init];
    if (self) {
        self = [[[NSBundle mainBundle] loadNibNamed:NSStringFromClass([self class]) owner:self options:nil] firstObject];
        
    }
    return self;
}

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self = [[[NSBundle mainBundle] loadNibNamed:NSStringFromClass([self class]) owner:self options:nil] firstObject];
        self.frame = frame;
    }
    return self;
}

- (void)awakeFromNib {
    [super awakeFromNib];
    for (UILabel *label in self.subviews) {
        label.text = @"--";
    }
}




@end
