
#include <string>

#include "CoreSDK.h"
#include "FL_CanProtocol.h"
#include "UnixTime.h"
#include "ActionScript.h"


#include "lib_event_scheduler.h"
#include "FL_Device_HMI.h"

#include "FL_CANInfoStruct.h"
#include "lib_fifo_buff.h"

#include <iostream>
#include <chrono>
#include <thread>
#include <ctime>

#ifdef _WIN32
#include <windows.h>
#else
#include <unistd.h>
#endif // _WIN32

using namespace std;
using namespace std::chrono;
using namespace std::this_thread;


#define SDK_Version_Str "b.0.20"


typedef struct CANPacket_st
{
    uint32_t can_id;
    bool is_extender_id;
    uint8_t data[64];
    uint8_t leng;
} CANPacket_T;

void parse_loop(void);
void timer_1ms_tick(void);


struct CoreSDKStatus_st
{
    CoreSDKInst_T Inst;
    uint8_t param_mem[4096];
};


static CANPacket_T can_rx_queue_buff[4096] = {};
static LIB_FIFO_INST_T can_rx_queue = {};

static CANPacket_T can_tx_queue_buff[4096] = {};
static LIB_FIFO_INST_T can_tx_queue = {};

thread* parse_thread_p;
thread* timer_thread_p;
bool is_thread_dispose = false;
static bool SDK_BeInit = false;

struct CoreSDKStatus_st sdk;

DeviceInformation_T DeviceInfoInst;
ISOTP_INST_T CoreSDK_ISOTP;
ISOTP_INST_T FL_HMI_ISOTP;
LIB_EVENT_SCHED_INST_T sched_inst;


int __stdcall CANBusPacket_IN(unsigned int can_id, bool is_extender_id, unsigned char* raw_data, unsigned int leng)
{
    CANPacket_T raw = {0};
    uint8_t index = 0;

    if (!SDK_BeInit)
    {
        return SDK_RETURN_NO_INIT;
    }

    if (can_id > 0 && raw_data != NULL)
    {
        raw.can_id = can_id;
        raw.is_extender_id = is_extender_id;
        raw.leng = leng;

        if (is_extender_id)
        {
            LogD("CAN[RX] ExtID:0x%05x Leng:%d Data[", can_id, leng);
        }
        else
        {
            LogD("CAN[RX] StdID:0x%03x Leng:%d Data[", can_id, leng);
        }
        

        for ( index=0;index < leng;index++)
        {
            raw.data[index] = raw_data[index];
            LogD("0x%02x ", raw_data[index]);
        }
        LogD("]\n");

        lib_fifo_write(&can_rx_queue, &raw);

        return SDK_RETURN_SUCCESS;
    }
    else
    {
        return SDK_RETURN_INVALID_PARAM;
    }
}

int __stdcall CANBusPacket_OUT(unsigned int* can_id, bool* is_extender_id, unsigned char* data, unsigned int* leng)
{
    CANPacket_T TxPacket = { 0 };
    unsigned int copy_index;

    if (lib_fifo_length(&can_tx_queue) != 0)
    {
        lib_fifo_read(&can_tx_queue, &TxPacket);

        *can_id = TxPacket.can_id;
        *is_extender_id = TxPacket.is_extender_id;
        *leng = TxPacket.leng;

        for (copy_index = 0; copy_index < TxPacket.leng; copy_index++)
        {
            data[copy_index] = TxPacket.data[copy_index];
        }

        return SDK_RETURN_SUCCESS;
    }

    return SDK_RETURN_NULL;
}


int __stdcall BLECommandPacket_IN(unsigned char* data, unsigned int leng)
{
    uint8_t frame_size, frame_index, target_device, response_code;
    uint16_t opc;

    if (leng >= 4)
    {
        unsigned char* pload = &data[6];
        frame_size = data[0];
        frame_index = data[1];
        opc = data[2] + (uint16_t)(data[3] << 8);
        target_device = data[4];
        response_code = data[5];

        if (opc == FL_BLE_OPC_CAN_PASS_DATA_RES)
        {
            LogD("BLE[RX]->");
        }
        else
        {
            LogD("BLE[RX] %d-%d OPC:%d Target:%d Res:%d Data[", frame_size, frame_index, opc, target_device, response_code);

            for (uint8_t index = 6; index < leng; index++)
            {
                LogD("0x%02x ", data[index]);
            }
            LogD("]\n");
        }

        
        
        switch (opc)
        {
        case FL_BLE_OPC_CAN_LISTEN_ID_RES:

            break;

        case FL_BLE_OPC_CAN_PASS_DATA_RES:
            if (leng >= 8)
            {
                uint32_t can_id = pload[0] + ((uint32_t)pload[1] << 8) + ((uint32_t)pload[2] << 16) + ((uint32_t)pload[3] << 24);
                bool is_extender = (can_id & 0x80000000) != 0 ? true : false;
                uint32_t pleng = leng - 10;

                can_id &= 0x7fffffff;
                CANBusPacket_IN(can_id, is_extender, &pload[4], pleng);
            }
            
            break;

        case FL_BLE_OPC_PARAM_READ_RES:
            AS_FL_BLE_ReadParam_GetRespond(target_device, opc, response_code, pload, (leng - 6));
            break;

        case FL_BLE_OPC_PARAM_WRITE_RES:
            AS_FL_BLE_WriteParam_GetRespond(target_device, opc, response_code, pload, (leng - 6));
            break;

        case FL_BLE_OPC_PARAM_RESET_RES:
            AS_FL_BLE_ResetParam_GetRespond(target_device, opc, response_code, pload, (leng - 6));
            break;


        case FL_BLE_OPC_DFU_READ_DEV_INFO_RES:
        case FL_BLE_OPC_DFU_WRITE_DEV_INFO_RES:
        case FL_BLE_OPC_DFU_WRITE_DATA_FLASH_RES:
        case FL_BLE_OPC_DFU_VERIFY_FLASH_RES:
        case FL_BLE_OPC_DFU_JUMP_COMMOND_RES:
            AS_FL_BLEUpgradeFirmware_GetRespond(target_device, opc, response_code, pload, (leng - 6));

            break;



        case FL_BLE_OPC_LOG_READ_RES:
            AS_FL_BLE_ReadDeviceLogs_GetRespond(target_device, opc, response_code, pload, (leng - 6));
            break;

        case FL_BLE_OPC_LOG_CLEAR_RES:
            AS_FL_BLE_ClearDeviceLogs_GetRespond(target_device, opc, response_code, pload, (leng - 6));
            break;
        }

        return SDK_RETURN_SUCCESS;
    }
    else
    {
        return SDK_RETURN_INVALID_SIZE;
    }
}

