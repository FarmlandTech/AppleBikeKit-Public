
#include <string>

#include "CoreSDK.h"
#include "FL_CanProtocol.h"
#include "UnixTime.h"
#include "ActionScript.h"


#include "lib_event_scheduler.h"
#include "FL_Device_HMI.h"

#include "FL_CANInfoStruct.h"
#include "lib_fifo_buff.h"
#include "FL_MstSdk.h"

#include <iostream>
#include <chrono>
#include <thread>
#include <ctime>

#include "LogPrinter.h"

#ifdef _WIN32
#include <windows.h>
#else
#include <unistd.h>
#endif // _WIN32

using namespace std;
using namespace std::chrono;
using namespace std::this_thread;

// SDK 版本號
#define SDK_Version_Str "1.2.0"

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

// CAN Bus封包輸入處理函式
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
        // Can ID
        raw.can_id = can_id;
        // 是否為拓展型ID定義
        raw.is_extender_id = is_extender_id;
        // 封包長度
        raw.leng = leng;

        if (is_extender_id)
        {
            LOG_PUSH("CAN[RX] ExtID:0x%05x Leng:%d Data[", can_id, leng);
        }
        else
        {
            LOG_PUSH("CAN[RX] StdID:0x%03x Leng:%d Data[", can_id, leng);
        }
        
        // 複製封包內容
        for ( index=0;index < leng;index++)
        {
            raw.data[index] = raw_data[index];
            LOG_PUSH("0x%02x ", raw_data[index]);
        }
        LOG_PUSH("]\n");
        LOG_FLUSH;
        // 寫入FIFO
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
            LOG_PUSH("BLE[RX]->");
        }
        else
        {
            LOG_PUSH("BLE[RX] %d-%d OPC:%d Target:%d Res:%d Data[", frame_size, frame_index, opc, target_device, response_code);
            for (uint8_t index = 6; index < leng; index++)
            {
                LOG_PUSH("0x%02x ", data[index]);
            }
            LOG_PUSH("]\n");

            LOG_FLUSH;
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
                LOG_PUSH("BLE[TX]->CAN[TX] ExtID:0x%05x Leng:%d Data[", can_id, packet_leng);
            }
            else
            {
                LOG_PUSH("BLE[TX]->CAN[TX] StdID:0x%03x Leng:%d Data[", can_id, packet_leng);
            }


            for (uint8_t index = 10; index < ble_common_leng; index++)
            {
                LOG_PUSH("0x%02x ", data[index]);
            }
            
            LOG_PUSH("]\n");
            LOG_FLUSH;
        }
        else
        {
            uint8_t frame_size = data[0];
            uint8_t frame_index = data[1];
            uint16_t opc = data[2] + ((uint16_t)data[3] << 8);
            uint8_t target = data[4];
            uint8_t resp = data[5];

            LOG_PUSH("BLE[TX] %d-%d OPC:%d Target:%d Res:%d Data[", frame_size, frame_index, opc, target, resp);

            if (ble_common_leng > 20)
            {
                LOG_PUSH("\n");
            }

            for (uint8_t index = 6; index < ble_common_leng; index++)
            {
                LOG_PUSH("0x%02x ", data[index]);

                if ((index-6)%20 == 0 && index > 6)
                {
                    LOG_PUSH("\n");
                }
            }
            LOG_PUSH("]\n");

            LOG_FLUSH;
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

        LOG_PUSH("BLE[TX] %d-%d OPC:%d Target:%d Res:%d With-out Respose Data[", frame_size, frame_index, opc, target, resp);
             

        for (copy_index = 0; copy_index < ble_common_leng; copy_index++)
        {
            data[copy_index] = ble_common_buff[copy_index];

            LOG_PUSH("0x%02x ", data[(copy_index+6)]);

            if ((copy_index % 20) == 0 && copy_index > 0)
            {
                LOG_PUSH("\n");
            }
        }

        LOG_PUSH("]\n");
        LOG_FLUSH;

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

// 啟用CoreSDK執行緒
int __stdcall Enable(void)
{
    // 判斷是否已執行初始化
    if (!SDK_BeInit)
    {
        // 尚未初始化 回傳錯誤代碼
        return SDK_RETURN_NO_INIT;
    }
    // ISO TP 發送封包程式重新定義
    CoreSDK_ISOTP.send_packet = SendToCANBUS;
    // ISO TP 相關程式初始化參數
    ISOTP_Init(&CoreSDK_ISOTP);

    LOG_PUSH("SDK Thread Enable\n");
    LOG_FLUSH;
    // 執行緒狀態轉為執行中
    is_thread_dispose = false;
    // 啟用執行緒 => parse_loop
    parse_thread_p = new thread(parse_loop);
    // 背景執行
    parse_thread_p->detach();
    // 啟用執行緒 => timer_1ms_tick
    timer_thread_p = new thread(timer_1ms_tick);
    // 背景執行
    timer_thread_p->detach();

    return SDK_RETURN_SUCCESS;
}


// 禁用CoreSDK執行緒
int __stdcall Disable(void)
{
    // 判斷是否已執行初始化
    if (!SDK_BeInit)
    {
        // 尚未初始化 回傳錯誤代碼
        return SDK_RETURN_NO_INIT;
    }

    LOG_PUSH("SDK Thread Disable\n");
    LOG_FLUSH;

    // 檢查執行緒是否存在
    if (parse_thread_p)
    {
        // 翻轉執行緒狀態, 讓執行緒自行中止
        is_thread_dispose = true;
    }

    return SDK_RETURN_SUCCESS;
}


void parse_loop(void)
{
    uint32_t do_nothing_cnt = 0;
    CANPacket_T read_packet = {0};
    // 檢查是否需要中止執行緒旗標
    while (is_thread_dispose == false)
    {
        // 委派用腳本運行
        ActionScriptRun();
        // 檢查CAN RX是否有待處理資料        
        if (lib_fifo_length(&can_rx_queue) > 0)
        {
            // 讀取FIFO內容 並複製到暫存區塊
            lib_fifo_read(&can_rx_queue, &read_packet);
        }
        else
        {
            // 清空暫存區塊
            read_packet = { };
        }
        // ISO TP解析程式
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
        // 嘗試使用農田CAN-Bus通訊協議解析暫存資料
        if (FL_CAN_TryPaser(read_packet.can_id,
            read_packet.is_extender_id,
            read_packet.data,
            read_packet.leng) == SDK_RETURN_SUCCESS)
        {
            if (sdk.Inst.InfoUpdateEvent)
            {
                // 通知狀態更新
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
        // 排程器執行
        lib_event_sched_run();
        //MST 執行期
        Mst_sdk_run_program();
        // 執行緒休眠
#ifdef _WIN32
        Sleep(0);
#else
        usleep(sdk.Inst.ThreadSleepInterval_us);
#endif // _WIN32
    }

    LOG_PUSH("SDK Thread Exit\n");
    LOG_FLUSH;
}

// 1 ms 計時器
// 所有與時間相關函式的基礎
void timer_1ms_tick(void)
{
    while (is_thread_dispose == false)
    {
#ifdef _WIN32
        // _WIN32
        static clock_t now = clock();
        now = clock();

        while (now >= clock())
        {
            Sleep(0);
        }
#else
        usleep(1000);
#endif 
        // ISO TP 計時
        ISOTP_timer_1ms_tick(&CoreSDK_ISOTP);
        ISOTP_timer_1ms_tick(&FL_HMI_ISOTP);
        // 委派計時
        ActionScript_timer_1ms_tick();
        // 排程器計時
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
        uint8_t  device_id = action_param[0].num.uint8_val;
        uint16_t addr = action_param[1].num.uint16_val;
        uint16_t leng = action_param[2].num.uint16_val;
        uint8_t  bank_index = action_param[3].num.uint8_val;

        FL_CAN_ReadParameter((SDKDeviceType_e)device_id, bank_index, addr, leng, sdk.param_mem);
        // 委派成功, 回傳讀取到的參數值
        ReadParameters_callback(SDK_RETURN_SUCCESS, (SDKDeviceType_e)device_id, sdk.param_mem, addr, leng, bank_index);
    }
}


void ReadParameter_Error(struct FunctionParameterDefine* action_param, uint32_t err_code)
{
    if (ReadParameters_callback)
    {  
        uint8_t  device_id = action_param[0].num.uint8_val;
        uint16_t addr = action_param[1].num.uint16_val; 
        uint16_t leng = action_param[2].num.uint16_val; 
        uint8_t  bank_index = action_param[3].num.uint8_val; 

        ReadParameters_callback(err_code, (SDKDeviceType_e)device_id, NULL, addr, leng, bank_index);
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
    // 參數[0]:目標裝置
    SetActionParam(&new_action.paras[0], PARA_TYPE_DEVICE_TYPE, &target_device);
    // 參數[1]:位址
    SetActionParam(&new_action.paras[1], PARA_TYPE_UINT16, &addr);
    // 參數[2]:長度
    SetActionParam(&new_action.paras[2], PARA_TYPE_UINT16, &leng);
    // 參數[3]:區塊索引
    SetActionParam(&new_action.paras[3], PARA_TYPE_UINT8, &bank_index);
    // 儲存執行完畢後回呼指標
    ReadParameters_callback = callback;
    // 判斷是發送BLE封包或是CAN-Bus封包
    switch (router)
    {
    case SDK_ROUTER_CANBUS:
    {
        // 指定腳本運行的功能名稱
        new_action.run_script = AS_FL_CANBus_ReadParameter;
        // 指定Action Script完成時的回呼指標
        new_action.finally_callback = ReadParameter_Finally;
        // 指定Action Script錯誤時的回呼指標
        new_action.error_callback = ReadParameter_Error;
    }
    break;
    case SDK_ROUTER_BLE: 
    {
        // 指定腳本運行的功能名稱
        new_action.run_script = AS_FL_BLE_ReadParameter;
        // 指定Action Script完成時的回呼指標
        new_action.finally_callback = ReadParameter_Finally;
        // 指定Action Script錯誤時的回呼指標
        new_action.error_callback = ReadParameter_Error;
    }
    break;
    case   SDK_ROUTER_MST_USB: 
    { 
        if (Mst_para_insta != NULL) 
        {
            new_action.run_script = Mst_para_insta->get_Mst_para_Script(Mst_Para::PARA_READ); 
            Mst_para_insta->register_user_callback(Mst_Para::PARA_READ, (void*)callback); 
            new_action.finally_callback = Mst_para_insta->get_finally_callback(Mst_Para::PARA_READ); 
            new_action.error_callback = Mst_para_insta->get_error_callback(Mst_Para::PARA_READ); 
        }
        else
            return SDK_RETURN_NULL; 
    }
    break;
    default:
        return SDK_RETURN_NULL;
    break;
    }

    // 將新Action推送至等待處理的腳本中
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
        uint8_t device_id = action_param[0].num.uint8_val;
        uint16_t addr = action_param[1].num.uint16_val;
        uint16_t leng = action_param[2].num.uint16_val;
        uint8_t bank_index = action_param[3].num.int8_val;
        WriteParameters_callback(SDK_RETURN_SUCCESS, (SDKDeviceType_e)device_id, addr, leng, bank_index);
    }
}


void WriteParameter_Error(struct FunctionParameterDefine* action_param, uint32_t err_code)
{
    if (WriteParameters_callback)
    {
        uint8_t device_id = action_param[0].num.uint8_val;
        uint16_t addr = action_param[1].num.uint16_val;
        uint16_t leng = action_param[2].num.uint16_val;
        uint8_t bank_index = action_param[3].num.int8_val;
        WriteParameters_callback(err_code, (SDKDeviceType_e)device_id, addr, leng, bank_index);
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
    // 參數[0]:目標裝置
    SetActionParam(&new_action.paras[0], PARA_TYPE_DEVICE_TYPE, &target_device);
    // 參數[1]:位址
    SetActionParam(&new_action.paras[1], PARA_TYPE_UINT16, &addr);
    // 參數[2]:長度
    SetActionParam(&new_action.paras[2], PARA_TYPE_UINT16, &leng);
    // 參數[3]:區塊索引
    SetActionParam(&new_action.paras[3], PARA_TYPE_UINT8, &bank_index);
    // 參數[4]:寫入資料區塊指針
    SetActionParam(&new_action.paras[4], PARA_TYPE_BYTE_ARRAY, data);
    // 儲存執行完畢後回呼指標
    WriteParameters_callback = callback;

    // 判斷是發送BLE封包或是CAN-Bus封包
    switch (router)
    {
    case SDK_ROUTER_CANBUS:
    {
        // 指定腳本運行的功能名稱
        new_action.run_script = AS_FL_CANBus_WriteParameter;
        new_action.finally_callback = WriteParameter_Finally;
        new_action.error_callback = WriteParameter_Error;
    }
        break;
    case SDK_ROUTER_BLE: 
    {
        new_action.run_script = AS_FL_BLE_WriteParameter;
        new_action.finally_callback = WriteParameter_Finally; 
        new_action.error_callback = WriteParameter_Error; 
    }
    break;
    case   SDK_ROUTER_MST_USB:    
    {
        if (Mst_para_insta != NULL)  
        {
            new_action.run_script = Mst_para_insta->get_Mst_para_Script(Mst_Para::PARA_WRITE); 
            Mst_para_insta->register_user_callback(Mst_Para::PARA_WRITE, (void*)callback); 
            new_action.finally_callback = Mst_para_insta->get_finally_callback(Mst_Para::PARA_WRITE);  
            new_action.error_callback = Mst_para_insta->get_error_callback(Mst_Para::PARA_WRITE);  
        }
        else
            return SDK_RETURN_NULL; 
    }
    break;
    default:
        // 指定腳本運行的功能名稱
        return SDK_RETURN_NULL;
        break;
    }

    // 將新Action推送至等待處理的腳本中
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
        uint8_t device_id = action_param[0].num.uint8_val;
        uint8_t bank_index = action_param[1].num.int8_val;
        ResetParameters_callback(SDK_RETURN_SUCCESS, (SDKDeviceType_e)device_id, bank_index);
    }
}


void ResetParameters_Error(struct FunctionParameterDefine* action_param, uint32_t err_code)
{
    if (ResetParameters_callback)
    { 
        uint8_t device_id = action_param[0].num.uint8_val; 
        uint8_t bank_index = action_param[1].num.int8_val; 
        ResetParameters_callback(err_code, (SDKDeviceType_e)device_id, bank_index);
    }
}


int __stdcall ResetParameters(RouterType router,
    SDKDeviceType_e target_device,
    unsigned char bank_index,
    fpCallback_ResetParameters callback)
{
    ACTION_DEFINE_T new_action = { };
    // 參數[0]:功能碼
    SetActionParam(&new_action.paras[0], PARA_TYPE_DEVICE_TYPE, &target_device);
    // 參數[1]:ID清單長度
    SetActionParam(&new_action.paras[1], PARA_TYPE_UINT8, &bank_index);
    // 儲存執行完畢後回呼指標
    ResetParameters_callback = callback;
    // 判斷發送封包路由類型
    switch (router)
    {
    case SDK_ROUTER_CANBUS:
        // 指定腳本運行的功能名稱
        //new_action.run_script = AS_FL_CANBus_ResetParameter;
        break;
    case SDK_ROUTER_BLE:
    {
        new_action.run_script = AS_FL_BLE_ResetParameter;
        new_action.finally_callback = ResetParameters_Finally;
        new_action.error_callback = ResetParameters_Error;
    }
    break;
    case  SDK_ROUTER_MST_USB:  
    {
        if (Mst_para_insta != NULL) 
        {
            new_action.run_script = Mst_para_insta->get_Mst_para_Script(Mst_Para::PARA_RESET);
            Mst_para_insta->register_user_callback(Mst_Para::PARA_RESET, (void*)callback);
            new_action.finally_callback = Mst_para_insta->get_finally_callback(Mst_Para::PARA_RESET);
            new_action.error_callback = Mst_para_insta->get_error_callback(Mst_Para::PARA_RESET);
        }
        else
            return SDK_RETURN_NULL;
    }
    break;
    default:
        return SDK_RETURN_NULL; 
        break;
    }

    // 將新Action推送至等待處理的腳本中
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

void UpgradeFirmware_Error(struct FunctionParameterDefine* action_param, uint32_t err_code)
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
    // 綁定狀態更新回呼
    AS_FL_UpgradeStateMsgBinding(upgrade_msg_callback);
    // 檢查並設置更新參數
    if (AS_FL_UpgradeSetting(target_device, device_MID, data, data_size) == false)
    {
        // 參數內容異常回傳錯誤碼
        return SDK_RETURN_INVALID_PARAM;
    }
    // 儲存執行完畢後回呼指標
    UpgradeFirmware_callback = callback;
    // 判斷發送封包路由類型
    if (router == SDK_ROUTER_BLE)
    {
        // 指定腳本運行的功能名稱
        new_action.run_script = AS_FL_BLEUpgradeFirmware;
    }
    else
    {
        // 指定腳本運行的功能名稱
        new_action.run_script = AS_FL_CANBusUpgradeFirmware;
    }

    switch (router)
    {
    case SDK_ROUTER_CANBUS:
    {
        new_action.run_script = AS_FL_CANBusUpgradeFirmware;
        new_action.finally_callback = UpgradeFirmware_Finally; 
        new_action.error_callback = UpgradeFirmware_Error; 
    }
    break;
    case SDK_ROUTER_BLE:
    {
        new_action.run_script = AS_FL_BLEUpgradeFirmware;
        new_action.finally_callback = UpgradeFirmware_Finally;
        new_action.error_callback = UpgradeFirmware_Error;
    }
    case SDK_ROUTER_MST_USB:
    {
        if (Mst_dfu_insta == NULL)
            return SDK_RETURN_NULL;

        ScriptFunction fp_temp = Mst_dfu_insta->get_Mst_Upgrad_FW_Script((uint8_t)target_device - 1, data, data_size);
        if (fp_temp == NULL)
            return SDK_RETURN_NULL;
        new_action.run_script = fp_temp;

        Mst_dfu_insta->register_user_callback(callback, upgrade_msg_callback);
        new_action.finally_callback = Mst_DFU::MST_Upgrade_script_finally_callback;
        new_action.error_callback = Mst_DFU::MST_Upgrade_script_error_callback;  
    }
    break;
    default:
        return SDK_RETURN_NULL;
    break;
    }

    // 將新Action推送至等待處理的腳本中
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


void SetDebugMode_Error(struct FunctionParameterDefine* action_param, uint32_t err_code)
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
    // 參數[0]:目標裝置
    SetActionParam(&new_action.paras[0], PARA_TYPE_DEVICE_TYPE, &target_device);
    // 參數[0]:模式
    SetActionParam(&new_action.paras[1], PARA_TYPE_UINT8, &mode);
    // 參數[0]:重複次數
    SetActionParam(&new_action.paras[2], PARA_TYPE_UINT8, &repet_cnt);
    // 參數[0]:重複發送間隔
    SetActionParam(&new_action.paras[3], PARA_TYPE_UINT16, &interval_time);
    // 參數[4]:CAN BUS路徑
    uint8_t   path = router == SDK_ROUTER_MST_USB ? MST_PATH_USB : MST_PATH_NULL; 
    SetActionParam(&new_action.paras[4], PARA_TYPE_UINT8, &path);
    // 儲存執行完畢後回呼指標
    SetDebugMode_callback = callback;
    // 判斷發送封包路由類型
    switch (router)
    {
    case SDK_ROUTER_CANBUS:
        // 指定腳本運行的功能名稱
        new_action.run_script = AS_FL_CANBus_SetDebugMode;
        break;

    default:
        // 指定腳本運行的功能名稱
        new_action.run_script = AS_FL_BLE_SetDebugMode;
        break;
    }
    // 指定Action Script完成時的回呼指標
    new_action.finally_callback = SetDebugMode_Finally;
    // 指定Action Script錯誤時的回呼指標
    new_action.error_callback = SetDebugMode_Error;
    // 將新Action推送至等待處理的腳本中
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


void SetTestMode_Error(struct FunctionParameterDefine* action_param, uint32_t err_code)
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
    // 參數[0]:目標裝置
    SetActionParam(&new_action.paras[0], PARA_TYPE_DEVICE_TYPE, &target_device);
    // 參數[1]:模式
    SetActionParam(&new_action.paras[1], PARA_TYPE_UINT8, &mode);
    // 參數[2]:數值
    SetActionParam(&new_action.paras[2], PARA_TYPE_UINT32, &value);
    // 參數[4]:CAN BUS路徑
    uint8_t   path = router == SDK_ROUTER_MST_USB ? MST_PATH_USB : MST_PATH_NULL; 
    SetActionParam(&new_action.paras[4], PARA_TYPE_UINT8, &path);
    // 儲存執行完畢後回呼指標
    SetTestMode_callback = callback;
    // 判斷是發送BLE封包或是CAN-Bus封包
    switch (router)
    {
    case SDK_ROUTER_CANBUS:
        // 指定腳本運行的功能名稱
        new_action.run_script = AS_FL_CANBus_SetTestMode;
        break;

    default:
        // 指定腳本運行的功能名稱
        new_action.run_script = AS_FL_BLE_SetTestMode;
        break;
    }
    // 指定Action Script完成時的回呼指標
    new_action.finally_callback = SetTestMode_Finally;
    // 指定Action Script錯誤時的回呼指標
    new_action.error_callback = SetTestMode_Error;
    // 將新Action推送至等待處理的腳本中
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

        // 委派成功,回呼傳送ID清單
        GetCanIdBypassList_callback(SDK_RETURN_SUCCESS, id_list.mode, id_list.count, &id_list.list->Bytes[0]);
    }
}


void GetCanIdBypassList_Error(struct FunctionParameterDefine* action_param, uint32_t err_code)
{
    if (GetCanIdBypassList_callback)
    {
        // 委派異常,回呼失敗並傳送失敗代碼
        GetCanIdBypassList_callback(err_code, 0, 0, NULL);
    }
}

int __stdcall GetCanIdBypassList(RouterType router,
    fpCallback_GetCanIdBypassList callback)
{
    ACTION_DEFINE_T new_action = {};
    // 儲存執行完畢後回呼指標
    GetCanIdBypassList_callback = callback;
    // 判斷是發送BLE封包或是CAN-Bus封包
    switch (router)
    {
    case SDK_ROUTER_CANBUS:
        return SDK_RETURN_INVALID_PARAM;
        break;

    default:
        // 指定腳本運行的功能名稱
        new_action.run_script = AS_FL_BLE_GetCanIdBypassList;
        break;
    }
    // 指定Action Script完成時的回呼指標
    new_action.finally_callback = GetCanIdBypassList_Finally;
    // 指定Action Script錯誤時的回呼指標
    new_action.error_callback = GetCanIdBypassList_Error;
    // 將新Action推送至等待處理的腳本中
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


void SetCanIdBypassAllowList_Error(struct FunctionParameterDefine* action_param, uint32_t err_code)
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
    // 參數[0]:功能碼
    SetActionParam(&new_action.paras[0], PARA_TYPE_UINT8, &function_code);
    // 參數[1]:ID清單長度
    SetActionParam(&new_action.paras[1], PARA_TYPE_UINT8, &id_list_count);
    // 參數[2]:ID清單指針
    SetActionParam(&new_action.paras[2], PARA_TYPE_BYTE_ARRAY, id_list_data);
    // 儲存執行完畢後回呼指標
    SetCanIdBypassAllowList_callback = callback;
    // 判斷發送封包路由類型
    switch (router)
    {
    case SDK_ROUTER_CANBUS:
        return SDK_RETURN_INVALID_PARAM;
        break;

    default:
        // 指定腳本運行的功能名稱
        new_action.run_script = AS_FL_BLE_SetCanIdBypassAllowList;
        break;
    }
    // 指定Action Script完成時的回呼指標
    new_action.finally_callback = SetCanIdBypassAllowList_Finally;
    // 指定Action Script錯誤時的回呼指標
    new_action.error_callback = SetCanIdBypassAllowList_Error;
    // 將新Action推送至等待處理的腳本中
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


void SetCanIdBypassBlockList_Error(struct FunctionParameterDefine* action_param, uint32_t err_code)
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
    // 參數[0]:功能碼
    SetActionParam(&new_action.paras[0], PARA_TYPE_UINT8, &function_code);
    // 參數[1]:ID清單數量
    SetActionParam(&new_action.paras[1], PARA_TYPE_UINT8, &id_list_count);
    // 參數[2]:ID清單指針
    SetActionParam(&new_action.paras[2], PARA_TYPE_BYTE_ARRAY, id_list_data);
    // 儲存執行完畢後回呼指標
    SetCanIdBypassBlockList_callback = callback;
    // 判斷是發送BLE封包或是CAN-Bus封包
    switch (router)
    {
    case SDK_ROUTER_CANBUS:
        return SDK_RETURN_INVALID_PARAM;
        break;

    default:
        // 指定腳本運行的功能名稱
        new_action.run_script = AS_FL_BLE_SetCanIdBypassBlockList;
        break;
    }
    // 指定Action Script完成時的回呼指標
    new_action.finally_callback = SetCanIdBypassBlockList_Finally;
    // 指定Action Script錯誤時的回呼指標
    new_action.error_callback = SetCanIdBypassBlockList_Error;
    // 將新Action推送至等待處理的腳本中
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
        // 調用回呼傳送操作成功
        RestartDevice_callback(SDK_RETURN_SUCCESS);
    }
}


void RestartDevice_Error(struct FunctionParameterDefine* action_param, uint32_t err_code)
{
    if (RestartDevice_callback)
    {
        // 調用回呼傳送錯誤碼
        RestartDevice_callback(err_code);
    }
}

int __stdcall RestartDevice(RouterType router,
    SDKDeviceType_e target_device,
    fpCallback_RestartDevice callback)
{
    ACTION_DEFINE_T new_action = { };
    // 參數[0]:目標裝置
    SetActionParam(&new_action.paras[0], PARA_TYPE_DEVICE_TYPE, &target_device);
    // 參數[4]:CAN BUS路徑
    uint8_t   path = router == SDK_ROUTER_MST_USB ? MST_PATH_USB : MST_PATH_NULL;  
    SetActionParam(&new_action.paras[4], PARA_TYPE_UINT8, &path);
    // 儲存執行完畢後回呼指標
    RestartDevice_callback = callback;
    // 判斷是發送BLE封包或是CAN-Bus封包
    switch (router)
    {
    case SDK_ROUTER_CANBUS:
        return SDK_RETURN_INVALID_PARAM;
        break;

    default:
        // 指定腳本運行的功能名稱
        new_action.run_script = AS_FL_BLE_RestartDevice;
        break;
    }
    // 指定Action Script完成時的回呼指標
    new_action.finally_callback = RestartDevice_Finally;
    // 指定Action Script錯誤時的回呼指標
    new_action.error_callback = RestartDevice_Error;
    // 將新Action推送至等待處理的腳本中
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


void ReadDeviceLogs_Error(struct FunctionParameterDefine* action_param, uint32_t err_code)
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
    // 參數[0]:目標裝置
    SetActionParam(&new_action.paras[0], PARA_TYPE_DEVICE_TYPE, &target_device);
    // 儲存執行完畢後回呼指標
    ReadDeviceLogs_callback = callback;
    // 判斷是發送BLE封包或是CAN-Bus封包
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
        // 回呼成功
        ClearDeviceLogs_callback(SDK_RETURN_SUCCESS);
    }
}


