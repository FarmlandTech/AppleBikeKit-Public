#pragma once

#ifndef _LOG_PRINTER_H // include guard
#define _LOG_PRINTER_H
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
//#include <iostream>
#include <string.h>
#include <sys/types.h>
#import <CoreSDKSourceCode/CoreSDK_Common.h>



typedef void(*fp_log_output)(char* log_buff, unsigned int log_leng);

int log_printf(LogLevel_E log_lv, const char* fmt, ...);
int log_flush(void);

void binding_log_callback(fp_log_output callback);
void log_output_set_lv(LogLevel_E* setting_lv);
LogLevel_E log_output_get_lv(void);

#define ELOG(...)	log_printf(LOG_LV_ERROR, __VA_ARGS__)
#define DLOG(...)	log_printf(LOG_LV_DEBUG, __VA_ARGS__)
#define RLOG(...)	log_printf(LOG_LV_RD, __VA_ARGS__)

#define LOG_FLUSH	log_flush()

#endif /* _LOG_PRINTER_H */
