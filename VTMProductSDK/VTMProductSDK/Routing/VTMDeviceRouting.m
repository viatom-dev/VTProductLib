//
//  VTMDeviceRouting.m
//  VTMProductSDK
//

#import "VTMDeviceRouting.h"

#pragma mark - 前缀表

// Module A 的前缀表，与 SDK 内部 VTMBLEDevice.m 的识别链一一对应。
// 改这里之前先确认 SDK 那边也支持，否则路由过去 SDK 会判成
// VTMDeviceTypeUnknown，指令发不出去。
static NSArray<NSDictionary *> *VTMModuleAPrefixTable(void) {
    static NSArray *table = nil;
    static dispatch_once_t once;
    dispatch_once(&once, ^{
        table = @[
            @{@"p": @"ER1",        @"t": @(VTMDeviceTypeECG)},
            @{@"p": @"VBeat",      @"t": @(VTMDeviceTypeECG)},
            @{@"p": @"ER2",        @"t": @(VTMDeviceTypeECG)},
            @{@"p": @"DuoEK ",     @"t": @(VTMDeviceTypeECG)},

            @{@"p": @"BP2",        @"t": @(VTMDeviceTypeBP)},
            @{@"p": @"BP2A",       @"t": @(VTMDeviceTypeBP)},
            @{@"p": @"BP2W",       @"t": @(VTMDeviceTypeBP)},
            @{@"p": @"LP-BP2W",    @"t": @(VTMDeviceTypeBP)},
            @{@"p": @"BP3",        @"t": @(VTMDeviceTypeBP)},

            @{@"p": @"le S1-",     @"t": @(VTMDeviceTypeScale)},
            @{@"p": @"Lepod",      @"t": @(VTMDeviceTypeER3)},
            @{@"p": @"M12",        @"t": @(VTMDeviceTypeMSeries)},

            // 腕式血氧。O2Ring S 必须排在 Module B 的 "O2Ring" 之前命中，
            // 靠的是「最长前缀优先」而不是表的顺序。
            @{@"p": @"O2Ring S",   @"t": @(VTMDeviceTypeWOxi)},
            @{@"p": @"S8-AW ",     @"t": @(VTMDeviceTypeWOxi)},

            // 指夹血氧
            @{@"p": @"PF10BW-VE",  @"t": @(VTMDeviceTypeFOxi)},
            @{@"p": @"SA10AW-PU",  @"t": @(VTMDeviceTypeFOxi)},
            @{@"p": @"PF-10BWS ",  @"t": @(VTMDeviceTypeFOxi)},

            @{@"p": @"BBSM P1 ",   @"t": @(VTMDeviceTypeBabyPatch)},
            @{@"p": @"BBSM BS1 ",  @"t": @(VTMDeviceTypeBabyPatch)},

            @{@"p": @"R200 ",      @"t": @(VTMDeviceTypeVentilator)},
        ];
    });
    return table;
}

// Module B 的前缀表，来自原 VTO2Lib Demo 的扫描过滤器。
static NSArray<NSString *> *VTMModuleBPrefixTable(void) {
    static NSArray *table = nil;
    static dispatch_once_t once;
    dispatch_once(&once, ^{
        table = @[
            @"O2 ", @"O2BAND ", @"SleepO2 ", @"O2Ring", @"WearO2 ", @"SleepU ",
            @"Oxylink ", @"KidsO2 ", @"BabyO2 ", @"Oxyfit", @"O2M ", @"CMRing",
            @"BBSM S3 ",
        ];
    });
    return table;
}

