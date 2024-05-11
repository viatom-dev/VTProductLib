//
//  VTCOMMPresenter.m
//  VTMProductSDK
//
//  Created by yangweichao on 2023/7/5.
//  Copyright © 2023 viatom. All rights reserved.
//

#import "VTCOMMPresenter.h"

@interface VTCOMMPresenter ()<VTMURATUtilsDelegate>

@property (nonatomic, copy) void (^DataListHandle)(NSArray * _Nullable);
@property (nonatomic, copy) void (^FileLengthHandle)(u_int, NSString *);
@property (nonatomic, copy) void (^FileContentHandle)(NSData * _Nullable);
@property (nonatomic, copy) void (^FileDoneHandle)(void);
@property (nonatomic, copy) void (^RealDataHandle)(NSData *_Nonnull, VTMDeviceType type);
@property (nonatomic, copy) void (^ConfigHandle)(NSData *configData, VTMDeviceType type);
@property (nonatomic, copy) void (^InfoHandle)(VTMDeviceInfo info);
@property (nonatomic, copy) void (^SyncResponse)(BOOL);

@property (nonatomic, strong, readonly) VTMProductURATUtils *utils;

@end

@implementation VTCOMMPresenter

static VTCOMMPresenter *_instance = nil;
+ (instancetype)sharedInstance{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _instance = [[super allocWithZone:NULL] init];
    });
    return _instance;
}

+ (instancetype)allocWithZone:(struct _NSZone *)zone{
    return [VTCOMMPresenter sharedInstance];
}
-(id)copyWithZone:(NSZone *)zone{
    return [VTCOMMPresenter sharedInstance];
}
-(id)mutableCopyWithZone:(NSZone *)zone{
    return [VTCOMMPresenter sharedInstance];
}

- (VTMProductURATUtils *)utils {
    return [VTMProductURATUtils sharedInstance];
}

- (void)startTaskScaleHandle:(dispatch_block_t)scaleHandle
                    BPHandle:(dispatch_block_t)bpHandle
                   ECGHandle:(dispatch_block_t)ecgHandle
                   ER3Handle:(dispatch_block_t)er3Handle
                  WOxiHandle:(dispatch_block_t)woxiHandle
                  FOxiHandle:(dispatch_block_t)foxiHandle {
    if (self.utils.currentType == VTMDeviceTypeScale) {
        if (scaleHandle) scaleHandle();
    } else if (self.utils.currentType == VTMDeviceTypeBP){
        if (bpHandle) bpHandle();
    } else if (self.utils.currentType == VTMDeviceTypeECG){
        if (ecgHandle) ecgHandle();
    } else if (self.utils.currentType == VTMDeviceTypeER3){
        if (er3Handle) er3Handle();
    } else if (self.utils.currentType == VTMDeviceTypeWOxi) {
        if (woxiHandle) woxiHandle();
    } else if (self.utils.currentType == VTMDeviceTypeFOxi) {
        if (foxiHandle) foxiHandle();
    }
}

#pragma mark - public methods

- (void)requestDataListHandle:(void (^)(NSArray * _Nullable))handle {
    _DataListHandle = handle;
    self.utils.delegate = self;
    [self.utils requestFilelist];
}

- (void)requestFileLength:(NSString *)fileName handle:(void (^)(u_int, NSString*))handle {
    _FileLengthHandle = handle;
    self.utils.delegate = self;
    [self.utils prepareReadFile:fileName];
}

- (void)requestFileContent:(u_int)offset handle:(void (^)(NSData * _Nonnull))handle {
    _FileContentHandle = handle;
    self.utils.delegate = self;
    [self.utils readFile:offset];
}

- (void)endRequestFileHandle:(void (^)(void))handle {
    _FileDoneHandle = handle;
    self.utils.delegate = self;
    [self.utils endReadFile];
}


- (void)requestRealDataHandle:(void (^)(NSData *_Nonnull, VTMDeviceType type))handle {
    self.RealDataHandle = handle;
    [self startTaskScaleHandle:^{
        [self.utils requestScaleRealData];
    } BPHandle:^{
        [self.utils requestBPRealData];
    } ECGHandle:^{
        [self.utils requestECGRealData];
    } ER3Handle:^{
        [self.utils requestER3ECGRealData];
    } WOxiHandle:^{
        [self.utils woxi_requestWOxiRealData];
    } FOxiHandle:nil];
}



