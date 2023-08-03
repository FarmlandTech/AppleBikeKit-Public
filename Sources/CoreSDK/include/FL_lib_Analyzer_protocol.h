#pragma once
#ifndef __ANALYZER_PROTOCOL_H
#define __ANALYZER_PROTOCOL_H

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
#include "FL_Analyzer_interface.h"
#include "FL_Analyzer_setting.h"


/* Exported types ------------------------------------------------------------*/
#define PROTOCOL_HEAD_LEN 10

#define SHORT_DATA_MAX_LEN 255

#define CONTROL_FRAME_MAX_LEN 9
#define STATES_FRAME_MAX_LEN 9

#define FIRST_FRAME_HEAD_LEN 2


/*Header-----------------------------------------*/

#pragma pack(1)
    typedef union
    {
        uint8_t base[PROTOCOL_HEAD_LEN];

        //  __packed struct protocol_head_st_
        struct protocol_head_st_
        {
#if BIG_ENDIANNESS == 0
            /*0~3---------------*/
            uint32_t head_start;

            /*4-----------------*/
            uint8_t dest_device : 6;//目標裝置          
            uint8_t extend_frame : 1;//擴展帧          
            uint8_t transmit_mode : 1;//傳輸模式          

            /*5-----------------*/
            uint8_t src_device : 6;//目標裝置          
            uint8_t control_states_frame : 2;//控制或狀態幀      

            /*6-----------------*/
            uint8_t src_frame : 6;//來源方幀號        
            uint8_t frame_type : 2;//幀類型            

            /*7-----------------*/
            uint8_t ack_frame : 6;//回復對方之幀號    回應端
            uint8_t response_frame : 1;//響應帧            回應端
            uint8_t des_ack : 1;//目標需確認        

            /*8-----------------*/
            uint8_t data_length;//資料長          

            /*9-----------------*/
            uint8_t data_crc8;//校驗碼    
#else                
            /*0~3---------------*/
            uint32_t head_start;

            /*4-----------------*/
            uint8_t transmit_mode : 1;//傳輸模式         
            uint8_t extend_frame : 1;//擴展幀          
            uint8_t dest_device : 6;//目標裝置 

            /*5-----------------*/
            uint8_t control_states_frame : 2;//控制或狀態幀 
            uint8_t src_device : 6;//目標裝置 

            /*6-----------------*/
            uint8_t frame_type : 2;//幀類型 
            uint8_t src_frame : 6;//來源方幀號

            /*7-----------------*/
            uint8_t des_ack : 1;//目標需確認  
            uint8_t response_frame : 1;//響應帧            回應端
            uint8_t ack_frame : 6;//回復對方之幀號    回應端

            /*8-----------------*/
            uint8_t data_length;//資料長 

            /*9-----------------*/
            uint8_t data_crc8;//校驗碼 

#endif
        }detail;

    }analy_protocol_head;
