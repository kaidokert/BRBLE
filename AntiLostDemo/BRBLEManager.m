//
//  BRBLEManager.m
//  AntiLostDemo
//
//  Created by Brown on 16/12/9.
//  Copyright © 2016年 Brown. All rights reserved.
//

#import "BRBLEManager.h"


@interface BRBLEListenerModel : NSObject

@property (nonatomic,copy) void (^centralStateCallBack)(CBCentralManager *central);
@property (nonatomic,copy) void (^connectPeripheralStateCallBack)(CBPeripheral *peripheral);
@property (nonatomic,copy) void (^readRSSICallBack)(CBPeripheral *peripheral,NSNumber * RSSI);
@property (nonatomic,copy) void (^readValueCallBack)(CBPeripheral *peripheral,CBCharacteristic *characteristic);
@property (nonatomic,copy) void (^writeValueCallBack)(CBPeripheral *peripheral,CBCharacteristic *characteristic);

@property (nonatomic,copy) void (^didUpdatePeripheralNameCallBack)(CBPeripheral *peripheral);

@property (nonatomic,copy) void (^didModifyServicesCallBack)(CBPeripheral *peripheral, NSArray<CBService *> *invalidatedServices);

@end

@implementation BRBLEListenerModel

@end


@interface BRBLEManager()<CBPeripheralDelegate,CBCentralManagerDelegate>{
    dispatch_queue_t _ble_queue;
}
@property (nonatomic,strong) CBCentralManager * manager;
@property (nonatomic,strong) NSMutableDictionary * listenerCentralStateChannelKVDict;
@property (nonatomic,strong) NSMutableDictionary * listenerPeripheralStateChannelKVDict;
@property (nonatomic,strong) NSMutableDictionary * listenerReadValueChannelKVDict;
@property (nonatomic,strong) NSMutableDictionary * listenerWriteValueChannelKVDict;
@property (nonatomic,strong) NSMutableDictionary * listenerReadRSSIChannelKVDict;

@end

#pragma mark - implements
@implementation BRBLEManager

+ (id)shareInstance{
    static BRBLEManager * instance = nil;
    static dispatch_once_t once;
    dispatch_once(&once, ^{
        instance = [[BRBLEManager alloc] init];
    });
    return instance;
}

#pragma mark - init
- (id)init{
    self = [super init];
    if (self) {
        [self initData];
    }
    return self;
}

- (void)initData{
    
    /**
     * 串行:DISPATCH_QUEUE_SERIAL
     * 并行:DISPATCH_QUEUE_CONCURRENT
     */
    _ble_queue = dispatch_queue_create("com.brble.central.manager.dispatch.queue", DISPATCH_QUEUE_CONCURRENT);//DISPATCH_QUEUE_SERIAL DISPATCH_QUEUE_CONCURRENT
    
    self.listenerCentralStateChannelKVDict = [NSMutableDictionary new];
    self.listenerPeripheralStateChannelKVDict = [NSMutableDictionary new];
    self.listenerReadValueChannelKVDict = [NSMutableDictionary new];
    self.listenerWriteValueChannelKVDict = [NSMutableDictionary new];
    self.listenerReadRSSIChannelKVDict = [NSMutableDictionary new];
    
    self.manager = [[CBCentralManager alloc] initWithDelegate:self queue:_ble_queue];
}




#pragma mark - setter 
- (void)setSetupScanForPeripheralsWithServicesOptions:(NSDictionary<NSString *,id> *(^)())setupScanForPeripheralsWithServicesOptions{
    _setupScanForPeripheralsWithServicesOptions = setupScanForPeripheralsWithServicesOptions;
    
    if(self.manager.isScanning){
        [self stopScanForPeripherals];
        [self startScanForPeripherals];
    }
}