void ClearDeviceLogs_Error(struct FunctionParameterDefine* action_param, uint32_t err_code)
{
    if (ClearDeviceLogs_callback)
    {
        // 回呼失敗並傳送失敗代碼
        ClearDeviceLogs_callback(err_code);
    }
}

int __stdcall ClearDeviceLogs(RouterType router,
    SDKDeviceType_e target_device,
    fpCallback_ClearDeviceLogs callback)
{
    ACTION_DEFINE_T new_action = { };
    // 參數[0]:目標裝置
    SetActionParam(&new_action.paras[0], PARA_TYPE_DEVICE_TYPE, &target_device);
    // 儲存執行完畢後回呼指標
    ClearDeviceLogs_callback = callback;

    switch (router)
    {
    case SDK_ROUTER_CANBUS:
        return SDK_RETURN_INVALID_PARAM;
        break;

    default:
        // 指定腳本運行的功能名稱
        new_action.run_script = AS_FL_BLE_ClearDeviceLogs;
        break;
    }
    // 指定Action Script完成時的回呼指標
    new_action.finally_callback = ClearDeviceLogs_Finally;
    // 指定Action Script錯誤時的回呼指標
    new_action.error_callback = ClearDeviceLogs_Error;
    // 將新Action推送至等待處理的腳本中
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
        // 回呼成功
        ConfigSysTime_callback(SDK_RETURN_SUCCESS);
    }
}


