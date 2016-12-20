//
//  BRBLEViewController2.m
//  AntiLostDemo
//
//  Created by Brown on 16/12/9.
//  Copyright © 2016年 Brown. All rights reserved.
//

#import "BRBLEViewController2.h"
#import "UIView+SDAutoLayout.h"
#import "CBService+helper.h"
#import "CBPeripheral+helper.h"
#import "BRBLEViewController3.h"
#import "AntiLostConfigModel.h"

#define Channel_Device_Info @"Channel_Device_Info"

#define Channel_Device_RSSI2 @"Channel_Device_RSSI2"

@interface BRBLEViewController2 ()
{
    BRBLEManager * _bleManager;
    BOOL isWarning;
}
@property (nonatomic,strong) UILabel * nameLabel;
@property (nonatomic,strong) UILabel * stateLabel;

@property (nonatomic,strong) UILabel * valueLabel;

@property (nonatomic,strong) UILabel * rssiLabel;

@property (nonatomic,strong) UIButton * connectButton;
@property (nonatomic,strong) UIButton * sendButton;

@property (nonatomic,strong) UIButton * goButton;
@property (nonatomic,strong) UIButton * readRSSIButton;



@end

@implementation BRBLEViewController2

- (void)dealloc{
    NSLog(@"--- dealloc %@ ---",self.class);
    [_bleManager removePeripheralStateWithChannelKey:Channel_Device_Info];
    [_bleManager removeReadRSSIWithChannelKey:Channel_Device_Info];
    [_bleManager removeReadValueWithChannelKey:Channel_Device_Info];
    [_bleManager removeWriteValueWithChannelKey:Channel_Device_Info];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    [self setupBLEManager];
    [self setupComponent];
    
    [self refreshView];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)refreshView{
    self.nameLabel.text = self.peripheral.name;
    [self updateState:self.peripheral];
}

- (void)updateValue:(CBCharacteristic *)chara{
    NSString * str = chara.value.description;
    self.valueLabel.text = [NSString stringWithFormat:@"值:%@",str];
}

- (void)updateState:(CBPeripheral *)peripheral{
    switch (peripheral.state) {
        case CBPeripheralStateConnected:
        {
            self.stateLabel.text = @"已连接";
        }
            break;
        case CBPeripheralStateConnecting:
        {
            self.stateLabel.text = @"连接中..";
        }
            break;
        case CBPeripheralStateDisconnected:
        {
            self.stateLabel.text = @"未连接";
        }
            break;
        case CBPeripheralStateDisconnecting:
        {
            self.stateLabel.text = @"断开中..";
        }
            break;
        default:
            break;
    }

}

- (void)setupBLEManager{
    _bleManager = [BRBLEManager shareInstance];
    __weak typeof(self) _weak_self = self;
    
    [_bleManager registerPeripheralStateWithChannelKey:Channel_Device_Info callBack:^(CBPeripheral *peripheral) {
        if([_weak_self.peripheral.identifier.UUIDString isEqualToString:peripheral.identifier.UUIDString]){
            dispatch_async(dispatch_get_main_queue(), ^{
                [_weak_self updateState:peripheral];
            });
        }
    }];
    
    [_bleManager registerReadValueWithChannelKey:Channel_Device_Info callBack:^(CBPeripheral *peripheral, CBCharacteristic *characteristic) {
        if([_weak_self.peripheral.identifier.UUIDString isEqualToString:peripheral.identifier.UUIDString]){
            dispatch_async(dispatch_get_main_queue(), ^{
                [_weak_self updateValue:characteristic];
            });
        }
    }];
    
    [_bleManager registerReadRSSIWithChannelKey:Channel_Device_Info callBack:^(CBPeripheral *peripheral, NSNumber *RSSI) {
        if([_weak_self.peripheral.identifier.UUIDString isEqualToString:peripheral.identifier.UUIDString]){
            dispatch_async(dispatch_get_main_queue(), ^{
                _weak_self.rssiLabel.text = [NSString stringWithFormat:@"RSSI:%@",RSSI];
            });
        }
    }];
    
    [_bleManager registerWriteValueWithChannelKey:Channel_Device_Info callBack:^(CBPeripheral *peripheral, CBCharacteristic *characteristic) {
        NSLog(@"write value:%@  value:%@",peripheral.name,characteristic.UUID.UUIDString);
    }];
    
}

