# VTMProductSDK

**Version / 版本：1.5.7**

iOS BLE SDK for Lepu devices.

iOS 蓝牙通信 SDK，用于连接和操作乐普系列设备。

---

## Changelog / 更新日志

### 1.5.7
- **BabyPatch** — Added `VTMBabySleepState` enum and `VTMBabySleepInfo` struct (40 bytes: sleep state, timestamps, durations, cough flag, etc.). `VTMBabyRunParams` now includes `hasSleepInfo` flag and `sleepInfo` field; parser detects old/new packet length automatically.
  新增 `VTMBabySleepState` 枚举和 `VTMBabySleepInfo` 结构体（40 字节：睡眠状态、时间戳、时长、咳嗽标志等）。`VTMBabyRunParams` 新增 `hasSleepInfo` 标志位和 `sleepInfo` 字段，解析器自动兼容新旧数据包长度。
- **VTMURATUtils** — `openupEncryptWithToken:secretKey:` now falls back to the built-in default credentials when token or key is empty/nil, so passing `@""` for both is supported. `allReset` is now exposed in the public header.
  `openupEncryptWithToken:secretKey:` 当 token 或 key 为空时自动回落到内置默认凭证，因此两个参数都传 `@""` 是受支持的用法。`allReset` 已在公共头文件中暴露。
- **VTO2Communicate** — `commandFailed:deviceType:failedType:` now handles `VTMBLECmdOpenupEncryption` and forwards the result to `o2Delegate` via `openupEncryptResult:`.
  `commandFailed:deviceType:failedType:` 新增对 `VTMBLECmdOpenupEncryption` 的处理，通过 `openupEncryptResult:` 将结果转发给 `o2Delegate`。

#### Distribution & docs / 分发与文档

Added after 1.5.7 was first published. **The framework binary is unchanged** — byte-for-byte
identical to the originally released 1.5.7, so there is nothing to upgrade if you already
use it via CocoaPods.

这些是 1.5.7 首次发布之后补充的。**框架二进制没有变化** —— 与最初发布的 1.5.7 逐字节一致，
已经通过 CocoaPods 使用的用户无需升级。