int __stdcall BLECommandPacket_OUT(unsigned char* data, unsigned int* leng)
{
    static uint8_t ble_common_buff[256] = { 0 };
    uint16_t ble_common_leng = 0;
    uint16_t copy_index = 0;

    if (AS_FL_GetBLECommon_TxQueue(ble_common_buff, sizeof(ble_common_buff), &ble_common_leng) == SDK_RETURN_SUCCESS)
    {
        for (copy_index = 0 ; copy_index < ble_common_leng ; copy_index++)
        {
            data[copy_index] = ble_common_buff[copy_index];
        }

        uint16_t opc = data[2] | ((uint16_t)data[2] << 8);

        if (opc == FL_BLE_OPC_CAN_PASS_DATA_REQ)
        {
            uint32_t can_id = data[6] + ((uint32_t)data[7] << 8) + ((uint32_t)data[8] << 16) + ((uint32_t)data[9] << 24);
            bool is_extender = (can_id & 0x80000000) != 0 ? true : false;
            uint8_t packet_leng = ble_common_leng - 10;
            can_id &= 0x7FFFFFFF;
            if (is_extender)
            {
                LogD("BLE[TX]->CAN[TX] ExtID:0x%05x Leng:%d Data[", can_id, packet_leng);
            }
            else
            {
                LogD("BLE[TX]->CAN[TX] StdID:0x%03x Leng:%d Data[", can_id, packet_leng);
            }

            for (uint8_t index = 10; index < ble_common_leng; index++)
            {
                LogD("0x%02x ", data[index]);
            }
            LogD("]\n");
        }
        else
        {
            uint8_t frame_size = data[0];
            uint8_t frame_index = data[1];
            uint16_t opc = data[2] + ((uint16_t)data[3] << 8);
            uint8_t target = data[4];
            uint8_t resp = data[5];

            LogD("BLE[TX] %d-%d OPC:%d Target:%d Res:%d Data[", frame_size, frame_index, opc, target, resp);

            if (ble_common_leng > 20)
            {
                LogD("\n");
            }

            for (uint8_t index = 6; index < ble_common_leng; index++)
            {
                LogD("0x%02x ", data[index]);

                if ((index-6)%20 == 0 && index > 6)
                {
                    LogD("\n");
                }
            }
            LogD("]\n");
        }
        

        
        *leng = ble_common_leng;
        return SDK_RETURN_SUCCESS;
    }
    else
    {
        return SDK_RETURN_NULL;
    }
    
}

int __stdcall BLEDataPacket_IN(unsigned char* data, unsigned int leng)
{
    return SDK_RETURN_SUCCESS;
}

int __stdcall BLEDataPacket_OUT(unsigned char* data, unsigned int* leng)
{
    static uint8_t ble_common_buff[256] = { 0 };
    uint16_t ble_common_leng = 0;
    uint16_t copy_index = 0;

    if (AS_FL_GetBLEData_TxQueue(ble_common_buff, sizeof(ble_common_buff), &ble_common_leng) == SDK_RETURN_SUCCESS)
    {
        uint8_t frame_size = ble_common_buff[0];
        uint8_t frame_index = ble_common_buff[1];
        uint16_t opc = ble_common_buff[2] + ((uint16_t)ble_common_buff[3] << 8);
        uint8_t target = ble_common_buff[4];
        uint8_t resp = ble_common_buff[5];

        LogD("BLE[TX] %d-%d OPC:%d Target:%d Res:%d With-out Respose Data[\n", frame_size, frame_index, opc, target, resp);
             

        for (copy_index = 0; copy_index < ble_common_leng; copy_index++)
        {
            data[copy_index] = ble_common_buff[copy_index];

            LogD("0x%02x ", data[(copy_index+6)]);

            if ((copy_index % 20) == 0 && copy_index > 0)
            {
                LogD("\n");
            }
        }

        LogD("]\n");

        *leng = ble_common_leng;
        return SDK_RETURN_SUCCESS;
    }
    else
    {
        return SDK_RETURN_NULL;
    }
}



