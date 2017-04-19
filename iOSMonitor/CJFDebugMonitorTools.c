//
//  CJFDebugMonitorTools.c
//  iOSMonitorDemo
//
//  Created by ChengJianFeng on 2017/2/2.
//  Copyright © 2017年 ChengJianFeng. All rights reserved.
//CJFFPSIndicatorTools


#include "CJFDebugMonitorTools.h"

#include <mach/vm_map.h>
#include <sys/sysctl.h>
#include <mach/mach.h>
#include <stdbool.h>


#define CJFFPS_CHECK_SYSCTL_NAME(TYPE, CALL) \
if(0 != (CALL)) \
{ \
return 0; \
}


// Avoiding static functions due to linker issues.

/** Get the current VM stats.
 *
 * @param vmStats Gets filled with the VM stats.
 *
 * @param pageSize gets filled with the page size.
 *
 * @return true if the operation was successful.
 */
bool CJFFPS_i_VMStats(vm_statistics_data_t* const vmStats,
                      vm_size_t* const pageSize);


// ============================================================================
#pragma mark - (internal) -
// ============================================================================


double CJFFPS_freeMemory(void)
{
    vm_statistics_data_t vmStats;
    vm_size_t pageSize;
    if(CJFFPS_i_VMStats(&vmStats, &pageSize))
    {
        return (((uint64_t)pageSize) * vmStats.free_count) / (1024.0 * 1024.0);
    }
    return 0.0;
}

double CJFFPS_usableMemory(void)
{
    vm_statistics_data_t vmStats;
    vm_size_t pageSize;
    if(CJFFPS_i_VMStats(&vmStats, &pageSize))
    {
        return ((uint64_t)pageSize) * (vmStats.active_count +
                                       vmStats.inactive_count +
                                       vmStats.wire_count +
                                       vmStats.free_count) / (1024.0 * 1024.0);
    }
    return 0.0;
}

bool CJFFPS_i_VMStats(vm_statistics_data_t* const vmStats,
                      vm_size_t* const pageSize)
{
    kern_return_t kr;
    const mach_port_t hostPort = mach_host_self();

    if((kr = host_page_size(hostPort, pageSize)) != KERN_SUCCESS)
    {
        return false;
    }

    mach_msg_type_number_t hostSize = sizeof(*vmStats) / sizeof(natural_t);
    kr = host_statistics(hostPort,
                         HOST_VM_INFO,
                         (host_info_t)vmStats,
                         &hostSize);
    if(kr != KERN_SUCCESS)
    {
        return false;
    }
    
    return true;
}

int64_t CJFFPS_kssysctl_int64ForName(const char* const name)
{
    int64_t value = 0;
    size_t size = sizeof(value);
    
    CJFFPS_CHECK_SYSCTL_NAME(int64, sysctlbyname(name, &value, &size, NULL, 0));
    
    return value;
}

double CJFFPS_AllMemory(void)
{
    const char* const allMemory = "hw.memsize";
    uint64_t allBytes = CJFFPS_kssysctl_int64ForName(allMemory);
    return allBytes / (1024.0 * 1024.0);
}

// 获取当前任务所占用的内存（单位：MB）
double CJFFPS_usedMemory(void)
{
    task_basic_info_data_t taskInfo;
    mach_msg_type_number_t infoCount = TASK_BASIC_INFO_COUNT;
    kern_return_t kernReturn = task_info(mach_task_self(),
                                         TASK_BASIC_INFO,
                                         (task_info_t)&taskInfo,
                                         &infoCount);
    
    if (kernReturn != KERN_SUCCESS
        ) {
        return 0.0;
    }
    
    return taskInfo.resident_size / 1024.0 / 1024.0;
}

#undef CJFFPS_CHECK_SYSCTL_NAME
