//
//  BRBLETestViewController1.m
//  AntiLostDemo
//
//  Created by Brown on 16/12/9.
//  Copyright © 2016年 Brown. All rights reserved.
//

#import "BRBLETestViewController1.h"
#import "BRBLEManager.h"
#import "UIView+SDAutoLayout.h"
#import "StoryConfigModel.h"
#import "AntiLostConfigModel.h"
#import "BRBLEViewController2.h"
#import "NSUserDefaults+helper.h"

#define Channel_Central_State @"Channel_Central_State"
#define Channel_PeripheralState @"Channel_PeripheralState"
#define Channel_PeripheralRSSI @"Channel_PeripheralRSSI"

@interface BRBLETestViewController1 ()<UITableViewDelegate,UITableViewDataSource>{
    
}

@property (nonatomic,strong) UITableView * tableView;
@property (nonatomic,strong) NSMutableArray * peripheralArray;
//@property (nonatomic,strong) NSMutableDictionary * peripheralDict;

@property (nonatomic,strong) BRBLEManager * bleManager;

@end

@implementation BRBLETestViewController1

- (void)dealloc{
    NSLog(@"--- dealloc %@ ---",self.class);
    
    [_bleManager removeReadRSSIWithChannelKey:Channel_PeripheralRSSI];
    [_bleManager removePeripheralStateWithChannelKey:Channel_PeripheralState];
    [_bleManager removeCentralStateWithChannelKey:Channel_Central_State];
    
    [_bleManager clearConnectedSetting];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    [self setupData];
    [self setupRetrieveConnected];
    [self setupBLEManager];
    [self setupComponent];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)setupData{
    self.peripheralArray = [NSMutableArray new];
//    self.peripheralDict = [NSMutableDictionary new];
    _bleManager = [BRBLEManager shareInstance];
}

- (void)setupRetrieveConnected{
    NSArray * arr = [_bleManager retrieveConnectedPeripheralsWithServices:@[[AntiLostConfigModel service_1802_uuid],[AntiLostConfigModel service_FFE0_uuid],[StoryConfigModel service_uuid]]];
    if(arr.count > 0){
        for(CBPeripheral * p in arr){
            if([p.name hasPrefix:@"Story"]){
                DNSLog(@"找到:%@",p);
                [_bleManager connectPeripheral:p options:nil];
                break;
            }
        }
        [self.peripheralArray addObjectsFromArray:arr];
    }
}

