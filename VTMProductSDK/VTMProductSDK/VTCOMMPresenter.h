//
//  VTCOMMPresenter.h
//  VTMProductSDK
//
//  Created by yangweichao on 2023/7/5.
//  Copyright © 2023 viatom. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface VTCOMMPresenter : NSObject

+ (instancetype)sharedInstance;

// MARK: History
- (void)requestDataListHandle:(void(^)(NSArray * _Nullable dataList))handle;

- (void)requestFileLength:(NSString * _Nonnull)fileName handle:(void(^)(u_int fileLen, NSString *fileName))handle;

- (void)requestFileContent:(u_int)offset handle:(void(^)(NSData *fileContent))handle;

- (void)endRequestFileHandle:(void(^)(void))handle;

// MARK: Dashboard
- (void)requestRealDataHandle:(void(^)(NSData *_Nonnull realdata, VTMDeviceType type))handle;


// MARK: settings
- (void)requestDeviceConfigHandle:(void(^)(NSData *configData, VTMDeviceType type))handle;

- (void)requestDeviceInfoHandle:(void(^)(VTMDeviceInfo info))handle;

- (void)syncDeivceConfig:(NSValue *)configValue configSize:(uint)size response:(void(^)(BOOL succeed))response;

- (void)syncDeviceTime:(NSDate *)date response:(void(^)(BOOL succeed))response;


@end

NS_ASSUME_NONNULL_END
