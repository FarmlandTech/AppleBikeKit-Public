
#include <string>
#include <iostream>
#include <chrono>
#include <queue>
#include <thread>
#include <ctime>
#include <stdio.h>
#include <stdarg.h>
#include "LogPrinter.h"

#include "UnixTime.h"
#include "FL_CanProtocol.h"
#include "FL_MstSdk.h"

using namespace std;
using namespace std::chrono;
using namespace std::this_thread;

#define MST_SDK_Version_Str "1.0.0"


/*Private  CAN BUS----------------*/
analy_receive_message_callback  user_can_receive_handler;
analy_send_message_notify       user_can_notify_handler;
  
static void user_analyzer_can_notify(uint8_t dest_device, uint8_t requester_id, analy_send_message_notify_eu send_notify)
{
    if(user_can_notify_handler != NULL)
        user_can_notify_handler(dest_device, requester_id, send_notify); 
}

static void user_analyzer_can_receive(uint8_t src_device, uint8_t* p_data, size_t length, analy_receive_detail_st* detail)
{
    CANBusPacket_IN((*(uint32_t*)p_data) & 0x1FFFFFFF, p_data[3] >> 7, p_data + 4, length - 4);
    if (user_can_receive_handler != NULL) 
        user_can_receive_handler(src_device, p_data, length, detail); 
}

analy_send_return_eu Mst_can_pass(MST_SEND_PATH path, uint32_t can_id, bool is_extender, uint8_t* data, uint32_t len)
{
    if (path == MST_PATH_NULL)
        return ANALY_ERROR_NOT_FOUND_DEVICE; 

    struct send_data_st
    {
        uint32_t                can_id;
        uint8_t                 data_buf[8];
    }send_data = { .can_id = can_id | (is_extender ? 0x80000000 : 0)};

    memcpy(send_data.data_buf, data, MIN(len, sizeof(send_data.data_buf)));

    return analy_send_short_message(CAN_BUS_DEVICE_ID, path == MST_PATH_BLE ? PC_BLE_DEVICE_ID : PC_USB_DEVICE_ID,
                                        0, ANALY_SEND_RESPONE, (void*)&send_data, (size_t)len + 4);
}

/*USER CAN BUS----------------*/

uint32_t can_bus_event_register(analy_send_message_notify user_notify, analy_receive_message_callback user_receive)
{
    user_can_notify_handler = user_notify;
    user_can_receive_handler = user_receive;
    return 0;
}

#pragma pack(1)
typedef struct
{
    uint8_t                     self_id;
    struct 
    {
        uint32_t                can_id;
        uint8_t                 data_buf[8];
        uint32_t                length;
    }send_data; 
}Mst_can_bus_st;
#pragma pack()
LOOP_FIFO_INSTANCE(user_can_bus_fifo, 20, Mst_can_bus_st);

uint32_t can_bus_send_message(uint8_t self_id, uint32_t can_id, bool is_extender, uint8_t* data, uint32_t len)
{
    Mst_can_bus_st data_temp = { .self_id = self_id, .send_data = {.can_id = can_id | (is_extender ? 0x80000000 : 0) , .length = len} };
    memcpy(data_temp.send_data.data_buf, data, MIN(len, sizeof(data_temp.send_data.data_buf)));  

    return fl_loop_fifo_put(&user_can_bus_fifo, &data_temp, sizeof(Mst_can_bus_st));
}
/*----------------Timer----------------*/
bool Mst_soft_timer ::soft_timer_1ms(uint32_t set_time, bool start)
{
    if (start)
    {
        if (set_time == 0)
        {
            state = PROCESS_TIMER_OVERFLOW;
            return true;
        }

        switch (state)
        {
        case PROCESS_TIMER_DISABLE:
        {
            start_time = analy_tick;
            through_time = 0;
            state = PROCESS_TIMER_ENABLE;
        }
        break;

        case PROCESS_TIMER_ENABLE:
        {
            if ((through_time = analy_tick - start_time) >= set_time)
            {
                state = PROCESS_TIMER_OVERFLOW;
                return true;
            }
        }
        break;

        case PROCESS_TIMER_OVERFLOW:
        {
            return true;
        }
        break;

        default:
            break;
        }
    }
    else
    {
        state = PROCESS_TIMER_DISABLE;
    }
    return false;
}

void Mst_soft_timer::soft_timer_reset(void)
{
    state = PROCESS_TIMER_DISABLE; 
    through_time = 0;
}
 Mst_soft_timer::Mst_soft_timer()
{
    soft_timer_reset();
}

 struct Sdk_script_op::operate_st            Sdk_script_op::script_op;

 Sdk_script_op::Sdk_script_op(Sdk_script_op::operate_st app_script_op)
 {
     Sdk_script_op::script_op = app_script_op;
 };


 /*----------------DFU----------------*/
Mst_DFU* Mst_dfu_insta;

#pragma pack(1)
typedef  struct rom_addr_st_
{
    uint8_t      addr[3];
}rom_addr_st;

typedef struct
{ 
    uint8_t                  fun_num;
    uint8_t                  process_num;
    uint8_t                  device;
}analy_dfu_opc0; 
 
typedef struct
{
    uint8_t         fun_num;
    uint8_t         process_num;
    uint8_t         init_data;
    uint16_t        identifier;
    uint16_t        block_index;
    rom_addr_st     flash_size;
    uint16_t        page_size;
    uint16_t        cache_size;
}analy_dfu_opc1;

typedef struct
{
    uint8_t          fun_num;
    uint8_t          process_num;
    rom_addr_st      erase_start_addr;
    rom_addr_st      erase_end_addr;
    uint16_t         write_info;
}analy_dfu_opc2;

typedef struct
{
    uint8_t      fun_num;
    uint8_t      process_num;
}analy_dfu_opc3;

typedef struct
{
    uint8_t      fun_num;
    uint8_t      process_num;
    uint32_t     ROM_start_addr; 
    uint32_t     ROM_total_len; 
    uint16_t     per_data_len; 
    uint8_t      execution_times;
}analy_dfu_opc4;

typedef struct
{
    uint8_t      fun_num;
    uint8_t      process_num;
    uint32_t     received_length;
    uint32_t     remaining_space;
}analy_dfu_opc5;

typedef struct
{
    struct long_data_head_st_
    {
        uint8_t      fun_num;
        uint8_t      process_num;
        uint32_t     data_offset;
    }data_head;
    uint8_t      data_bin;
}analy_dfu_opc6;

