//
//  CJFDebugMonitor.h
//  iOSMonitorDemo
//
//  Created by ChengJianFeng on 2017/2/2.
//  Copyright © 2017年 ChengJianFeng. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "CJFDebugLog.h"

//频率枚举
typedef NS_ENUM(NSUInteger, CJFDebugMonitorRefreshFrequency) {
    CJFDebugMonitorRefreshFrequencyNormal = 1,
    CJFDebugMonitorRefreshFrequencyMedium = 3,
    CJFDebugMonitorRefreshFrequencyHigh = 10
};

@interface CJFDebugMonitor : NSObject

@property (nonatomic, assign) CJFDebugMonitorRefreshFrequency frequency;


/**
 返回单例指示器
 */
+(instancetype)sharedInstance;
+(instancetype) alloc __attribute__((unavailable("alloc not available, call sharedInstance instead")));
-(instancetype) init __attribute__((unavailable("init not available, call sharedInstance instead")));
+(instancetype) new __attribute__((unavailable("new not available, call sharedInstance instead")));


/**
 要开始必须填充入一个能够随着屏幕变化自动旋转的view
 建议不要加到window上，因为iOS7上window不会自动旋转

 @param containerView 容器view
 */
- (void)start:(UIView*)containerView;
- (void)stop;

-(void)addLogStr:(NSString*)str andColor:(UIColor*)color;

@end
