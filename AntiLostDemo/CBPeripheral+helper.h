//
//  CBPeripheral+helper.h
//  AntiLostDemo
//
//  Created by Brown on 16/12/1.
//  Copyright © 2016年 Brown. All rights reserved.
//

#import <CoreBluetooth/CoreBluetooth.h>

@interface CBPeripheral (helper)

+ (CBService *)searchServiceWithPeripheral:(CBPeripheral *)peripheral serviceUUID:(NSString *)serviceUUID;

@end