typedef struct
{
    uint8_t      fun_num;
    uint8_t      process_num;
    uint32_t     check_start_addr;
    uint32_t     check_end_addr;
}analy_dfu_opc8;

typedef struct
{
    uint8_t      fun_num;
    uint8_t      process_num;
    uint32_t     crc32_result;
}analy_dfu_opc9;
typedef struct
{
    uint8_t      fun_num;
    uint8_t      process_num;
}analy_dfu_opc10;

typedef struct
{
    uint8_t      fun_num;
    uint8_t      process_num;
}analy_dfu_opc11;

typedef struct
{
    uint8_t      fun_num;
    uint8_t      process_num;
    uint8_t      error_response;
    uint8_t      error_code;
    uint8_t      error_type;
}analy_dfu_opc255;

#pragma pack()

enum mst_dfu_opc_eu
{
    ANALY_DFU_OPC_START = 0,
    ANALY_DFU_OPC_READ_INFO,
    ANALY_DFU_OPC_WRITE_INFO_ERASE,
    ANALY_DFU_OPC_WRITE_ROM_READY,
    ANALY_DFU_OPC_WRITE_SET,
    ANALY_DFU_OPC_RESPONSE_STATE,
    ANALY_DFU_OPC_RX_DATA,
    ANALY_DFU_OPC_MAINTAIN_1,
    ANALY_DFU_OPC_REQUEST_CRC,
    ANALY_DFU_OPC_RESPONSE_CRC,
    ANALY_DFU_OPC_ENDING,
    ANALY_DFU_OPC_JUMP_APP_FINISH,
    ANALY_DFU_OPC_ERROR = 255
};
struct Mst_DFU::execute_record_st           Mst_DFU::execute_record;
struct Mst_DFU::user_callback_st            Mst_DFU::user_callback;
Mst_soft_timer                              Mst_DFU::dfu_time_out;
Mst_DFU::Upgrad_program*                    Mst_DFU::upgrad_insta;
bool                                        Mst_DFU::run_busy;

class Mst_DFU::Upgrad_program
{
public:
    uint8_t  self_device;
    uint16_t  write_cache_per_len;
    uint16_t  write_cache_total_len;
    uint8_t  target_device;
    uint8_t* p_bin_file;
    uint32_t file_len;

    bool info_erase_send_finish = false;
    bool write_setting_finish = false;
    bool receive_crc_finish = false;
    bool bin_file_crc32_finish = false;

    uint32_t bin_file_crc32_result = 0;
    uint32_t receive_crc32_lit = 0;

    bool analy_send_busy = false;
    bool data_next_standby = false;

    uint32_t send_addr_start_current = 0;
    uint32_t send_addr_end_current = 0;
    uint32_t send_addr_start_next = 0;
    uint32_t send_addr_end_next = 0;
    
    uint32_t report_len = 0;

    analy_dfu_opc1 receive_device_info = {0}; 
    analy_dfu_opc9 receive_device_rom_crc = {0};
    enum state_eu
    {
        idle,
        start,
        wait_device_info,
        write_device_info_and_erase,
        write_set,
        wait_standby_write_ROM,
        send_bin_data,
        request_verify_flash,
        wait_flash_crc_result,
        request_ending,
        wait_ending,
    }states ;
    Upgrad_program(uint8_t target_device, uint8_t* p_bin_file, uint32_t file_len)
    { 
        execute_record.last_result = Mst_DFU::execute_record_st::UPGRADE_NULL;
        execute_record.error_code = 0;

        self_device = 1;

        this->file_len = file_len;
        this->p_bin_file = p_bin_file;
        this->target_device = target_device;
         
        this->write_cache_per_len = 1024;
        this->write_cache_total_len = this->write_cache_per_len * 2;

        states = state_eu::start;
    }
};

void  Mst_DFU::time_out_execute(uint32_t time, uint8_t current_state)
{
    if (dfu_time_out.soft_timer_1ms(time, upgrad_insta->states == (Upgrad_program::state_eu)current_state))
        Mst_DFU::error_ending((uint8_t)upgrad_insta->states,0, 0, 0);
}
void Mst_DFU::time_out_reset()
{
    dfu_time_out.soft_timer_reset();
}

ScriptFunction  Mst_DFU::get_Mst_Upgrad_FW_Script(uint8_t target_device, uint8_t* p_bin_file, uint32_t file_len) 
{
    if (analy_get_system_states() == 0)
        return NULL; 

    if (p_bin_file != NULL)
    {
        if(Mst_DFU::run_busy)
            return  NULL;

        if (upgrad_insta != NULL)
            delete upgrad_insta;
        upgrad_insta = new Upgrad_program(target_device, p_bin_file,  file_len);

        Mst_DFU::run_busy = true;
        return Mst_DFU::MST_Upgrade_run;
    }
    return  NULL;
};

void  Mst_DFU::register_user_callback(fpCallback_UpgradeFirmware  result_callback, UpgradeStateMsg_p p_script_wait)
{
    user_callback.upgrade_result_callback = result_callback;
    user_callback.upgrade_msg_callback = p_script_wait;
};

void Mst_DFU::MST_Upgrade_script_finally_callback(struct FunctionParameterDefine* para)
{
    if (user_callback.upgrade_result_callback != NULL)
        user_callback.upgrade_result_callback(Mst_DFU::execute_record.error_code);   
    Mst_DFU::run_busy = false;
};
void Mst_DFU::MST_Upgrade_script_error_callback(struct FunctionParameterDefine* para, uint32_t err_code)
{
    if (user_callback.upgrade_result_callback != NULL) 
        user_callback.upgrade_result_callback((int)(err_code));
    Mst_DFU::run_busy = false;
};
void  Mst_DFU::error_ending(uint8_t dfu_state, uint8_t type, uint8_t code, uint8_t response )
{
    static char return_str[1024] = { 0 };
   Mst_DFU::execute_record.error_code = dfu_state << 24  | type << 16 | code << 8 | response ;
   Mst_DFU::execute_record.last_result = Mst_DFU::execute_record_st::UPGRADE_ERROR; 
   upgrad_insta->states = Upgrad_program::state_eu::idle; 
   Sdk_script_op::script_op.fp_Script_done();
   //printf("dfu_state:%d __ type:%d __ code:%d __ response:%d \r\n ", dfu_state, type, code, response);

   memset(return_str, 0, 1024);
   sprintf(return_str, "[self:%d ] [state:%d ] [type:%d ] [FW:%d ] [response:%d ] ", dfu_state >> 4, dfu_state & 0x0F, type, code, response);
   user_callback.upgrade_msg_callback(return_str, 0);
}

