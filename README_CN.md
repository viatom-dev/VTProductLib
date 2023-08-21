[TOC]

#### 1. VTProductLib
* ##### 1.1 版本变更日志
    ##### [变更日志](https://github.com/viatom-dev/VTProductLib/blob/main/ChangeLog.md)
* ##### 1.2 功能描述
   VTProduct是为源动健康多款产品开发的iOS版本的SDK，目前主要支持部分心电系列产品以及S1体脂秤。主要功能大致分为通信和解析两部分。
   &nbsp;&nbsp; 1. 通信功能。 用于使用Bluetooth的iOS设备与产品进行通信。 主要功能分为读取设备信息，下载数据，同步设备参数，恢复出厂和读取实时数据等。
   &nbsp;&nbsp; 2. 解析功能。 用于解析通信获取后的各类数据，并返回相应的结构体供其他开发者使用。

#### 2. 环境
   &nbsp;&nbsp;&nbsp; iOS 9.0及以上

#### 3. 集成

* ##### 3.1 使用cocoapods集成

> 使用cocoapods进行集成，如下：
>
> ```pod 'VTProductLib'```

* ##### 3.2 直接导入.xcframework

> 查看 [VTProductLib](https://git.lepudev.com/lepusdk/vtproductlib) 并下载，然后放到你的项目中。

首先，由于`VTMURATUtils`未使用单例模式，需要子类化一个单例，后续使用可以避免一些不必要的问题。
然后，设置`VTMURATUtils`的属性`peripheral`和`VTMURATDeviceDelegate`代理，SDK会进行服务和特征的配置，通过回调方法`utilDeployCompletion:`返回YES，即可以正常通信。
最后，在需要通信的页面设置`VTMURATUtilsDelegate`，发送相应的指令获取数据，通过SDK解析器返回对应的结构体。

<<<<<<< HEAD
#### 4. 以下均为获取数据的接口，设备是否支持，请参考对应设备的协议。

##### 4.1 部分通用
- 读取设备相关的信息
```
- (void)requestDeviceInfo;
```

- 读取设备电池电量信息
```
- (void)requestBatteryInfo;
```

- 同步设备时间
```
- (void)syncTime:(NSDate * _Nullable)date;
```

- 同步设备时间与时区
```
- (void)syncTimeZone:(NSDate * _Nullable)date;
```

- 读取设备存储的文件列表
```
- (void)requestFilelist;
```

- 准备读取指定文件，使用该命令可以获取文件的总长度
```
- (void)prepareReadFile:(NSString * _Nonnull)fileName;
```

- 通过文件的偏移长度来读取下一包文件， 每次会返回一定数量的文件字节数
```
- (void)readFile:(u_int)offset;
```

- 读取文件结束/终止，需要停止读取
```
- (void)endReadFile;
```

- 准备写入文件
```
- (void)prepareWriteFile:(VTMWriteFileReturn)writeFile;
```

- 写入文件 
```
- (void)writeFile:(NSData * _Nonnull)data;
```

- 写入文件结束/终止，需要关闭写入
```
- (void)endWriteFile;
```

- 删除设备文件
```
- (void)deleteFile;
```

- 恢复出厂设置
```
- (void)factoryReset;
```

##### 4.2 以下为ECG系列相关产品特定指令：
- 请求配置信息
```
- (void)requestECGConfig;
```

- 请求实时数据
```
- (void)requestECGRealData;
```

- 配置信息同步， 具体参考协议支持的结构体
```
- (void)syncER1Config:(VTMER1Config)config;
- (void)syncER2Config:(VTMER2Config)config;
```

##### 4.3 以下为BP系列相关产品特定指令：
-  改变BP设备状态
```
- (void)requestChangeBPState:(u_char)state;
```

- 请求配置信息
```
- (void)requestBPConfig;
```

- 配置信息同步
```
- (void)syncBPConfig:(VTMBPConfig)config;
```

- 请求实时数据
```
- (void)requestBPRealData;
```

- 扫描WiFi列表 
```
- (void)requestScanWiFiList;
```

- 获取BP Wi-Fi 配置信息
```
- (void)requestBPWiFiConfiguration;
```

- 配置设备 Wi-Fi 模块信息
```
- (void)requestBPConfigureWiFi:(VTMWiFiConfig)wifiConfig;
```

- 获取用户列表文件CRC32校验
```
- (void)requestCRCFromBPWUserList;
```


##### 4.4 以下为S1体脂秤特定指令:
- 请求实时波形
```
- (void)requestScaleRealWve;
```

- 请求实时数据
```
- (void)requestScaleRealData;
```

#### 5. 数据解析
数据解析通过解析器`VTMBLEParser`进行， 对应的返回同时参考协议文档与`VTMBLEStruct.h`中对应的结构体
=======
#### 4.快速开始
> 查看 [README](https://git.lepudev.com/lepusdk/vtproductlib/-/blob/master/README.md)
>>>>>>> develop
