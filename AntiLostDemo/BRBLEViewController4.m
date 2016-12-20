//
//  BRBLEViewController4.m
//  AntiLostDemo
//
//  Created by Brown on 16/12/9.
//  Copyright © 2016年 Brown. All rights reserved.
//

#import "BRBLEViewController4.h"
#import "UIView+SDAutoLayout.h"
#import "StoryConfigModel.h"
#import "CBService+helper.h"
#import "CBPeripheral+helper.h"

#define Channel_Mp3_List @"Channel_Mp3_List"

@interface BRBLEViewController4 ()<UITableViewDelegate,UITableViewDataSource>
{
    BRBLEManager * _bleManager;
}
@property (nonatomic,strong) UITableView * tableView;
@property (nonatomic,strong) NSMutableArray * fielArray;
@property (nonatomic,strong) NSMutableData * fileData;
@end

@implementation BRBLEViewController4

- (void)dealloc{
    NSLog(@"--- dealloc %@ ---",self.class);
    [_bleManager removeReadValueWithChannelKey:Channel_Mp3_List];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    [self setupData];
    [self setupBLEManager];
    [self setupComponent];
    
    [self gotoFolder:self.folderName];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)setupData{
    self.fielArray = [NSMutableArray new];
    _bleManager = [BRBLEManager shareInstance];
}

- (void)setupBLEManager{
    __weak typeof(self) _weak_self = self;
    [_bleManager registerReadValueWithChannelKey:Channel_Mp3_List callBack:^(CBPeripheral *peripheral, CBCharacteristic *characteristic) {
        if([_weak_self.peripheral.identifier.UUIDString isEqualToString:peripheral.identifier.UUIDString]){
            NSData * data = characteristic.value;
            UInt8 val[20] = {0};
            [data getBytes:&val length:data.length];
            if (val[0] == 0x06 && val[3] == 0x07){
                //进入设备根文件夹
                NSLog(@"--- 进入设备根目录成功 ---");
                _weak_self.fileData = [NSMutableData new];
                [_weak_self.fielArray removeAllObjects];
                [_weak_self getFolderList];
            }else if(val[0] == 0x06 && val[3] == 0x08){
                //获取当前文件夹下的列表
//                NSLog(@"--- 获取当前文件夹下的文件列表成功 ---");
                NSData *sub = [data subdataWithRange:NSMakeRange(6, val[1] - 5)];
                [_weak_self.fileData appendData:sub];
                if(val[5] == 0xFF){
                    NSData *data = (NSData *)_weak_self.fileData;
                    if (data.length > 4) {
                        data = [data subdataWithRange:NSMakeRange(4, data.length - 4)];
                        NSString *str = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
                        NSArray *array = [str componentsSeparatedByString:@"\n"];
                        for(NSString * f in array){
                            NSLog(@"文件夹 = %@", f);
                            if (f.length>0 && [f hasPrefix:@"-"]){
                                [_weak_self.fielArray addObject:[f substringFromIndex:1]];
                            }
                        }
                    }
                }
            }else if(val[0] == 0x06 && val[3] == 0x09){
                NSLog(@"播放成功");
            }
            dispatch_async(dispatch_get_main_queue(), ^{
                [_weak_self.tableView reloadData];
            });
        }
    }];
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



#pragma mark - UITableViewDelegate
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.fielArray.count;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    
    return 50;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    return 0;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString * cellID = @"cellID";
    UITableViewCell * cell = [tableView dequeueReusableCellWithIdentifier:cellID];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellID];
        //cell.selectionStyle = UITableViewCellSelectionStyleNone;
    }
    cell.textLabel.text = self.fielArray[indexPath.row];
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    [self playerMp3WithFileName:self.fielArray[indexPath.row]];
    
}


- (void)playerMp3WithFileName:(NSString *)fileName{
    NSData *data = [fileName dataUsingEncoding:NSUTF8StringEncoding];
    
    NSUInteger maxLength = 13;
    NSInteger length = 0;
    NSData *sub;
    
    for(int i=0;i<data.length;i+=maxLength){
        UInt8 val[20] = {0x06};
        if (i + maxLength < data.length) {
            length = maxLength;
            val[3] = 0x00;
        } else {
            length = data.length - i;
            val[3] = 0xFF;
        }
        
        val[1] = 3 + length;
        val[2] = 0X09;
        val[length + 4] = 0x07;
        
        sub = [data subdataWithRange:NSMakeRange(i, length)];
        
        memcpy(val + 4, sub.bytes, sub.length);
        
        NSData *sData = [[NSData alloc] initWithBytes:val length:sub.length+5];
        
        NSLog(@"发送的mp3数据:%@",sData);
        
        CBService * service = [CBPeripheral searchServiceWithPeripheral:self.peripheral serviceUUID:[StoryConfigModel service_uuid].UUIDString];
        CBCharacteristic * chara = [CBService searchCharacteristicWithService:service characteristicUUID:[StoryConfigModel characteristic_FF05_uuid].UUIDString];
        
        [self.peripheral writeValue:sData forCharacteristic:chara type:CBCharacteristicWriteWithResponse];
    }
}

- (void)gotoFolder:(NSString *)folder{
    NSData *data = [folder dataUsingEncoding:NSUTF8StringEncoding];
    NSLog(@"folder:%@  data:%@",folder,data);
    UInt8 val[20] = {0x06, 0x00, 0x07};
    
    val[0] = 0x06;
    val[1] = 3+data.length;
    val[2] = 0x07;
    val[3] = 0xFF;
    val[data.length + 4] = 0x07;
    
    memcpy(val + 4, data.bytes, data.length);
    
    NSData *sData = [[NSData alloc] initWithBytes:val length:data.length+5];
    
    NSLog(@"发送的数据:%@",sData);
    
    CBService * service = [CBPeripheral searchServiceWithPeripheral:self.peripheral serviceUUID:[StoryConfigModel service_uuid].UUIDString];
    CBCharacteristic * chara = [CBService searchCharacteristicWithService:service characteristicUUID:[StoryConfigModel characteristic_FF05_uuid].UUIDString];
    
    [self.peripheral writeValue:sData forCharacteristic:chara type:CBCharacteristicWriteWithResponse];
}

- (void)getFolderList{
    
    UInt8 val[20] = {0x06, 0x03, 0x08, 0xFF, 0x07};
    NSData *sData = [[NSData alloc] initWithBytes:val length:5];
    
    CBService * service = [CBPeripheral searchServiceWithPeripheral:self.peripheral serviceUUID:[StoryConfigModel service_uuid].UUIDString];
    CBCharacteristic * chara = [CBService searchCharacteristicWithService:service characteristicUUID:[StoryConfigModel characteristic_FF05_uuid].UUIDString];
    
    [self.peripheral writeValue:sData forCharacteristic:chara type:CBCharacteristicWriteWithResponse];
    
    NSLog(@"发送命令: 获取当前目录下的文件列表");
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