#pragma pack()



    /*-----transfer-------------------*/

    typedef enum
    {
        ANALY_SELF = 1,//自身
        ANALY_PROXY = 2,//代理
        ANALY_OUTSIDE = 4,//外部

    }analy_device_def_eu;


    /*待傳輸資料*/
    typedef struct
    {
        uint8_t                     dest_device;
        uint8_t                     self_device;
        uint8_t                     requester_id;  //process id 
        uint8_t                     requester_handle;  //使用者定義
        analy_send_type_eu          data_type;
        uint8_t                     transfer_count;//已傳輸次數 ，>0代表已傳輸
        uint8_t                     frame_number;  //發送之幀號，0 = 不需確認或已通知 
        uint16_t                    transfer_tick; //發送時節拍，timeout用 0~65535ms，
        uint16_t                    data_len;
        uint8_t* p_data;
    }analy_transfer_record_st;

    typedef struct
    {
        uint8_t                     frame_number;  //發送之幀號，0 = 不需確認         
        uint16_t                    data_len;
        uint8_t* p_data;
    }analy_continu_frame_record_st;



    typedef struct
    {
        analy_transfer_record_st                first_frame_record;
        analy_continu_frame_record_st* continu_frame_record;
        analy_protocol_head                     first_head_data;
        analy_protocol_head                     continu_head_data;
        uint8_t                                 continu_transfer_count;
        uint8_t                                 continu_quantity;
        uint16_t                                continu_transfer_tick;
        uint16_t                                continu_over_time;
        uint8_t                                 last_first_frame_num;
        bool                                    delay_ing;
        uint16_t                                transfer_delay_tick;
        uint64_t                                wait_ack_frame_bit;
        size_t                                  send_index;
    }analy_long_data_record_st;


    typedef enum
    {
        ANALY_FRAME_DATA,//單一幀
        ANALY_FRAME_FIRST,//首幀
        ANALY_FRAME_CONTINUOUS,//連續幀
        ANALY_FRAME_SPARE,//備用
        ANALY_FRAME_CONTROL,//控制幀
        ANALY_FRAME_STATES,//狀態幀

    }analy_frame_type_eu;


    typedef enum
    {
        ANALY_SINGLE_ACK_ARRIVE,//確認幀
        ANALY_CONTINUE_ACK_ARRIVE,//連續確認幀
        ANALY_MULTY_ACK_ARRIVE,//多重確認幀到達
        ANALY_FLOW_ARRIVE,//流量幀到達         
    }analy_transfer_event_type_eu;



    typedef struct
    {
        uint8_t                         src_device_id;     //來源device
        uint8_t                         self_device_id;    //自身device身分 
        uint8_t                         frame_ack_begin; //起始確認幀號，僅連續確認幀使用
        uint8_t                         frame_ack_number; //確認幀號
        analy_frame_type_eu             frame_type;    //幀類型  
        bool                            response_frame; //響應幀
        analy_transfer_event_type_eu    event_type;    //事件類型
        uint8_t* p_data;//資料
    }analy_transfer_event_st;


    typedef struct
    {
        uint8_t                         device_id;      //來源device
        uint8_t                         self_id;        //自身 id 可能有兩個
        uint8_t                         ack_frame;      //需確認幀號 
        uint8_t                         ack_finish;
    }analy_frame_ack_st;


    typedef enum
    {
        ANALY_LONG_SEND_IDLE,
        ANALY_LONG_SEND_INIT,
        ANALY_LONG_SEND_FIRST,
        ANALY_LONG_SEND_CONTINUOUS,
        ANALY_LONG_SEND_WAIT_ACK,
    }analy_data_transfer_states_eu;


    typedef struct analy_transfer_st_
    {
        uint8_t                             transfer_id;

        void (*transfer_notify_handler)(struct analy_transfer_st_* transfer_insta, analy_transfer_event_st event);//傳輸事件
        void (*transfer_ack_handler)(struct analy_transfer_st_* transfer_insta, analy_frame_ack_st ack_frame);//回應對方幀號

        /*短資料紀錄池*/
        loop_fifo_st* p_short_data_record;    //結構 analy_transfer_record_st
        /*短資料儲存區*/
        loop_fifo_st* p_short_data_store;

        /*長資料紀錄*/
        analy_long_data_record_st* p_long_data_record;
        /*長資料儲存區*/
        uint8_t* p_long_data_store;
        uint16_t                            continu_frame_interval;

        /*ack資料紀錄池*/
        loop_fifo_st* p_ack_record;           //結構 analy_frame_ack_st

        /*當前狀態 */
        uint8_t                             error_count;            // 錯誤次數
        uint32_t                            ack_all_index;

        analy_data_transfer_states_eu       transfer_states;

    }analy_transfer_st;



    typedef struct
    {

        //*短資料紀錄池*/
        loop_fifo_st* p_short_data_record;
        /*短資料儲存區*/
        loop_fifo_st* p_short_data_store;


        /*長資料紀錄*/
        analy_long_data_record_st* p_long_data_record;
        /*長資料儲存區*/
        uint8_t* p_long_data_store;


        /*ack資料紀錄池*/
        loop_fifo_st* p_ack_record;

    }analy_transfer_config_st;


    /*----device-------------------------------------------*/
    
    typedef struct
    {
        uint64_t                            src_frame_bit;          //observer:已接收幀號bit
        uint64_t                            wait_ack_frame_bit;     //transfer:已發送之未確認幀號bit    
        uint8_t                             uninterrupt_frame;      //observer:最後收到不中斷幀號
        uint8_t                             alloc_frame;           //transfer:最後分配傳輸幀號        
    }analy_frame_control_st;

    typedef enum
    {
        ANALY_LONG_RECEIVE_IDLE,
        ANALY_LONG_RECEIVE_SUSPEND,
        ANALY_LONG_RECEIVE_ING,

    }analy_long_receive_states_eu;

    typedef struct
    {
        uint64_t                            src_frame_bit;          //已接收
        uint8_t                             first_frame_num;        //首幀號
        uint8_t                             first_frame_len;        //首幀長
        uint8_t                             continu_frame_count;    //連續幀數量
        uint8_t                             continu_single_len;     //連續幀長度
        uint16_t                            total_length;           //全長
        uint32_t                            last_receive_tick;      //最後接收時間
        uint32_t                            over_time;              //超時時間
        uint64_t                            src_frame_done_state;   //目標完成幀狀態
        analy_long_receive_states_eu        receive_states;
        memory_alloc_st* long_data_space;        //動態記憶體
    }analy_long_data_frame_states_st;

    typedef enum 
    {
        ANALY_FLOW_CONTINU,
        ANALY_FLOW_WAIT,
        ANALY_FLOW_OVERLOAD,

    }analy_flow_response_eu ;
    typedef struct
    {
        analy_flow_response_eu              response_states;
        uint8_t                             interval_time;
        uint16_t                            buf_len;
    }analy_current_flow_states;

    typedef struct
    {
        uint8_t                             device_id;      //DEVICE ID號
        uint8_t                             short_max_len;
        analy_device_def_eu                 device_role;
        uint8_t                             current_interface_number;
        analyzer_interface_st* p_path_interface;//外部裝置路由接口  
        /*self  -----------------*/


        /*send receive call back------------------*/
        analy_receive_message_callback      receive_callback; //接收事件
        analy_send_message_notify           notify_callback; //傳輸事件

        /*傳輸者-----------------*/
        analy_transfer_st* transfer_handle;//外部裝置傳輸者

        /*frame 控制-------------*/
        analy_frame_control_st* p_frame_control;//幀控制
        /*flow 控制-------------*/
        analy_current_flow_states           current_flow_states;

        /*長資料*/
        analy_long_data_frame_states_st* p_long_frame_states;

        uint16_t                            package_overtime; //單包超時時間
    }analy_device_st;


    typedef struct
    {
        uint8_t                             device_id;      //DEVICE ID號
        uint8_t                             short_max_len;

        analy_device_def_eu                 device_role;    //裝置角色定義

        analyzer_interface_st* p_path_interface;//路由接口

        /* send receive call back------------------*/
        analy_receive_message_callback      receive_callback; //接收事件
        analy_send_message_notify           notify_callback; //傳輸事件    

        /*傳輸者-----------------*/
        analy_transfer_st* transfer_handle;//綁定傳輸者

        /*frame 控制-------------*/
        analy_frame_control_st* p_frame_control;//幀控制          

        /*長資料*/
        analy_long_data_frame_states_st* p_long_frame_states; //幀狀態


        uint16_t                            package_overtime; //單包超時時間
    }analy_device_config_st;



    /*observer--------------------------------------------------*/
    typedef enum
    {
        ANALY_FRAME_FLOW_CONTROL = 2,  //流量控制幀 
        ANALY_MULTY_ACK_REQUEST = 3,//請求多重確認幀      
    }analy_control_frame_eu;

    typedef enum
    {
        ANALY_FRAME_FLOW_STATE = 2,  //流量狀態幀  
        ANALY_MULTY_ACK_RESPONSE = 3,//多重確認幀狀態響應   

    }analy_states_frame_eu;


    typedef enum
    {
        ANALY_OBSERVER_HEAD_LACK,
        ANALY_OBSERVER_HEAD_CATCH,
        ANALY_OBSERVER_FRAME_RECEIVING,
        ANALY_OBSERVER_FRAME_RECEIVE_DONE,
    }analy_data_observe_states_eu;


    typedef struct
    {
        uint8_t                             observer_id;
        uint8_t                             self_device_id;
        uint16_t                            receive_over_time;

        analyzer_interface_st* p_observer_interface;//觀察接口


        analy_protocol_head                 current_head;
        analy_device_def_eu                 current_device_role;

        uint16_t                            long_data_pool_threshold;

        uint8_t                             head_left_len;
        uint8_t                             data_left_len;
        bool                                start_flag;
        uint16_t                            start_tick;

        /*長資料*/
        uint8_t                             long_receiveing_device;  //> 0 接收中
        uint8_t                             long_source_device;

        analy_data_observe_states_eu        observe_states;

    }analy_observer_st;

    typedef struct
    {
        uint8_t                             self_device_id;
        uint16_t                            receive_over_time;
        analyzer_interface_st* p_observer_interface;//觀察接口
        uint16_t                            long_data_pool_threshold;

    }analy_observer_config_st;


    /* Exported constants --------------------------------------------------------*/



    /* Exported macro ------------------------------------------------------------*/