int SendToCANBUS(unsigned int can_id, bool is_extender_id, unsigned char* raw_data, unsigned int leng)
{
    CANPacket_T can_packet = {};
    uint8_t index = 0;

    can_packet.can_id = can_id;
    can_packet.is_extender_id = is_extender_id;
    can_packet.leng = leng;

    for ( index=0;index<leng;index++)
    {
        can_packet.data[index] = raw_data[index];
    }

    lib_fifo_write(&can_tx_queue, &can_packet);

    return 0;
}

int __stdcall Enable(void)
{
    if (!SDK_BeInit)
    {
        return SDK_RETURN_NO_INIT;
    }

    CoreSDK_ISOTP.send_packet = SendToCANBUS;

    ISOTP_Init(&CoreSDK_ISOTP);

    LogD("SDK Thread Enable\n");


    is_thread_dispose = false;
    parse_thread_p = new thread(parse_loop);
    parse_thread_p->detach();

    timer_thread_p = new thread(timer_1ms_tick);
    timer_thread_p->detach();

    return SDK_RETURN_SUCCESS;
}



int __stdcall Disable(void)
{
    if (!SDK_BeInit)
    {
        return SDK_RETURN_NO_INIT;
    }

    LogD("SDK Thread Disable\n");
    if (parse_thread_p)
    {
        is_thread_dispose = true;
    }

    return SDK_RETURN_SUCCESS;
}


void parse_loop(void)
{
    uint32_t do_nothing_cnt = 0;
    CANPacket_T read_packet = {0};

    while (is_thread_dispose == false)
    {
        ActionScriptRun();

        
        if (lib_fifo_length(&can_rx_queue) > 0)
        {
            lib_fifo_read(&can_rx_queue, &read_packet);

        }
        else
        {
            read_packet = { };
        }

        ISOTP_Process(&CoreSDK_ISOTP,
            read_packet.can_id,
            read_packet.is_extender_id,
            read_packet.data,
            read_packet.leng);
        /*
        ISOTP_Process(&FL_HMI_ISOTP,
            read_packet.can_id,
            read_packet.is_extender_id,
            read_packet.data,
            read_packet.leng);
        */

        if (FL_CAN_TryPaser(read_packet.can_id,
            read_packet.is_extender_id,
            read_packet.data,
            read_packet.leng) == SDK_RETURN_SUCCESS)
        {
            if (sdk.Inst.InfoUpdateEvent)
            {
                sdk.Inst.InfoUpdateEvent(DeviceInfoInst);
            }
        }
        else
        {
            /*
            FL_HMI_CAN_TryPaser(read_packet.can_id,
                read_packet.is_extender_id,
                read_packet.data,
                read_packet.leng);
                */
        }


        /*
        if (lib_fifo_length(&can_rx_queue) > 0 && read_packet.leng != 0)
        {
            can_rx_queue.pop();
        }
        */

        lib_event_sched_run();
    }

    LogD("SDK Thread Exit\n");
}

void timer_1ms_tick(void)
{
    while (is_thread_dispose == false)
    {
#ifdef _WIN32
        Sleep(1);
#else
        usleep(1000);
#endif // _WIN32

        ISOTP_timer_1ms_tick(&CoreSDK_ISOTP);
        ISOTP_timer_1ms_tick(&FL_HMI_ISOTP);
        
        ActionScript_timer_1ms_tick();
        lib_event_sched_1ms_timer_callback();
    }
}

void GetActionParam(struct FunctionParameterDefine* param, void* val)
{
    switch (param->type)
    {
    
    case PARA_TYPE_UINT64:
    {
         *(uint64_t*)val = param->num.uint64_val;
    }
    break;

    case PARA_TYPE_INT64:
    {
         *(int64_t*)val = param->num.int64_val;
    }
    break;
    
    case PARA_TYPE_UINT32:
    {
        *(uint32_t*)val = param->num.uint32_val;
    }
    break;

    case PARA_TYPE_INT32:
    {
        *(int32_t*)val = param->num.int32_val;
    }
    break;

    case PARA_TYPE_UINT16:
    {
        *(uint16_t*)val = param->num.uint16_val;
    }
    break;

    case PARA_TYPE_INT16:
    {
        *(int16_t*)val = param->num.int16_val;
    }
    break;

    case PARA_TYPE_UINT8:
    {
        *(uint8_t*)val = param->num.uint8_val;
    }
    break;

    case PARA_TYPE_INT8:
    {
        *(int8_t*)val = param->num.int8_val ;
    }
    break;

    case PARA_TYPE_BYTE_ARRAY:
    {
        val = param->buff;
    }
    break;

    case PARA_TYPE_FLOAT:
    {
        *(float*)val = param->num.float_val;
    }
    break;

    case PARA_TYPE_DEVICE_TYPE:
    {
        *(uint8_t*)val = param->num.uint8_val;
    }
    break;

    }
}

