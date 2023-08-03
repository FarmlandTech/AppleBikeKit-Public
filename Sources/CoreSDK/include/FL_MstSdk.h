#pragma once
#pragma warning(disable:4996)
#pragma warning(disable:26812)
#pragma warning(disable:26813)

#ifndef _FL_MST_SDK_H // include guard
#define _FL_MST_SDK_H

 

#include "ActionScript.h"
#include "FL_Analyzer_setting.h"

#ifdef _WIN32
#define DllExport   __declspec( dllexport )
#else
#define DllExport
#define __stdcall
#endif 

#ifdef __cplusplus
extern "C" {
#endif

    uint32_t Mst_init(MstSdkConfig_T configuration);
    void Mst_sdk_run_program();
    DllExport uint32_t __stdcall  can_bus_event_register(analy_send_message_notify user_notify, analy_receive_message_callback user_receive); 
    DllExport uint32_t __stdcall can_bus_send_message(uint8_t self_id, uint32_t can_id, bool is_extender, uint8_t* data, uint32_t len);

#ifdef __cplusplus
}
#endif
typedef enum MST_SEND_PATH_
{
    MST_PATH_NULL,
    MST_PATH_USB,
    MST_PATH_BLE
}MST_SEND_PATH;

analy_send_return_eu Mst_can_pass(MST_SEND_PATH path, uint32_t can_id, bool is_extender, uint8_t* data, uint32_t len);


typedef  ActionFinally_Callback*    ActFinally_Callback;
typedef  ActionError_Callback*      ActError_Callback;

class  Mst_soft_timer
{
public:
    enum soft_timer_state_eu
    {
        PROCESS_TIMER_DISABLE,
        PROCESS_TIMER_ENABLE,
        PROCESS_TIMER_SUSPEND,
        PROCESS_TIMER_OVERFLOW
    }state ; 

    uint16_t             start_time = 0;
    uint16_t             through_time = 0;
    bool soft_timer_1ms(uint32_t set_time, bool start);
    void soft_timer_reset(void);
    Mst_soft_timer(void);
};

class Sdk_script_op
{
public:
    static struct operate_st
    {
        typedef void (*fp_Script_argument_st)(uint32_t timeout_ms_sets);
        typedef void (*fp_Script_operate_st)(void);
        fp_Script_argument_st fp_Script_wait;
        fp_Script_operate_st  fp_Script_resume;
        fp_Script_operate_st  fp_Script_done;
    }script_op;
    Sdk_script_op(Sdk_script_op::operate_st app_script_op); 
};

class  Mst_DFU
{
public:

    static  struct user_callback_st
    {
        fpCallback_UpgradeFirmware upgrade_result_callback;
        UpgradeStateMsg_p upgrade_msg_callback;
    }user_callback;

    static struct execute_record_st
    {
        enum result_eu
        {
            UPGRADE_NULL,
            UPGRADE_DONE,
            UPGRADE_ERROR,
        }last_result;
        enum upgrad_error_eu
        {
            UPGRADE_ERROR_NULL = 0,
            UPGRADE_ERROR_SEND_TIMEOUT = 1 << 4,  
            UPGRADE_ERROR_ANALY_DISCONNECT = 2 << 4, 
            UPGRADE_ERROR_BIN_FILE_CEC32_ERROR = 3 << 4
        };
        int32_t  error_code;
    }execute_record;
    static bool run_busy;
    Mst_DFU();   

    ~Mst_DFU();

    ScriptFunction  get_Mst_Upgrad_FW_Script(uint8_t target_device, uint8_t* p_bin_file, uint32_t file_len);

    void  register_user_callback(fpCallback_UpgradeFirmware  result_callback, UpgradeStateMsg_p p_script_wait);

    static void MST_Upgrade_script_finally_callback(struct FunctionParameterDefine* para); 

    static void MST_Upgrade_script_error_callback(struct FunctionParameterDefine* para, uint32_t err_code);

private:
    static const uint8_t process_number = 24;   