void  Mst_DFU::done_ending()
{
    Mst_DFU::execute_record.last_result = Mst_DFU::execute_record_st::UPGRADE_DONE;
    upgrad_insta->states = Upgrad_program::state_eu::idle;
    Sdk_script_op::script_op.fp_Script_done();
}

void  Mst_DFU::snd_bin_data(void)
{
    if (!upgrad_insta->analy_send_busy)
    {
        if (upgrad_insta->data_next_standby)
        {
            uint8_t long_data_buf[4108];

            analy_dfu_opc6* const p_send_data = (analy_dfu_opc6*)long_data_buf;

            upgrad_insta->send_addr_start_current = upgrad_insta->send_addr_start_next;
            upgrad_insta->send_addr_end_current = upgrad_insta->send_addr_end_next;

            p_send_data->data_head.fun_num = ANALY_DFU_OPC_RX_DATA;
            p_send_data->data_head.process_num = process_number; 
            p_send_data->data_head.data_offset = BYTE_2_U32_LIT(&upgrad_insta->send_addr_start_current);
            size_t data_len = upgrad_insta->send_addr_end_current - upgrad_insta->send_addr_start_current;
            
            memcpy(&p_send_data->data_bin, upgrad_insta->p_bin_file + upgrad_insta->send_addr_start_current, data_len);

            if (analy_send_long_message(6,
                upgrad_insta->self_device,
                (uint16_t)process_number | 6 << 8,
                ANALY_SEND_WAIT_FLOW,
                long_data_buf,
                sizeof(analy_dfu_opc6::long_data_head_st_) + data_len) == ANALY_MESSAGE_SUBMIT_SUCCESS)
            {
                upgrad_insta->data_next_standby = false;
                upgrad_insta->analy_send_busy = true;
            }
        }
    }
}

void Mst_DFU::analy_notify(uint8_t dest_device, uint8_t requester_id, analy_send_message_notify_eu notify_event)
{     
    if (upgrad_insta == NULL || upgrad_insta->states == Mst_DFU::Upgrad_program::state_eu::idle) 
        return;

    if (notify_event == FL_ANALY_ERROR_RETRY_SEND)
    {
        Mst_DFU::error_ending((uint8_t)upgrad_insta->states | Mst_DFU::execute_record_st::upgrad_error_eu::UPGRADE_ERROR_ANALY_DISCONNECT,0, 0, 0);
        return;
    }
    if (requester_id == 6)
    {        
        if (notify_event == FL_ANALY_SEND_MESSAGE_DONE)
        {
            upgrad_insta->analy_send_busy = false;
            Mst_DFU::snd_bin_data(); 
        }
    }
} 

void Mst_DFU::analy_receive(uint8_t src_device, uint8_t* p_data, size_t length, analy_receive_detail_st* detail)
{   
    static char return_str[1024] = { 0 };
    if(upgrad_insta == NULL || upgrad_insta->states ==  Mst_DFU::Upgrad_program::state_eu::idle) 
        return;

    switch (p_data[0])//function(op) code
    {
    case mst_dfu_opc_eu::ANALY_DFU_OPC_READ_INFO :// 
    {
        if (upgrad_insta->states != Mst_DFU::Upgrad_program::state_eu::wait_device_info ||
            length != sizeof(analy_dfu_opc1))
            return;
        BYTE_2_STRUCT(analy_dfu_opc1, upgrad_insta->receive_device_info, p_data);
        upgrad_insta->states = Mst_DFU::Upgrad_program::state_eu::write_device_info_and_erase;
        time_out_reset(); 
    }
    break;
    case mst_dfu_opc_eu::ANALY_DFU_OPC_WRITE_ROM_READY: // 
    {
        if (upgrad_insta->states != Mst_DFU::Upgrad_program::state_eu::wait_standby_write_ROM  ||
            length != sizeof(analy_dfu_opc3))
            return;
        upgrad_insta->states = Mst_DFU::Upgrad_program::state_eu::send_bin_data;

        upgrad_insta->send_addr_end_next = upgrad_insta->write_cache_total_len;
        upgrad_insta->data_next_standby = true;
        Mst_DFU::snd_bin_data(); 
        time_out_reset(); 
    } 
    break;
    case mst_dfu_opc_eu::ANALY_DFU_OPC_RESPONSE_STATE: // 
    {
        if (length != sizeof(analy_dfu_opc5))
            return;

        uint32_t received_length_lit = BYTE_2_U32_LIT(&((analy_dfu_opc5*)p_data)->received_length);
        uint32_t remaining_space_lit = BYTE_2_U32_LIT(&((analy_dfu_opc5*)p_data)->remaining_space);

        if (received_length_lit == upgrad_insta->send_addr_end_current )
        {
        /*    printf("Rx_len:== %d == ||| remaining:== %d ==  \r\n ", received_length_lit, remaining_space_lit);*/
            if (!upgrad_insta->data_next_standby)
            {
                if (received_length_lit < upgrad_insta->file_len)
                {
                    uint32_t  target_write_cache_len = MIN(upgrad_insta->file_len - upgrad_insta->send_addr_end_current, (uint32_t)upgrad_insta->write_cache_total_len);
                    if (remaining_space_lit >= sizeof(analy_dfu_opc6::long_data_head_st_) + target_write_cache_len)
                    {
                        upgrad_insta->send_addr_start_next = upgrad_insta->send_addr_end_current;
                        upgrad_insta->send_addr_end_next = upgrad_insta->send_addr_start_next + target_write_cache_len;
                        upgrad_insta->data_next_standby = true;
                    }
                }
                else
                {
                    upgrad_insta->states = Mst_DFU::Upgrad_program::state_eu::request_verify_flash;
                }
            }
            time_out_reset(); 
        }
        Mst_DFU::snd_bin_data();

        if (upgrad_insta->report_len != received_length_lit)
        {
            memset(return_str, 0, 1024);
            int32_t received_len = MIN((received_length_lit * 100 / upgrad_insta->file_len), 95);
            sprintf(return_str, "-----------write device ROM : %d%%----------- ", received_len);
            user_callback.upgrade_msg_callback(return_str  , received_len);
        }
        upgrad_insta->report_len = received_length_lit;
    }
    break;
    case mst_dfu_opc_eu::ANALY_DFU_OPC_RESPONSE_CRC: // 
    {
        if (upgrad_insta->states != Mst_DFU::Upgrad_program::state_eu::wait_flash_crc_result ||
            length != sizeof(analy_dfu_opc9) ||
            upgrad_insta->receive_crc_finish )
            return;

        BYTE_2_STRUCT(analy_dfu_opc9, upgrad_insta->receive_device_rom_crc, p_data);   
        upgrad_insta->receive_crc32_lit = BYTE_2_U32_LIT(&upgrad_insta->receive_device_rom_crc.crc32_result);
        upgrad_insta->receive_crc_finish = true;
    }
    break;
    case mst_dfu_opc_eu::ANALY_DFU_OPC_JUMP_APP_FINISH:  // 
    {
        if (upgrad_insta->states != Mst_DFU::Upgrad_program::state_eu::wait_ending || length != sizeof(analy_dfu_opc11))
            return;
        memset(return_str, 0, 1024);
        sprintf(return_str, "--------------DFU Done--------------");
        user_callback.upgrade_msg_callback(return_str, 100); 
        Mst_DFU::done_ending();
    }
    break;
    case mst_dfu_opc_eu::ANALY_DFU_OPC_ERROR:   // 
    {
        if (length != sizeof(analy_dfu_opc255))
            return;

        analy_dfu_opc255* p_op255 = (analy_dfu_opc255*)p_data;

        Mst_DFU::error_ending( (uint8_t)upgrad_insta->states,
                                p_op255->error_type,
                                p_op255->error_code,
                                p_op255->error_response );
    }
    break;
    }
    return;
}
void  Mst_DFU::Dfu_setting(void)
{
    if (!upgrad_insta->write_setting_finish)
    {
        analy_dfu_opc4 send_data = { .fun_num = ANALY_DFU_OPC_WRITE_SET,
            .process_num = process_number,
            .ROM_start_addr = 0,
            .ROM_total_len = BYTE_2_U32_LIT(&upgrad_insta->file_len),
            .per_data_len = BYTE_2_U16_LIT(&upgrad_insta->write_cache_per_len),
            .execution_times = 1 };

        if (analy_send_short_message(6, upgrad_insta->self_device, (uint16_t)process_number | 4 << 8, ANALY_SEND_RESPONE, &send_data, sizeof(analy_dfu_opc4)) == ANALY_MESSAGE_SUBMIT_SUCCESS)
            upgrad_insta->write_setting_finish = true;
    }
}


