#include "LogPrinter.h"
#include <stdio.h>
#include <stdarg.h>
#include "CoreSDK.h"

#ifndef LOG_PRINT_ENABLE
#define LOG_PRINT_ENABLE 1
#endif

#if LOG_PRINT_ENABLE == 1

#ifdef _WIN32

#define LogD(...) printf(__VA_ARGS__)
#define LogE(...) printf(__VA_ARGS__)

#else

#include "android/log.h"
#include <cstdarg>

#define LOG_TAG "JNI/CPP_Log"

#define LogD(...) __android_log_print(ANDROID_LOG_DEBUG, LOG_TAG, __VA_ARGS__)
#define LogE(...) __android_log_print(ANDROID_LOG_ERROR, LOG_TAG, __VA_ARGS__)

#endif


#else

#define LogD(...)
#define LogE(...)

#endif

#define PRINT_BUFF_SIZE 32768
char print_buff[PRINT_BUFF_SIZE] = { 0 };
unsigned int print_buff_index = 0;


int log_printf(const char* fmt, ...)
{
    char* fp = &print_buff[print_buff_index];
    int buff_size = PRINT_BUFF_SIZE < print_buff_index ? 0 : (PRINT_BUFF_SIZE - print_buff_index);

    va_list arg_list;
    va_start(arg_list, fmt);

    print_buff_index += vsnprintf(fp, buff_size, fmt, arg_list);
    va_end(arg_list);

    return print_buff_index;
}

int log_flush(void)
{
    LogD("%s", print_buff);
    print_buff_index = 0;
    memset(print_buff, 0x0, PRINT_BUFF_SIZE);

    return true;
}
