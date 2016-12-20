//
//  AntiLostConfigModel.h
//  AntiLostDemo
//
//  Created by Brown on 16/12/2.
//  Copyright © 2016年 Brown. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreBluetooth/CoreBluetooth.h>

@interface AntiLostConfigModel : NSObject

+ (CBUUID *)service_FFE0_uuid;

+ (CBUUID *)characteristic_FFE1_uuid;

+ (CBUUID *)service_1802_uuid;

+ (CBUUID *)characteristic_2A06_uuid;

@end