- (void)requestDeviceConfigHandle:(void (^)(NSData *configData, VTMDeviceType type))handle {
    self.ConfigHandle = handle;
    self.utils.delegate = self;
    if (self.utils.currentType == VTMDeviceTypeScale) {
//        [self.utils requestsc];
        NSLog(@"current device not support configuration.");
    } else if (self.utils.currentType == VTMDeviceTypeBP){
        [self.utils requestBPConfig];
    } else if (self.utils.currentType == VTMDeviceTypeECG){
        [self.utils requestECGConfig];
    } else if (self.utils.currentType == VTMDeviceTypeER3){
        [self.utils requestER3Config];
    } else if (self.utils.currentType == VTMDeviceTypeWOxi) {
        [self.utils woxi_requestConfig];
    }
    [self startTaskScaleHandle:^{
        
    } BPHandle:^{
        [self.utils requestBPConfig];
    } ECGHandle:^{
        [self.utils requestECGConfig];
    } ER3Handle:^{
        [self.utils requestER3Config];
    } WOxiHandle:^{
        [self.utils woxi_requestConfig];
    } FOxiHandle:^{
        [self.utils foxi_requestConfig];
    }];
    
}

- (void)requestDeviceInfoHandle:(void (^)(VTMDeviceInfo))handle {
    _InfoHandle = handle;
    self.utils.delegate = self;
    [self.utils requestDeviceInfo];
}


- (void)syncDeivceConfig:(NSValue *)configValue configSize:(uint)size response:(void(^)(BOOL succeed))response {
    self.SyncResponse = response;
    
    if (self.utils.currentType == VTMDeviceTypeScale) {
//        [self.utils requestsc];
        NSLog(@"current device not support configuration.");
    } else if (self.utils.currentType == VTMDeviceTypeECG){
        
        
    } else if (self.utils.currentType == VTMDeviceTypeBP ){
        VTMBPConfig config;
        [configValue getValue:&config];
        [self.utils syncBPConfig:config];
    } else if (self.utils.currentType == VTMDeviceTypeER3 ){
        VTMER3Config config;
        [configValue getValue:&config];
        [self.utils syncER3Config:config];
    }
    [self startTaskScaleHandle:^{
        
    } BPHandle:^{
        VTMBPConfig config;
        [configValue getValue:&config];
        [self.utils syncBPConfig:config];
    } ECGHandle:^{
        if (size == sizeof(VTMER1Config)) {
            VTMER1Config config;
            [configValue getValue:&config];
            [self.utils syncER1Config:config];
        } else {
            VTMER2Config config;
            [configValue getValue:&config];
            [self.utils syncER2Config:config];
        }
    } ER3Handle:^{
        VTMER3Config config;
        [configValue getValue:&config];
        [self.utils syncER3Config:config];
    } WOxiHandle:^{
        VTMOxiParamsOption op ;
        [configValue getValue:&op];
        [self.utils woxi_syncConfigParam:op];
    } FOxiHandle:^{
        VTMOxiParamsOption op ;
        [configValue getValue:&op];
        [self.utils foxi_syncConfigParam:op];
    }];
    
}

- (void)syncDeviceTime:(NSDate *)date response:(void (^)(BOOL))response {
    self.SyncResponse = response;
    self.utils.delegate = self;
    [self.utils syncTime:date];
}


