//
//  StoryConfigModel.m
//  AntiLostDemo
//
//  Created by Brown on 16/12/2.
//  Copyright © 2016年 Brown. All rights reserved.
//

#import "StoryConfigModel.h"

//主服务
#define Story_Service_UUID @"0000FF00-0000-1000-8000-00805F9B34FB"

//读 特征
#define Story_Characteristic_0xFF01_UUID @"0000FF01-0000-1000-8000-00805F9B34FB"
#define Story_Characteristic_0xFF02_UUID @"0000FF02-0000-1000-8000-00805F9B34FB"
#define Story_Characteristic_0xFF03_UUID @"0000FF03-0000-1000-8000-00805F9B34FB"

//读写 特征
#define Story_Characteristic_0xFF05_UUID @"0000FF05-0000-1000-8000-00805F9B34FB"
#define Story_Characteristic_0xFF11_UUID @"0000FF11-0000-1000-8000-00805F9B34FB"


@implementation StoryConfigModel

+ (CBUUID *)service_uuid{
    return [CBUUID UUIDWithString:Story_Service_UUID];
}

+ (CBUUID *)characteristic_FF01_uuid{
    return [CBUUID UUIDWithString:Story_Characteristic_0xFF01_UUID];
}

+ (CBUUID *)characteristic_FF02_uuid{
    return [CBUUID UUIDWithString:Story_Characteristic_0xFF02_UUID];
}

+ (CBUUID *)characteristic_FF03_uuid{
    return [CBUUID UUIDWithString:Story_Characteristic_0xFF03_UUID];
}

+ (CBUUID *)characteristic_FF05_uuid{
    return [CBUUID UUIDWithString:Story_Characteristic_0xFF05_UUID];
}

+ (CBUUID *)characteristic_FF11_uuid{
    return [CBUUID UUIDWithString:Story_Characteristic_0xFF11_UUID];
}

@end