- (void)setupComponent{
    self.view.backgroundColor = [UIColor whiteColor];
    [self.view addSubview:self.nameLabel];
    [self.view addSubview:self.stateLabel];
    [self.view addSubview:self.valueLabel];
    [self.view addSubview:self.rssiLabel];
    [self.view addSubview:self.connectButton];
    [self.view addSubview:self.sendButton];
    [self.view addSubview:self.goButton];
    [self.view addSubview:self.readRSSIButton];
    
    self.nameLabel
    .sd_layout
    .leftSpaceToView(self.view,10)
    .rightSpaceToView(self.view,10)
    .topSpaceToView(self.view,100)
    .heightIs(30);
    
    self.stateLabel
    .sd_layout
    .leftSpaceToView(self.view,10)
    .rightSpaceToView(self.view,10)
    .topSpaceToView(self.nameLabel,10)
    .heightIs(30);
    
    self.valueLabel
    .sd_layout
    .leftSpaceToView(self.view,10)
    .rightSpaceToView(self.view,10)
    .topSpaceToView(self.stateLabel,10)
    .heightIs(30);
    
    self.rssiLabel
    .sd_layout
    .leftSpaceToView(self.view,10)
    .rightSpaceToView(self.view,10)
    .topSpaceToView(self.valueLabel,10)
    .heightIs(30);
    
    self.connectButton
    .sd_layout
    .leftSpaceToView(self.view,10)
    .widthIs(120)
    .topSpaceToView(self.rssiLabel,20)
    .heightIs(44);
    
    self.sendButton
    .sd_layout
    .leftSpaceToView(self.connectButton,20)
    .widthIs(120)
    .topSpaceToView(self.rssiLabel,20)
    .heightIs(44);
    
    self.goButton
    .sd_layout
    .leftSpaceToView(self.view,10)
    .widthIs(120)
    .topSpaceToView(self.sendButton,20)
    .heightIs(44);
    
    self.readRSSIButton
    .sd_layout
    .leftSpaceToView(self.view,10)
    .widthIs(120)
    .topSpaceToView(self.goButton,20)
    .heightIs(44);
}

- (void)event_connect{
    if(self.peripheral.state == CBPeripheralStateConnected || self.peripheral.state == CBPeripheralStateConnecting){
        [_bleManager cancelPeripheralConnection:self.peripheral];
    }else{
        [_bleManager connectPeripheral:self.peripheral options:nil];
    }
}

- (void)event_warning{
//    [self readValue];
    [self warning];
}

- (void)event_go_dir{
    if(self.peripheral.state == CBPeripheralStateConnected){
        BRBLEViewController3 * vc = [[BRBLEViewController3 alloc] init];
        vc.peripheral = self.peripheral;
        [self.navigationController pushViewController:vc animated:YES];
    }else{
        NSLog(@"------  设备未连接  ------");
    }
}

- (void)event_read_rssi{
    if(self.peripheral.state == CBPeripheralStateConnected){
        [self.peripheral readRSSI];
    }
}

#pragma mark - private
- (void)readValue{
    CBPeripheral * peripheral = self.peripheral;
    
    CBService * service = [CBPeripheral searchServiceWithPeripheral:peripheral serviceUUID:[AntiLostConfigModel service_1802_uuid].UUIDString];
    
    if(!service){
        NSLog(@"服务为空");
        return;
    }
    CBCharacteristic * chara = [CBService searchCharacteristicWithService:service characteristicUUID:[AntiLostConfigModel characteristic_2A06_uuid].UUIDString];
    
    if(!chara){
        NSLog(@"特征为空");
        return;
    }
    [peripheral readValueForCharacteristic:chara];
}