// ─────────────────────────────────────────────────────────────────────────────
// 同名双代血氧设备表
// ─────────────────────────────────────────────────────────────────────────────
//
// 适用范围很窄，只包含**存在一代旧版本的血氧设备**：这类产品蓝牙名没有变，
// 但固件把协议升级到了新 UUID。对它们，如果广播数据表明是二代
// (VTMProtocolGenerationSecond)，走 Module A 的 woxi_* 优于走 Module B ——
// Module B 虽然也能通，但内部要做一层转包。
//
// 不适用于：
//   - 非血氧的 Module B 设备。例如 BBSM S3 是睡眠监护，走的是 VTO2Communicate
//     的 a5 协议（VTO2A5RespDelegate），不是血氧指令集，不能映射到 WOxi。
//   - 没有一代旧版本的设备。它们的蓝牙名要么已经在 SDK 内置识别链里
//     （如 O2Ring S），要么本来就只有一种协议。
//   - 定制改名产品。那是另一回事，见下面的 VTMCustomNamePrefixTable。
//
// 新增条目前请逐个产品确认：用这个 Demo 扫描，扫描列表每行会显示解析出的代际；
// 对显示「2nd」的设备确认它确实响应 woxi_* 指令集之后再加进来。
//
static NSArray<NSDictionary *> *VTMDualGenerationTable(void) {
    static NSArray *table = nil;
    static dispatch_once_t once;
    dispatch_once(&once, ^{
        table = @[
            // O2Ring：一代走 VTO2Communicate，二代固件支持 woxi_*。
            // 注意这里是裸 "O2Ring" 前缀；"O2Ring S" 由 Module A 的表直接命中
            // （最长前缀优先），不走这里。
            @{@"p": @"O2Ring", @"t": @(VTMDeviceTypeWOxi)},

            // 其余 O2 系列血氧（O2 / O2BAND / SleepO2 / WearO2 / SleepU /
            // Oxylink / KidsO2 / BabyO2 / Oxyfit / O2M / CMRing）是否有二代固件
            // 需要逐个确认，确认后按上面的格式加进来。
        ];
    });
    return table;
}

// ─────────────────────────────────────────────────────────────────────────────
// 定制产品蓝牙名表
// ─────────────────────────────────────────────────────────────────────────────
//
// 和代际无关。如果你的产品改了出厂蓝牙名，SDK 的内置识别链认不出来，
// 需要在这里登记「前缀 → 设备类型」，再由 VTMURATDeviceExtension 告诉 SDK。
//
// 这张表默认为空，由集成方按自己的产品填写。
//
static NSArray<NSDictionary *> *VTMCustomNamePrefixTable(void) {
    static NSArray *table = nil;
    static dispatch_once_t once;
    dispatch_once(&once, ^{
        table = @[
            // 示例：
            // @{@"p": @"MyECG",     @"t": @(VTMDeviceTypeECG)},
            // @{@"p": @"MyO2Ring",  @"t": @(VTMDeviceTypeWOxi)},
        ];
    });
    return table;
}

#pragma mark -

@implementation VTMDeviceRouting

+ (VTMProtocolGeneration)generationFromAdvertisementData:(NSDictionary *)adv {
    NSData *manufacturerData = adv[@"kCBAdvDataManufacturerData"];
    if (![manufacturerData isKindOfClass:[NSData class]]) {
        return VTMProtocolGenerationUnknown;
    }
    if (manufacturerData.length < sizeof(UserAdvData_t)) {
        return VTMProtocolGenerationUnknown;
    }

    UserAdvData_t t;
    memset(&t, 0, sizeof(t));
    [manufacturerData getBytes:&t length:sizeof(UserAdvData_t)];

    // uuid1_version 是新 UUID 服务的协议版本：0 表示不存在。
    // 非 0 即「二代」—— 这是代际的判定依据。
    //
    // 注意不要用 uuid1_enc_level 判代际，那是加密等级，语义不同。
    // SDK 内部的 VTMBLEDevice.encryptedII 用的是 enc_level，那个值回答的是
    // 「要不要做加密握手」，不是「是不是二代」。
    if (t.uuid1_version != 0) {
        return VTMProtocolGenerationSecond;
    }
    if (t.uuid0_version != 0) {
        return VTMProtocolGenerationLegacy;
    }
    return VTMProtocolGenerationUnknown;
}

/// 在前缀表里找最长匹配。返回命中的前缀，没命中返回 nil。
+ (NSString *)longestMatchIn:(NSArray<NSString *> *)prefixes forName:(NSString *)name {
    NSString *best = nil;
    for (NSString *p in prefixes) {
        if ([name hasPrefix:p] && (best == nil || p.length > best.length)) {
            best = p;
        }
    }
    return best;
}