void SetActionParam(struct FunctionParameterDefine * param, enum ParameterTypeDefine type, void* val)
{
    param->type = type;

    switch (type)
    {
    case PARA_TYPE_UINT64:
    {
        param->num.uint64_val = *(uint64_t*)val;
    }
    break;

    case PARA_TYPE_INT64:
    {
        param->num.int64_val = *(int64_t*)val;
    }
    break;

    case PARA_TYPE_UINT32:
    {
        param->num.uint32_val = *(uint32_t*)val;
    }
    break;

    case PARA_TYPE_INT32:
    {
        param->num.int32_val = *(int32_t*)val;
    }
    break;

    case PARA_TYPE_UINT16:
    {
        param->num.uint16_val = *(uint16_t*)val;
    }
    break;

    case PARA_TYPE_INT16:
    {
        param->num.int16_val = *(int16_t*)val;
    }
    break;

    case PARA_TYPE_UINT8:
    {
        param->num.uint8_val = *(uint8_t*)val;
    }
    break;

    case PARA_TYPE_INT8:
    {
        param->num.int8_val = *(int8_t*)val;
    }
    break;

    case PARA_TYPE_BYTE_ARRAY:
    {
        param->buff = (uint8_t*)val;
    }
    break;

    case PARA_TYPE_FLOAT:
    {
        param->num.float_val = *(float*)val;
    }
    break;

    case PARA_TYPE_DEVICE_TYPE:
    {
        param->num.uint8_val = *(uint8_t*)val;
    }
    break;

    }


    
}


/*
    Delegate Method : Read Paramter
*/

static fpCallback_ReadParameters ReadParameters_callback = NULL;

void ReadParameter_Finally(struct FunctionParameterDefine* action_param)
{
    if (ReadParameters_callback)
    {
        uint64_t temp_val;
        uint32_t addr;
        uint16_t leng;
        uint8_t bank_index, device;

        GetActionParam(&action_param[0], &temp_val);
        device = (uint8_t)temp_val;
        GetActionParam(&action_param[1], &temp_val);
        addr = (uint32_t)temp_val;
        GetActionParam(&action_param[2], &temp_val);
        leng = (uint16_t)temp_val;
        GetActionParam(&action_param[3], &temp_val);
        bank_index = (uint8_t)temp_val;
        FL_CAN_ReadParameter((SDKDeviceType_e)device, bank_index, addr, leng, sdk.param_mem);
        ReadParameters_callback(SDK_RETURN_SUCCESS, (SDKDeviceType_e)device, sdk.param_mem, addr, leng, bank_index);
    }
}


void ReadParameter_Error(uint32_t err_code)
{
    if (ReadParameters_callback)
    {
        /*
        uint32_t addr;
        uint16_t leng;
        uint8_t bank_index, device;
        
        GetActionParam(&action_param[0], &device);
        GetActionParam(&action_param[1], &addr);
        GetActionParam(&action_param[2], &leng);
        GetActionParam(&action_param[3], &bank_index);
        
        ReadParameters_callback(err_code, (SDKDeviceType_e)device, sdk.param_mem, addr, leng, bank_index);
        */
    }
}


int __stdcall ReadParameters(RouterType router, 
    SDKDeviceType_e target_device,
    unsigned short addr,
    unsigned short leng, 
    unsigned char bank_index,
    fpCallback_ReadParameters callback)
{
    ACTION_DEFINE_T new_action = {};

    SetActionParam(&new_action.paras[0], PARA_TYPE_DEVICE_TYPE, &target_device);
    SetActionParam(&new_action.paras[1], PARA_TYPE_UINT16, &addr);
    SetActionParam(&new_action.paras[2], PARA_TYPE_UINT16, &leng);
    SetActionParam(&new_action.paras[3], PARA_TYPE_UINT8, &bank_index);
    ReadParameters_callback = callback;

    switch (router)
    {
    case SDK_ROUTER_CANBUS:
        new_action.run_script = AS_FL_CANBus_ReadParameter;
        break;

    default:
        new_action.run_script = AS_FL_BLE_ReadParameter;
        break;
    }

    
    new_action.finally_callback = ReadParameter_Finally;
    new_action.error_callback = ReadParameter_Error;
    ActionScriptCreate(new_action);

    return SDK_RETURN_SUCCESS;
}

/*
    Delegate Method : Read Paramter
*/

static fpCallback_WriteParameters WriteParameters_callback = NULL;

void WriteParameter_Finally(struct FunctionParameterDefine* action_param)
{
    if (WriteParameters_callback)
    {
        WriteParameters_callback(SDK_RETURN_SUCCESS);
    }
}


void WriteParameter_Error(uint32_t err_code)
{
    if (WriteParameters_callback)
    {
        WriteParameters_callback(err_code);
    }
}


