//
//  NSString+CBUUID.m
//  AntiLostDemo
//
//  Created by Brown on 16/12/9.
//  Copyright © 2016年 Brown. All rights reserved.
//

#import "NSString+CBUUID.h"

@implementation NSString (CBUUID)

- (CBUUID *)CBUUID{
    return [CBUUID UUIDWithString:self];
}

@end