void ConfigSysTime_Error(struct FunctionParameterDefine* action_param, uint32_t err_code)
{
    if (ConfigSysTime_callback)
    {
        // 回呼失敗並傳送失敗代碼
        ConfigSysTime_callback(err_code);
    }
}

int __stdcall ConfigSysTime(RouterType router,
    SDKDeviceType_e target_device,
    uint64_t unix_time, fpCallback_ConfigSysTime callback)
{
    ACTION_DEFINE_T new_action = {};
    // 參數[0]:目標裝置
    SetActionParam(&new_action.paras[0], PARA_TYPE_DEVICE_TYPE, &target_device);
    // 參數[1]:設定的Unix時間
    SetActionParam(&new_action.paras[1], PARA_TYPE_UINT64, &unix_time);
    // 儲存執行完畢後回呼指標
    ConfigSysTime_callback = callback;
    // 判斷是發送BLE封包或是CAN-Bus封包
    switch (router)
    {
    case SDK_ROUTER_CANBUS:
        return SDK_RETURN_INVALID_PARAM;
        break;

    default:
        // 指定腳本運行的功能名稱
        new_action.run_script = AS_FL_BLE_ConfigSysTime;
        break;
    }
    // 指定Action Script完成時的回呼指標
    new_action.finally_callback = ConfigSysTime_Finally;
    // 指定Action Script錯誤時的回呼指標
    new_action.error_callback = ConfigSysTime_Error;
    // 將新Action推送至等待處理的腳本中
    ActionScriptCreate(new_action);

    return SDK_RETURN_SUCCESS;
}



