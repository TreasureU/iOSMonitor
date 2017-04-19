//
//  CJFDebugLog.h
//  iOSMonitorDemo
//
//  Created by ChengJianFeng on 2017/2/2.
//  Copyright © 2017年 ChengJianFeng. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

#ifdef DEBUG
#define CJFDebugNormalLog(s,...) [CJFDebugLogManager appendLog:@"Normal" andColor:[UIColor whiteColor] withContent:(s),##__VA_ARGS__]
#define CJFDebugErrorLog(s,...) [CJFDebugLogManager appendLog:@"Error" andColor:[UIColor redColor] withContent:(s),##__VA_ARGS__]
#define CJFDebugWarningLog(s,...) [CJFDebugLogManager appendLog:@"Warning" andColor:[UIColor yellowColor] withContent:(s),##__VA_ARGS__]
#define CJFDebugSuccessLog(s,...) [CJFDebugLogManager appendLog:@"Success" andColor:[UIColor blueColor] withContent:(s),##__VA_ARGS__]
#else
#define CJFDebugNormalLog(s,...) NSLog((s),##__VA_ARGS__)
#define CJFDebugErrorLog(s,...) NSLog((s),##__VA_ARGS__)
#define CJFDebugWarningLog(s,...) NSLog((s),##__VA_ARGS__)
#define CJFDebugSuccessLog(s,...) NSLog((s),##__VA_ARGS__)
#endif

@interface CJFDebugLogManager : NSObject

+(void)appendLog:(NSString*)typeStr andColor:(UIColor*)color withContent:(NSString*)format, ...;

@end