void Mst_DFU::MST_Upgrade_run(struct FunctionParameterDefine* paras)
{
    static char return_str[1024] = { 0 };
    memset(return_str, 0, 1024); 
    switch (upgrad_insta->states)
    {
    case Upgrad_program::state_eu::start:
    {
        analy_dfu_opc0 send_data = { .fun_num = ANALY_DFU_OPC_START,
            .process_num = process_number,
            .device = upgrad_insta->target_device,};

        if (analy_send_short_message(6, upgrad_insta->self_device, (uint16_t)process_number, ANALY_SEND_RESPONE, &send_data, sizeof(analy_dfu_opc0)) == ANALY_MESSAGE_SUBMIT_SUCCESS)
        {        
            upgrad_insta->states = Upgrad_program::state_eu::wait_device_info;
            sprintf(return_str, "--------------DFU Start--------------");
            user_callback.upgrade_msg_callback(return_str, 1);
        }
        Mst_DFU::time_out_execute(2000, Upgrad_program::state_eu::start);
    }
    break;
    case Upgrad_program::state_eu::wait_device_info:
    {
        Mst_DFU::time_out_execute(8000, Upgrad_program::state_eu::wait_device_info);
    }
    break;
    case Upgrad_program::state_eu::write_device_info_and_erase:
    {
        if (!upgrad_insta->info_erase_send_finish)
        {
            analy_dfu_opc2 send_data = { .fun_num = ANALY_DFU_OPC_WRITE_INFO_ERASE,
                .process_num = process_number,
                .erase_start_addr = 0,
                .erase_end_addr = 0,
                .write_info = 'A' << 8 | 'N'};
             
            uint32_t erase_end = (BYTE_2_U32_LIT(&upgrad_insta->receive_device_info.flash_size) & 0x00FFFFFF) - 1; 

            erase_end = BYTE_2_U32_LIT(&erase_end);
            BYTE_2_STRUCT(rom_addr_st, send_data.erase_end_addr, &erase_end);

            if (analy_send_short_message(6, upgrad_insta->self_device, (uint16_t)process_number | 2 << 8, ANALY_SEND_RESPONE, &send_data, sizeof(analy_dfu_opc2)) == ANALY_MESSAGE_SUBMIT_SUCCESS)
                upgrad_insta->info_erase_send_finish = true;

            Dfu_setting();
        }
        if (upgrad_insta->info_erase_send_finish)
        {
            sprintf(return_str, "-----------erase ROM-----------");
            user_callback.upgrade_msg_callback(return_str, 3);
            upgrad_insta->states = Upgrad_program::state_eu::wait_standby_write_ROM;
        }
        Mst_DFU::time_out_execute(2000, Upgrad_program::state_eu::write_device_info_and_erase);
    }
    break;
    case Upgrad_program::state_eu::wait_standby_write_ROM: 
    {
        Mst_DFU::time_out_execute(11000, Upgrad_program::state_eu::wait_standby_write_ROM);
    }
    break;

    case Upgrad_program::state_eu::send_bin_data:
    {
        Mst_DFU::snd_bin_data(); 
        Mst_DFU::time_out_execute(3500, Upgrad_program::state_eu::send_bin_data);
    }
    break;
    case Upgrad_program::state_eu::request_verify_flash:
    {
        uint32_t check_end = upgrad_insta->file_len - 1; 

        analy_dfu_opc8 send_data = { .fun_num = ANALY_DFU_OPC_REQUEST_CRC, 
                   .process_num = process_number,
                   .check_start_addr = 0,
                   .check_end_addr = BYTE_2_U32_LIT(&check_end) }; 

        if (analy_send_short_message(6, upgrad_insta->self_device, (uint16_t)process_number | 8 << 8, ANALY_SEND_RESPONE, &send_data, sizeof(analy_dfu_opc8)) == ANALY_MESSAGE_SUBMIT_SUCCESS)
            upgrad_insta->states = Upgrad_program::state_eu::wait_flash_crc_result;

        Mst_DFU::time_out_execute(1500, Upgrad_program::state_eu::request_verify_flash);
    }
    break; 
    case Upgrad_program::state_eu::wait_flash_crc_result:
    {
        if (!upgrad_insta->bin_file_crc32_finish)
        {
            uint32_t crc32_result = analy_math_crc32(upgrad_insta->p_bin_file, upgrad_insta->file_len, 0);
            upgrad_insta->bin_file_crc32_result = BYTE_2_U32_LIT(&crc32_result);
            upgrad_insta->bin_file_crc32_finish = true;
            sprintf(return_str, "-----------check ROM crc -----------");
            user_callback.upgrade_msg_callback(return_str, 97);
        }

        if (upgrad_insta->receive_crc_finish)
        {
            if (upgrad_insta->bin_file_crc32_result == upgrad_insta->receive_crc32_lit)
                upgrad_insta->states = Mst_DFU::Upgrad_program::state_eu::request_ending;
            else
                Mst_DFU::error_ending((uint8_t)upgrad_insta->states | Mst_DFU::execute_record_st::upgrad_error_eu::UPGRADE_ERROR_BIN_FILE_CEC32_ERROR, 0, 0, 0);
        }
        Mst_DFU::time_out_execute(5000, Upgrad_program::state_eu::wait_flash_crc_result);      
    }
    break;
    case Upgrad_program::state_eu::request_ending:
    {
        analy_dfu_opc10 send_data = { .fun_num = ANALY_DFU_OPC_ENDING,
           .process_num = process_number};

        if (analy_send_short_message(6, upgrad_insta->self_device, (uint16_t)process_number | 9 << 8, ANALY_SEND_RESPONE, &send_data, sizeof(analy_dfu_opc10)) == ANALY_MESSAGE_SUBMIT_SUCCESS)
        {
            upgrad_insta->states = Mst_DFU::Upgrad_program::state_eu::wait_ending;
            sprintf(return_str, "-----------wait jump app-----------");
            user_callback.upgrade_msg_callback(return_str, 99);
        }

        Mst_DFU::time_out_execute(1500, Upgrad_program::state_eu::request_ending);
    }
    break;
    case Upgrad_program::state_eu::wait_ending:
    {
        Mst_DFU::time_out_execute(1500, Upgrad_program::state_eu::wait_ending);
    } 
    break;
    }
};

