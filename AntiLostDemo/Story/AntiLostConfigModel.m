//
//  AntiLostConfigModel.m
//  AntiLostDemo
//
//  Created by Brown on 16/12/2.
//  Copyright © 2016年 Brown. All rights reserved.
//

#import "AntiLostConfigModel.h"

#define AntiLost_MainService_UUID @"FFE0"
#define AntiLost_MainService_Characteristic_UUID @"FFE1"

#define AntiLost_SendService_UUID @"1802"
#define AntiLost_SendService_Characteristic_UUID @"2A06"

@implementation AntiLostConfigModel

+ (CBUUID *)service_FFE0_uuid{
    return [CBUUID UUIDWithString:AntiLost_MainService_UUID];
}

+ (CBUUID *)characteristic_FFE1_uuid{
    return [CBUUID UUIDWithString:AntiLost_MainService_Characteristic_UUID];
}

+ (CBUUID *)service_1802_uuid{
    return [CBUUID UUIDWithString:AntiLost_SendService_UUID];
}

+ (CBUUID *)characteristic_2A06_uuid{
    return [CBUUID UUIDWithString:AntiLost_SendService_Characteristic_UUID];
}

@end