//#define SWAP_16(x) \
//    (uint16_t)( (( (uint16_t)(x) & 0xFF00) >> 8 )  | \
//                (( (uint16_t)(x) & 0x00FF) << 8 )  ) 
//
//#define SWAP_32(x) \
//    (uint32_t)( (( (uint32_t)(x) & 0xFF000000) >> 24)  | \
//                (( (uint32_t)(x) & 0x00FF0000) >> 8 )  | \
//                (( (uint32_t)(x) & 0x0000FF00) << 8 )  | \
//                (( (uint32_t)(x) & 0x000000FF) << 24)  ) 


#define BYTE_TO_U16_LIT(p_x) \
 (uint16_t) (  ((*( (uint8_t*)(p_x)   ) )        )  | \
               ((*( (uint8_t*)(p_x) +1) )  << 8  )  ) 

#define U16_TO_BYTE_LIT(p_var,p_x) \
    do{                                                         \
        *(uint16_t*)(p_var) = BYTE_TO_U16_LIT(p_x);             \
    }while (0)


#define BYTE_TO_U32_LIT(p_x) \
 (uint32_t) (  ((*( (uint8_t*)(p_x)   ) )        )  | \
               ((*( (uint8_t*)(p_x) +1) )  << 8  )  | \
               ((*( (uint8_t*)(p_x) +2) )  << 16 )  | \
               ((*( (uint8_t*)(p_x) +3) )  << 24 )  ) 