- (void)warning{
    CBPeripheral * peripheral = self.peripheral;
    CBService * service = [CBPeripheral searchServiceWithPeripheral:peripheral serviceUUID:[AntiLostConfigModel service_1802_uuid].UUIDString];
    
    if(!service){
        NSLog(@"服务为空");
        return;
    }
    CBCharacteristic * chara = [CBService searchCharacteristicWithService:service characteristicUUID:[AntiLostConfigModel characteristic_2A06_uuid].UUIDString];
    
    if(!chara){
        NSLog(@"特征为空");
        return;
    }
    UInt8 val[1] = {0x02};
    if(!isWarning){
        val[0] = 0x02;
        NSLog(@"发起报警");
    }else{
        NSLog(@"报警停止");
        val[0] = 0x00;
    }
    isWarning = !isWarning;
    
    NSData *sData = [[NSData alloc] initWithBytes:val length:1];
    [peripheral writeValue:sData forCharacteristic:chara type:CBCharacteristicWriteWithResponse];
}

#pragma mark - setter and getter
- (UILabel * )nameLabel{
    if(!_nameLabel){
        UILabel * v = [[UILabel alloc] init];
        v.backgroundColor = [UIColor orangeColor];
        _nameLabel = v;
    }
    return _nameLabel;
}

- (UILabel * )stateLabel{
    if(!_stateLabel){
        UILabel * v = [[UILabel alloc] init];
        v.backgroundColor = [UIColor orangeColor];
        _stateLabel = v;
    }
    return _stateLabel;
}

- (UILabel * )valueLabel{
    if(!_valueLabel){
        UILabel * v = [[UILabel alloc] init];
        v.text = @"值:";
        v.backgroundColor = [UIColor orangeColor];
        _valueLabel = v;
    }
    return _valueLabel;
}

- (UILabel * )rssiLabel{
    if(!_rssiLabel){
        UILabel * v = [[UILabel alloc] init];
        v.text = @"信号量:";
        v.backgroundColor = [UIColor orangeColor];
        _rssiLabel = v;
    }
    return _rssiLabel;
}

- (UIButton *)connectButton{
    if(!_connectButton){
        UIButton * b = [UIButton buttonWithType:UIButtonTypeSystem];
        [b setTitle:@"连接/断开" forState:UIControlStateNormal];
        [b addTarget:self action:@selector(event_connect) forControlEvents:UIControlEventTouchUpInside];
        b.backgroundColor = [UIColor purpleColor];
        _connectButton = b;
    }
    return  _connectButton;
}

- (UIButton *)sendButton{
    if(!_sendButton){
        UIButton * b = [UIButton buttonWithType:UIButtonTypeSystem];
        [b setTitle:@"报警/停止" forState:UIControlStateNormal];
        [b addTarget:self action:@selector(event_warning) forControlEvents:UIControlEventTouchUpInside];
        b.backgroundColor = [UIColor purpleColor];
        _sendButton = b;
    }
    return  _sendButton;
}

- (UIButton *)goButton{
    if(!_goButton){
        UIButton * b = [UIButton buttonWithType:UIButtonTypeSystem];
        [b setTitle:@"进入故事机" forState:UIControlStateNormal];
        [b addTarget:self action:@selector(event_go_dir) forControlEvents:UIControlEventTouchUpInside];
        b.backgroundColor = [UIColor purpleColor];
        _goButton = b;
    }
    return  _goButton;
}

- (UIButton *)readRSSIButton{
    if(!_readRSSIButton){
        UIButton * b = [UIButton buttonWithType:UIButtonTypeSystem];
        [b setTitle:@"读取信号" forState:UIControlStateNormal];
        [b addTarget:self action:@selector(event_read_rssi) forControlEvents:UIControlEventTouchUpInside];
        b.backgroundColor = [UIColor purpleColor];
        _readRSSIButton = b;
    }
    return  _readRSSIButton;
}


@end