/*
    Delegate Method : E-Lock Operation command
*/

static fpCallback_SetELock_DEV SetELock_DEV_callback = NULL;

void SetELock_DEV_Finally(struct FunctionParameterDefine* action_param)
{
    if (SetELock_DEV_callback)
    {
        // 回呼成功
        SetELock_DEV_callback(SDK_RETURN_SUCCESS);
    }
}


void SetELock_DEV_Error(struct FunctionParameterDefine* action_param, uint32_t err_code)
{
    if (SetELock_DEV_callback)
    {
        // 回呼失敗並傳送失敗代碼
        SetELock_DEV_callback(err_code);
    }
}

int __stdcall SetELock_DEV(RouterType router,
    bool release, bool unlocked,
    fpCallback_SetELock_DEV callback)
{
    ACTION_DEFINE_T new_action = {};
    // 參數[0]:解除定位閂鎖
    SetActionParam(&new_action.paras[0], PARA_TYPE_UINT8, &release);
    // 參數[1]:解除環形鎖
    SetActionParam(&new_action.paras[1], PARA_TYPE_UINT8, &unlocked);
    // 儲存執行完畢後回呼指標
    SetELock_DEV_callback = callback;
    // 判斷是發送BLE封包或是CAN-Bus封包
    switch (router)
    {
    case SDK_ROUTER_CANBUS:
        return SDK_RETURN_INVALID_PARAM;
        break;

    default:
        // 指定腳本運行的功能名稱
        new_action.run_script = AS_FL_BLE_SetELock_DEV;
        break;
    }
    // 指定Action Script完成時的回呼指標
    new_action.finally_callback = SetELock_DEV_Finally;
    // 指定Action Script錯誤時的回呼指標
    new_action.error_callback = SetELock_DEV_Error;
    // 將新Action推送至等待處理的腳本中
    ActionScriptCreate(new_action);

    return SDK_RETURN_SUCCESS;
}