#define U32_TO_BYTE_LIT(p_var,p_x) \
    do{                                                         \
        *(uint32_t*)(p_var) = BYTE_TO_U32_LIT(p_x);             \
    }while (0)    


#define BYTE_TO_U64_LIT(p_x) \
 (uint64_t) (   ( (*( (uint8_t*)(p_x)   ) )        )             | \
                ( (*( (uint8_t*)(p_x) +1) )  << 8  )             | \
                ( (*( (uint8_t*)(p_x) +2) )  << 16 )             | \
                ( (*( (uint8_t*)(p_x) +3) )  << 24 )             | \
                ( ( (uint64_t) *( (uint8_t*)(p_x) +4) ) << 32 )  | \
                ( ( (uint64_t) *( (uint8_t*)(p_x) +5) ) << 40 )  | \
                ( ( (uint64_t) *( (uint8_t*)(p_x) +6) ) << 48 )  | \
                ( ( (uint64_t) *( (uint8_t*)(p_x) +7) ) << 56 )  ) 

#define U64_TO_BYTE_LIT(p_var,p_x) \
    do{                                                         \
        *(uint64_t*)(p_var) = BYTE_TO_U64_LIT(p_x);             \
    }while (0) 



#define BYTE_TO_U16_BIG(p_x) \
 (uint16_t) (  ((*( (uint8_t*)(p_x)   ) )  << 8  )  |           \
               ((*( (uint8_t*)(p_x) +1) )        )  ) 

