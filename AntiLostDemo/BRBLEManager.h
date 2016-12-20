//
//  BRBLEManager.h
//  AntiLostDemo
//
//  Created by Brown on 16/12/9.
//  Copyright © 2016年 Brown. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreBluetooth/CoreBluetooth.h>

#ifdef DEBUG
//处理xCode8下打印日志不完全 __PRETTY_FUNCTION__,
#   define DNSLog(format, ...) printf("***** DNSLog ***** %s:(%d) \t -->> %s\n", [[[NSString stringWithUTF8String:__FILE__] lastPathComponent] UTF8String], __LINE__, [[NSString stringWithFormat:(format), ##__VA_ARGS__] UTF8String] )
#else
#   define DNSLog(format, ...)
#endif


typedef void (^CentralStateCallBack)(CBCentralManager *central);
typedef void (^PeripheralStateCallBack)(CBPeripheral *peripheral);
typedef void (^ReadValueCallBack)(CBPeripheral *peripheral, CBCharacteristic *characteristic);
typedef void (^WriteValueCallBack)(CBPeripheral *peripheral, CBCharacteristic *characteristic);
typedef void (^ReadRSSICallBack)(CBPeripheral *peripheral, NSNumber *RSSI);


/**
 *  BRBLEManager
 *  通过添加ChannelKey的方式管理蓝牙连接、监听状态等
 *  回调方法中需要指定主线程更新界面
 *  block 属性 setupXXXX等用完后需要置nil，注册的channelkey也需要移除
 */
@interface BRBLEManager : NSObject

// --------------   property start  ----------------

/**
 *  扫描选项
 *  如果没有设置，默认为@{CBCentralManagerScanOptionAllowDuplicatesKey:@YES};
 */
@property (nonatomic,copy) NSDictionary<NSString *,id> *(^setupScanForPeripheralsWithServicesOptions)();

//发现外设
@property (nonatomic,copy) void (^setupDidDiscoverPeripheralWithCentralManager)(CBCentralManager *central, CBPeripheral *peripheral, NSDictionary *advertisementData, NSNumber *RSSI);

//过滤外设
@property (nonatomic,copy) BOOL (^setupFilterDiscoverPeripheral)(NSString *peripheralName, NSDictionary *advertisementData, NSNumber *RSSI);

//过滤服务
@property (nonatomic,copy) NSArray<CBUUID *>* (^setupFilterDiscoverServices)(CBPeripheral *peripheral);

//过滤特性
@property (nonatomic,copy) NSArray<CBUUID *>* (^setupFilterDiscoverCharacteristics)(CBPeripheral *peripheral,CBService * service);

//发现服务的特征
@property (nonatomic,copy) void (^setupDidDiscoverCharacteristicsForService)(CBPeripheral *peripheral,CBService * service,CBCharacteristic *characteristic);

// --------------   property end  ----------------


// --------------   method start  ----------------
+ (id)shareInstance;

//获取所有ServiceUUIDs相关的连接的设备，设备断开连接后不会马上清除，结合连接状态做判断
- (NSArray<CBPeripheral *> *)retrieveConnectedPeripheralsWithServices:(NSArray<CBUUID *> *)serviceUUIDs;

//清除设置(block等..)
- (void)clearConnectedSetting;

//开始扫描(手动)
- (void)startScanForPeripherals;

//停止扫描
- (void)stopScanForPeripherals;

//连接到设备
- (void)connectPeripheral:(CBPeripheral *)peripheral options:(NSDictionary<NSString *, id> *)options;

//取消连接
- (void)cancelPeripheralConnection:(CBPeripheral *)peripheral;

// --------------   method end  ----------------



//**************************   监听  start  *********************

- (void)registerCentralStateWithChannelKey:(NSString *)channelKey callBack:(CentralStateCallBack)callBack;
- (void)removeCentralStateWithChannelKey:(NSString *)channelKey;
//- (void)removeAllCentralState;

- (void)registerPeripheralStateWithChannelKey:(NSString *)channelKey callBack:(PeripheralStateCallBack)callBack;
- (void)removePeripheralStateWithChannelKey:(NSString *)channelKey;
//- (void)removeAllPeripheralState;

- (void)registerReadValueWithChannelKey:(NSString *)channelKey callBack:(ReadValueCallBack)callBack;
- (void)removeReadValueWithChannelKey:(NSString *)channelKey;
//- (void)removeAllReadValue;

- (void)registerWriteValueWithChannelKey:(NSString *)channelKey callBack:(WriteValueCallBack)callBack;
- (void)removeWriteValueWithChannelKey:(NSString *)channelKey;
//- (void)removeAllWriteValue;

- (void)registerReadRSSIWithChannelKey:(NSString *)channelKey callBack:(ReadRSSICallBack)callBack;
- (void)removeReadRSSIWithChannelKey:(NSString *)channelKey;
//- (void)removeAllReadRSSI;


//**************************   监听  end  *********************

@end