int __stdcall WriteParameters(RouterType router, 
    SDKDeviceType_e target_device,
    unsigned short addr,
    unsigned short leng,
    unsigned char bank_index,
    unsigned char * data,
    fpCallback_WriteParameters callback)
{
    ACTION_DEFINE_T new_action = {};

    SetActionParam(&new_action.paras[0], PARA_TYPE_DEVICE_TYPE, &target_device);
    SetActionParam(&new_action.paras[1], PARA_TYPE_UINT16, &addr);
    SetActionParam(&new_action.paras[2], PARA_TYPE_UINT16, &leng);
    SetActionParam(&new_action.paras[3], PARA_TYPE_UINT8, &bank_index);
    SetActionParam(&new_action.paras[4], PARA_TYPE_BYTE_ARRAY, data);
    WriteParameters_callback = callback;


    switch (router)
    {
    case SDK_ROUTER_CANBUS:
        new_action.run_script = AS_FL_CANBus_WriteParameter;
        break;

    default:
        new_action.run_script = AS_FL_BLE_WriteParameter;
        break;
    }

    new_action.finally_callback = WriteParameter_Finally;
    new_action.error_callback = WriteParameter_Error;
    ActionScriptCreate(new_action);

    return SDK_RETURN_SUCCESS;
}



/*
    Delegate Method : ResetParameters
*/



static fpCallback_ResetParameters ResetParameters_callback = NULL;

void ResetParameters_Finally(struct FunctionParameterDefine* action_param)
{
    if (ResetParameters_callback)
    {
        ResetParameters_callback(SDK_RETURN_SUCCESS);
    }
}


void ResetParameters_Error(uint32_t err_code)
{
    if (ResetParameters_callback)
    {
        ResetParameters_callback(err_code);
    }
}


int __stdcall ResetParameters(RouterType router,
    SDKDeviceType_e target_device,
    unsigned char bank_index,
    fpCallback_ResetParameters callback)
{
    ACTION_DEFINE_T new_action = { };

    SetActionParam(&new_action.paras[0], PARA_TYPE_DEVICE_TYPE, &target_device);
    SetActionParam(&new_action.paras[1], PARA_TYPE_UINT8, &bank_index);
    WriteParameters_callback = callback;


    switch (router)
    {
    case SDK_ROUTER_CANBUS:
        //new_action.run_script = AS_FL_CANBus_ResetParameter;
        break;

    default:
        new_action.run_script = AS_FL_BLE_ResetParameter;
        break;
    }

    new_action.finally_callback = ResetParameters_Finally;
    new_action.error_callback = ResetParameters_Error;
    ActionScriptCreate(new_action);

    return SDK_RETURN_SUCCESS;
}



/*
    Delegate Method : UpgradeFirmwareSetting
*/

static fpCallback_UpgradeFirmware UpgradeFirmware_callback = NULL;

void UpgradeFirmware_Finally(struct FunctionParameterDefine* action_param)
{
    if (UpgradeFirmware_callback)
    {
        UpgradeFirmware_callback(SDK_RETURN_SUCCESS);
    }
}

void UpgradeFirmware_Error(uint32_t err_code)
{
    if (UpgradeFirmware_callback)
    {
        UpgradeFirmware_callback(err_code);
    }
}

int __stdcall UpgradeFirmware(RouterType router,
    SDKDeviceType_e target_device,
    unsigned char* device_MID,
    unsigned char* data,
    unsigned int data_size,
    UpgradeStateMsg_p upgrade_msg_callback,
    fpCallback_UpgradeFirmware callback)
{
    ACTION_DEFINE_T new_action = { };

    AS_FL_UpgradeStateMsgBinding(upgrade_msg_callback);
    if (AS_FL_UpgradeSetting(target_device, device_MID, data, data_size) == false)
    {
        return SDK_RETURN_INVALID_PARAM;
    }
    UpgradeFirmware_callback = callback;
    
    if (router == SDK_ROUTER_BLE)
    {
        new_action.run_script = AS_FL_BLEUpgradeFirmware;
    }
    else
    {
        new_action.run_script = AS_FL_CANBusUpgradeFirmware;
    }    
    new_action.finally_callback = UpgradeFirmware_Finally;
    new_action.error_callback = UpgradeFirmware_Error;
    ActionScriptCreate(new_action);

    return SDK_RETURN_SUCCESS;
}


/*
    Delegate Method : Debug mode config
*/

static fpCallback_SetDebugMode SetDebugMode_callback = NULL;

void SetDebugMode_Finally(struct FunctionParameterDefine* action_param)
{
    if (SetDebugMode_callback)
    {
        SetDebugMode_callback(SDK_RETURN_SUCCESS);
    }
}


void SetDebugMode_Error(uint32_t err_code)
{
    if (SetDebugMode_callback)
    {
        SetDebugMode_callback(err_code);
    }
}


int __stdcall SetDebugMode(RouterType router, 
    SDKDeviceType_e target_device,
    unsigned char mode,
    unsigned char repet_cnt,
    unsigned short interval_time,
    fpCallback_SetDebugMode callback)
{
    ACTION_DEFINE_T new_action = {};

    SetActionParam(&new_action.paras[0], PARA_TYPE_DEVICE_TYPE, &target_device);
    SetActionParam(&new_action.paras[1], PARA_TYPE_UINT8, &mode);
    SetActionParam(&new_action.paras[2], PARA_TYPE_UINT8, &repet_cnt);
    SetActionParam(&new_action.paras[3], PARA_TYPE_UINT16, &interval_time);
    SetDebugMode_callback = callback;


    switch (router)
    {
    case SDK_ROUTER_CANBUS:
        new_action.run_script = AS_FL_CANBus_SetDebugMode;
        break;

    default:
        new_action.run_script = AS_FL_BLE_SetDebugMode;
        break;
    }
    
    new_action.finally_callback = SetDebugMode_Finally;
    new_action.error_callback = SetDebugMode_Error;
    ActionScriptCreate(new_action);

    return SDK_RETURN_SUCCESS;
}