#define U16_TO_BYTE_BIG(p_var,p_x) \
    do{                                                         \
        *(uint16_t*)(p_var) = BYTE_TO_U16_BIG(p_x);             \
    }while (0)     



#define BYTE_TO_U32_BIG(p_x) \
 (uint32_t) (  ((*( (uint8_t*)(p_x)   ) )  << 24 )  | \
               ((*( (uint8_t*)(p_x) +1) )  << 16 )  | \
               ((*( (uint8_t*)(p_x) +2) )  << 8  )  | \
               ((*( (uint8_t*)(p_x) +3) )        )  ) 

#define U32_TO_BYTE_BIG(p_var,p_x) \
    do{                                                         \
        *(uint32_t*)(p_var) = BYTE_TO_U32_BIG(p_x);             \
    }while (0) 


#define BYTE_TO_U64_BIG(p_x) \
(uint64_t)  (   ( ( (uint64_t) *( (uint8_t*)(p_x)   ) ) << 56 )  | \
                ( ( (uint64_t) *( (uint8_t*)(p_x) +1) ) << 48 )  | \
                ( ( (uint64_t) *( (uint8_t*)(p_x) +2) ) << 40 )  | \
                ( ( (uint64_t) *( (uint8_t*)(p_x) +3) ) << 32 )  | \
                ( (*( (uint8_t*)(p_x) +4) )  << 24 )             | \
                ( (*( (uint8_t*)(p_x) +5) )  << 16 )             | \
                ( (*( (uint8_t*)(p_x) +6) )  << 8  )             | \
                ( (*( (uint8_t*)(p_x) +7) )        )             )                

#define U64_TO_BYTE_BIG(p_var,p_x) \
    do{                                                         \
        *(uint64_t*)(p_var) = BYTE_TO_U64_BIG(p_x);             \
    }while (0) 

#if BIG_ENDIANNESS == 0
#define    BYTE_2_U16_LIT(p_x) *((uint16_t*)(p_x))
#define    BYTE_2_U32_LIT(p_x) *((uint32_t*)(p_x))
#define    BYTE_2_U64_LIT(p_x) *((uint64_t*)(p_x))
#else
#define    BYTE_2_U16_LIT(p_x) BYTE_TO_U16_LIT(p_x)
#define    BYTE_2_U32_LIT(p_x) BYTE_TO_U32_LIT(p_x)
#define    BYTE_2_U64_LIT(p_x) BYTE_TO_U64_LIT(p_x)
#endif   
/* Exported functions prototypes ---------------------------------------------*/

/*INIT-----------------------------------------*/
//接口觀察者初始化
    uint32_t analy_interface_observer_init(analy_observer_st* observer_insta, analy_observer_config_st* observer_config);

    //資料傳輸者初始化
    uint32_t analy_message_transfer_init(analy_transfer_st* transfer_insta, analy_transfer_config_st* transfer_config);

    //裝置初始化
    uint32_t analy_device_init(analy_device_st* device_insta, analy_device_config_st* device_config);




    //註冊process 接收事件
    uint32_t analy_register_process_receive(uint8_t process_id, analy_receive_message_callback receive_callback);

    //註冊process 傳輸通知
    uint32_t analy_register_process_transfer(uint8_t process_id, analy_send_message_notify send_callback);

    //註冊device 接收事件
    uint32_t analy_register_device_receive(uint8_t device_id, analy_receive_message_callback receive_callback);
    //註冊device 傳輸通知
    uint32_t analy_register_device_transfer(uint8_t device_id, analy_send_message_notify send_callback);

    void analy_memory_free(void* p_current_link);

    uint32_t analy_sys_init(get_1ms_tick tick_handler, memory_pool_st * mem_pool);

    /*INIT END-------------------------------------*/


    /*運行*/
    uint32_t analy_observer_runtime(analy_observer_st* observer_insta);

    uint32_t analy_transfer_runtime(analy_transfer_st* transfer_insta);


    extern get_1ms_tick get_system_tick;

    extern analy_observer_st* observer_group[];
    extern analy_transfer_st* transfer_group[];


#ifdef __cplusplus
}
#endif

#endif /* __FARMLAND_SDK_COMMON_H */