#pragma mark - private
- (void)startScanForPeripherals {
    NSDictionary<NSString *,id> *options = nil;
    if(self.setupScanForPeripheralsWithServicesOptions){
        options = self.setupScanForPeripheralsWithServicesOptions();
    }else{
        options = @{CBCentralManagerScanOptionAllowDuplicatesKey:@YES};
    }
    // 开始扫描设备， 第一个参数为nil时为扫描所有蓝牙设备，但是不能在后台扫描
    // 不为nil时带上某个服务时只会扫描有这个服务的设备, 并且这个服务必须在设备广播时发现。 设备广播时没这个服务也是发现不了蓝牙设备的
    [self.manager scanForPeripheralsWithServices:nil options:options];
}

- (void)stopScanForPeripherals {
    [self.manager stopScan];
}

- (void)connectPeripheral:(CBPeripheral *)peripheral options:(NSDictionary<NSString *,id> *)options{
    if(peripheral.state == CBPeripheralStateDisconnected || peripheral.state == CBPeripheralStateDisconnecting){
        [_manager connectPeripheral:peripheral options:options];
    }
}

- (void)cancelPeripheralConnection:(CBPeripheral *)peripheral{
    [_manager cancelPeripheralConnection:peripheral];
}

- (NSArray<CBPeripheral *> *)retrieveConnectedPeripheralsWithServices:(NSArray<CBUUID *> *)serviceUUIDs{
    NSArray<CBPeripheral *> * peripherals = [_manager retrieveConnectedPeripheralsWithServices:serviceUUIDs];
//    for(CBPeripheral * peripheral in peripherals){
//        [_manager connectPeripheral:peripheral options:@{CBConnectPeripheralOptionNotifyOnDisconnectionKey:[NSNumber numberWithBool:true]}];
//    }
    return peripherals;
}


- (void)clearConnectedSetting{
    [self clearBlockSetting];
}

- (void)clearBlockSetting{
    DNSLog(@"清空连接设置");
    self.setupScanForPeripheralsWithServicesOptions = nil;
    self.setupDidDiscoverPeripheralWithCentralManager = nil;
    
    self.setupFilterDiscoverPeripheral = nil;
    self.setupFilterDiscoverServices = nil;
    self.setupFilterDiscoverCharacteristics = nil;
    self.setupDidDiscoverCharacteristicsForService = nil;
}

#pragma mark -  CBCentralManagerDelegate
- (void)centralManagerDidUpdateState:(CBCentralManager *)central{
    
    for(NSString * key in self.listenerCentralStateChannelKVDict.allKeys){
        BRBLEListenerModel * model = [self.listenerCentralStateChannelKVDict valueForKey:key];
        if(model && model.centralStateCallBack){
            model.centralStateCallBack(central);
        }
    }
    
    switch (central.state) {
        case CBCentralManagerStateUnknown:
            DNSLog(@"CBCentralManagerStateUnknown");
            break;
        case CBCentralManagerStateResetting:
            DNSLog(@"CBCentralManagerStateResetting");
            break;
        case CBCentralManagerStateUnsupported:
            DNSLog(@"CBCentralManagerStateUnsupported");
            break;
        case CBCentralManagerStateUnauthorized:
            DNSLog(@"CBCentralManagerStateUnauthorized");
            break;
        case CBCentralManagerStatePoweredOff:{
            DNSLog(@"CBCentralManagerStatePoweredOff");
            [self stopScanForPeripherals];
        }
            break;
        case CBCentralManagerStatePoweredOn:{
            DNSLog(@"CBCentralManagerStatePoweredOn");
            [self startScanForPeripherals];
        }
            break;
        default:
            break;
    }
}

//发现外设
- (void)centralManager:(CBCentralManager *)central didDiscoverPeripheral:(CBPeripheral *)peripheral advertisementData:(NSDictionary *)advertisementData RSSI:(NSNumber *)RSSI{
    if(self.setupFilterDiscoverPeripheral){
        BOOL b = self.setupFilterDiscoverPeripheral(peripheral.name,advertisementData,RSSI);
        if(b){
//            NSLog(@"--->>BRBLEManager 发现外设:%@ --->>",peripheral.name);
            if(self.setupDidDiscoverPeripheralWithCentralManager){
                self.setupDidDiscoverPeripheralWithCentralManager(central,peripheral,advertisementData,RSSI);
            }
        }
    }
}