/*
    Delegate Method : Test mode config
*/

static fpCallback_SetTestMode SetTestMode_callback = NULL;

void SetTestMode_Finally(struct FunctionParameterDefine* action_param)
{
    if (SetTestMode_callback)
    {
        SetTestMode_callback(SDK_RETURN_SUCCESS);
    }
}


void SetTestMode_Error(uint32_t err_code)
{
    if (SetTestMode_callback)
    {
        SetTestMode_callback(err_code);
    }
}

int __stdcall SetTestMode(RouterType router, 
    SDKDeviceType_e target_device,
    unsigned char mode,
    unsigned int value,
    fpCallback_SetTestMode callback)
{
    ACTION_DEFINE_T new_action = { };

    SetActionParam(&new_action.paras[0], PARA_TYPE_DEVICE_TYPE, &target_device);
    SetActionParam(&new_action.paras[1], PARA_TYPE_UINT8, &mode);
    SetActionParam(&new_action.paras[2], PARA_TYPE_UINT32, &value);
    SetTestMode_callback = callback;


    switch (router)
    {
    case SDK_ROUTER_CANBUS:
        new_action.run_script = AS_FL_CANBus_SetTestMode;
        break;

    default:
        new_action.run_script = AS_FL_BLE_SetTestMode;
        break;
    }

    new_action.finally_callback = SetTestMode_Finally;
    new_action.error_callback = SetTestMode_Error;
    ActionScriptCreate(new_action);

    return SDK_RETURN_SUCCESS;
}


/*
    Delegate Method : Get CAN Bypass List
*/

static fpCallback_GetCanIdBypassList GetCanIdBypassList_callback = NULL;

void GetCanIdBypassList_Finally(struct FunctionParameterDefine* action_param)
{
    if (GetCanIdBypassList_callback)
    {
        struct CANBypass_IdList id_list;
        AS_FL_BLE_Copy_CanIdBytpassList(&id_list);
        GetCanIdBypassList_callback(SDK_RETURN_SUCCESS, id_list.mode, id_list.count, &id_list.list->Bytes[0]);
    }
}


void GetCanIdBypassList_Error(uint32_t err_code)
{
    if (GetCanIdBypassList_callback)
    {
        GetCanIdBypassList_callback(err_code, 0, 0, NULL);
    }
}

int __stdcall GetCanIdBypassList(RouterType router,
    fpCallback_GetCanIdBypassList callback)
{
    ACTION_DEFINE_T new_action = {};

    GetCanIdBypassList_callback = callback;

    switch (router)
    {
    case SDK_ROUTER_CANBUS:
        return SDK_RETURN_INVALID_PARAM;
        break;

    default:
        new_action.run_script = AS_FL_BLE_GetCanIdBypassList;
        break;
    }

    new_action.finally_callback = GetCanIdBypassList_Finally;
    new_action.error_callback = GetCanIdBypassList_Error;
    ActionScriptCreate(new_action);

    return SDK_RETURN_SUCCESS;
}


/*
    Delegate Method : Set CAN Bypass mode allow list value
*/

static fpCallback_SetCanIdBypassAllowList SetCanIdBypassAllowList_callback = NULL;

void SetCanIdBypassAllowList_Finally(struct FunctionParameterDefine* action_param)
{
    if (SetCanIdBypassAllowList_callback)
    {
        SetCanIdBypassAllowList_callback(SDK_RETURN_SUCCESS);
    }
}


void SetCanIdBypassAllowList_Error(uint32_t err_code)
{
    if (SetCanIdBypassAllowList_callback)
    {
        SetCanIdBypassAllowList_callback(err_code);
    }
}

int __stdcall SetCanIdBypassAllowList(RouterType router,
    unsigned char function_code,
    unsigned char id_list_count,
    unsigned char *id_list_data,
    fpCallback_SetCanIdBypassAllowList callback)
{
    ACTION_DEFINE_T new_action = {};

    SetActionParam(&new_action.paras[0], PARA_TYPE_UINT8, &function_code);
    SetActionParam(&new_action.paras[1], PARA_TYPE_UINT8, &id_list_count);
    SetActionParam(&new_action.paras[2], PARA_TYPE_BYTE_ARRAY, id_list_data);
    SetCanIdBypassAllowList_callback = callback;


    switch (router)
    {
    case SDK_ROUTER_CANBUS:
        return SDK_RETURN_INVALID_PARAM;
        break;

    default:
        new_action.run_script = AS_FL_BLE_SetCanIdBypassAllowList;
        break;
    }

    new_action.finally_callback = SetCanIdBypassAllowList_Finally;
    new_action.error_callback = SetCanIdBypassAllowList_Error;
    ActionScriptCreate(new_action);

    return SDK_RETURN_SUCCESS;
}



/*
    Delegate Method : Set CAN Bypass mode Block List value
*/

static fpCallback_SetCanIdBypassBlockList SetCanIdBypassBlockList_callback = NULL;