/*
    Delegate Method : Get E-Lock Status
*/

static fpCallback_GetELock_DEV GetELock_DEV_callback = NULL;

void GetELock_DEV_Finally(struct FunctionParameterDefine* action_param)
{
    if (GetELock_DEV_callback)
    {
        // 回呼成功
        GetELock_DEV_callback(SDK_RETURN_SUCCESS, sdk.Inst.DeviceInfo.FL.e_lock_states);
    }
}


void GetELock_DEV_Error(struct FunctionParameterDefine* action_param, uint32_t err_code)
{
    if (GetELock_DEV_callback)
    {
        // 回呼失敗並傳送失敗代碼
        GetELock_DEV_callback(err_code, ELOCK_STATES_UNKNOW);
    }
}

int __stdcall GetELock_DEV(RouterType router,
    fpCallback_GetELock_DEV callback)
{
    ACTION_DEFINE_T new_action = {};
    // 儲存執行完畢後回呼指標
    GetELock_DEV_callback = callback;
    // 判斷是發送BLE封包或是CAN-Bus封包
    switch (router)
    {
    case SDK_ROUTER_CANBUS:
        return SDK_RETURN_INVALID_PARAM;
        break;

    default:
        // 指定腳本運行的功能名稱
        new_action.run_script = AS_FL_BLE_GetELock_DEV;
        break;
    }
    // 指定Action Script完成時的回呼指標
    new_action.finally_callback = GetELock_DEV_Finally;
    // 指定Action Script錯誤時的回呼指標
    new_action.error_callback = GetELock_DEV_Error;
    // 將新Action推送至等待處理的腳本中
    ActionScriptCreate(new_action);

    return SDK_RETURN_SUCCESS;
}

