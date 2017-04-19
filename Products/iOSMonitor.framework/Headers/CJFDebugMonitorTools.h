//
//  CJFDebugMonitorTools.h
//  iOSMonitorDemo
//
//  Created by ChengJianFeng on 2017/2/2.
//  Copyright © 2017年 ChengJianFeng. All rights reserved.
//


/* 
 Utility functions for querying the mach kernel.
 */


#ifndef CJFFPS_IndicatorTools_h
#define CJFFPS_IndicatorTools_h

#ifdef __cplusplus
extern "C" {
#endif
    
#include <sys/ucontext.h>



// ============================================================================
#pragma mark - General Information -
// ============================================================================


/**
 获取设备未使用的内存大小
 warnning：内存监控建议仅用于参考，与Xcode展示数值存在差异，但是变化趋势相似

 @return 设备未使用内存大小
 */
double CJFFPS_freeMemory(void);


/**
 获取全部进程已使用的内存大小，单位为MB
 warnning：内存监控建议仅用于参考，与Xcode展示数值存在差异，但是变化趋势相似

 @return 全部进程使用的内存大小
 */
double CJFFPS_usableMemory(void);
    

/**
 获取设备内存的总大小，单位为MB
 数值确切

 @return 设备内存总大小
 */
double CJFFPS_AllMemory(void);
    


/**
 获取本应用使用的内存，单位为MB
 warnning：内存监控建议仅用于参考，与Xcode展示数值存在差异，但是变化趋势相似

 @return 本应用使用的内存大小
 */
double CJFFPS_usedMemory(void);

#ifdef __cplusplus
}
#endif

#endif // CJFFPS_IndicatorTools_h