Mst_DFU::Mst_DFU()
{
    upgrad_insta = NULL;
    analy_register_process_receive(process_number, Mst_DFU::analy_receive);
    analy_register_process_transfer(process_number, Mst_DFU::analy_notify);
}
Mst_DFU::~Mst_DFU()
{
    if(upgrad_insta)
        delete upgrad_insta;
}


/*-------------------------------------Parameter-------------------------------------*/
#define PARA_CHANNEL_NUM 5 
#define USER_PARA_BUF_LEN 208 

#define PARA_CHANNEL_RANGE 3
#define PARA_R_REQUEST 0
#define PARA_R_RESPONSE 1
#define PARA_W_REQUEST 2
#define PARA_W_RESPONSE 3
#define PARA_RESET_REQUEST 24
#define PARA_RESET_RESPONSE 25 

Mst_Para*                   Mst_para_insta; 
Mst_Para::run_states_eu     Mst_Para::run_states;
uint8_t                     Mst_Para::self_device;
Mst_soft_timer              Mst_Para::time_out;
Mst_Para::para_type         Mst_Para::curr_type;
int                         Mst_Para::error_code;

uint32_t                    Mst_Para::package_quan; 
uint16_t                    Mst_Para::total_len;
Mst_Para::para_arg_st       Mst_Para::arg_group[PARA_CHANNEL_NUM];

struct Mst_Para::user_callback_st   Mst_Para::user_callback;
#pragma pack(1)
typedef struct
{
    uint8_t                 fun_num;
    uint8_t                 process_num;

    uint8_t                 over_time : 4;   //1 = 128ms
    uint8_t                 silence_time : 4; //1 = 128ms

    uint8_t                 device_number;
    uint8_t                 bank_index;
    uint16_t                memory_address;
    uint16_t                memory_len;
}analy_para_read_req;

typedef struct
{
    uint8_t                     fun_num;
    uint8_t                     process_num;
    Mst_Para::res_states        states ;
    uint8_t                     device_response;
    uint8_t                     device_number;
    uint8_t                     bank_index;
    uint16_t                    memory_address;
    uint16_t                    memory_len;
    uint8_t                     read_data;
}analy_para_read_res;

typedef struct
{
    uint8_t                 fun_num;
    uint8_t                 process_num;

    uint8_t                 over_time : 4;   //1 = 128ms
    uint8_t                 silence_time : 4; //1 = 128ms

    uint8_t                 device_number;
    uint8_t                 bank_index;
    uint16_t                memory_address;
    uint16_t                memory_len;
    uint8_t                 write_data;
}analy_para_write_req;

typedef struct
{
    uint8_t                     fun_num;
    uint8_t                     process_num;
    Mst_Para::res_states        states;
    uint8_t                     device_response;
    uint8_t                     device_number;
    uint8_t                     bank_index;
    uint16_t                    memory_address;
    uint16_t                    memory_len;
}analy_para_write_res;

typedef struct
{
    uint8_t                 fun_num;
    uint8_t                 process_num;

    uint8_t                 over_time : 4;   //1 = 128ms
    uint8_t                 silence_time : 4; //1 = 128ms

    uint8_t                 device_number;
    uint8_t                 bank_index;

}analy_para_reset_req;

typedef struct
{
    uint8_t                     fun_num;
    uint8_t                     process_num;
    Mst_Para::res_states        states;
    uint8_t                     device_response;
    uint8_t                     device_number;
    uint8_t                     bank_index;
}analy_para_reset_res;

#pragma pack()

ScriptFunction  Mst_Para::get_Mst_para_Script(para_type exe_type) 
{
    if(analy_get_system_states() == 0)
        return NULL; 
    if (exe_type >= PARA_MAX)
        return NULL;

   return Mst_Para::script_run[exe_type];
};

void  Mst_Para::register_user_callback(para_type exe_type, void* user_call_back)
{
    switch (exe_type)
    {
    case Mst_Para::PARA_READ:
    {
        Mst_Para::user_callback.read_result_callback = (fpCallback_ReadParameters)user_call_back; 
    }
    break;
    case Mst_Para::PARA_WRITE:
    {
        Mst_Para::user_callback.write_result_callback = (fpCallback_WriteParameters)user_call_back;
    }
    break;
    case Mst_Para::PARA_RESET:
    {
        Mst_Para::user_callback.reset_result_callback = (fpCallback_ResetParameters)user_call_back; 
    }
    break;
    default:
    {
    }
    break;
    }
};

ActFinally_Callback Mst_Para::get_finally_callback(para_type exe_type)
{
    if (exe_type >= PARA_MAX)
        return NULL;

    return  Mst_Para::act_finally_callback[exe_type];
};
ActError_Callback Mst_Para::get_error_callback(para_type exe_type)
{
    if (exe_type >= PARA_MAX)
        return NULL; 

    return Mst_Para::act_error_callback[exe_type];
};

