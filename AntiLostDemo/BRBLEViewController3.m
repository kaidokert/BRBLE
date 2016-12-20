//
//  BRBLEViewController3.m
//  AntiLostDemo
//
//  Created by Brown on 16/12/9.
//  Copyright © 2016年 Brown. All rights reserved.
//

#import "BRBLEViewController3.h"
#import "UIView+SDAutoLayout.h"
#import "StoryConfigModel.h"

#import "CBService+helper.h"
#import "CBPeripheral+helper.h"

#import "BRBLEViewController4.h"

#define Channel_Dir_List @"Channel_Dir_List"

@interface BRBLEViewController3 ()<UITableViewDelegate,UITableViewDataSource>
{
    BRBLEManager * _bleManager;
    
}
@property (nonatomic,strong) UITableView * tableView;
@property (nonatomic,strong) NSMutableArray * fielArray;
@property (nonatomic,strong) NSMutableData * fileData;

@property (nonatomic,assign) BOOL inMp3List;

@end

@implementation BRBLEViewController3

- (void)dealloc{
    NSLog(@"--- dealloc %@ ---",self.class);
    [_bleManager removeReadValueWithChannelKey:Channel_Dir_List];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    [self setupData];
    [self setupBLEManager];
    [self setupComponent];
    
    [self gotoDeviceRootFolder];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    self.inMp3List = NO;
}

- (void)viewWillDisappear:(BOOL)animated{
    [super viewWillDisappear:animated];
    self.inMp3List = YES;
}

- (void)setupData{
    self.fielArray = [NSMutableArray new];
    _bleManager = [BRBLEManager shareInstance];
}

- (void)setupBLEManager{
    __weak typeof(self) _weak_self = self;
    
    [_bleManager registerReadValueWithChannelKey:Channel_Dir_List callBack:^(CBPeripheral *peripheral, CBCharacteristic *characteristic) {
        if(!_weak_self.inMp3List && [_weak_self.peripheral.identifier.UUIDString isEqualToString:peripheral.identifier.UUIDString]){
            NSData * data = characteristic.value;
            NSLog(@"收到数据:%@",data.description);
            
            UInt8 val[20] = {0};
            [data getBytes:&val length:data.length];
            
            if (val[0] == 0x06 && val[3] == 0x07){
                //进入设备文件夹
                NSLog(@"--- 进入设备目录成功 ---");
                _weak_self.fileData = [NSMutableData new];
                [_weak_self.fielArray removeAllObjects];
                [_weak_self getFolderList];
            }else if( val[0] == 0x06 && val[3] == 0x08){
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
                            if(f.length > 0 && [f hasPrefix:@"d"]){
                                [_weak_self.fielArray addObject:[f substringFromIndex:1]];
                            }
                        }
                    }
                }
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

#pragma mark -
- (void)gotoDeviceRootFolder{
    
    NSString *sendStr = @"/";
    NSData *data = [sendStr dataUsingEncoding:NSUTF8StringEncoding];
    
    UInt8 val[20] = {0x06};
    val[1] = 3 + data.length;
    val[2] = 0X07;
    val[3] = 0xFF;
    val[data.length + 4] = 0x07;
    memcpy(val + 4, data.bytes, data.length);
    
    NSData * send_data = [[NSData alloc] initWithBytes:val length:val[1]+2];
    
    CBService * service = [CBPeripheral searchServiceWithPeripheral:self.peripheral serviceUUID:[StoryConfigModel service_uuid].UUIDString];
    CBCharacteristic * chara = [CBService searchCharacteristicWithService:service characteristicUUID:[StoryConfigModel characteristic_FF05_uuid].UUIDString];
    
    [self.peripheral writeValue:send_data forCharacteristic:chara type:CBCharacteristicWriteWithResponse];
    
    NSLog(@"发送命令: 进入设备根目录");
}

- (void)getFolderList{
    
    UInt8 val[20] = {0x06, 0x03, 0x08, 0xFF, 0x07};
    NSData *sData = [[NSData alloc] initWithBytes:val length:5];
    
    CBService * service = [CBPeripheral searchServiceWithPeripheral:self.peripheral serviceUUID:[StoryConfigModel service_uuid].UUIDString];
    CBCharacteristic * chara = [CBService searchCharacteristicWithService:service characteristicUUID:[StoryConfigModel characteristic_FF05_uuid].UUIDString];
    
    [self.peripheral writeValue:sData forCharacteristic:chara type:CBCharacteristicWriteWithResponse];
    
    NSLog(@"发送命令: 获取当前目录下的文件列表");
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
    
    BRBLEViewController4 * vc = [[BRBLEViewController4 alloc] init];
    vc.peripheral = self.peripheral;
    vc.folderName = self.fielArray[indexPath.row];
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