void SetCanIdBypassBlockList_Finally(struct FunctionParameterDefine* action_param)
{
    if (SetCanIdBypassBlockList_callback)
    {
        SetCanIdBypassBlockList_callback(SDK_RETURN_SUCCESS);
    }
}


void SetCanIdBypassBlockList_Error(uint32_t err_code)
{
    if (SetCanIdBypassBlockList_callback)
    {
        SetCanIdBypassBlockList_callback(err_code);
    }
}

int __stdcall SetCanIdBypassBlockList(RouterType router,
    unsigned char function_code,
    unsigned char id_list_count,
    unsigned char* id_list_data,
    fpCallback_SetCanIdBypassBlockList callback)
{
    ACTION_DEFINE_T new_action = { };

    SetActionParam(&new_action.paras[0], PARA_TYPE_UINT8, &function_code);
    SetActionParam(&new_action.paras[1], PARA_TYPE_UINT8, &id_list_count);
    SetActionParam(&new_action.paras[2], PARA_TYPE_BYTE_ARRAY, id_list_data);
    SetCanIdBypassBlockList_callback = callback;


    switch (router)
    {
    case SDK_ROUTER_CANBUS:
        return SDK_RETURN_INVALID_PARAM;
        break;

    default:
        new_action.run_script = AS_FL_BLE_SetCanIdBypassBlockList;
        break;
    }

    new_action.finally_callback = SetCanIdBypassBlockList_Finally;
    new_action.error_callback = SetCanIdBypassBlockList_Error;
    ActionScriptCreate(new_action);

    return SDK_RETURN_SUCCESS;
}





/*
    Delegate Method : Re-Start Device
*/

static fpCallback_RestartDevice RestartDevice_callback = NULL;

void RestartDevice_Finally(struct FunctionParameterDefine* action_param)
{
    if (RestartDevice_callback)
    {
        RestartDevice_callback(SDK_RETURN_SUCCESS);
    }
}


void RestartDevice_Error(uint32_t err_code)
{
    if (RestartDevice_callback)
    {
        RestartDevice_callback(err_code);
    }
}

int __stdcall RestartDevice(RouterType router,
    SDKDeviceType_e target_device,
    fpCallback_RestartDevice callback)
{
    ACTION_DEFINE_T new_action = { };

    SetActionParam(&new_action.paras[0], PARA_TYPE_DEVICE_TYPE, &target_device);
    RestartDevice_callback = callback;


    switch (router)
    {
    case SDK_ROUTER_CANBUS:
        return SDK_RETURN_INVALID_PARAM;
        break;

    default:
        new_action.run_script = AS_FL_BLE_RestartDevice;
        break;
    }

    new_action.finally_callback = RestartDevice_Finally;
    new_action.error_callback = RestartDevice_Error;
    ActionScriptCreate(new_action);

    return SDK_RETURN_SUCCESS;
}



/*
    Delegate Method : Read Device Logs
*/

static fpCallback_ReadDeviceLogs ReadDeviceLogs_callback = NULL;

void ReadDeviceLogs_Finally(struct FunctionParameterDefine* action_param)
{
    if (ReadDeviceLogs_callback)
    {
        DeviceLogs_T* logs_list = 0;
        uint32_t log_count = 0;
        SDKDeviceType_e device;
        GetActionParam(&action_param[0], &device);
        
        log_count = AS_FL_GetDeviceLogs_Inst(logs_list);

        ReadDeviceLogs_callback(SDK_RETURN_SUCCESS, device, logs_list, log_count);
    }
}


void ReadDeviceLogs_Error(uint32_t err_code)
{
    if (ReadDeviceLogs_callback)
    {
        //ReadDeviceLogs_callback(err_code);
    }
}

int __stdcall ReadDeviceLogs(RouterType router,
    SDKDeviceType_e target_device,
    fpCallback_ReadDeviceLogs callback)
{
    ACTION_DEFINE_T new_action = {};

    SetActionParam(&new_action.paras[0], PARA_TYPE_DEVICE_TYPE, &target_device);
    ReadDeviceLogs_callback = callback;


    switch (router)
    {
    case SDK_ROUTER_CANBUS:
        return SDK_RETURN_INVALID_PARAM;
        break;

    default:
        new_action.run_script = AS_FL_BLE_ReadDeviceLogs;
        break;
    }

    new_action.finally_callback = ReadDeviceLogs_Finally;
    new_action.error_callback = ReadDeviceLogs_Error;
    ActionScriptCreate(new_action);

    return SDK_RETURN_SUCCESS;
}



/*
    Delegate Method : Clear Device Logs
*/

static fpCallback_ClearDeviceLogs ClearDeviceLogs_callback = NULL;

void ClearDeviceLogs_Finally(struct FunctionParameterDefine* action_param)
{
    if (ClearDeviceLogs_callback)
    {
        ClearDeviceLogs_callback(SDK_RETURN_SUCCESS);
    }
}


void ClearDeviceLogs_Error(uint32_t err_code)
{
    if (ClearDeviceLogs_callback)
    {
        ClearDeviceLogs_callback(err_code);
    }
}

