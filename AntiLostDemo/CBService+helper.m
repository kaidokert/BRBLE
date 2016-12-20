//
//  CBService+helper.m
//  AntiLostDemo
//
//  Created by Brown on 16/12/1.
//  Copyright © 2016年 Brown. All rights reserved.
//

#import "CBService+helper.h"

@implementation CBService (helper)

+ (CBCharacteristic *)searchCharacteristicWithService:(CBService *)service characteristicUUID:(NSString *)characteristicUUID{
    for (CBCharacteristic *chara in service.characteristics) {
        if ([chara.UUID.UUIDString isEqualToString:characteristicUUID]) {
            return chara;
        }
    }
    return nil;
}

@end
