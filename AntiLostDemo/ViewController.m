//
//  ViewController.m
//  AntiLostDemo
//
//  Created by Brown on 16/9/19.
//  Copyright © 2016年 Brown. All rights reserved.
//

#import "ViewController.h"

#import "BRBLETestViewController1.h"




@interface ViewController ()

@end

@implementation ViewController

- (void)dealloc{

}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    [self initData];
    [self initComponent];
    
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)initData{
    
}

- (void)initComponent{
    UIButton * button2 = [UIButton buttonWithType:UIButtonTypeCustom];
    button2.frame = CGRectMake(20, 220, 100, 44);
    [button2 setTitle:@"蓝牙列表" forState:UIControlStateNormal];
    [button2 addTarget:self action:@selector(click3) forControlEvents:UIControlEventTouchUpInside];
    button2.backgroundColor = [UIColor colorWithRed:random()%256/255.0 green:random()%256/255.0 blue:random()%256/255.0 alpha:1.0];
    [self.view addSubview:button2];
}

- (void)click3{
    BRBLETestViewController1 * vc = [[BRBLETestViewController1 alloc] init];
    vc.title = @"蓝牙列表";
    [self.navigationController pushViewController:vc animated:YES];
}


@end





