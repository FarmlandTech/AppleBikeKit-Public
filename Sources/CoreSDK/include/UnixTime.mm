
#include "UnixTime.h"


#define UTC_BASE_YEAR   1970
#define MONTH_PER_YEAR  12
#define DAY_PER_YEAR    365
#define SEC_PER_DAY     86400
#define SEC_PER_HOUR    3600
#define SEC_PER_MIN     60

// Days in month
const unsigned char g_day_per_mon[MONTH_PER_YEAR] = { 31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31 };



static unsigned char applib_dt_is_leap_year(unsigned short year)
{

    if ((year % 400) == 0) {
        return 1;
    }
    else if ((year % 100) == 0) {
        return 0;
    }
    else if ((year % 4) == 0) {
        return 1;
    }
    else {
        return 0;
    }
}



static unsigned char applib_dt_last_day_of_mon(unsigned char month, unsigned short year)
{
    if ((month == 0) || (month > 12)) {
        return g_day_per_mon[1] + applib_dt_is_leap_year(year);
    }

    if (month != 2) {
        return g_day_per_mon[month - 1];
    }
    else {
        return g_day_per_mon[1] + applib_dt_is_leap_year(year);
    }
}


void Unix2DateTime(unsigned long long unix_num, DateTime_st * out_date_time)
{
    unsigned long long GMT_sec = SEC_PER_HOUR * out_date_time->GMT;
    //GMT
    if (out_date_time->GMT > 0 && out_date_time->GMT < 24)
    {
        unix_num += GMT_sec;
    }
    else if (out_date_time->GMT < 0 && out_date_time->GMT > -24)
    {
        unix_num -= GMT_sec;
    }

    //先將Unix轉成天數
    unsigned long long days = unix_num / SEC_PER_DAY;
    //計算年分
    int yearTmp = 0;
    int dayTmp = 0;
    //計算出當年一年中的天數
    for (yearTmp = UTC_BASE_YEAR; days > 0; yearTmp++) {
        dayTmp = (DAY_PER_YEAR + applib_dt_is_leap_year(yearTmp)); //取得這一年的天數
        if (days >= dayTmp)
        {
            days -= dayTmp;
        }
        else
        {
            break;
        }
    }
    out_date_time->year = yearTmp;

    //計算月
    int monthTmp = 0;
    for (monthTmp = 1; monthTmp < MONTH_PER_YEAR; monthTmp++) {
        dayTmp = applib_dt_last_day_of_mon(monthTmp, out_date_time->year);
        if (days >= dayTmp) {
            days -= dayTmp;
        }
        else
        {
            break;
        }
    }
    out_date_time->month = monthTmp;

    out_date_time->day = (uint8_t)(days + 1);

    //取出當天剩餘秒數
    int secs = unix_num % SEC_PER_DAY;
    //計算時數
    out_date_time->hour = secs / SEC_PER_HOUR;
    //計算分鐘數
    secs %= SEC_PER_HOUR;
    out_date_time->minute = secs / SEC_PER_MIN;
    //計算秒數
    out_date_time->second = secs % SEC_PER_MIN;

}


unsigned long long DateTime2Unix(DateTime_st in_date_time)
{
    unsigned long long unix_time;
    int passed_days = 0;
    int month_array[13] = { 0,31,28,31,30,31,30,31,31,30,31,30,31 };

    //該月以前的天數
    for (int i = 1; i < in_date_time.month; i++) {
        passed_days += month_array[i];
        //閏年的二月多一天
        if (i == 2 && (in_date_time.year % 400 == 0 || (in_date_time.year % 4 == 0 && in_date_time.year % 100 != 0))) {
            passed_days += 1;
        }
    }

    //該年以前的天數
    while (--in_date_time.year >= 1970) {
        if (in_date_time.year % 400 == 0 || (in_date_time.year % 4 == 0 && in_date_time.year % 100 != 0))
            passed_days += 366;
        else
            passed_days += 365;
    }

    //(該月1號為止的總天數 + 當天 - 1號)轉秒 + 時轉秒 + 分轉秒 + 秒
    unix_time = (passed_days + in_date_time.day - 1) * 24 * 3600 + in_date_time.hour * 3600 + in_date_time.minute * 60 + in_date_time.second;
    
    //GMT
    if (in_date_time.GMT > 0 && in_date_time.GMT < 24)
    {
        unix_time -= (in_date_time.GMT * SEC_PER_HOUR);
    }
    else if (in_date_time.GMT < 0 && in_date_time.GMT > -24)
    {
        unix_time -= (in_date_time.GMT * SEC_PER_HOUR);
    }

    // Return GMT+0 unix timestamp
    return unix_time;
}

