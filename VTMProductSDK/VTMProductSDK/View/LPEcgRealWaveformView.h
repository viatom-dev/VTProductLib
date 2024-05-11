//
//  LPEcgRealWaveformView.h
//  iwown
//
//  Created by fengye on 2020/5/24.
//  Copyright © 2020 LP. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface LPEcgRealWaveformView : UIView

@property (nonatomic, copy) NSArray *receiveArray;

@property (nonatomic, assign) NSInteger hz;

@property (nonatomic, assign) BOOL isBpWave;

- (void)clearChache;

@end

NS_ASSUME_NONNULL_END