bool Mst_Para::judge_done_states()
{
    for (uint32_t index = 0; index < Mst_Para::package_quan; ++index)
    {
        if (!Mst_Para::arg_group[index].response_done)
            break;
        else if (index == Mst_Para::package_quan - 1)
            return true;
    }
    return false;
}

void  Mst_Para::done_ending()
{
    Mst_Para::error_code = 0;
    Mst_Para::run_states = Mst_Para::PARA_IDLE; 
    Sdk_script_op::script_op.fp_Script_done();
    switch (Mst_Para::curr_type)
    {
    case PARA_READ:   
        LOG_PUSH(" ------------para read  :[ %d Byte]    Done ------------\n", Mst_Para::total_len);
    break;
    case PARA_WRITE:    
        LOG_PUSH(" ------------para write :[ %d Byte]    Done ------------\n", Mst_Para::total_len);
    break;
    case PARA_RESET:
        LOG_PUSH(" ------------para reset :[ Bank %d ]   Done ------------\n", Mst_Para::arg_group[0].bank_index);
    break;
    }
    LOG_FLUSH; 
}

void  Mst_Para::error_ending(uint8_t para_state, uint8_t type, uint8_t response)
{
    Mst_Para::error_code = response | type << 8 | para_state << 16;
    Mst_Para::run_states = Mst_Para::PARA_IDLE; 
    Sdk_script_op::script_op.fp_Script_done();

    LOG_PUSH( " [state:%d ] [FW:%d ] [response:%d ]\n", para_state, type, response);
    LOG_FLUSH; 
}



void Mst_Para::analy_notify(uint8_t dest_device, uint8_t requester_id, analy_send_message_notify_eu notify_event)
{
    if (run_states == 0)
        return;

    if (notify_event == FL_ANALY_ERROR_RETRY_SEND)
    {
        Mst_Para::error_ending(Mst_Para::self_error::ANALY_DISCONNECT, 0, 0);
    }
}
bool Mst_Para::check_argument(uint16_t  addr, uint16_t len)
{
    for (uint32_t index = 0; index < Mst_Para::package_quan; ++index) 
    { 
        if (Mst_Para::arg_group[index].mem_addr == addr)
            if (Mst_Para::arg_group[index].mem_len = len)
                return true;
    }
    return false;
}

void Mst_Para::analy_receive(uint8_t src_device, uint8_t* p_data, size_t length, analy_receive_detail_st* detail)
{
    if (run_states == Mst_Para::PARA_IDLE) 
        return;

    if (p_data[4] != Mst_Para::arg_group[0].device_number || p_data[5] != Mst_Para::arg_group[0].bank_index)
        return;

    uint32_t  channel_num = p_data[0] >> 2;

    if (p_data[0] < PARA_CHANNEL_NUM << 2)
        p_data[0] &= PARA_CHANNEL_RANGE; 

    switch (p_data[0])//function(op) code
    {
    case PARA_R_RESPONSE:
    {
        if (length < sizeof(analy_para_read_res) - 1)
            return;

        analy_para_read_res* p_res = (analy_para_read_res*)p_data;

        if (p_res->states != Mst_Para::PARA_DONE)
        {
            Mst_Para::error_ending(0, p_res->states, p_res->device_response);
            return;
        }

        if (Mst_Para::check_argument(p_res->memory_address, p_res->memory_len))
        {
            memcpy( Mst_Para::arg_group[0].data_buf +  p_res->memory_address - Mst_Para::arg_group[0].mem_addr, &p_res->read_data, p_res->memory_len);
            Mst_Para::arg_group[channel_num].response_done = true;

            if (Mst_Para::judge_done_states())
            {
                Mst_Para::done_ending(); 
                UpdateDeviceParameter((DeviceObjTypes)Mst_Para::arg_group[0].device_number,
                    Mst_Para::arg_group[0].bank_index,
                    Mst_Para::arg_group[0].mem_addr,
                    Mst_Para::total_len, 
                    Mst_Para::arg_group[0].data_buf);                 
            }
        }
        else
            Mst_Para::error_ending(ANALY_ARG_INCOMPATIBLE, p_res->states, p_res->device_response);
    }
    break;

    break;

    case PARA_W_RESPONSE: //  
    {
        if (length != sizeof(analy_para_write_res))
            return;

        analy_para_write_res* p_res = (analy_para_write_res*)p_data; 

        if (p_res->states != Mst_Para::PARA_DONE)
        {
            Mst_Para::error_ending(0, p_res->states, p_res->device_response);
            return;
        }

        if (Mst_Para::check_argument(p_res->memory_address, p_res->memory_len)) 
        {
            Mst_Para::arg_group[channel_num].response_done = true;

            if (Mst_Para::judge_done_states())
                Mst_Para::done_ending();
        }
        else
            Mst_Para::error_ending(ANALY_ARG_INCOMPATIBLE, p_res->states, p_res->device_response); 
    }
    break;
    case PARA_RESET_RESPONSE:  // 
    {
        if (length != sizeof(analy_para_reset_res)) 
            return;

        analy_para_reset_res* p_res = (analy_para_reset_res*)p_data;

        if (p_res->states == Mst_Para::PARA_DONE)
            Mst_Para::done_ending(); 
        else
            Mst_Para::error_ending(0, p_res->states, p_res->device_response);
    }
    break;
    }
    return;
}
void  Mst_Para::para_run_RW_init(struct FunctionParameterDefine* paras) 
{
    memset(Mst_Para::arg_group, 0, sizeof(Mst_Para::arg_group)); 
    uint8_t device_id = ConverterToFlDeviceId(paras[0].num.uint8_val);
    uint16_t addr = paras[1].num.uint16_val;
    uint16_t leng = paras[2].num.uint16_val;
    uint8_t bank_index = paras[3].num.int8_val;

    Mst_Para::total_len = leng;
    uint32_t para_package_quantity = leng / USER_PARA_BUF_LEN;
    uint32_t last_len = leng % USER_PARA_BUF_LEN;

    if (last_len != 0)
        ++para_package_quantity;

    Mst_Para::package_quan = MIN(para_package_quantity, PARA_CHANNEL_NUM);

    for (uint32_t index = 0; index < Mst_Para::package_quan; ++index)
    {
        Mst_Para::arg_group[index].device_number = device_id;
        Mst_Para::arg_group[index].bank_index = bank_index;
        Mst_Para::arg_group[index].mem_addr = addr + USER_PARA_BUF_LEN * index;
        Mst_Para::arg_group[index].mem_len = index != Mst_Para::package_quan - 1 ? USER_PARA_BUF_LEN : last_len;
    }
    Mst_Para::time_out.soft_timer_reset();
    Mst_Para::run_states = Mst_Para::PARA_REQUEST; 
}


 void para_read_run(struct FunctionParameterDefine* paras)
{
    switch (Mst_Para::run_states)
    {
        case Mst_Para::PARA_IDLE: 
        {
            Mst_Para::para_run_RW_init(paras);  

            Mst_Para::curr_type = Mst_Para::PARA_READ;
        }
        break;

        case Mst_Para::PARA_REQUEST: 
        {
            for (uint32_t index = 0; index < Mst_Para::package_quan; ++index)
            {
                if (!Mst_Para::arg_group[index].request_done)
                    break;
                else if(index == Mst_Para::package_quan - 1) 
                    Mst_Para::run_states = Mst_Para::PARA_WAIT_RES; 
            }
            if (Mst_Para::time_out.soft_timer_1ms(500, Mst_Para::run_states == Mst_Para::PARA_REQUEST)) 
                Mst_Para::error_ending(Mst_Para::self_error::SEND_TIMEOUT , 0, 0);
        }
        break;
        case  Mst_Para::PARA_WAIT_RES:  
        {
            if (Mst_Para::time_out.soft_timer_1ms(2500, Mst_Para::run_states == Mst_Para::PARA_WAIT_RES)) 
                Mst_Para::error_ending(Mst_Para::self_error::RESPOSE_TIMEOUT, 0, 0);
        }
        break;
    }

    if (Mst_Para::run_states != Mst_Para::PARA_REQUEST)
        return;

    analy_para_read_req send_data = {   .fun_num = 0, 
                                        .process_num = Mst_Para::process_number,
                                        .over_time = 8,
                                        .silence_time = 1,
                                        .device_number = Mst_Para::arg_group[0].device_number,
                                        .bank_index = Mst_Para::arg_group[0].bank_index };

    for (uint32_t index = 0; index < Mst_Para::Mst_Para::package_quan; ++index)
    {
        if (Mst_Para::arg_group[index].request_done)
            continue;
       
        send_data.fun_num = PARA_R_REQUEST + (index << 2);
        send_data.memory_address = Mst_Para::arg_group[index].mem_addr ;
        send_data.memory_len = Mst_Para::arg_group[index].mem_len;

        if (analy_send_short_message(6, Mst_Para::self_device, Mst_Para::process_number, ANALY_SEND_RESPONE, &send_data, sizeof(analy_para_read_req)) == ANALY_MESSAGE_SUBMIT_SUCCESS)
            Mst_Para::arg_group[index].request_done = true;
    }
};
void para_read_finally(struct FunctionParameterDefine* paras)
{
    Mst_Para::user_callback.read_result_callback(Mst_Para::error_code, (SDKDeviceType_e)(Mst_Para::arg_group[0].device_number + 1),
        Mst_Para::arg_group[0].data_buf, Mst_Para::arg_group[0].mem_addr,
        Mst_Para::total_len, Mst_Para::arg_group[0].bank_index);
};
void para_read_error(struct FunctionParameterDefine* action_param, uint32_t  error_code)
{ 
    struct FunctionParameterDefine para_define = {};
    para_read_finally(&para_define);
};

