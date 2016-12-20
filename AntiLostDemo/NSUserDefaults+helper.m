//
//  NSUserDefaults+helper.m
//  SMGeng
//
//  Created by LiYeBiao on 15/7/8.
//  Copyright (c) 2015年 GaoJing Electric Co., Ltd. All rights reserved.
//

#import "NSUserDefaults+helper.h"

@implementation NSUserDefaults (helper)

+ (BOOL)saveObject:(id)object key:(NSString *)key{
    NSUserDefaults * ud = [NSUserDefaults standardUserDefaults];
    [ud setObject:object forKey:key];
    return [ud synchronize];
}

+ (id)readObjectForKey:(NSString *)key{
    return [[NSUserDefaults standardUserDefaults] objectForKey:key];
}

+ (BOOL)saveValue:(id)value key:(NSString *)key{
    NSUserDefaults * ud = [NSUserDefaults standardUserDefaults];
    [ud setValue:value forKey:key];
    return [ud synchronize];
}

+ (id)readValueForKey:(NSString *)key{
    return [[NSUserDefaults standardUserDefaults] valueForKey:key];
}

@end