#pragma mark - utils delegate
- (void)util:(VTMURATUtils *)util commandCompletion:(u_char)cmdType deviceType:(VTMDeviceType)deviceType response:(NSData *)response {
    if (cmdType == VTMBLECmdGetFileList) {
        
        VTMFileList list = [VTMBLEParser parseFileList:response];
        NSMutableArray *downloadArr = [NSMutableArray array];
        for (int i = 0; i < list.file_num; i++) {
            NSMutableString *temp = [NSMutableString string];
            u_char *file_name = list.fileName[i].str;
            size_t fileLen = strlen((char *)file_name);
            for (int j = 0; j < fileLen; j++) {
                [temp appendString:[NSString stringWithFormat:@"%c",file_name[j]]];
            }
            [downloadArr addObject:temp];
        }
        if (_DataListHandle) {
            _DataListHandle(downloadArr);
        }
        return;
    } else if (cmdType == VTMBLECmdStartRead) {
        
        VTMOpenFileReturn fsrr = [VTMBLEParser parseFileLength:response];
        if (_FileLengthHandle) {
            _FileLengthHandle(fsrr.file_size, util.curReadFileName);
        }
        return;
    } else if (cmdType == VTMBLECmdReadFile) {
        
        if (_FileContentHandle) {
            _FileContentHandle(response);
        }
        return;
    } else if(cmdType == VTMBLECmdEndRead){
       
        if (_FileDoneHandle) {
            _FileDoneHandle();
        }
        return;
    }   else if (cmdType == VTMBLECmdSyncTime) {
        if (self.SyncResponse) {
            self.SyncResponse(YES);
        }
        return;
    } else if (cmdType == VTMBLECmdGetDeviceInfo) {
        VTMDeviceInfo info = [VTMBLEParser parseDeviceInfo:response];
        if (_InfoHandle) {
            _InfoHandle(info);
        }
        return;
    }
    
    [self startTaskScaleHandle:^{
        if (cmdType == VTMSCALECmdGetRealData) {
            if (self.RealDataHandle) {
                self.RealDataHandle(response, deviceType);
            }
        }
    } BPHandle:^{
        if (cmdType == VTMBPCmdGetRealData) {
            if (self.RealDataHandle) {
                self.RealDataHandle(response, deviceType);
            }
        } else if (cmdType == VTMBPCmdGetConfig) {
            if (self.ConfigHandle) {
                self.ConfigHandle(response, deviceType);
            }
        } else if (cmdType == VTMBPCmdSetConfig) {
            if (self.SyncResponse) {
                self.SyncResponse(YES);
            }
        }
    } ECGHandle:^{
        if (cmdType == VTMECGCmdGetRealData) {
            if (self.RealDataHandle) {
                self.RealDataHandle(response, deviceType);
            }
        } else if (cmdType == VTMECGCmdGetConfig) {
            if (self.ConfigHandle) {
                self.ConfigHandle(response, deviceType);
            }
        } else if (cmdType == VTMECGCmdSetConfig) {
            if (self.SyncResponse) {
                self.SyncResponse(YES);
            }
        }
    } ER3Handle:^{
        if (cmdType == VTMER3ECGCmdGetRealData) {
            if (self.RealDataHandle) {
                self.RealDataHandle(response, deviceType);
            }
        } else if (cmdType == VTMECGCmdGetConfig) {
            if (self.ConfigHandle) {
                self.ConfigHandle(response, deviceType);
            }
        } else if (cmdType == VTMECGCmdSetConfig) {
            if (self.SyncResponse) {
                self.SyncResponse(YES);
            }
        }
    } WOxiHandle:^{
        if (cmdType == VTMWOxiCmdGetRealData) {
            if (self.RealDataHandle) {
                self.RealDataHandle(response, deviceType);
            }
        } else if (cmdType == VTMWOxiCmdGetConfig) {
            if (self.ConfigHandle) {
                self.ConfigHandle(response, deviceType);
            }
        } else if (cmdType == VTMWOxiCmdSetConfig) {
            if (self.SyncResponse) {
                self.SyncResponse(YES);
            }
        }
    } FOxiHandle:^{
        if (cmdType == VTMFOxiCmdWaveResp) {
            
        } else if (cmdType == VTMFOxiCmdInfoResp) {
            
        } else if (cmdType == VTMWOxiCmdGetConfig) {
            if (self.ConfigHandle) {
                self.ConfigHandle(response, deviceType);
            }
        } else if (cmdType == VTMWOxiCmdSetConfig) {
            if (self.SyncResponse) {
                self.SyncResponse(YES);
            }
        }
    }];
}

- (void)util:(VTMURATUtils *)util commandFailed:(u_char)cmdType deviceType:(VTMDeviceType)deviceType failedType:(VTMBLEPkgType)type {
    
}





@end