void para_write_run(struct FunctionParameterDefine* paras)
{
    switch (Mst_Para::run_states)
    {
    case Mst_Para::PARA_IDLE: 
    {
        Mst_Para::para_run_RW_init(paras);

        for (uint32_t index = 0, data_offset = 0; index < Mst_Para::package_quan; ++index)
        {
            memcpy(Mst_Para::arg_group[0].data_buf + data_offset, paras[4].buff + data_offset, Mst_Para::arg_group[index].mem_len); 
            data_offset += Mst_Para::arg_group[index].mem_len; 
        }

        Mst_Para::curr_type = Mst_Para::PARA_WRITE; 
    }
    break;
    case Mst_Para::PARA_REQUEST: 
    {
        for (uint32_t index = 0; index < Mst_Para::package_quan; ++index)
        {
            if (!Mst_Para::arg_group[index].request_done)
                break;
            else if (index == Mst_Para::package_quan - 1)
                Mst_Para::run_states = Mst_Para::PARA_WAIT_RES; 
        }
        if (Mst_Para::time_out.soft_timer_1ms(500, Mst_Para::run_states == Mst_Para::PARA_REQUEST)) 
            Mst_Para::error_ending(Mst_Para::self_error::SEND_TIMEOUT, 0, 0);
    }
    break;
    case Mst_Para::PARA_WAIT_RES:  
    {
        if (Mst_Para::time_out.soft_timer_1ms(2500, Mst_Para::run_states == Mst_Para::PARA_WAIT_RES)) 
            Mst_Para::error_ending(Mst_Para::self_error::RESPOSE_TIMEOUT, 0, 0);
    }
    break;
    }

    if (Mst_Para::run_states != Mst_Para::PARA_REQUEST) 
        return;

    uint8_t  send_buf[Mst_Para::MAX_DATA_BUF_LEN + sizeof(analy_para_write_req) - 1] = { 0 }; 
     
    analy_para_write_req* p_send_data = (analy_para_write_req*)send_buf;

    p_send_data->process_num = Mst_Para::process_number;
    p_send_data->over_time = 8;
    p_send_data->silence_time = 1;
    p_send_data->device_number = Mst_Para::arg_group[0].device_number;
    p_send_data->bank_index = Mst_Para::arg_group[0].bank_index;

    for (uint32_t index = 0; index < Mst_Para::Mst_Para::package_quan; ++index)
    {
        if (Mst_Para::arg_group[index].request_done)
            continue;

        p_send_data->fun_num = PARA_W_REQUEST + (index << 2);
        p_send_data->memory_address = Mst_Para::arg_group[index].mem_addr;
        p_send_data->memory_len = Mst_Para::arg_group[index].mem_len;
         
        memcpy(&p_send_data->write_data,
            Mst_Para::arg_group[0].data_buf + Mst_Para::arg_group[index].mem_addr - Mst_Para::arg_group[0].mem_addr,
            Mst_Para::arg_group[index].mem_len);

        if (analy_send_short_message(6, Mst_Para::self_device, Mst_Para::process_number, ANALY_SEND_RESPONE, p_send_data,
                        sizeof(analy_para_write_req) -1 + Mst_Para::total_len) == ANALY_MESSAGE_SUBMIT_SUCCESS)
            Mst_Para::arg_group[index].request_done = true;
    }
};
void para_write_finally(struct FunctionParameterDefine* paras)
{
    Mst_Para::user_callback.write_result_callback(Mst_Para::error_code, (SDKDeviceType_e)(Mst_Para::arg_group[0].device_number + 1),
         Mst_Para::arg_group[0].mem_addr,
        Mst_Para::total_len, Mst_Para::arg_group[0].bank_index);
};
void para_write_error(struct FunctionParameterDefine* action_param, uint32_t  error_code)
{
    struct FunctionParameterDefine para_define = {};
    para_write_finally(&para_define);
};

