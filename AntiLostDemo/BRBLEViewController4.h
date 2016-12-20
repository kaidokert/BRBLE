//
//  BRBLEViewController4.h
//  AntiLostDemo
//
//  Created by Brown on 16/12/9.
//  Copyright © 2016年 Brown. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "BRBLEManager.h"

@interface BRBLEViewController4 : UIViewController

@property(nonatomic,strong) CBPeripheral * peripheral;

@property (nonatomic,copy) NSString * folderName;

@end
