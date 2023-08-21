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
然后，设置`VTO2Communicate`的属性`peripheral`和`VTMURATDeviceDelegate`代理，SDK会进行服务和特征的配置，通过回调方法`utilDeployCompletion:`返回YES，即可以正常通信。
最后，在需要通信的页面设置`VTMURATUtilsDelegate`，发送相应的指令获取数据，通过SDK解析器返回对应的结构体。

#### 4.快速开始
> 查看 [README](https://git.lepudev.com/lepusdk/vtproductlib/-/blob/master/README.md)
