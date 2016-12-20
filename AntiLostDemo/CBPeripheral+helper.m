//
//  CBPeripheral+helper.m
//  AntiLostDemo
//
//  Created by Brown on 16/12/1.
//  Copyright © 2016年 Brown. All rights reserved.
//

#import "CBPeripheral+helper.h"

@implementation CBPeripheral (helper)

+ (CBService *)searchServiceWithPeripheral:(CBPeripheral *)peripheral serviceUUID:(NSString *)serviceUUID{
    for(CBService * service in peripheral.services){
        if([service.UUID.UUIDString isEqualToString:serviceUUID]){
            return service;
        }
    }
    return nil;
}

@end
