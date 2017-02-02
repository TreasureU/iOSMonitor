//
//  ViewController.m
//  iOSMonitorDemo
//
//  Created by ChengJianFeng on 2017/2/2.
//  Copyright © 2017年 ChengJianFeng. All rights reserved.
//

#import "ViewController.h"
#import "CJFDebugMonitor.h"

@interface ViewController ()

@property(nonatomic,strong) NSTimer* timer;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [CJFDebugMonitor sharedInstance].frequency = CJFDebugMonitorRefreshFrequencyMedium;
    [[CJFDebugMonitor sharedInstance] start:self.view];
    // Do any additional setup after loading the view, typically from a nib.
    self.timer = [NSTimer timerWithTimeInterval:1 repeats:YES block:^(NSTimer * _Nonnull timer) {
        int random = arc4random();
        if( random % 4 == 0 ){
            CJFDebugNormalLog(@"i am normal log");
        }else if (  random % 4 == 1 ){
            CJFDebugSuccessLog(@"i am success log");
        }else if ( random % 4 == 2 ){
            CJFDebugWarningLog(@"i am warning log");
        }else{
            CJFDebugErrorLog(@"i am error log");
        }
    }];
    [[NSRunLoop mainRunLoop] addTimer:self.timer forMode:NSDefaultRunLoopMode];
}

-(void)dealloc
{
    [self.timer invalidate];
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
