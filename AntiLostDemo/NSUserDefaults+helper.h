//
//  NSUserDefaults+helper.h
//  SMGeng
//
//  Created by LiYeBiao on 15/7/8.
//  Copyright (c) 2015年 GaoJing Electric Co., Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSUserDefaults (helper)

+ (BOOL)saveObject:(id)object key:(NSString *)key;
+ (id)readObjectForKey:(NSString *)key;
+ (BOOL)saveValue:(id)value key:(NSString *)key;
+ (id)readValueForKey:(NSString *)key;


@end
