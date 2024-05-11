//
//  VTRealParamsView.h
//  VTMProductSDK
//
//  Created by yangweichao on 2023/8/9.
//  Copyright © 2023 viatom. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface VTRealParamsView : UIView

@property (weak, nonatomic) IBOutlet UILabel *batteryLabel;

@property (weak, nonatomic) IBOutlet UILabel *batteryStaLabel;

@property (weak, nonatomic) IBOutlet UILabel *runStaLabel;

@property (weak, nonatomic) IBOutlet UILabel *timeLabel;

@property (weak, nonatomic) IBOutlet UILabel *param1Label;

@property (weak, nonatomic) IBOutlet UILabel *param2Label;

@end

NS_ASSUME_NONNULL_END