int __stdcall ClearDeviceLogs(RouterType router,
    SDKDeviceType_e target_device,
    fpCallback_ClearDeviceLogs callback)
{
    ACTION_DEFINE_T new_action = { };

    SetActionParam(&new_action.paras[0], PARA_TYPE_DEVICE_TYPE, &target_device);
    ClearDeviceLogs_callback = callback;


    switch (router)
    {
    case SDK_ROUTER_CANBUS:
        return SDK_RETURN_INVALID_PARAM;
        break;

    default:
        new_action.run_script = AS_FL_BLE_ClearDeviceLogs;
        break;
    }

    new_action.finally_callback = ClearDeviceLogs_Finally;
    new_action.error_callback = ClearDeviceLogs_Error;
    ActionScriptCreate(new_action);

    return SDK_RETURN_SUCCESS;
}



/*
    Delegate Method : Config E-Bike System Time
*/

static fpCallback_ConfigSysTime ConfigSysTime_callback = NULL;

void ConfigSysTime_Finally(struct FunctionParameterDefine* action_param)
{
    if (ConfigSysTime_callback)
    {
        ConfigSysTime_callback(SDK_RETURN_SUCCESS);
    }
}


void ConfigSysTime_Error(uint32_t err_code)
{
    if (ConfigSysTime_callback)
    {
        ConfigSysTime_callback(err_code);
    }
}

int __stdcall ConfigSysTime(RouterType router,
    SDKDeviceType_e target_device,
    uint64_t unix_time, fpCallback_ConfigSysTime callback)
{
    ACTION_DEFINE_T new_action = {};

    SetActionParam(&new_action.paras[0], PARA_TYPE_DEVICE_TYPE, &target_device);
    SetActionParam(&new_action.paras[1], PARA_TYPE_UINT64, &unix_time);
    ConfigSysTime_callback = callback;


    switch (router)
    {
    case SDK_ROUTER_CANBUS:
        return SDK_RETURN_INVALID_PARAM;
        break;

    default:
        new_action.run_script = AS_FL_BLE_ConfigSysTime;
        break;
    }

    new_action.finally_callback = ConfigSysTime_Finally;
    new_action.error_callback = ConfigSysTime_Error;
    ActionScriptCreate(new_action);

    return SDK_RETURN_SUCCESS;
}


/*
    Init Method : Init CoreSDK
*/


int FarmLandCoreSDK_Init(CoreSDKInst_T* SDK_Inst)
{
    if (SDK_Inst)
    {
        ActionScriptInit();

        can_rx_queue.buffer_size = 4096;
        can_rx_queue.buffer = (char*)&can_rx_queue_buff;
        can_rx_queue.is_full = false;
        can_rx_queue.item_size = sizeof(CANPacket_T);

        can_tx_queue.buffer_size = 4096;
        can_tx_queue.buffer = (char*)&can_tx_queue_buff;
        can_tx_queue.is_full = false;
        can_tx_queue.item_size = sizeof(CANPacket_T);

        SDK_Inst->Enable = Enable;
        SDK_Inst->Disable = Disable;
        
        SDK_Inst->DelegateMethod.ReadParameters = ReadParameters;
        SDK_Inst->DelegateMethod.WriteParameters = WriteParameters;
        SDK_Inst->DelegateMethod.ResetParameters = ResetParameters;
        SDK_Inst->DelegateMethod.UpgradeFirmware = UpgradeFirmware;
        SDK_Inst->DelegateMethod.SetDebugMode = SetDebugMode;
        SDK_Inst->DelegateMethod.SetTestMode = SetTestMode;
        SDK_Inst->DelegateMethod.SetCanIdBypassAllowList = SetCanIdBypassAllowList;
        SDK_Inst->DelegateMethod.SetCanIdBypassBlockList = SetCanIdBypassBlockList;
        SDK_Inst->DelegateMethod.RestartDevice = RestartDevice;
        SDK_Inst->DelegateMethod.ReadDeviceLogs = ReadDeviceLogs;
        SDK_Inst->DelegateMethod.ClearDeviceLogs = ClearDeviceLogs;
        SDK_Inst->DelegateMethod.ConfigSysTime = ConfigSysTime;

        SDK_Inst->Method.CANBusPacket_IN = CANBusPacket_IN;
        SDK_Inst->Method.CANBusPacket_OUT = CANBusPacket_OUT;
        SDK_Inst->Method.BLECommandPacket_IN = BLECommandPacket_IN;
        SDK_Inst->Method.BLECommandPacket_OUT = BLECommandPacket_OUT;
        SDK_Inst->Method.BLEDataPacket_IN = BLEDataPacket_IN;
        SDK_Inst->Method.BLEDataPacket_OUT = BLEDataPacket_OUT;

        SDK_Inst->ParametersArray[0] = 0x12;

        memcpy(SDK_Inst->Version, SDK_Version_Str, sizeof(SDK_Version_Str));

        DeviceInfoInst = { 0 };

        FL_CAN_Init(&DeviceInfoInst, SendToCANBUS, &CoreSDK_ISOTP);

        memcpy(&sdk.Inst, SDK_Inst, sizeof(CoreSDKInst_T));
        
        lib_event_sched_init(&sched_inst);

        FL_device_HML_Init(&FL_HMI_ISOTP, SendToCANBUS);

        SDK_BeInit = true;

        return SDK_RETURN_SUCCESS;
    }
    else
    {
        SDK_BeInit = false;

        return SDK_RETURN_NULL;
    }
}