//即将恢复状态
/**
 * 打开后提示[CoreBluetooth] API MISUSE: <private> has no restore identifier but the delegate implements the centralManager:willRestoreState: method. Restoring will not be supported
 */
//- (void)centralManager:(CBCentralManager *)central willRestoreState:(NSDictionary<NSString *, id> *)dict{
//    NSLog(@"----- 即将恢复状态 ------");
//}

//连接成功代理
- (void)centralManager:(CBCentralManager *)central didConnectPeripheral:(CBPeripheral *)peripheral {
    DNSLog(@"BRBLEManager 连接成功");
    
    for(NSString * key in self.listenerPeripheralStateChannelKVDict.allKeys){
        BRBLEListenerModel * model = [self.listenerPeripheralStateChannelKVDict valueForKey:key];
        if(model && model.connectPeripheralStateCallBack){
            model.connectPeripheralStateCallBack(peripheral);
        }
    }
    
    if(self.setupFilterDiscoverServices){
        NSArray<CBUUID *> * serviceUUIDs = self.setupFilterDiscoverServices(peripheral);
        if(serviceUUIDs && serviceUUIDs.count > 0){
            [peripheral setDelegate:self];
            [peripheral discoverServices:serviceUUIDs];
        }
    }
}

//连接失败代理
- (void)centralManager:(CBCentralManager *)central didFailToConnectPeripheral:(CBPeripheral *)peripheral error:(nullable NSError *)error{
    
    DNSLog(@"BRBLEManager 连接失败");
    for(NSString * key in self.listenerPeripheralStateChannelKVDict.allKeys){
        BRBLEListenerModel * model = [self.listenerPeripheralStateChannelKVDict valueForKey:key];
        if(model && model.connectPeripheralStateCallBack){
            model.connectPeripheralStateCallBack(peripheral);
        }
    }
}

//断开连接代理
- (void)centralManager:(CBCentralManager *)central didDisconnectPeripheral:(CBPeripheral *)peripheral error:(nullable NSError *)error{
    
    DNSLog(@"BRBLEManager 断开连接");
    
    [self cancelPeripheralConnection:peripheral];
    
    for(NSString * key in self.listenerPeripheralStateChannelKVDict.allKeys){
        BRBLEListenerModel * model = [self.listenerPeripheralStateChannelKVDict valueForKey:key];
        if(model && model.connectPeripheralStateCallBack){
            model.connectPeripheralStateCallBack(peripheral);
        }
    }
}

#pragma mark - CBPeripheralDelegate
//外设名称更改时的回调方法
- (void)peripheralDidUpdateName:(CBPeripheral *)peripheral{
    NSLog(@"peripheralDidUpdateName:%@",peripheral.name);
}

//修改服务完成
- (void)peripheral:(CBPeripheral *)peripheral didModifyServices:(NSArray<CBService *> *)invalidatedServices{
    NSLog(@"didModifyServices");
}

//在服务中发现子服务的回调方法
- (void)peripheral:(CBPeripheral *)peripheral didDiscoverIncludedServicesForService:(CBService *)service error:(nullable NSError *)error{
    DNSLog(@"didDiscoverIncludedServicesForService");
}

//写特征完成
- (void)peripheral:(CBPeripheral *)peripheral didWriteValueForCharacteristic:(CBCharacteristic *)characteristic error:(nullable NSError *)error{
    for(NSString * key in self.listenerWriteValueChannelKVDict.allKeys){
        BRBLEListenerModel * model = [self.listenerWriteValueChannelKVDict valueForKey:key];
        if(model && model.writeValueCallBack){
            model.writeValueCallBack(peripheral,characteristic);
        }
    }
}

//特征值的通知设置改变时触发的方法
- (void)peripheral:(CBPeripheral *)peripheral didUpdateNotificationStateForCharacteristic:(CBCharacteristic *)characteristic error:(nullable NSError *)error{
    DNSLog(@"didUpdateNotificationStateForCharacteristic peripheral.name:%@ chara.UUID:%@",peripheral.name,characteristic.UUID.UUIDString);
}

