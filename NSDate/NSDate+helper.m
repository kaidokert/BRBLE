//
//  NSDate+helper.m
//  AntiLostDemo
//
//  Created by Brown on 16/9/19.
//  Copyright © 2016年 Brown. All rights reserved.
//

#import "NSDate+helper.h"

@implementation NSDate (helper)

+ (NSTimeInterval)current_timestamp{
    return [[NSDate date] timeIntervalSince1970];
}

@end