void para_reset_run(struct FunctionParameterDefine* paras)
{
    switch (Mst_Para::run_states)
    {
    case Mst_Para::PARA_IDLE:
    {
        memset(Mst_Para::arg_group, 0, sizeof(Mst_Para::arg_group));

        Mst_Para::arg_group[0].device_number = ConverterToFlDeviceId(paras[0].num.uint8_val);
        Mst_Para::arg_group[0].bank_index = paras[1].num.int8_val;

        Mst_Para::time_out.soft_timer_reset();
        Mst_Para::run_states = Mst_Para::PARA_REQUEST;
        Mst_Para::curr_type = Mst_Para::PARA_RESET; 
    }
    break;
    case Mst_Para::PARA_REQUEST:
    {
        if (Mst_Para::arg_group[0].request_done)
            Mst_Para::run_states = Mst_Para::PARA_WAIT_RES;
      
        if (Mst_Para::time_out.soft_timer_1ms(500, Mst_Para::run_states == Mst_Para::PARA_REQUEST))
            Mst_Para::error_ending(Mst_Para::self_error::SEND_TIMEOUT, 0, 0);
    }
    break;
    case Mst_Para::PARA_WAIT_RES:
    {
        if (Mst_Para::time_out.soft_timer_1ms(2500, Mst_Para::run_states == Mst_Para::PARA_WAIT_RES))
            Mst_Para::error_ending(Mst_Para::self_error::RESPOSE_TIMEOUT, 0, 0); 
    }
    break;
    }

    if (Mst_Para::run_states != Mst_Para::PARA_REQUEST)
        return;

    analy_para_reset_req send_data = { .fun_num = PARA_RESET_REQUEST,
                                        .process_num = Mst_Para::process_number,
                                        .over_time = 0xF,
                                        .silence_time = 0xF,
                                        .device_number = Mst_Para::arg_group[0].device_number,
                                        .bank_index = Mst_Para::arg_group[0].bank_index };

    if (analy_send_short_message(6, Mst_Para::self_device, Mst_Para::process_number, ANALY_SEND_RESPONE, &send_data, sizeof(analy_para_reset_req)) == ANALY_MESSAGE_SUBMIT_SUCCESS)
        Mst_Para::arg_group[0].request_done = true; 
};
void para_reset_finally(struct FunctionParameterDefine* paras)
{
    Mst_Para::user_callback.reset_result_callback(Mst_Para::error_code, (SDKDeviceType_e)(Mst_Para::arg_group[0].device_number + 1),
         Mst_Para::arg_group[0].bank_index);
};
void para_reset_error(struct FunctionParameterDefine* action_param, uint32_t  error_code)
{
    struct FunctionParameterDefine para_define = {};
    para_reset_finally(&para_define);
};

ScriptFunction          Mst_Para::script_run[PARA_MAX] = { para_read_run , para_write_run , para_reset_run };
ActFinally_Callback     Mst_Para::act_finally_callback[PARA_MAX] = { para_read_finally , para_write_finally , para_reset_finally }; 
ActError_Callback       Mst_Para::act_error_callback[PARA_MAX] = { para_read_error , para_write_error , para_reset_error };

Mst_Para::Mst_Para()
{
    analy_register_process_receive(process_number, Mst_Para::analy_receive);
    analy_register_process_transfer(process_number, Mst_Para::analy_notify);
    Mst_Para::self_device = 1;
}
Mst_Para::~Mst_Para()
{
}

/*------*/

void Mst_sdk_run_program()
{
    if (analy_get_system_states() == 0)
        return;

    update_analy_tick();

    if(internal_usb_clear())
        fl_loop_fifo_free(&user_can_bus_fifo, user_can_bus_fifo.full_len);

    Mst_can_bus_st user_can_bus_data;
    if (GET_FIFO_COUNT(&user_can_bus_fifo))
    {
        fl_loop_fifo_get(&user_can_bus_fifo, &user_can_bus_data, sizeof(Mst_can_bus_st));
        analy_send_short_message(CAN_BUS_DEVICE_ID, user_can_bus_data.self_id, 0, ANALY_SEND_RESPONE, &user_can_bus_data.send_data, user_can_bus_data.send_data.length + 4);
    }

    for (int i1 = 0; i1 < DRV_INTERFACE_COUNT; ++i1)
    {
        if (observer_group[i1] != NULL)
            analy_observer_runtime(observer_group[i1]);
    }

    for (int i2 = 0; i2 < DATA_TRANSFER_COUNT; ++i2)
    {
        if (transfer_group[i2] != NULL) 
            analy_transfer_runtime(transfer_group[i2]);
    }
     
    if (SOFT_INTERFACE_USE == 1)
    {
        static size_t send_len_rem[DATA_TRANSFER_COUNT] = { 0 };

        for (int i3 = 0; i3 < DRV_INTERFACE_COUNT; ++i3)
        {
            if (soft_interface_out_notify[i3] == NULL)
                continue;
            if (observer_group[i3] == NULL)
                continue;

            send_len_rem[i3] = observer_group[i3]->p_observer_interface->p_tx_fifo->current_len;

            if (send_len_rem[i3] > 0)
                soft_interface_out_notify[i3](send_len_rem[i3]);
        }
    }        
}

uint32_t Mst_init(MstSdkConfig_T configuration) 
{ 
    analy_framework_init();

    Sdk_script_op Sdk_script_inst({ ActionScriptRespondWait, AS_FL_ActionScriptResume, ActionScriptDone });

    analy_register_device_receive(CAN_BUS_DEVICE_ID, user_analyzer_can_receive);
    analy_register_device_transfer(CAN_BUS_DEVICE_ID, user_analyzer_can_notify);

    if(configuration.dfuEnable)
        Mst_dfu_insta = new Mst_DFU();
    if (configuration.paraEnable)
        Mst_para_insta = new Mst_Para(); 
  
    return 0;
}