//发现特征的描述
- (void)peripheral:(CBPeripheral *)peripheral didDiscoverDescriptorsForCharacteristic:(CBCharacteristic *)characteristic error:(nullable NSError *)error{
    DNSLog(@"didDiscoverDescriptorsForCharacteristic");
}

//更新描述完成
- (void)peripheral:(CBPeripheral *)peripheral didUpdateValueForDescriptor:(CBDescriptor *)descriptor error:(nullable NSError *)error{
    DNSLog(@"didUpdateValueForDescriptor");
}

//写描述信息时触发的方法
- (void)peripheral:(CBPeripheral *)peripheral didWriteValueForDescriptor:(CBDescriptor *)descriptor error:(nullable NSError *)error{
    DNSLog(@"didWriteValueForDescriptor");
}

//读取外设的信号完成
- (void)peripheral:(CBPeripheral *)peripheral didReadRSSI:(NSNumber *)RSSI error:(nullable NSError *)error{
    if (error) {
        DNSLog(@"Error didReadRSSI:%@", [error localizedDescription]);
        return;
    }
    for(NSString * key in self.listenerReadRSSIChannelKVDict.allKeys){
        BRBLEListenerModel * model = [self.listenerReadRSSIChannelKVDict valueForKey:key];
        if(model && model.readRSSICallBack){
            model.readRSSICallBack(peripheral,RSSI);
        }
    }
}

//发现外设的服务
- (void)peripheral:(CBPeripheral *)aPeripheral didDiscoverServices:(nullable NSError *)error {
    if (error) {
        DNSLog(@"Error discovering service:%@", [error localizedDescription]);
        return;
    }
    if(self.setupFilterDiscoverCharacteristics){
        for (CBService *service in aPeripheral.services) {
            NSArray<CBUUID *>* characteristicUUIDs = self.setupFilterDiscoverCharacteristics(aPeripheral,service);
            if(characteristicUUIDs && characteristicUUIDs.count>0){
                [aPeripheral discoverCharacteristics:characteristicUUIDs forService:service];
            }
        }
    }
}

//发现外设的服务的特征
- (void)peripheral:(CBPeripheral *)peripheral didDiscoverCharacteristicsForService:(CBService *)service error:(nullable NSError *)error {
    
    if (error) {
        DNSLog(@"Error discovering characteristic: %@", [error localizedDescription]);
        return;
    }
    
    for (CBCharacteristic *characteristic in service.characteristics) {
        self.setupDidDiscoverCharacteristicsForService(peripheral,service,characteristic);
        [peripheral setNotifyValue:YES forCharacteristic:characteristic];
    }
}

//更新特征的值完成
- (void)peripheral:(CBPeripheral *)peripheral didUpdateValueForCharacteristic:(CBCharacteristic *)characteristic error:(nullable NSError *)error{
    
    for(NSString * key in self.listenerReadValueChannelKVDict.allKeys){
        BRBLEListenerModel * model = [self.listenerReadValueChannelKVDict valueForKey:key];
        if(model && model.readValueCallBack){
            model.readValueCallBack(peripheral,characteristic);
        }
    }
}

#pragma mark - ------- register 监听
- (void)registerCentralStateWithChannelKey:(NSString *)channelKey callBack:(CentralStateCallBack)callBack{
    DNSLog(@"注册CentralState监听:%@",channelKey);
    BRBLEListenerModel * model = [BRBLEManager setupModelWithKVDict:self.listenerCentralStateChannelKVDict channelKey:channelKey];
    model.centralStateCallBack = callBack;
}

- (void)registerPeripheralStateWithChannelKey:(NSString *)channelKey callBack:(PeripheralStateCallBack)callBack{
    DNSLog(@"注册PeripheralState监听:%@",channelKey);
    BRBLEListenerModel * model = [BRBLEManager setupModelWithKVDict:self.listenerPeripheralStateChannelKVDict channelKey:channelKey];
    model.connectPeripheralStateCallBack = callBack;
}

