//
//  CJFDebugLog.m
//  iOSMonitorDemo
//
//  Created by ChengJianFeng on 2017/2/2.
//  Copyright © 2017年 ChengJianFeng. All rights reserved.
//

#import "CJFDebugLog.h"
#import <pthread.h>
#import "CJFDebugMonitor.h"

@implementation CJFDebugLogManager

+(void)appendLog:(NSString*)typeStr andColor:(UIColor*)color withContent:(NSString*)format, ...
{
#ifdef DEBUG
    va_list ap;
    NSString *str = nil;
    va_start(ap,format);
    str = [[NSString alloc] initWithFormat:format arguments: ap];
    va_end(ap);
    
    if( ![str isKindOfClass:[NSString class]] ){
        return;
    }
    NSLog(@"%@", str);
    str = [self p_formatOutputString:str andType:typeStr];
    [self p_excuteMainBlock:^{
        [[CJFDebugMonitor sharedInstance] addLogStr:str andColor:color];
    }];
#endif
}

#pragma mark - 私有接口

+(NSString*)p_formatOutputString:(NSString*)str andType:(NSString*)typeStr
{
    return  [NSString stringWithFormat:@"[%@ %@]: %@\n",[self p_getNowTimeString],typeStr,str];
}

+(NSDateFormatter*)p_getLocalDateFormatter
{
    static NSDateFormatter* s_localFormatter = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        s_localFormatter = [[NSDateFormatter alloc] init];
        [s_localFormatter setTimeZone:[NSTimeZone timeZoneWithName:@"GMT8"]];
        [s_localFormatter setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
    });
    return s_localFormatter;
}

+(NSString*)p_getNowTimeString
{
    return [[self p_getLocalDateFormatter] stringFromDate:[NSDate date]];
}

+(void)p_excuteMainBlock:(dispatch_block_t)block
{
    if( block == nil ){
        return;
    }
    if( pthread_main_np() > 0 ){
        block();
    }else{
        dispatch_sync(dispatch_get_main_queue(), ^{
            block();
        });
    }
}

@end