/*
    Delegate Method : light control
*/

static fpCallback_LightControl  Light_control_callback = NULL;

void Light_control_Finally(struct FunctionParameterDefine* action_param)
{
    if (Light_control_callback)
    {
        // 調用回呼傳送操作成功
        Light_control_callback(SDK_RETURN_SUCCESS);
    }
}


void Light_control_Error(struct FunctionParameterDefine* action_param, uint32_t err_code)
{
    if (Light_control_callback)
    {
        // 調用回呼傳送錯誤碼
        Light_control_callback(err_code);
    }
}

int __stdcall  Light_control(RouterType router,
    light_control_parts  parts,
    bool on_off,
    fpCallback_LightControl callback)
{
    ACTION_DEFINE_T new_action = { };
   
    SetActionParam(&new_action.paras[0], PARA_TYPE_UINT8, &parts);
    SetActionParam(&new_action.paras[1], PARA_TYPE_UINT8, &on_off);
    // 儲存執行完畢後回呼指標
    Light_control_callback = callback; 
    // 判斷是發送BLE封包或是CAN-Bus封包
    switch (router)
    {
    case SDK_ROUTER_CANBUS:
        return SDK_RETURN_INVALID_PARAM;
        break;

    default:
        // 指定腳本運行的功能名稱
        new_action.run_script = BLE_light_control;
        break;
    } 
    // 指定Action Script完成時的回呼指標
    new_action.finally_callback = Light_control_Finally;
    // 指定Action Script錯誤時的回呼指標
    new_action.error_callback = Light_control_Error;
    // 將新Action推送至等待處理的腳本中
    ActionScriptCreate(new_action);

    return SDK_RETURN_SUCCESS;
}


