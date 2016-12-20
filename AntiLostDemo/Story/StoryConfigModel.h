//
//  StoryConfigModel.h
//  AntiLostDemo
//
//  Created by Brown on 16/12/2.
//  Copyright © 2016年 Brown. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreBluetooth/CoreBluetooth.h>

@interface StoryConfigModel : NSObject

+ (CBUUID *)service_uuid;
+ (CBUUID *)characteristic_FF01_uuid;
+ (CBUUID *)characteristic_FF02_uuid;
+ (CBUUID *)characteristic_FF03_uuid;
+ (CBUUID *)characteristic_FF05_uuid;

+ (CBUUID *)characteristic_FF11_uuid;

@end
