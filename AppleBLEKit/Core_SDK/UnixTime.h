#pragma once

#ifndef _UNIXTIME_H
#define _UNIXTIME_H
#include <stdint.h>

struct DateTime_st
{
	uint16_t year;
	uint8_t month;
	uint8_t day;
	uint8_t hour;
	uint8_t minute;
	uint8_t second;
	int8_t GMT;
};


void Unix2DateTime(unsigned long long unix_num, DateTime_st* out_date_time);
unsigned long long DateTime2Unix(DateTime_st in_date_time);

#endif