static fpCallback_ClearTripInfo  ClearTripInfo_callback = NULL;

void ClearTripInfo_Finally(struct FunctionParameterDefine* action_param)
{
    if (ClearTripInfo_callback)
    {
        // 調用回呼傳送操作成功
        ClearTripInfo_callback(SDK_RETURN_SUCCESS);
    }
}


void ClearTripInfo_Error(struct FunctionParameterDefine* action_param, uint32_t err_code)
{
    if (ClearTripInfo_callback)
    {
        // 調用回呼傳送錯誤碼
        ClearTripInfo_callback(err_code);
    }
}

int __stdcall  ClearTripInfo(RouterType router,
    fpCallback_ClearTripInfo callback)
{
    ACTION_DEFINE_T new_action = { };

    // 儲存執行完畢後回呼指標
    ClearTripInfo_callback = callback;
    // 判斷是發送BLE封包或是CAN-Bus封包
    switch (router)
    {
    case SDK_ROUTER_CANBUS:
        return SDK_RETURN_INVALID_PARAM;
        break;

    default:
        // 指定腳本運行的功能名稱
        new_action.run_script = BLE_ClearTripInfo;  
        break;
    }
    // 指定Action Script完成時的回呼指標
    new_action.finally_callback = ClearTripInfo_Finally;
    // 指定Action Script錯誤時的回呼指標
    new_action.error_callback = ClearTripInfo_Error;
    // 將新Action推送至等待處理的腳本中
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
        // 初始化 Action Script並實例化相關的Buffer
        ActionScriptInit();
        // 設定CAN-Bus接收封包Buffer透過Queue的方式實作
        can_rx_queue.buffer_size = 4096;
        can_rx_queue.buffer = (char*)&can_rx_queue_buff;
        can_rx_queue.is_full = false;
        can_rx_queue.item_size = sizeof(CANPacket_T);
        // 設定CAN-Bus發送封包Buffer透過Queue的方式實作
        can_tx_queue.buffer_size = 4096;
        can_tx_queue.buffer = (char*)&can_tx_queue_buff;
        can_tx_queue.is_full = false;
        can_tx_queue.item_size = sizeof(CANPacket_T);
        // 將SDK Inst內的程式指針重新指向實例目標位址
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
        SDK_Inst->DelegateMethod.SetELock_DEV = SetELock_DEV;
        SDK_Inst->DelegateMethod.GetELock_DEV = GetELock_DEV;
        SDK_Inst->DelegateMethod.LightControl = Light_control;
        SDK_Inst->DelegateMethod.ClearTripInfo = ClearTripInfo;

        SDK_Inst->Method.CANBusPacket_IN = CANBusPacket_IN;
        SDK_Inst->Method.CANBusPacket_OUT = CANBusPacket_OUT;
        SDK_Inst->Method.BLECommandPacket_IN = BLECommandPacket_IN;
        SDK_Inst->Method.BLECommandPacket_OUT = BLECommandPacket_OUT;
        SDK_Inst->Method.BLEDataPacket_IN = BLEDataPacket_IN;
        SDK_Inst->Method.BLEDataPacket_OUT = BLEDataPacket_OUT;

        SDK_Inst->DeviceInfo.FL.e_lock_states = ELOCK_STATES_UNKNOW;

        SDK_Inst->ParametersArray[0] = 0x12;
        // 判斷迴圈休眠時間
        if (SDK_Inst->ThreadSleepInterval_us == 0)
        {
            SDK_Inst->ThreadSleepInterval_us = 1000;
        }
        

        // 複製現在版本號到指定記憶體, 供外部讀取
        memcpy(SDK_Inst->Version, SDK_Version_Str, sizeof(SDK_Version_Str));

        LOG_PUSH("SDK Version:%s\n", SDK_Version_Str);
        LOG_PUSH("CAN Protocol Version:%s\n", CAN_PROTOCOL_VER);   

        LOG_FLUSH;

        DeviceInfoInst = { 0 };

        // 初始化農田專屬通訊協議解析器
        FL_CAN_Init(&DeviceInfoInst, SendToCANBUS, &CoreSDK_ISOTP);

        memcpy(&sdk.Inst, SDK_Inst, sizeof(CoreSDKInst_T));
        // 初始化排程運行模組
        lib_event_sched_init(&sched_inst);
        // 初始化虛擬HMI, 但目前尚未使用
        FL_device_HMI_Init(&FL_HMI_ISOTP, SendToCANBUS);
        //MST 功能初始化
        if(SDK_Inst->MstSdkConfig.initEnable)
            Mst_init(SDK_Inst->MstSdkConfig);
        // 確認SDK已被初始化, 避免重複初始化
        SDK_BeInit = true;

        return SDK_RETURN_SUCCESS;
    }
    else
    {
        SDK_BeInit = false;

        return SDK_RETURN_NULL;
    }
}