- (void)setupBLEManager{
    __weak typeof(self) _weak_self = self;
    
    [_bleManager registerCentralStateWithChannelKey:Channel_Central_State callBack:^(CBCentralManager *central) {
        if(central.state == CBCentralManagerStatePoweredOn){
            NSLog(@"1设备打开成功，开始扫描..");
        }else{
            NSLog(@"1设备蓝牙关闭，停止扫描..");
        }
    }];
    
    [_bleManager registerPeripheralStateWithChannelKey:Channel_PeripheralState callBack:^(CBPeripheral *peripheral) {
        if(peripheral.state == CBPeripheralStateDisconnected){
            [_weak_self.peripheralArray removeObject:peripheral];
        }
        dispatch_async(dispatch_get_main_queue(), ^{
            [_weak_self refreshTableView];
        });
    }];
    
    [_bleManager registerReadRSSIWithChannelKey:Channel_PeripheralRSSI callBack:^(CBPeripheral *peripheral, NSNumber *RSSI) {
        NSLog(@"  %@   ||   %@",peripheral.name,RSSI);
        
    }];
    
    //总机扫描选项
    _bleManager.setupScanForPeripheralsWithServicesOptions = ^(){
        return @{CBCentralManagerScanOptionAllowDuplicatesKey:@NO};
    };
    
    //发现新设备
    _bleManager.setupDidDiscoverPeripheralWithCentralManager = ^(CBCentralManager *central, CBPeripheral *peripheral, NSDictionary *advertisementData, NSNumber *RSSI){
        if(![_weak_self.peripheralArray containsObject:peripheral]){
            NSLog(@"发现新设备:%@  UUID:%@ RSSI:%@",peripheral.name,peripheral.identifier.UUIDString,RSSI);
            if([peripheral.name hasPrefix:@"Story"]){
                [_weak_self.bleManager connectPeripheral:peripheral options:nil];
            }
            [_weak_self.peripheralArray addObject:peripheral];
            dispatch_async(dispatch_get_main_queue(), ^{
                [_weak_self refreshTableView];
            });
        }
    };
    
    //过滤设备
    _bleManager.setupFilterDiscoverPeripheral = ^BOOL(NSString *peripheralName, NSDictionary *advertisementData, NSNumber *RSSI){
        if([peripheralName hasPrefix:@"MLE"] || [peripheralName hasPrefix:@"Story"]){
            return YES;//[peripheralName hasPrefix:@"Brt"] || 
        }
        return NO;
    };
    
    //过滤服务
    _bleManager.setupFilterDiscoverServices = ^NSArray<CBUUID *>*(CBPeripheral *peripheral){
        return @[[StoryConfigModel service_uuid],[AntiLostConfigModel service_FFE0_uuid],[AntiLostConfigModel service_1802_uuid]];
    };
    
    //过滤特征
    _bleManager.setupFilterDiscoverCharacteristics = ^NSArray<CBUUID *>*(CBPeripheral *peripheral,CBService * service){
        if([service.UUID.UUIDString isEqualToString:[StoryConfigModel service_uuid].UUIDString]){
            return @[[StoryConfigModel characteristic_FF01_uuid],
                     [StoryConfigModel characteristic_FF02_uuid],
                     [StoryConfigModel characteristic_FF03_uuid],
                     [StoryConfigModel characteristic_FF05_uuid],
                     [StoryConfigModel characteristic_FF11_uuid]];
        }else if([service.UUID isEqual:[AntiLostConfigModel service_FFE0_uuid]]){
            return @[[AntiLostConfigModel characteristic_FFE1_uuid]];
        }else if([service.UUID isEqual:[AntiLostConfigModel service_1802_uuid]]){
            return @[[AntiLostConfigModel characteristic_2A06_uuid]];
        }
        return nil;
    };
    
    //发现特征
    _bleManager.setupDidDiscoverCharacteristicsForService = ^(CBPeripheral *peripheral,CBService * service,CBCharacteristic *characteristic){
//        NSLog(@"service:::%@  characteristic:%@",service,characteristic);
        
    };
    
}

- (void)setupComponent{
    
    self.view.backgroundColor = [UIColor whiteColor];
    [self.view addSubview:self.tableView];
    
    self.tableView
    .sd_layout
    .leftSpaceToView(self.view,0)
    .rightSpaceToView(self.view,0)
    .topSpaceToView(self.view,0)
    .bottomSpaceToView(self.view,0);
    
}

#pragma mark - private
- (void)refreshTableView{
    [self.tableView reloadData];
}

- (NSString *)convertStateToString:(CBPeripheralState)state{
    switch (state) {
        case CBPeripheralStateConnected:
            return @"已连接";
            break;
        case CBPeripheralStateDisconnected:
            return @"未连接";
            break;
        case CBPeripheralStateConnecting:
            return @"连接中..";
            break;
        default:
            break;
    }
    return @"未知";
}

#pragma mark - UITableViewDelegate
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    return self.peripheralArray.count;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
    
    return 50;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section{
    return 0;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    static NSString * cellID = @"cellID";
    UITableViewCell * cell = [tableView dequeueReusableCellWithIdentifier:cellID];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:cellID];
        cell.textLabel.font = [UIFont systemFontOfSize:17];
        cell.detailTextLabel.font = [UIFont systemFontOfSize:10];
    }
    cell.tag = 100+indexPath.row;
    
    CBPeripheral * peripheral = self.peripheralArray[indexPath.row];
    cell.textLabel.text = [NSString stringWithFormat:@"%@ - %@",peripheral.name,[self convertStateToString:peripheral.state]];
    cell.detailTextLabel.text = [NSString stringWithFormat:@"UUID:<%@>",peripheral.identifier.UUIDString];
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    CBPeripheral * peripheral = self.peripheralArray[indexPath.row];

    
    BRBLEViewController2 * vc = [[BRBLEViewController2 alloc] init];
    vc.peripheral = peripheral;
    [self.navigationController pushViewController:vc animated:YES];
    
}

#pragma mark -  getter and setter
- (UITableView *)tableView{
    if(!_tableView){
        UITableView * tableView = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStylePlain];
        tableView.delegate = self;
        tableView.dataSource = self;
        _tableView = tableView;
    }
    return _tableView;
}

@end