    static void  Dfu_setting(void);
    static void error_ending( uint8_t step, uint8_t type, uint8_t code, uint8_t response);
    static void done_ending(void);
    static void snd_bin_data(void);
    static void analy_notify(uint8_t dest_device, uint8_t requester_id, analy_send_message_notify_eu event);   

    static void analy_receive(uint8_t src_device, uint8_t* p_data, size_t length, analy_receive_detail_st* detail);

    static Mst_soft_timer dfu_time_out;
    static void time_out_execute(uint32_t time, uint8_t current_state);
    static void time_out_reset(); 

    class Upgrad_program; 
    static Upgrad_program* upgrad_insta;

    static void MST_Upgrade_run(struct FunctionParameterDefine* paras);
};

class  Mst_Para
{
public:

    static  struct user_callback_st
    {
        fpCallback_ReadParameters   read_result_callback;
        fpCallback_WriteParameters  write_result_callback;
        fpCallback_ResetParameters  reset_result_callback;
    }user_callback;

    typedef  enum  para_type_eu : unsigned int
    {
        PARA_READ,
        PARA_WRITE,
        PARA_RESET,
        PARA_MAX
    }para_type;

    typedef enum self_error_eu 
    { 
        ERROR_NULL = 0,
        SEND_TIMEOUT = 1 , 
        ANALY_DISCONNECT = 2, 
        RESPOSE_TIMEOUT = 3, 
        ANALY_ARG_INCOMPATIBLE = 4,
    }self_error;
      
    typedef  enum  res_states_eu :uint8_t 
    { 
        PARA_DONE, 
        PARA_BUSY, 
        PARA_ARG_ERR, 
        PARA_DEVICE_ERR  
    }res_states;

    static uint8_t          self_device;

    typedef  enum  run_states_eu_
    {
        PARA_IDLE,  
        PARA_REQUEST,
        PARA_WAIT_RES,
    }run_states_eu;

    static run_states_eu    run_states;

    static Mst_soft_timer   time_out;
    static para_type        curr_type;
    static int              error_code;

    static const uint8_t process_number = 20;
    static const uint16_t MAX_DATA_BUF_LEN = 1024; 

    static  uint32_t     package_quan;
    static  uint16_t     total_len;
    typedef  struct  
    {
        uint8_t         device_number;
        uint8_t         bank_index;
        uint16_t        mem_addr;
        uint16_t        mem_len;
        bool            request_done;
        bool            response_done;
        uint8_t         data_buf[MAX_DATA_BUF_LEN]; 
    } para_arg_st;
    static para_arg_st   arg_group[];
    Mst_Para();

    ~Mst_Para();
     
    ScriptFunction  get_Mst_para_Script(para_type exe_type);

    static void  register_user_callback(para_type exe_type, void* user_call_back);

    static ActFinally_Callback     get_finally_callback(para_type exe_type);

    static ActError_Callback       get_error_callback(para_type exe_type); 

    static void error_ending(uint8_t state, uint8_t type, uint8_t response);

    static void para_run_RW_init(struct FunctionParameterDefine* paras);  
private:
    static bool check_argument(uint16_t  addr, uint16_t len);  

    static bool judge_done_states(void);  

    static void done_ending(void); 

    static void analy_notify(uint8_t dest_device, uint8_t requester_id, analy_send_message_notify_eu event);

    static void analy_receive(uint8_t src_device, uint8_t* p_data, size_t length, analy_receive_detail_st* detail);

    static ScriptFunction    script_run[];

    static ActFinally_Callback  act_finally_callback[];
    static ActError_Callback    act_error_callback[];
};

extern Mst_DFU* Mst_dfu_insta;
extern Mst_Para* Mst_para_insta;


#define BYTE_2_STRUCT(type_, dest_, sour_)      (dest_) = *(type_*)(sour_)     
#define STRUCT_2_BYTE(type_, dest_, sour_)      *(type_*)(dest_) = (sour_)


#endif

