#### 1.VTProductLib

* ##### 1.1 Changelog

    ##### [Changelog](https://github.com/viatom-dev/VTProductLib/blob/main/ChangeLog.md)

* ##### 1.2 Functions

VTProductLib is iOS framework for a part of Viatom's Product. There are two part in this lib: Communicate function and Data analysis function.
&nbsp;&nbsp; 1. Communicate function.  You can get data from Viatom's Product, also sync parameters the product. 
&nbsp;&nbsp; 2. Data analysis function. 用于解析通信获取后的各类数据，并返回相应的结构体供其他开发者使用。

#### 2. Environment
&nbsp;&nbsp;&nbsp; iOS 9.0 or later.

#### 3. Quick Start
First of all, because `VTMURATUtils` does not use the singleton mode, you need to subclass a singleton, and subsequent use can avoid some unnecessary problems.
Then, set the property `peripheral` and `VTMURATDeviceDelegate` proxy of `VTO2Communicate`, the SDK will configure services and features, and return YES through the callback method `utilDeployCompletion:`, that is, normal communication can be performed.
Finally, set `VTMURATUtilsDelegate` on the page that needs to be communicated, send the corresponding command to get the data, and return the corresponding structure through the `VTMBLEParser`.

#### 4. All methods the following is used communicate with product. Whether the product supports it, please refer to the protocol of the corresponding product.

##### 4.1 Common
- Request product info.
```
- (void)requestDeviceInfo;
```

- Request product current battery info.
```
- (void)requestBatteryInfo;
```

- Sync product time.
```
- (void)syncTime:(NSDate * _Nullable)date;
```

- Request file list from product.
```
- (void)requestFilelist;
```

- Prepare to read file by the file name from file list. 
```
- (void)prepareReadFile:(NSString * _Nonnull)fileName;
```

- Read the next package file by the offset length of the file, and return a certain number of file bytes each time.
```
- (void)readFile:(u_int)offset;
```

- End read file.
```
- (void)endReadFile;
```

- Restore factory.
```
- (void)factoryReset;
```

##### 4.2 ECG series related product specific command：
- Request config info.
```
- (void)requestECGConfig;
```

- Request real data.
```
- (void)requestECGRealData;
```

- Sync config info, Struct supported by the reference protocol.
```
- (void)syncER1Config:(VTMER1Config)config;
- (void)syncER2Config:(VTMER2Config)config;
```

##### 4.3 Blood pressure series related product specific command：
- Request config info.
```
- (void)requestBPConfig;
```

- Set the buzzer switch.
```
- (void)syncBPSwitch:(BOOL)swi;
```

- Request real data.
```
- (void)requestBPRealData;
```

##### 4.4 S1 body scale series related product specific command:
- Request real waveform.
```
- (void)requestScaleRealWve;
```

- Request real data.
```
- (void)requestScaleRealData;
```

#### 5. Parse the data.
Parse the data through `VTMBLEParser`, Reference protocol document and the corresponding structure in `VTMBLEStruct.h`.

