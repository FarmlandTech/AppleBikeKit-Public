#pragma once

#ifndef _LOG_PRINTER_H // include guard
#define _LOG_PRINTER_H
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <iostream>
#include <string.h>
#include <sys/types.h>

#define LOG_LEVEL_ERROR	1
#define LOG_LEVEL_DEBUG	2
#define LOG_LEVEL_RD	3

#define NOW_LOG_LEVEL	LOG_LEVEL_RD

int log_printf(const char* fmt, ...);
int log_flush(void);

#define LOG_PUSH(...)	log_printf(__VA_ARGS__)
#define LOG_FLUSH	log_flush()

#endif /* _LOG_PRINTER_H */