- (void)registerReadRSSIWithChannelKey:(NSString *)channelKey callBack:(ReadRSSICallBack)callBack{
    DNSLog(@"注册RSSI监听:%@",channelKey);
    BRBLEListenerModel * model = [BRBLEManager setupModelWithKVDict:self.listenerReadRSSIChannelKVDict channelKey:channelKey];
    model.readRSSICallBack = callBack;
}

- (void)registerReadValueWithChannelKey:(NSString *)channelKey callBack:(ReadValueCallBack)callBack{
    DNSLog(@"注册ReadValue监听:%@",channelKey);
    BRBLEListenerModel * model = [BRBLEManager setupModelWithKVDict:self.listenerReadValueChannelKVDict channelKey:channelKey];
    model.readValueCallBack = callBack;
}

- (void)registerWriteValueWithChannelKey:(NSString *)channelKey callBack:(WriteValueCallBack)callBack{
    DNSLog(@"注册WriteValue监听:%@",channelKey);
    BRBLEListenerModel * model = [BRBLEManager setupModelWithKVDict:self.listenerWriteValueChannelKVDict channelKey:channelKey];
    model.writeValueCallBack = callBack;
    
}

#pragma mark - remove with channel key
- (void)removeCentralStateWithChannelKey:(NSString *)channelKey{
    DNSLog(@"移除CentralState监听:%@",channelKey);
    [self.listenerCentralStateChannelKVDict removeObjectForKey:channelKey];
}

- (void)removePeripheralStateWithChannelKey:(NSString *)channelKey{
    DNSLog(@"移除PeripheralState监听:%@",channelKey);
    [self.listenerPeripheralStateChannelKVDict removeObjectForKey:channelKey];
}

- (void)removeReadRSSIWithChannelKey:(NSString *)channelKey{
    DNSLog(@"移除ReadRSSI监听:%@",channelKey);
    [self.listenerReadRSSIChannelKVDict removeObjectForKey:channelKey];
}

- (void)removeReadValueWithChannelKey:(NSString *)channelKey{
    DNSLog(@"移除ReadValue监听:%@",channelKey);
    [self.listenerReadValueChannelKVDict removeObjectForKey:channelKey];
}

- (void)removeWriteValueWithChannelKey:(NSString *)channelKey{
    DNSLog(@"移除WriteValue监听:%@",channelKey);
    [self.listenerWriteValueChannelKVDict removeObjectForKey:channelKey];
}

#pragma mark - remove all
- (void)removeAllCentralState{
    DNSLog(@"移除全部CentralState监听");
    [self.listenerCentralStateChannelKVDict removeAllObjects];
}

- (void)removeAllPeripheralState{
    DNSLog(@"移除全部PeripheralState监听");
    [self.listenerPeripheralStateChannelKVDict removeAllObjects];
}

- (void)removeAllReadRSSI{
    DNSLog(@"移除全部RSSI监听");
    [self.listenerReadRSSIChannelKVDict removeAllObjects];
}

- (void)removeAllReadValue{
    DNSLog(@"移除全部ReadValue监听");
    [self.listenerReadValueChannelKVDict removeAllObjects];
}

- (void)removeAllWriteValue{
    DNSLog(@"移除全部WriteValue监听");
    [self.listenerWriteValueChannelKVDict removeAllObjects];
}

#pragma mark - method ++++
+ (BRBLEListenerModel *)setupModelWithKVDict:(NSMutableDictionary *)kvDict channelKey:(NSString *)channelKey{
    BRBLEListenerModel * model = [BRBLEManager createModelWithChannelKey:channelKey kvDict:kvDict];
    return model;
}

+ (BRBLEListenerModel *)createModelWithChannelKey:(NSString *)channelKey kvDict:(NSMutableDictionary *)kvDict{
    BRBLEListenerModel * model = [kvDict valueForKey:channelKey];
    if(model){
        [kvDict removeObjectForKey:channelKey];
        DNSLog(@"没有移除监听，请检查你的程序(这里自动为你移除上次的残留)：channelKey is %@",channelKey);
    }else{
        model = [[BRBLEListenerModel alloc] init];
    }
    [kvDict setValue:model forKey:channelKey];
    return model;
}




@end