+ (BOOL)isKnownDeviceName:(NSString *)name {
    if (name.length == 0) {
        return NO;
    }
    NSMutableArray<NSString *> *all = [NSMutableArray array];
    for (NSDictionary *e in VTMModuleAPrefixTable()) {
        [all addObject:e[@"p"]];
    }
    for (NSDictionary *e in VTMCustomNamePrefixTable()) {
        [all addObject:e[@"p"]];
    }
    [all addObjectsFromArray:VTMModuleBPrefixTable()];
    return [self longestMatchIn:all forName:name] != nil;
}

+ (VTMDeviceRoute)routeForDeviceName:(NSString *)name
                   advertisementData:(NSDictionary *)adv {
    VTMDeviceRoute route;
    route.module = VTMCommModuleUnsupported;
    route.expectedDeviceType = VTMDeviceTypeUnknown;
    route.generation = [self generationFromAdvertisementData:adv];

    if (name.length == 0) {
        return route;
    }

    // Module A 的前缀表（含定制改名产品）优先，且取最长匹配。
    // "O2Ring S" 比 Module B 的 "O2Ring" 长，所以 O2Ring S 会正确落到 Module A。
    NSMutableArray<NSString *> *aPrefixes = [NSMutableArray array];
    NSMutableDictionary<NSString *, NSNumber *> *aTypes = [NSMutableDictionary dictionary];
    for (NSArray<NSDictionary *> *table in @[VTMModuleAPrefixTable(),
                                             VTMCustomNamePrefixTable()]) {
        for (NSDictionary *e in table) {
            [aPrefixes addObject:e[@"p"]];
            aTypes[e[@"p"]] = e[@"t"];
        }
    }
    NSString *aHit = [self longestMatchIn:aPrefixes forName:name];
    NSString *bHit = [self longestMatchIn:VTMModuleBPrefixTable() forName:name];

    // 两边都命中时按前缀长度裁决（O2Ring S vs O2Ring 就是这种情况）
    if (aHit && (!bHit || aHit.length >= bHit.length)) {
        route.module = VTMCommModuleURAT;
        route.expectedDeviceType = (VTMDeviceType)aTypes[aHit].integerValue;
        return route;
    }

    if (bHit) {
        // 名字落在 Module B。但如果它在「同名双代」表里，且广播数据表明是二代，
        // 就改走 Module A 的 woxi_*（更优路径，不需要转包）。
        if (route.generation == VTMProtocolGenerationSecond) {
            for (NSDictionary *e in VTMDualGenerationTable()) {
                if ([name hasPrefix:e[@"p"]]) {
                    route.module = VTMCommModuleURAT;
                    route.expectedDeviceType = (VTMDeviceType)[e[@"t"] integerValue];
                    return route;
                }
            }
        }
        route.module = VTMCommModuleO2;
        return route;
    }

    return route;
}

+ (NSArray<NSString *> *)extensionNamePrefixesForDeviceType:(VTMDeviceType)deviceType {
    // 两类设备的蓝牙名不在 SDK 的内置识别链里，都要靠 VTMURATDeviceExtension
    // 告诉 SDK 该当成什么类型：
    //   1. 同名双代血氧的二代设备（如二代 O2Ring）
    //   2. 定制改名产品
    NSMutableArray<NSString *> *result = [NSMutableArray array];
    for (NSArray<NSDictionary *> *table in @[VTMDualGenerationTable(),
                                             VTMCustomNamePrefixTable()]) {
        for (NSDictionary *e in table) {
            if ((VTMDeviceType)[e[@"t"] integerValue] == deviceType) {
                [result addObject:e[@"p"]];
            }
        }
    }
    return result.count > 0 ? result : nil;
}

+ (NSString *)descriptionForModule:(VTMCommModule)module {
    switch (module) {
        case VTMCommModuleURAT:        return @"VTMURATUtils";
        case VTMCommModuleO2:          return @"VTO2Communicate";
        case VTMCommModuleUnsupported: return @"Unsupported";
    }
    return @"Unsupported";
}

+ (NSString *)descriptionForGeneration:(VTMProtocolGeneration)generation {
    switch (generation) {
        case VTMProtocolGenerationSecond:  return @"2nd";
        case VTMProtocolGenerationLegacy:  return @"1st";
        case VTMProtocolGenerationUnknown: return @"n/a";
    }
    return @"n/a";
}

@end