- **Swift Package Manager** — now supported. See [Installation](#installation--集成方式).
  新增 Swift Package Manager 支持，见[集成方式](#installation--集成方式)。
- **Mac Catalyst** — the xcframework ships a Mac Catalyst slice alongside iOS device and simulator.
  xcframework 除 iOS 真机与模拟器外，还包含 Mac Catalyst 切片。
- **Docs** — added an Installation section; corrected the authorization API (keys are set via
  `VTMURATUtils.wearablePPGKey` / `.controlKey`, not a key manager class); documented which
  commands the keys actually gate.
  新增集成章节；修正授权接口说明（Key 通过 `VTMURATUtils.wearablePPGKey` / `.controlKey`
  设置，而非某个 key 管理类）；补充了 Key 实际保护哪些指令。
- **Demo** — fixed three compile errors against 1.5.x (`er3_notifyMeasurementStart` /
  `er3_notifyMeasurementEnd` renames; the `andState:` argument of
  `parseER3RealWaveData:withCable:andState:` needs a `VTMER3LeadState` converted via
  `parseCable:state:`). Now uses `setPeripheral:advertisementData:` as the docs require,
  and demonstrates `VTMURATDeviceExtension` for custom BLE names.
  修复 Demo 对 1.5.x 编译不过的三处问题；改用文档要求的 `setPeripheral:advertisementData:`；
  并演示了用于自定义蓝牙名的 `VTMURATDeviceExtension`。

---

## Supported Devices / 支持的设备

| Category / 类别 | Devices / 设备型号 | DeviceType |
|---|---|---|
| ECG Monitor / 心电监护 | ER1, ER2, VBeat, DuoEK, DuoEKS | `VTMDeviceTypeECG` |
| Blood Pressure / 血压计 | BP2, BP2A, BP2T, BP2W, BP2Pro, BP3 | `VTMDeviceTypeBP` |
| Body Scale / 体脂秤 | S1 | `VTMDeviceTypeScale` |
| 12-Lead ECG / 多导心电 | Lepod, Lepod Pro | `VTMDeviceTypeER3` |
| M-Series ECG / M系列心电 | M12, M5 | `VTMDeviceTypeMSeries` |
| Wearable Oximeter / 腕式血氧仪 | O2Ring S | `VTMDeviceTypeWOxi` |
| Finger Clip Oximeter / 指夹血氧仪 | PF-10BWS | `VTMDeviceTypeFOxi` |
| Baby Monitor / 婴儿监护 | BBSM P1 | `VTMDeviceTypeBabyPatch` |
| Ventilator / 呼吸机 | R200 | `VTMDeviceTypeVentilator` |

---

## Requirements / 环境要求

- iOS 11.0+ (Xcode 15 and newer raise their own floor to iOS 12 / Xcode 15 及以上版本自身的下限为 iOS 12)
- Mac Catalyst 14.0+
- Objective-C or Swift. The framework defines a module, so no bridging header is needed.
  Objective-C 或 Swift 均可。框架自带 module，无需桥接头文件。

---

## Installation / 集成方式

### Swift Package Manager

In Xcode: **File ▸ Add Package Dependencies…** and enter

在 Xcode 中选择 **File ▸ Add Package Dependencies…**，输入

```
https://github.com/viatom-dev/VTProductLib
```

Or declare it in your own `Package.swift`. Note the package identity is
`VTProductLib` (taken from the repository name) while the product is `VTMProductLib`:

或在自己的 `Package.swift` 中声明。注意包标识是 `VTProductLib`（取自仓库名），
而产品名是 `VTMProductLib`：

```swift
dependencies: [
    .package(url: "https://github.com/viatom-dev/VTProductLib", from: "1.5.7")
],
targets: [
    .target(
        name: "YourApp",
        dependencies: [
            .product(name: "VTMProductLib", package: "VTProductLib")
        ]
    )
]
```

### CocoaPods

```ruby
pod 'VTMProductLib'
```

### Manual / 手动集成

Download `VTMProductLib.xcframework` from the
[repository](https://github.com/viatom-dev/VTProductLib) and drag it into your project.
The framework is static and contains Objective-C++ code, so add `-lc++` to
**Other Linker Flags** if your app has no C++ or Swift code of its own — otherwise the
link fails with undefined `std::` symbols. The SPM and CocoaPods integrations handle
this for you.

从[仓库](https://github.com/viatom-dev/VTProductLib)下载 `VTMProductLib.xcframework`
拖入工程即可。该框架为静态库且包含 Objective-C++ 代码，如果你的 App 本身不含 C++ 或
Swift 代码，需要在 **Other Linker Flags** 中加入 `-lc++`，否则链接时会报 `std::`
符号未定义。SPM 与 CocoaPods 方式已自动处理此项。

### Import / 引入

```objc
// Objective-C
#import <VTMProductLib/VTMProductLib.h>
```

```swift
// Swift
import VTMProductLib
```

Supported slices / 支持的切片：

| Slice | Platform |
|---|---|
| `ios-arm64` | iOS device / iOS 真机 |
| `ios-arm64_x86_64-simulator` | iOS Simulator / iOS 模拟器 |
| `ios-arm64_x86_64-maccatalyst` | Mac Catalyst |

Native macOS, visionOS, tvOS and watchOS are not supported.

不支持原生 macOS、visionOS、tvOS、watchOS。

---

## Architecture Overview / 架构概述

```
┌─────────────────────────────────────────────────────┐
│                   Your App / 你的应用                  │
├─────────────────────────────────────────────────────┤
│  VTMURATUtils / VTO2Communicate  (Communication)    │
│  ─────────────────────────────────────────────────  │
│  VTMBLEParser / VTO2Parser       (Data Parsing)     │
│  ─────────────────────────────────────────────────  │
│  VTMFilter                       (Algorithm)        │
└─────────────────────────────────────────────────────┘
```

---

## Getting Started / 快速开始

The SDK provides two communication modules. Choose based on your device type:

SDK 提供两个通信模块，根据设备类型选择：

| Module / 模块 | Applicable Devices / 适用设备 | Delegate |
|---|---|---|
| `VTMURATUtils` | ECG, BP, Scale, ER3, M-Series, Wearable Oximeter, Finger Clip Oximeter, Baby Monitor, Ventilator | `VTMURATUtilsDelegate` + `VTMURATDeviceDelegate` |
| `VTO2Communicate` | O2Ring, BabyO2, Oxylink, KidsO2 (O2 series) | `VTO2CommunicateDelegate` |

> ⚠️ Do NOT mix the two modules. Use one or the other for a given device.
>
> ⚠️ 两个模块不要混用，对于同一个设备只使用其中一个。

### 1. Scan & Connect / 扫描与连接

Use CoreBluetooth `CBCentralManager` to scan and connect peripherals. SDK does not manage scanning — you handle it yourself.

使用 CoreBluetooth 的 `CBCentralManager` 扫描并连接外设。SDK 不负责扫描，需要你自行管理。

---

## Module A: VTMURATUtils

For ECG, BP, Scale, ER3, M-Series, Wearable Oximeter, Finger Clip Oximeter, Baby Monitor, and Ventilator.

适用于心电、血压、体脂秤、ER3、M 系列、腕式血氧仪、指夹血氧仪、婴儿监护和呼吸机。

> For 2nd-generation oximeter devices and some newer oximeter products, you can use `VTMURATUtils`. Implement `VTMURATDeviceExtension` to extend support for custom BLE names and map them to `VTMDeviceTypeWOxi`, then use the Wearable Oximeter commands (`woxi_*`). If you are unsure whether your device is supported, please contact sales for confirmation.
>
> 二代血氧设备及部分新血氧产品可以使用 `VTMURATUtils`。通过实现 `VTMURATDeviceExtension` 协议可扩展支持定制化蓝牙名称并映射为 `VTMDeviceTypeWOxi`，然后使用腕式血氧仪指令（`woxi_*`）进行通信。如不确定设备是否支持，请联系销售咨询。

### Initialize / 初始化

```objc
#import <VTMProductLib/VTMURATUtils.h>

VTMURATUtils *urat = [[VTMURATUtils alloc] init];
urat.delegate = self;           // Communication callbacks / 通信回调
urat.deviceDelegate = self;     // Service discovery callbacks / 服务发现回调

// Set authorization keys if needed / 如需使用受保护的指令，设置授权 Key
// Registration is process-wide, so assigning them once is enough.
// 注册结果是进程级生效的，因此赋值一次即可。
urat.wearablePPGKey = @"your-ppg-key";
urat.controlKey = @"your-control-key";

// Implement VTMURATDeviceExtension to support custom BLE names for a given device type
// 实现 VTMURATDeviceExtension 协议可扩展支持定制化蓝牙名称
urat.extension = self;

// --- VTMURATDeviceExtension example / 示例 ---
- (NSArray<NSString *> *)extensionNamePrefixsWithType:(VTMDeviceType)deviceType {
    switch (deviceType) {
        case VTMDeviceTypeECG:
            return @[@"MyECG", @"CardioMonitor"];
        case VTMDeviceTypeBP:
            return @[@"MyBP", @"PressureGuard"];
        case VTMDeviceTypeWOxi:
            return @[@"MyO2Ring", @"OxiWatch"];
        case VTMDeviceTypeBabyPatch:
            return @[@"BabySensor"];
        default:
            return nil;
    }
}

// Set connected peripheral with advertisement data / 设置已连接的外设（携带广播数据）
// ⚠️ MUST use this method. Some devices cannot be identified correctly without advertisementData.
// ⚠️ 必须使用此方法。部分设备如果不传 advertisementData 将无法正确识别。
[urat setPeripheral:connectedPeripheral advertisementData:advData];
```

### Wait for Deployment / 等待服务就绪

```objc
// VTMURATDeviceDelegate
- (void)utilDeployCompletion:(VTMURATUtils *)util {
    // Ready to communicate / 可以开始通信了
    // For encrypted devices, call openupEncrypt first / 对于加密设备，先执行加密握手
    // If token or key is nil/empty, SDK uses built-in default credentials automatically
    // 如果 token 或 key 为空，SDK 会自动使用内置默认凭证
    [util openupEncryptWithToken:@"your-token" secretKey:@"your-secret-key"];
}

- (void)utilDeployFailed:(VTMURATUtils *)util {
    // Service/Characteristic error / 服务或特征值错误
}
```

### Commands / 指令

#### Common Commands / 通用指令

```objc
// Get device info / 获取设备信息
[urat requestDeviceInfo];

// Get battery info / 获取电量信息
[urat requestBatteryInfo];

// Sync time / 同步时间
[urat syncTime:[NSDate date]];

// Sync time with timezone (BP2 Pro, O2Ring S) / 同步时间含时区
[urat syncTimeZone:[NSDate date]];

// Get file list / 获取文件列表
[urat requestFilelist];

// Read a file / 读取文件
[urat prepareReadFile:@"20230101120000"];  // Open file / 打开文件
[urat readFile:0];                         // Read from offset / 从偏移位置读取
[urat endReadFile];                        // Close file / 关闭文件

// Write a file (BP2 Pro) / 写入文件
[urat writeFile:data withName:@"filename"];

// Delete a file (BP2 Pro) / 删除文件
[urat deleteFile:@"filename"];

// Factory reset / 恢复出厂设置
[urat factoryReset];

// Clear all status and data / 清除所有状态和数据
[urat allReset];
```

#### ECG Device Commands / 心电设备指令

```objc
// Get ECG config / 获取心电配置
[urat requestECGConfig];

// Get real-time ECG data / 获取实时心电数据
[urat requestECGRealData];

// Set ER1/VBeat config / 设置 ER1/VBeat 配置
VTMER1Config config = {.vibeSw = 0x01, .hrTarget1 = 50, .hrTarget2 = 120};
[urat syncER1Config:config];

// Set ER2/DuoEK config / 设置 ER2/DuoEK 配置
VTMER2Config config2 = {.ecgSwitch = 0x01};
[urat syncER2Config:config2];
```

#### ER3/M-Series Commands / ER3/M系列指令

```objc
// Get ER3 config / 获取 ER3 配置
[urat requestER3Config];

// Set ER3 config / 设置 ER3 配置
[urat syncER3Config:config];

// Get real-time data / 获取实时数据
[urat requestER3ECGRealData];

// M-Series: get real-time data with index / M系列获取带索引的实时数据
[urat requestMSeriesRunParamsWithIndex:0];

// Get/Set config params / 获取/设置配置参数
[urat getER3ConfigParams];
VTMER3ConfigParams params = {.ISO = 0x00, .logo = 0x02};
[urat setER3ConfigParams:params];
```

#### Blood Pressure Commands / 血压设备指令

```objc
// Get BP config / 获取血压配置
[urat requestBPConfig];

// Get real-time BP data / 获取实时血压数据
[urat requestBPRealData];

// Get real-time run status / 获取实时运行状态
[urat bp_requestRealStatus];

// Set BP config / 设置血压配置
[urat syncBPConfig:bpConfig];

// Wi-Fi operations (BP2W/BP3) / Wi-Fi 操作
[urat requestScanWiFiList];
[urat requestBPWiFiConfiguration];
[urat requestBPConfigureWiFi:wifiConfig];

// BP3 alarm / BP3 闹钟设置
[urat bp3_requestAlarmInfo];
[urat bp3_syncAlarmInfo:alarmInfo];
```

#### Scale Commands / 体脂秤指令

```objc
[urat requestScaleRunPrams];
[urat requestScaleRealData];
[urat requestScaleRealWve];
```

#### Wearable Oximeter Commands / 腕式血氧仪指令

```objc
[urat woxi_requestConfig];
[urat woxi_requestWOxiRealData];
[urat woxi_requestWOxiRunParams];
[urat woxi_syncConfigParam:param];

// PPG raw data / PPG 原始数据
VTMWOxiRawSampleInfo info = {.marker = 0x01, .sample_rate = 0};
[urat woxi_requestWOxiPPGData:info];

// Push control / 推送控制
[urat observeParameters:YES waveform:YES rawdata:NO accdata:NO];
```

#### Finger Clip Oximeter Commands / 指夹血氧仪指令

```objc
[urat foxi_requestConfig];
[urat foxi_syncConfigParam:param];
[urat foxi_makeInfoSend:YES];
[urat foxi_makeWaveSend:YES];
```

#### Baby Monitor Commands / 婴儿监护指令

```objc
[urat baby_requestConfig];
[urat baby_syncConfigParam:param];
[urat baby_requestRunParams];
[urat baby_requestGesture];
```

#### Ventilator Commands / 呼吸机指令

```objc
[urat ventilator_requestLastestStatistics];
[urat ventilator_requestStatisticsList:timeInterval];

// Read statistics file / 读取统计文件
[urat ventilator_prepareReadStatisticsFile:@"filename"];
[urat ventilator_readStatisticsFile:0];
[urat ventilator_endReadStaitsticsFile];

// Wi-Fi / Wi-Fi 配置
[urat ventilator_scanWiFiList];
[urat ventilator_requestWiFiConfiguration];
[urat ventilator_syncConfigureWiFi:wifiConfig];
```

---

### VTMURATUtilsDelegate — Response Callbacks / 响应回调

```objc
- (void)util:(VTMURATUtils *)util
    commandCompletion:(u_char)cmdType
           deviceType:(VTMDeviceType)deviceType
             response:(NSData *)response {

    switch (deviceType) {

        // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
        // Common commands (all device types)
        // 通用指令（所有设备类型）
        // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
        default: {
            switch (cmdType) {
                case VTMBLECmdGetDeviceInfo: {
                    VTMDeviceInfo info = [VTMBLEParser parseDeviceInfo:response];
                    break;
                }
                case VTMBLECmdGetBattery: {
                    VTMBatteryInfo battery = [VTMBLEParser parseBatteryInfo:response];
                    break;
                }
                case VTMBLECmdGetFileList: {
                    VTMFileList fileList = [VTMBLEParser parseFileList:response];
                    break;
                }
                case VTMBLECmdStartRead: {
                    VTMOpenFileReturn fileLen = [VTMBLEParser parseFileLength:response];
                    // fileLen.file_size — total bytes / 文件总长度
                    break;
                }
                case VTMBLECmdReadFile: {
                    VTMFileData fileData = [VTMBLEParser parseFileData:response];
                    // Append fileData.file_data to your buffer / 拼接到缓冲区
                    break;
                }
                default:
                    break;
            }
            break;
        }

        // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
        // ECG devices (ER1, ER2, VBeat, DuoEK)
        // 心电设备
        // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
        case VTMDeviceTypeECG: {
            switch (cmdType) {
                case VTMECGCmdGetConfig: {
                    // ER1/VBeat
                    VTMER1Config er1Cfg = [VTMBLEParser parseER1Config:response];
                    // or ER2/DuoEK
                    // VTMER2Config er2Cfg = [VTMBLEParser parseER2Config:response];
                    break;
                }
                case VTMECGCmdGetRealData: {
                    VTMRealTimeData rtData = [VTMBLEParser parseRealTimeData:response];
                    // rtData.run_para.hr — heart rate / 心率
                    // rtData.waveform — waveform data / 波形数据
                    VTMFreeRealTimeData(&rtData);
                    break;
                }
                default:
                    break;
            }
            break;
        }

        // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
        // ER3 (Lepod Pro)
        // 多导联心电
        // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
        case VTMDeviceTypeER3: {
            switch (cmdType) {
                case VTMECGCmdGetConfig: {
                    VTMER3Config er3Cfg = [VTMBLEParser parseER3Config:response];
                    break;
                }
                case VTMER3ECGCmdGetRealData: {
                    VTMER3RealTimeData rtData = [VTMBLEParser parseER3RealTimeData:response];
                    // rtData.run_params — run parameters / 运行参数
                    // rtData.waveform — compressed waveform / 压缩波形
                    // Decompress waveform / 解压波形:
                    // NSData *waveData = [VTMBLEParser parseER3WaveData:data withCable:rtData.run_params.cable_type];
                    break;
                }
                case VTMER3ECGCmdGetConfigParams: {
                    VTMER3ConfigParams params = [VTMBLEParser parseER3ConfigParams:response];
                    break;
                }
                default:
                    break;
            }
            break;
        }

        // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
        // M-Series (M12, M5)
        // M系列心电
        // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
        case VTMDeviceTypeMSeries: {
            switch (cmdType) {
                case VTMMSeriesCmdGetRealData: {
                    VTMMSeriesRunParams params = [VTMBLEParser parseMSeriesRunParams:response];
                    VTMMSeriesFlag flag = [VTMBLEParser parseMSeiriesSysFlag:params];
                    break;
                }
                default:
                    break;
            }
            break;
        }

        // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
        // Blood Pressure (BP2, BP2A, BP2W, BP2Pro, BP3)
        // 血压设备
        // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
        case VTMDeviceTypeBP: {
            switch (cmdType) {
                case VTMBPCmdGetConfig: {
                    VTMBPConfig bpCfg = [VTMBLEParser parseBPConfig:response];
                    break;
                }
                case VTMBPCmdGetRealData: {
                    VTMBPRealTimeData bpData = [VTMBLEParser parseBPRealTimeData:response];
                    // bpData.run_status.status — current status / 当前状态 (VTMBPStatus)
                    // bpData.rt_wav — real-time waveform / 实时波形
                    VTMFreeBPRealTimeData(&bpData);
                    break;
                }
                case VTMBPCmdGetRealStatus: {
                    VTMBPRunStatus status = [VTMBLEParser parseBPRealTimeStatus:response];
                    break;
                }
                case VTMBPCmdScanWiFiList: {
                    NSArray *wifiList = [VTMBLEParser parseWiFiList:response];
                    break;
                }
                case VTMBPCmdGetWiFiConfig: {
                    VTMWiFiConfig wifiCfg = [VTMBLEParser parseWiFiConfig:response];
                    VTMFreeWiFiConfig(&wifiCfg);
                    break;
                }
                case VTMBPCmdGetAlarmInfo: {
                    // BP3 only
                    VTMBP3AlarmInfo alarm = [VTMBLEParser bp3_parseAlarmInfo:response];
                    VTMFreeBP3AlarmInfo(&alarm);
                    break;
                }
                default:
                    break;
            }
            break;
        }

        // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
        // Body Scale (S1)
        // 体脂秤
        // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
        case VTMDeviceTypeScale: {
            switch (cmdType) {
                case VTMSCALECmdGetRunParams: {
                    VTMScaleRunParams params = [VTMBLEParser parseScaleRunParams:response];
                    break;
                }
                case VTMSCALECmdGetRealData: {
                    VTMScaleRealData scaleData = [VTMBLEParser parseScaleRealData:response];
                    // scaleData.run_para — run params / 运行参数
                    // scaleData.scale_data — weight & resistance / 体重和阻抗
                    // scaleData.waveform — ECG waveform / 心电波形
                    VTMFreeScaleRealData(&scaleData);
                    break;
                }
                default:
                    break;
            }
            break;
        }

        // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
        // Wearable Oximeter (O2Ring S)
        // 腕式血氧仪
        // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
        case VTMDeviceTypeWOxi: {
            switch (cmdType) {
                case VTMWOxiCmdGetConfig: {
                    VTMWOxiInfo oxiInfo = [VTMBLEParser woxi_parseConfig:response];
                    break;
                }
                case VTMWOxiCmdGetRealData: {
                    VTMWOxiRealData oxiData = [VTMBLEParser woxi_parseRealData:response];
                    // oxiData.run_para.spo2 — SpO2 / 血氧
                    // oxiData.run_para.pr — pulse rate / 脉率
                    // oxiData.run_para.pi — perfusion index / 灌注指数
                    // oxiData.waveform — plethysmogram waveform / 脉搏波形
                    VTMFreeWOxiRealData(&oxiData);
                    break;
                }
                default:
                    break;
            }
            break;
        }

        // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
        // Finger Clip Oximeter (PF-10BWS)
        // 指夹血氧仪
        // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
        case VTMDeviceTypeFOxi: {
            switch (cmdType) {
                case VTMFOxiCmdGetConfig: {
                    VTMFOxiConfig foxiCfg = [VTMBLEParser foxi_parseConfig:response];
                    break;
                }
                case VTMFOxiCmdInfoResp: {
                    VTMFOxiMeasureInfo info = [VTMBLEParser foxi_parseMeasureInfo:response];
                    // info.spo2, info.pr, info.pi
                    break;
                }
                case VTMFOxiCmdWaveResp: {
                    [VTMBLEParser foxi_parseMeasureWave:response completion:^(int num, VTMFOxiMeasureWave *wave) {
                        // num — number of wave points / 波形点数
                        // wave — waveform data / 波形数据
                    }];
                    break;
                }
                case VTMFOxiCmdWorkMode: {
                    VTMFOxiWorkStatus status = [VTMBLEParser foxi_parseWorkStatus:response];
                    break;
                }
                default:
                    break;
            }
            break;
        }

        // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
        // Baby Monitor (BBSM P1)
        // 婴儿监护
        // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
        case VTMDeviceTypeBabyPatch: {
            switch (cmdType) {
                case VTMBabyCmdGetConfig: {
                    VTMBabyConfig babyCfg = [VTMBLEParser baby_parseConfig:response];
                    break;
                }
                case VTMBabyCmdGetRunParams: {
                    VTMBabyRunParams params = [VTMBLEParser baby_parseRunParams:response];
                    // params.rr — respiration rate / 呼吸率
                    // params.cur_temperature — temperature / 当前温度
                    // params.attitude_status — posture / 姿态
                    // params.hasSleepInfo — whether sleep info is available / 是否包含睡眠信息
                    if (params.hasSleepInfo) {
                        // params.sleepInfo.Sleep_state — VTMBabySleepState (Deep/Light/Wake)
                        // params.sleepInfo.falling_asleep — sleep start timestamp / 入睡时间戳
                        // params.sleepInfo.awake_time — wake timestamp / 出睡时间戳
                        // params.sleepInfo.cough_display_flag — cough flag / 咳嗽标志
                    }
                    break;
                }
                case VTMBabyCmdGetGesture: {
                    VTMBabyAtt attitude = [VTMBLEParser baby_parseAttitude:response];
                    break;
                }
                default:
                    break;
            }
            break;
        }

        // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
        // Ventilator (R200)
        // 呼吸机
        // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
        case VTMDeviceTypeVentilator: {
            switch (cmdType) {
                case VTMRVentilatorCmdGetLatest: {
                    VTMRStatistict stat = [VTMBLEParser ventilator_parseStatistictData:response];
                    break;
                }
                case VTMRVentilatorCmdGetStatisticsList: {
                    VTMRStatistictsList list = [VTMBLEParser ventilator_parseStatisticsList:response];
                    VTMFreeRStatistictsList(&list);
                    break;
                }
                case VTMRVentilatorCmdScanWiFi: {
                    NSArray *wifiList = [VTMBLEParser parseWiFiList:response];
                    break;
                }
                case VTMRVentilatorCmdWiFiConfig: {
                    VTMWiFiConfig wifiCfg = [VTMBLEParser parseWiFiConfig:response];
                    VTMFreeWiFiConfig(&wifiCfg);
                    break;
                }
                default:
                    break;
            }
            break;
        }
    }
}

// Command failed / 指令失败
- (void)util:(VTMURATUtils *)util
    commandFailed:(u_char)cmdType
       deviceType:(VTMDeviceType)deviceType
       failedType:(VTMBLEPkgType)type {
    // Handle error / 处理错误
}

// Send error / 发送错误
- (void)util:(VTMURATUtils *)util commandSendFailed:(u_char)errorCode {
    // 0: peripheral nil  1: tx nil  2: disconnected  3: timeout
}
```

---

### VTMBLEParser — Data Parsing / 数据解析

Parses raw `NSData` responses into structured C types.

将原始 `NSData` 响应解析为结构化的 C 类型。

#### Common Parsing / 通用解析

```objc
VTMDeviceInfo info = [VTMBLEParser parseDeviceInfo:response];
VTMBatteryInfo battery = [VTMBLEParser parseBatteryInfo:response];
VTMFileList fileList = [VTMBLEParser parseFileList:response];
```

#### ECG Parsing / 心电解析

```objc
// Real-time data / 实时数据
VTMRealTimeData rtData = [VTMBLEParser parseRealTimeData:response];
// Access: rtData.run_para.hr, rtData.waveform.wave_data
// Remember to free / 记得释放内存
VTMFreeRealTimeData(&rtData);

// Real-time waveform only / 仅实时波形
VTMRealTimeWF wf = [VTMBLEParser parseRealTimeWaveform:response];
VTMFreeRealTimeWF(&wf);

// Parse mV value / 解析 mV 值
float mv = [VTMBLEParser mVFromShort:shortValue];

// Config / 配置
VTMER1Config er1Cfg = [VTMBLEParser parseER1Config:response];
VTMER2Config er2Cfg = [VTMBLEParser parseER2Config:response];

// ER3 real-time data / ER3 实时数据
VTMER3RealTimeData er3Data = [VTMBLEParser parseER3RealTimeData:response];

// ER3 waveform decompression / ER3 波形解压
NSData *waveData = [VTMBLEParser parseER3WaveData:data withCable:cable];

// ER3 12-lead parsing / ER3 十二导联解析
NSArray *leads = [VTMBLEParser parseER3RealWaveData:data withCable:cable andState:state];

// File parsing / 文件解析
[VTMBLEParser parseWaveHeadAndTail:fileData result:^(VTMFileHead head, VTMER2FileTail tail) {
    // ...
}];

// ER3 file parsing / ER3 文件解析
[VTMBLEParser parseER3OriginFile:fileData
    head:^(VTMER3FileHead head) { }
    fragment:^(NSData *subData) { }
    tail:^(VTMER3FileTail tail) { }];
```

#### Blood Pressure Parsing / 血压解析

```objc
VTMBPRealTimeData bpData = [VTMBLEParser parseBPRealTimeData:response];
VTMFreeBPRealTimeData(&bpData);

VTMBPRunStatus status = [VTMBLEParser parseBPRealTimeStatus:response];
VTMBPConfig bpCfg = [VTMBLEParser parseBPConfig:response];
VTMBPBPResult bpResult = [VTMBLEParser parseBPResult:response];
VTMBPECGResult ecgResult = [VTMBLEParser parseECGResult:response];

// BP measuring data / 血压测量中数据
VTMBPMeasuringData measuring = [VTMBLEParser parseBPMeasuringData:response];
VTMBPEndMeasureData endData = [VTMBLEParser parseBPEndMeasureData:response];

// WiFi / WiFi 解析
NSArray *wifiList = [VTMBLEParser parseWiFiList:response];
VTMWiFiConfig wifiCfg = [VTMBLEParser parseWiFiConfig:response];
VTMFreeWiFiConfig(&wifiCfg);
```

#### Scale Parsing / 体脂秤解析

```objc
VTMScaleRunParams runParams = [VTMBLEParser parseScaleRunParams:response];
VTMScaleRealData scaleData = [VTMBLEParser parseScaleRealData:response];
VTMFreeScaleRealData(&scaleData);

[VTMBLEParser parseScaleFile:fileData completion:^(VTMScaleFileHead head, VTMScaleFileData data) {
    // ...
}];
```

#### Oximeter Parsing / 血氧仪解析

```objc
// Wearable (O2Ring S) / 腕式
VTMWOxiInfo oxiInfo = [VTMBLEParser woxi_parseConfig:response];
VTMWOxiRealData oxiData = [VTMBLEParser woxi_parseRealData:response];
VTMFreeWOxiRealData(&oxiData);

// Finger Clip (PF-10BWS) / 指夹式
VTMFOxiConfig foxiCfg = [VTMBLEParser foxi_parseConfig:response];
VTMFOxiMeasureInfo foxiInfo = [VTMBLEParser foxi_parseMeasureInfo:response];

// File / 文件解析
[VTMBLEParser oxi_parseFile:fileData completion:^(VTMOxiFileHead head, VTMOxiPoint *point, VTMOxiFileTail tail) {
    // ...
}];
```

#### Baby Monitor Parsing / 婴儿监护解析

```objc
VTMBabyConfig babyCfg = [VTMBLEParser baby_parseConfig:response];
VTMBabyRunParams babyParams = [VTMBLEParser baby_parseRunParams:response];
VTMBabyAtt attitude = [VTMBLEParser baby_parseAttitude:response];

// Sleep info (auto-detected by parser) / 睡眠信息（解析器自动检测）
if (babyParams.hasSleepInfo) {
    VTMBabySleepInfo sleep = babyParams.sleepInfo;
    // sleep.Sleep_state — VTMBabySleepState (Deep/Light/Wake/Unknown)
    // sleep.falling_asleep — sleep start timestamp / 入睡时间戳
    // sleep.awake_time — wake timestamp / 出睡时间戳
    // sleep.cough_display_flag — cough detected / 咳嗽标志
}
```

#### Ventilator Parsing / 呼吸机解析

```objc
VTMRMonitorData monitor = [VTMBLEParser ventilator_parseMonitorData:response];
VTMFreeRMonitorData(&monitor);

VTMRStatistict stat = [VTMBLEParser ventilator_parseStatistictData:response];
VTMRStatistictsList list = [VTMBLEParser ventilator_parseStatisticsList:response];
VTMFreeRStatistictsList(&list);
```

---

---

## Module B: VTO2Communicate

For O2 series devices: O2Ring, BabyO2, Oxylink, KidsO2, etc. Supports both encrypted and non-encrypted devices (internally implemented via `VTMURATUtils`).

适用于 O2 系列设备：O2Ring、BabyO2、Oxylink、KidsO2 等。同时支持加密和非加密设备（内部通过 `VTMURATUtils` 实现）。

### Initialize / 初始化

```objc
#import <VTMProductLib/VTO2Communicate.h>

VTO2Communicate *o2Comm = [[VTO2Communicate alloc] init];
o2Comm.o2Delegate = self;

// Set connected peripheral / 设置已连接的外设
[o2Comm setPeripheral:connectedPeripheral advertisementData:advData];
```

### Wait for Deployment / 等待服务就绪

```objc
// VTO2CommunicateDelegate
- (void)o2_serviceDeployed:(BOOL)completed {
    if (completed) {
        // Ready to communicate / 可以开始通信了
        // For encrypted devices, call openupEncrypt first / 对于加密设备，需先完成加密握手
        // If token or key is nil/empty, SDK uses built-in default credentials automatically
        // 如果 token 或 key 为空，SDK 会自动使用内置默认凭证
        [o2Comm openupEncryptWithToken:@"your-token" secretKey:@"your-secret-key"];
    } else {
        // Service error / 服务错误
    }
}
```

### Commands / 指令

```objc
// Get device info / 获取设备信息
[o2Comm beginGetInfo];

// Get real-time data / 获取实时数据
[o2Comm beginGetRealData];

// Get real-time waveform / 获取实时波形
[o2Comm beginGetRealWave];

// Get PPG data / 获取 PPG 数据
[o2Comm beginGetRealPPG];

// Set parameters / 设置参数
[o2Comm beginToParamType:VTParamTypeOxiThr content:@"90"];

// Set multiple parameters / 批量设置参数
[o2Comm beginToParamsDictionary:@{@"1": @"90", @"5": @"50"}];

// Download file / 下载文件
[o2Comm beginReadFileWithFileName:@"20230101120000"];

// Factory reset / 恢复出厂
[o2Comm beginFactory];
```

### VTO2CommunicateDelegate Callbacks / 响应回调

```objc
- (void)getInfoWithResultData:(NSData *)infoData {
    VTO2Info *info = [VTO2Parser parseO2InfoWithData:infoData];
}

- (void)realDataCallBackWithData:(NSData *)realData {
    VTRealObject *real = [VTO2Parser parseO2RealObjectWithData:realData];
    // real.spo2, real.hr, real.battery, real.pi
}

- (void)realWaveCallBackWithData:(NSData *)realWave {
    VTRealWave *wave = [VTO2Parser parseO2RealWaveWithData:realWave];
    // wave.points — waveform array / 波形数组
}

- (void)readCompleteWithData:(VTFileToRead *)fileData {
    VTO2Object *obj = [VTO2Parser parseO2ObjectWithData:fileData.fileData];
    NSArray<VTO2WaveObject *> *waves = [VTO2Parser parseO2WaveObjectArrayWithWaveData:obj.waveData];
}

- (void)postCurrentReadProgress:(double)progress {
    // Update download progress / 更新下载进度
}

- (void)openupEncryptResult:(VTCommonResult)result {
    // Encryption handshake result / 加密握手结果
    // VTCommonResultSuccess — success / 成功
    // VTCommonResultFailed — failed / 失败
}
```

### Migration from VTO2Lib / 从 VTO2Lib 迁移

If you are migrating from the legacy `VTO2Lib` (which used a singleton pattern), here is a quick guide:

如果你从旧版 `VTO2Lib`（单例模式）迁移到当前库（实例模式），参考以下指引：

**Before (VTO2Lib singleton) / 迁移前（VTO2Lib 单例）：**

```objc
// Old: shared singleton / 旧：使用单例
VTO2Communicate *comm = [VTO2Communicate sharedInstance];
comm.peripheral = peripheral;
```

**After (VTMProductLib instance) / 迁移后（VTMProductLib 实例）：**

```objc
// New: create instance per device / 新：为每个设备创建实例
VTO2Communicate *comm = [[VTO2Communicate alloc] init];
comm.o2Delegate = self;
[comm setPeripheral:peripheral advertisementData:advData];
```

**Key differences / 主要区别：**

| | VTO2Lib (old) | VTMProductLib (current) |
|---|---|---|
| Pattern / 模式 | Singleton (`sharedInstance`) | Instance (`alloc init`) |
| Set peripheral / 设置外设 | `comm.peripheral = ...` | `[comm setPeripheral:... advertisementData:...]` |
| Multi-device / 多设备支持 | Not supported / 不支持 | One instance per device / 每个设备一个实例 |

**Migration steps / 迁移步骤：**

1. Replace `[VTO2Communicate sharedInstance]` with `[[VTO2Communicate alloc] init]`.
   将 `[VTO2Communicate sharedInstance]` 替换为 `[[VTO2Communicate alloc] init]`。

2. Replace `comm.peripheral = peripheral` with `[comm setPeripheral:peripheral advertisementData:advData]`.
   将 `comm.peripheral = peripheral` 替换为 `[comm setPeripheral:peripheral advertisementData:advData]`。

3. Hold a strong reference to the instance (e.g. as a property). Since it's no longer a singleton, it will be deallocated if not retained.
   持有实例的强引用（如作为属性）。由于不再是单例，不持有会被释放。

4. API names and delegate methods remain unchanged. No other code changes needed.
   API 名称和代理方法保持不变，无需其他代码修改。

---

## Common Tools / 通用工具

### VTMFilter — ECG Signal Filter / 心电信号滤波

```objc
VTMFilter *filter = [VTMFilter shared];

// Reset before new measurement / 新测量前重置
[filter resetParams];

// Real-time filtering (one point at a time) / 实时滤波（逐点）
NSArray *filtered = [filter filterPointValue:mVValue];

// Real-time filtering (batch) / 实时滤波（批量）
NSArray *filtered = [filter sfilterPointValue:pointArray];

// Offline filtering (history file) / 离线滤波（历史文件）
NSArray *filtered = [filter offlineFilterPoints:pointArray];
```

---

## Memory Management / 内存管理

Some parsed structs contain dynamically allocated memory. You **must** call the corresponding free function after use.

部分解析后的结构体包含动态分配的内存，使用完毕后**必须**调用对应的释放函数。

```objc
VTMRealTimeData data = [VTMBLEParser parseRealTimeData:response];
// Use data... / 使用数据...
VTMFreeRealTimeData(&data);

// Available free functions / 可用的释放函数:
VTMFreeRealTimeWF(&wf);
VTMFreeRealTimeData(&data);
VTMFreeScaleRealData(&scaleData);
VTMFreeBPRealTimeWaveform(&wf);
VTMFreeBPRealTimeData(&bpData);
VTMFreeBP3AlarmInfo(&info);
VTMFreeRMonitorData(&monitor);
VTMFreeRStatistictsList(&list);
VTMFreeWiFiInfo(&wifiInfo);
VTMFreeServerInfo(&serverInfo);
VTMFreeWiFiConfig(&config);
VTMFreeWOxiRealData(&oxiData);
```

---

## Key Data Structures / 关键数据结构

### Device Info / 设备信息 — `VTMDeviceInfo`

| Field | Description / 描述 |
|---|---|
| `hw_version` | Hardware version / 硬件版本 (e.g. 'A') |
| `fw_version` | Firmware version / 固件版本 (e.g. 0x010100 = V1.1.0) |
| `bl_version` | Bootloader version / 引导程序版本 |
| `branch_code` | Branch code / 分支编码 |
| `device_type` | Device type / 设备类型 |
| `sn` | Serial number / 序列号 |

### Battery Info / 电量信息 — `VTMBatteryInfo`

| Field | Description / 描述 |
|---|---|
| `state` | 0: Normal / 正常, 1: Charging / 充电中, 2: Full / 充满, 3: Low / 低电量 |
| `percent` | Battery percentage / 电量百分比 |
| `voltage` | Voltage in mV / 电压 (mV) |

### ECG Real-Time Data / 心电实时数据 — `VTMRealTimeData`

| Field | Description / 描述 |
|---|---|
| `run_para.hr` | Heart rate (bpm) / 心率 |
| `run_para.sys_flag` | Status flags / 状态标志 |
| `run_para.record_time` | Recording duration (s) / 已记录时长 |
| `waveform.sampling_num` | Number of samples / 采样点数 |
| `waveform.wave_data` | Raw waveform data / 原始波形数据 |

### BP Result / 血压结果 — `VTMBPBPResult`

| Field | Description / 描述 |
|---|---|
| `systolic_pressure` | Systolic (mmHg) / 收缩压 |
| `diastolic_pressure` | Diastolic (mmHg) / 舒张压 |
| `mean_pressure` | Mean pressure (mmHg) / 平均压 |
| `pulse_rate` | Pulse rate (bpm) / 脉率 |

### O2 Real-Time Object / O2 实时对象 — `VTRealObject`

| Property | Description / 描述 |
|---|---|
| `spo2` | Blood oxygen (%) / 血氧值 |
| `hr` | Heart rate (bpm) / 心率 |
| `pi` | Perfusion Index / 灌注指数 |
| `battery` | Battery level / 电量 |
| `leadState` | Lead status / 导联状态 |

---

## Error Handling / 错误处理

### BLE Package Error Types / 蓝牙包错误类型 — `VTMBLEPkgType`

| Value | Meaning / 含义 |
|---|---|
| `VTMBLEPkgTypeNotFound` (0xE0) | File not found / 文件不存在 |
| `VTMBLEPkgTypeOpenFailed` (0xE1) | Open file failed / 打开文件失败 |
| `VTMBLEPkgTypeReadFailed` (0xE2) | Read file failed / 读取文件失败 |
| `VTMBLEPkgTypeWriteFailed` (0xE3) | Write file failed / 写入文件失败 |
| `VTMBLEPkgTypeDeviceOccupied` (0xFB) | Device occupied / 设备被占用 |
| `VTMBLEPkgTypeFormatError` (0xFC) | Format error / 格式错误 |
| `VTMBLEPkgTypeFormatUnsupport` (0xFD) | Unsupported format / 不支持的格式 |
| `VTMBLEPkgTypeCommonError` (0xFF) | Common error / 通用错误 |

---

## Typical Workflow / 典型工作流程

```
1. Scan peripheral        / 扫描设备
2. Connect peripheral     / 连接设备
3. Set peripheral to SDK  / 将外设传入 SDK
4. Wait for deployment    / 等待服务就绪
5. Send commands          / 发送指令
6. Parse responses        / 解析响应
7. Free memory if needed  / 释放内存（如需要）
```

---

## Notes / 注意事项

- The SDK automatically determines device type from the peripheral name and advertisement data.
  SDK 会根据外设名称和广播数据自动判断设备类型。

- Commands are device-type specific. Sending an ECG command to a BP device will be ignored.
  指令按设备类型区分，向血压设备发送心电指令将被忽略。

- File reading is a lock operation. You must call `endReadFile` before reading another file.
  文件读取为锁定操作，读取下一个文件前必须调用 `endReadFile`。

- Authorization keys only gate a subset of commands; everything else works without them.
  Calling a gated command without a valid key triggers an assertion in Debug builds. In
  Release builds assertions are compiled out, so set the keys before shipping.

  授权 Key 只保护部分指令，其余接口无需 Key 即可使用。未设置有效 Key 就调用受保护指令，
  Debug 构建会触发断言；Release 构建中断言被编译移除，因此请在发版前确认已设置 Key。

  | Key | Gated commands / 受保护的指令 |
  |---|---|
  | `controlKey` | `er1_notifyMeasurementEnd`, `bp_syncRunState:`, `er3_notifyMeasurementStart`, `er3_notifyMeasurementEnd` |
  | `wearablePPGKey` | `woxi_requestPPGList`, `woxi_prepareReadPPGFile:`, `woxi_readPPGFile:`, `woxi_endReadPPGFile` |

---

## License / 许可

Copyright © Viatom Technology. All rights reserved.
