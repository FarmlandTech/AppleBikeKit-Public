#pragma once
#ifndef __ANALYZER_SETTING_H
#define __ANALYZER_SETTING_H

#ifdef _WIN32
#define DllExport   __declspec( dllexport )
#else
#define DllExport
#define __stdcall
#endif 


#ifdef __cplusplus


extern "C" {
#endif
    /* Analyzer  config  ------------------------------------------------------------------*/

    /*目前系統 大小端*/
#define BIG_ENDIANNESS     0   // 0 小端 1 大端    

#define SOFT_INTERFACE_USE    1   

#define DRV_INTERFACE_COUNT   2//接口數量
#define DATA_TRANSFER_COUNT   3//傳輸者數量 
     

/*-------傳輸者-----------*/
#define TRANSFER_RETRY_COUNT  2 //需ACK之傳輸資料，重傳次數     

#define SHORT_DATA_FRAME_COUNT 30//短資料同時最大幀數
#define SHORT_DATA_BUFFER 4096   //短資料BUFF大小

#define LONG_DATA_FRAME_COUNT 16//長資料最大幀數
#define LONG_DATA_BUFFER 4120//長資料BUFFER大小
/*-------傳輸者END-----------*/

/* Includes ------------------------------------------------------------------*/
#include <stdio.h>
#include <stdint.h>
#include <stdbool.h>
#include <stdint.h>
#include <string.h>
#include <stdarg.h>

/* Private includes ----------------------------------------------------------*/

#include "FL_lib_Analyzer_protocol.h"

/* Exported types ------------------------------------------------------------*/

/* Exported constants --------------------------------------------------------*/
    typedef enum DllExport 
    {
        ANALYZER_INTERFACE_USB,
        ANALYZER_INTERFACE_BLE,
    } analyzer_soft_interface_eu; 


/* Exported macro ------------------------------------------------------------*/


/* Exported functions prototypes ---------------------------------------------*/
   extern uint32_t analy_tick;
   extern analy_data_out_notify  soft_interface_out_notify[];//通知軟體接口

   uint32_t  analy_framework_init(void);
   void update_analy_tick(void);
   uint32_t analy_math_crc32(const uint8_t* buf, uint32_t len, uint32_t init);
   /*PC USB用----------------------------------------*/
 
   DllExport uint32_t __stdcall  analy_usb_init(analyzer_soft_interface_st* user_inatance, analy_data_out_notify user_callback);
 /*  DllExport size_t __stdcall   fl_analy_get_usb_sen_buf_len();*/
   DllExport int32_t __stdcall  analy_get_system_states();
   bool internal_usb_clear(void);
    
#ifdef __cplusplus
}
#endif

#endif /* __FARMLAND_SDK_COMMON_H */