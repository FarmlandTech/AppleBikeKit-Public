#pragma once
/* Define to prevent recursive inclusion -------------------------------------*/
#ifndef __ANALYZER_INTERFACE_H
#define __ANALYZER_INTERFACE_H

//#define NEED_EXPORT_DLL	1

#ifdef _WIN32
#define DllExport   __declspec( dllexport )
#else
#define DllExport
#define __stdcall
#endif 

#ifdef __cplusplus

extern "C" {
#endif

    /* Includes ------------------------------------------------------------------*/
#include <stdio.h>
#include <stdint.h>
#include <stdbool.h>
#include <stdint.h>
#include <string.h>
#include <stdarg.h>

/* Private includes ----------------------------------------------------------*/

#include "fl_lib_loop_fifo.h" 
#include "fl_lib_memory manage.h"

/* Exported types ------------------------------------------------------------*/



/* Exported constants --------------------------------------------------------*/

#define APP_PROCESS_BASE 4
#define APP_PROCESS_COUNT 200 //process使用數量


/*以下勿隨意更動----------------------------*/

/*裝置ID號*/
    enum DllExport analy_device_def
    {
        PC_USB_DEVICE_ID = 1,

        PC_BLE_DEVICE_ID = 2,

        BRIDGE_WIRED_DEVICE_ID = 3,
        BRIDGE_BLE_DEVICE_ID = 4,

        SIMULATOR_DEVICE_ID = 5,
        COMMUNICATOR_DEVICE_ID = 6,

        EXTERNAL_UART_DEVICE_ID = 7,

        CAN_BUS_DEVICE_ID = 8,
        HMI_BLE_DEVICE_ID = 9,

        DEVICE_MAX_ID = HMI_BLE_DEVICE_ID//最大id號
    };


    /*協議頭加CRC長度*/
#define PROTOCOL_LENGTH 14

/*單包最大資料長*/
#define USB_AND_UART_DATA_MAX 255 
#define BLE_DATA_MAX 230  //BLE MTU:244 - 14


/*幀最大編號(1開始)*/
#define FRAME_NUMBER_MAX 63

/*幀號最大間距*/
#define FRAME_NUMBER_INTERVAL 26

/* Exported macro ------------------------------------------------------------*/

/* Exported functions prototypes ---------------------------------------------*/

/*send message--------------*/
    typedef enum DllExport :uint32_t
    {
        ANALY_MESSAGE_SUBMIT_SUCCESS,//資料提交成功
        ANALY_BUSY_MESSAGE_POOL_FULL,//傳輸層記憶體已滿
        ANALY_BUSY_MESSAGE_PROGRESS,//傳輸層忙碌
        ANALY_ERROR_DRV_CLOSE,//DRV層未開啟
        ANALY_ERROR_NOT_SUPPORT,//不支持操作
        ANALY_ERROR_NOT_FOUND_DEVICE,//未找到對應接口
        ANALY_ERROR_LENGTH_INVALID,
        ANALY_ERROR_OVER_LENGTH,

    }analy_send_return_eu;

    typedef enum DllExport :uint8_t
    {
        ANALY_SEND_NO_RESPONE_STORE,
        ANALY_SEND_RESPONE = 1,//響應，過程緩存
        ANALY_SEND_DIRECT = 2,//過程直接
        ANALY_SEND_RESPONE_DIRECT = ANALY_SEND_RESPONE | ANALY_SEND_DIRECT,
        ANALY_SEND_WAIT_FIRST = 4,
        ANALY_SEND_WAIT_FLOW = 8,
        ANALY_SEND_WAIT_FIRST_OR_FLOW = ANALY_SEND_WAIT_FIRST | ANALY_SEND_WAIT_FLOW,
        ANALY_SEND_MUST_RESPONE = ANALY_SEND_RESPONE | ANALY_SEND_WAIT_FIRST | ANALY_SEND_WAIT_FLOW
    }analy_send_type_eu;


    typedef  enum DllExport :uint8_t
    {
        FL_ANALY_SEND_MESSAGE_DONE,//對方接收資料完成
        FL_ANALY_RECEIVER_BUSY,//接收方忙碌中
        FL_ANALY_RECEIVER_FULL,//接收方已滿
        FL_ANALY_ERROR_RECEIVER_REJECT,//接收方拒絕
        FL_ANALY_ERROR_RETRY_SEND,//嘗試重發未回應            
    }analy_send_message_notify_eu;

    typedef void(__stdcall* analy_send_message_notify)(uint8_t dest_device, uint8_t requester_handle, analy_send_message_notify_eu send_notify);



    enum data_states_eu : uint8_t
    {
        FL_ANALY_DATA_ARRIVE,                      //資料到達
        FL_ANALY_DATA_POOL,                        //儲存記憶體池
    };

    typedef struct DllExport
    {
        enum data_states_eu                 data_states;
        uint8_t                             frame_number;
        void* memory_pool;//記憶體池 

    }analy_receive_detail_st;

    typedef void(__stdcall* analy_receive_message_callback)(uint8_t src_device, uint8_t* p_data, size_t length, analy_receive_detail_st* detail);

    typedef void(__stdcall* analy_data_out_notify)(size_t current_data_len);

    typedef size_t(__stdcall* analy_get_data_len)(void);

    /* Exported constants --------------------------------------------------------*/



    /* Exported types ------------------------------------------------------------*/


    typedef uint32_t(__stdcall* get_1ms_tick)(void);

    typedef void(__stdcall* pf_clear_buf)(void);
    typedef uint32_t(__stdcall* pf_data_unit)(void* p_data, size_t length);
    typedef uint32_t(__stdcall* pf_data_multi)(void* p_data, size_t length, size_t element_len);
    typedef uint32_t(__stdcall* pf_fifo_move)(loop_fifo_st* p_fifo, size_t length);


    typedef enum DllExport
    {
        ANALYZER_INTERFACE_DISABLE,
        ANALYZER_INTERFACE_READY,
        ANALYZER_INTERFACE_RUNNING,
        ANALYZER_INTERFACE_ERROR = 0x7FFFFFFF,//強制成INT32 ,

    } analyzer_interface_states_eu;


    typedef enum DllExport
    {
        ANALYZER_PORT_CLOSE,
        ANALYZER_PORT_READY,
        ANALYZER_PORT_BUSY,
        ANALYZER_PORT_ERROR = 0x7FFFFFFF,

    }analyzer_port_states_eu;


    typedef struct 
    {
        analyzer_interface_states_eu    interface_states;
        /*RX----------------------------------------------*/
        loop_fifo_st* p_rx_fifo;
        pf_data_unit                    rx_get_handler;
        pf_fifo_move                    rx_move_handler;
        analyzer_port_states_eu         rx_states;
        uint32_t                        rx_lock_inter_id;
        /*TX----------------------------------------------*/
        loop_fifo_st* p_tx_fifo;
        pf_data_unit                    tx_put_handler;
        pf_fifo_move                    tx_move_handler;
        analyzer_port_states_eu         tx_states;
        uint32_t                        tx_lock_inter_id;
        /*硬體帶資料校驗*/
        bool                            data_verified;

    }analyzer_interface_st;


    typedef struct DllExport
    {
        analy_get_data_len      data_out_len;
        pf_data_unit            data_in_handler;
        pf_data_unit            data_out_handler;
        pf_clear_buf            data_clear;
    }analyzer_soft_interface_st;


    /* Exported functions prototypes ---------------------------------------------*/
    //註冊process 接收事件
    DllExport uint32_t __stdcall  analy_register_process_receive(uint8_t process_id, analy_receive_message_callback receive_callback);

    //註冊process 傳輸通知
    DllExport uint32_t __stdcall  analy_register_process_transfer(uint8_t process_id, analy_send_message_notify send_callback);

    //註冊device 接收事件
    DllExport uint32_t __stdcall analy_register_device_receive(uint8_t device_id, analy_receive_message_callback receive_callback);

    //註冊device 傳輸通知
    DllExport uint32_t __stdcall analy_register_device_transfer(uint8_t device_id, analy_send_message_notify send_callback);

    /*發送資料*/
    DllExport analy_send_return_eu __stdcall analy_send_short_message(uint8_t dest_device, uint8_t self_id, uint16_t requester_id, analy_send_type_eu type, void* p_data_src, size_t length);
    DllExport analy_send_return_eu __stdcall analy_send_long_message(uint8_t dest_device, uint8_t self_id, uint16_t requester_id, analy_send_type_eu type, void* p_data_src, size_t length);

    DllExport void __stdcall analy_memory_free(void* p_current_link);

    //DllExport size_t __stdcall fl_analy_get_usb_sen_buf_len(void);




#ifdef __cplusplus
}
#endif

#endif /* __FARMLAND_SDK_COMMON_H */

