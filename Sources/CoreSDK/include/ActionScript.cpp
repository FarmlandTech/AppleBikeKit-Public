

#include "ActionScript.h"
#include "FL_CanProtocol.h"
#include "FL_CANInfoStruct.h"
#include "lib_fifo_buff.h"
#include <iostream>
#include <ctime>
#include "LogPrinter.h"
#include "FL_MstSdk.h"
using namespace std;

#define ISO_TP_BUFF_SIZE	4096
#define NONE_TIMEOUT_SET	0xffffffff
#define BIN_FILE_MAX_SIZE	(512*1024)

#define BLE_DFU_DATA_SIZE	238
#define BLE_PARAM_DATA_SIZE	228

typedef enum FirmwareUpdateStep_e
{
	DFU_IDLE = 0u,
	DFU_WAIT_COMMAND
} FirmwareUpdateStep_E;

typedef struct BLE_packet_st
{
	uint8_t frame_size;
	uint8_t frame_index;
	uint16_t opc;
	uint8_t target_device;
	uint8_t response_code;
	uint8_t data[BLE_DFU_DATA_SIZE];
	uint8_t leng;
} BLE_packet_T;

BLE_packet_T ble_dfu_response_queue_buffer[4096] = {};
static LIB_FIFO_INST_T ble_dfu_response_queue = {};

BLE_packet_T ble_dfu_commond_queue_buffer[4096] = {};
static LIB_FIFO_INST_T ble_dfu_commond_queue = {};

BLE_packet_T ble_dfu_data_queue_buffer[4096] = {};
static LIB_FIFO_INST_T ble_dfu_data_queue = {};

struct FlashVerify_st
{
	uint32_t start_addr;
	uint32_t end_addr;
	uint32_t crc;
};

struct UpgradeFirmwareSetting_st
{
	uint8_t target_DMID[32];
	uint8_t target_device;
	uint32_t bin_size;
	uint32_t start_index;
	uint32_t now_index;
	uint32_t end_index;
	uint16_t cache_index;
	uint16_t identifier;
	uint16_t block_index;
	uint8_t bin_file[BIN_FILE_MAX_SIZE];
	struct FlashVerify_st flash_verify;
	struct DFU_device_information_st deviceInfo;
	FirmwareUpdateStep_E NowStep;
};

struct BLEUpgradeFirmwareState_st
{
	bool enable;
	uint8_t target_device;
	uint8_t request_code;
	uint8_t response_code;

};

#pragma pack(push)
#pragma pack(8)

struct ActionTimer_st
{
	uint32_t count;
	uint32_t threshold;
};

struct ActionScriptClass
{
	struct ActionTimer_st timeout;
	struct ActionTimer_st wait;
	uint8_t run_step;
	uint8_t retry_cnt;
	enum ActionScritpStatus status;
	ACTION_DEFINE_T Runtime;

	ACTION_DEFINE_T action_queue_buffer[4096];
	LIB_FIFO_INST_T action_queue;
};

#pragma pack(pop)

#define CAN_BYPASS_BLOCK_MODE	(uint8_t)0
#define CAN_BYPASS_ALLOW_MODE	(uint8_t)1

#define CAN_BYPASS_ADD_FUNCTION	(uint8_t)1
#define CAN_BYPASS_DEL_FUNCTION	(uint8_t)2
#define CAN_BYPASS_GET_FUNCTION	(uint8_t)3




struct ActionScriptClass AS_Inst = {0};
struct UpgradeFirmwareSetting_st DFU_Setting = {0};
struct BLEUpgradeFirmwareState_st BLE_DFU_State = { 0 };
struct CANBypass_IdList canbus_bypass_listen = { 0 };

#define MAX_DEVICE_LOGS_SIZE	4096
struct LogsInfo_st
{
	DeviceLogs_T list[MAX_DEVICE_LOGS_SIZE];
	uint16_t count;
};

struct LogsInfo_st deviceLogs;


static void Recover_SilenceMode_Set(void);

void print_time(void)
{
	time_t tmNow;
	tmNow = time(NULL);
	tm* tm_local = localtime(&tmNow);
	//printf("%d:%d:%d-", tm_local->tm_hour, tm_local->tm_min, tm_local->tm_sec);

}


void ActionScript_timer_1ms_tick(void)
{
	if (!(AS_Inst.status == ACTION_SCRITP_STATUS_WAIT ||
		AS_Inst.status == ACTION_SCRITP_STATUS_RESPOND_WAIT))
	{
		return;
	}

	if (AS_Inst.timeout.threshold == 0)
	{
		return;
	}

	if (AS_Inst.timeout.count > AS_Inst.timeout.threshold)
	{
		AS_Inst.timeout.count++;

		if (AS_Inst.status == ACTION_SCRITP_STATUS_RESPOND_WAIT)
		{
			if (AS_Inst.retry_cnt)
			{
				--AS_Inst.retry_cnt;
			}

			if (AS_Inst.retry_cnt)
			{
				AS_Inst.timeout.count = 0;
				AS_Inst.status = ACTION_SCRITP_STATUS_RUNNING;
			}
			else
			{
				LOG_PUSH("Error :: Action Timeout\n");
				LOG_FLUSH;
				AS_Inst.status = ACTION_SCRITP_STATUS_TIMEOUT;
			}
			
		}
	}
	else if(AS_Inst.timeout.count <= AS_Inst.timeout.threshold)
	{
		AS_Inst.timeout.count++;
	}
}

void ActionScriptRespondWait(uint32_t timeout_ms_set)
{
	AS_Inst.timeout.count = 0;
	AS_Inst.timeout.threshold = timeout_ms_set;
	AS_Inst.status = ACTION_SCRITP_STATUS_RESPOND_WAIT;

}

void ActionScriptRespondWaitAndRetry(uint32_t timeout_ms_set, uint8_t retry_cnt)
{
	AS_Inst.timeout.count = 0;
	AS_Inst.timeout.threshold = timeout_ms_set;

	if (AS_Inst.retry_cnt == 0)
	{
		AS_Inst.retry_cnt = retry_cnt;
	}
	
	AS_Inst.status = ACTION_SCRITP_STATUS_RESPOND_WAIT;

}

enum DEVICE_OBJ_TYPE_E ConverterToFlDeviceId( uint8_t sdk_device_id_type)
{
	switch ((SDKDeviceType_e)sdk_device_id_type)
	{
	case SDK_FL_HMI:
		return DEVICE_OBJ_HMI;

	case SDK_FL_CONTROLLER:
		return DEVICE_OBJ_CONTROLLER;

	case SDK_FL_MAIN_BATT:
		return DEVICE_OBJ_MAIN_BATT;

	case SDK_FL_SUB_BATT1:
		return DEVICE_OBJ_SUB_BATT1;

	case SDK_FL_SUB_BATT2:
		return DEVICE_OBJ_SUB_BATT2;

	case SDK_FL_DISPLAY:
		return DEVICE_OBJ_DISPLAY;

	case SDK_FL_IOT:
		return DEVICE_OBJ_IOT;

	case SDK_FL_E_DERAILLEUR:
		return DEVICE_OBJ_E_DERAILLEUR;

	case SDK_FL_E_LOCK:
		return DEVICE_OBJ_E_LOCK;

	default:
		return DEVICE_OBJ_UNKNOWN;
	}
}

void AS_FL_ActionErrorHandler(uint32_t error_code)
{
	switch (error_code)
	{
	case ISOTP_DELEGATE_TIMEOUT:
	{
		AS_Inst.status = ACTION_SCRITP_STATUS_TIMEOUT;
	}
	break;

	}
}

void AS_FL_ActionStepNext(void)
{
	LOG_PUSH("Now Action Step[%d] ==> ", AS_Inst.run_step);
	AS_Inst.run_step++;
	LOG_PUSH("Next Action Step[%d]\n", AS_Inst.run_step);
	LOG_FLUSH;
	AS_Inst.timeout.count = 0;
	AS_Inst.timeout.threshold = 0;
	AS_Inst.retry_cnt = 0;
	AS_Inst.status = ACTION_SCRITP_STATUS_RUNNING;
}


void ActionScriptResetStatus(void)
{	
	//lib_fifo_drop(&AS_Inst.action_queue); 

	AS_Inst.run_step = 0;
	AS_Inst.timeout.count = 0;
	AS_Inst.timeout.threshold = 0;
	AS_Inst.retry_cnt = 0;
	AS_Inst.status = ACTION_SCRITP_STATUS_IDLE;

	BLE_DFU_State.enable = false;
}


void ActionScriptInit(void)
{
	ble_dfu_response_queue.buffer = (char*)&ble_dfu_response_queue_buffer;
	ble_dfu_response_queue.buffer_size = 4096;
	ble_dfu_response_queue.is_full = false;
	ble_dfu_response_queue.item_size = sizeof(BLE_packet_T);


	ble_dfu_commond_queue.buffer = (char*)&ble_dfu_commond_queue_buffer;
	ble_dfu_commond_queue.buffer_size = 4096;
	ble_dfu_commond_queue.is_full = false;
	ble_dfu_commond_queue.item_size = sizeof(BLE_packet_T);


	ble_dfu_data_queue.buffer = (char*)&ble_dfu_data_queue_buffer;
	ble_dfu_data_queue.buffer_size = 4096;
	ble_dfu_data_queue.is_full = false;
	ble_dfu_data_queue.item_size = sizeof(BLE_packet_T);

	AS_Inst.action_queue.buffer = (char*)&AS_Inst.action_queue_buffer;
	AS_Inst.action_queue.buffer_size = 4096;
	AS_Inst.action_queue.is_full = false;
	AS_Inst.action_queue.item_size = sizeof(ACTION_DEFINE_T);
}

int ActionScriptCreate(ACTION_DEFINE_T new_action)
{
	lib_fifo_write(&AS_Inst.action_queue, &new_action);
	return 0;
}
void ActionScriptDone()
{
	AS_Inst.status = ACTION_SCRITP_STATUS_DONE;
}
void AS_FL_ActionScriptResume(void)
{
	AS_Inst.timeout.threshold = 0;
	AS_Inst.status = ACTION_SCRITP_STATUS_RUNNING;
}


void ActionScriptRun(void)
{
	static uint32_t dont_kill_me = 0;
	if (AS_Inst.status == ACTION_SCRITP_STATUS_IDLE)
	{
		if (lib_fifo_length(&AS_Inst.action_queue) > 0)
		{
			lib_fifo_read(&AS_Inst.action_queue, &AS_Inst.Runtime);
			AS_Inst.status = ACTION_SCRITP_STATUS_RUNNING;
			AS_Inst.run_step = 0;
		}
	}
	else if (AS_Inst.status == ACTION_SCRITP_STATUS_RUNNING)
	{
		AS_Inst.Runtime.run_script(AS_Inst.Runtime.paras);
	}
	else if (AS_Inst.status == ACTION_SCRITP_STATUS_DONE)
	{
		if (AS_Inst.Runtime.finally_callback)
		{
			AS_Inst.Runtime.finally_callback(AS_Inst.Runtime.paras);
		}
		ActionScriptResetStatus();
	}
	else if(AS_Inst.status == ACTION_SCRITP_STATUS_TIMEOUT)
	{
		if (AS_Inst.Runtime.error_callback)
		{
			AS_Inst.Runtime.error_callback(AS_Inst.Runtime.paras, SDK_RETURN_TIMEOUT);
		}
		ActionScriptResetStatus();

		Recover_SilenceMode_Set();
	}
	else
	{
		dont_kill_me++;
	}
}



void AS_FL_BLE_DFU_CommonPackage_Send(uint8_t frame_size, uint8_t frame_index,
	uint16_t opc, uint8_t target_device, uint8_t response_code, uint8_t* data, uint8_t leng)
{
	BLE_packet_T packet = { 0 };
	uint16_t copy_index = 0;

	packet.frame_size = frame_size;
	packet.frame_index = frame_index;
	packet.opc = opc;
	packet.target_device = target_device;
	packet.response_code = response_code;

	for (copy_index = 0; copy_index < leng; copy_index++)
	{
		packet.data[copy_index] = data[copy_index];
	}
	packet.leng = leng;
	lib_fifo_write(&ble_dfu_commond_queue, &packet);
}


int AS_FL_GetBLECommon_TxQueue(uint8_t* out_data, uint16_t out_data_size, uint16_t* leng)
{
	uint16_t packet_leng = 0;
	BLE_packet_T tx = { 0 };



	if (lib_fifo_length(&ble_dfu_commond_queue) > 0 && out_data != NULL)
	{
		lib_fifo_read(&ble_dfu_commond_queue, &tx);

		if (out_data_size >= tx.leng)
		{
			out_data[packet_leng++] = tx.frame_size;
			out_data[packet_leng++] = tx.frame_index;
			out_data[packet_leng++] = (uint8_t)tx.opc;
			out_data[packet_leng++] = (uint8_t)(tx.opc >> 8);
			out_data[packet_leng++] = tx.target_device;
			out_data[packet_leng++] = tx.response_code;

			for (uint16_t index = 0; index < tx.leng; index++)
			{
				out_data[packet_leng++] = tx.data[index];
			}

			*leng = packet_leng;
		}
		else
		{
			return SDK_RETURN_INVALID_SIZE;
		}


		return SDK_RETURN_SUCCESS;
	}
	else
	{
		return SDK_RETURN_NULL;
	}
}

/*

	Functional command

*/
static bool BLE_SilenceMode_ON = false;

static void BLE_SilenceMode_Set(bool enable, uint8_t time_sec)
{
	uint8_t post_data[10] = {0};
	uint8_t post_leng = 0;
	HOST_CONTROLINFO_02_T info = { 0 };

	info.bits.silence_mode = enable ? 1 : 0;
	info.bits.silence_timeout = time_sec;

	post_data[post_leng++] = FL_CANID_HOST_INFO_02;
	post_data[post_leng++] = (uint8_t)(FL_CANID_HOST_INFO_02 >> 8);
	post_data[post_leng++] = (uint8_t)(FL_CANID_HOST_INFO_02 >> 16);
	post_data[post_leng++] = (uint8_t)(FL_CANID_HOST_INFO_02 >> 24);

	post_data[post_leng++] = info.bytes[0];
	post_data[post_leng++] = info.bytes[1];

	AS_FL_BLE_DFU_CommonPackage_Send(1, 0,
		FL_BLE_OPC_CAN_PASS_DATA_REQ,
		DEVICE_OBJ_HMI,
		0, post_data, post_leng);

	BLE_SilenceMode_ON = enable ? true : false;
}

static void Recover_SilenceMode_Set(void)
{
	if (BLE_SilenceMode_ON)
	{
		BLE_SilenceMode_Set(false, 0);
	}
}

static void BLE_FilterMode_Set()
{

}


/*

	Action command

*/


void AS_FL_CANBus_ReadParameter(struct FunctionParameterDefine* paras)
{
	

	switch (AS_Inst.run_step)
	{
	case 0:
	{
		uint8_t device_id = ConverterToFlDeviceId(paras[0].num.uint8_val);
		uint16_t start_addr = paras[1].num.uint32_val;
		uint16_t leng = paras[2].num.uint16_val;
		uint8_t bank_index = paras[3].num.int8_val;

		if (device_id != DEVICE_OBJ_UNKNOWN)
		{
			
			FL_CAN_ReadParameter_Requset(
				device_id,
				bank_index,
				start_addr,
				leng,
				AS_FL_ActionStepNext,
				AS_FL_ActionErrorHandler);

			ActionScriptRespondWait(5000);

		}
		else
		{
			AS_Inst.status = ACTION_SCRITP_STATUS_ERROR;
		}		
	}
	break;



	default:
	{

		AS_Inst.status = ACTION_SCRITP_STATUS_DONE;
	}
	break;
	}
}
int read_para_Request; //test
int read_para_Response; //test
int read_para_err; //test
clock_t r_start; //test
void AS_FL_BLE_ReadParam_GetRespond(uint8_t device, uint16_t opc, uint8_t response_code,
	uint8_t* data, uint16_t data_leng)
{
	++read_para_Response;//test
	if (data_leng >= 10)
	{
		uint32_t get_crc = data[(data_leng - 4)] + (data[(data_leng - 3)] << 8) + (data[(data_leng - 2)] << 16) + (data[(data_leng - 1)] << 24);
		uint32_t cal_crc = FarmlandCalCrc32(data, (data_leng - 4), 0);

		if (get_crc == cal_crc)
		{
			uint8_t bank_index = data[0];
			uint16_t addr = data[1] + ((uint16_t)data[2] << 8);
			uint16_t leng = data[3] + ((uint16_t)data[4] << 16);
			UpdateDeviceParameter((DeviceObjTypes)device, bank_index, addr, leng, &data[5]);
			AS_FL_ActionStepNext();
		}
		
	}
	if (response_code != 0)//test
		++read_para_err;//test
	LOG_PUSH("Elapsed time:%d ms\r\n read_para_Request: %d _____ read_para_Response: %d _____ error: %d \r\n ", clock() - r_start, read_para_Request, read_para_Response, read_para_err);//test 
	LOG_FLUSH; //test 
}

void AS_FL_BLE_ReadParameter(struct FunctionParameterDefine* paras)
{
	static uint8_t device_id = 0;
	static uint16_t start_addr = 0, end_addr = 0, param_leng = 0;
	static uint8_t bank_index = 0;

	switch (AS_Inst.run_step)
	{
	case 0:
	{
		device_id = ConverterToFlDeviceId(paras[0].num.uint8_val);
		start_addr = paras[1].num.uint16_val;
		param_leng = paras[2].num.uint16_val;
		bank_index = paras[3].num.int8_val;
		uint8_t post_data[6] = { 0 };
		uint8_t post_leng = 0;
		uint16_t leng = 0;

		end_addr = (start_addr + param_leng) - 1;

		leng = param_leng >= BLE_PARAM_DATA_SIZE ? BLE_PARAM_DATA_SIZE : param_leng;

		post_data[post_leng++] = bank_index;
		post_data[post_leng++] = (uint8_t)start_addr;
		post_data[post_leng++] = (uint8_t)(start_addr >> 8);
		post_data[post_leng++] = (uint8_t)leng;
		post_data[post_leng++] = (uint8_t)(leng >> 8);

		if (device_id != DEVICE_OBJ_UNKNOWN)
		{
			BLE_SilenceMode_Set(true, 6);
			AS_FL_BLE_DFU_CommonPackage_Send(1, 0,
				FL_BLE_OPC_PARAM_READ_REQ,
				device_id,
				0, post_data, post_leng);

			start_addr += leng;
			++read_para_Request;//test
			r_start = clock();//test
			LOG_PUSH("-----read_para_Request: %d \r\n ", read_para_Request);//test
			LOG_FLUSH; //test 
			ActionScriptRespondWait(5000);
		}
		else
		{
			AS_Inst.status = ACTION_SCRITP_STATUS_ERROR;
		}
	}
	break;

	case 1:
	{
		uint8_t post_data[6] = { 0 };
		uint8_t post_leng = 0;
		uint16_t leng;

		if (start_addr < end_addr)
		{
			leng = ((end_addr- start_addr) + 1) > BLE_PARAM_DATA_SIZE ? BLE_PARAM_DATA_SIZE : ((end_addr - start_addr) + 1);

			post_data[post_leng++] = bank_index;
			post_data[post_leng++] = (uint8_t)start_addr;
			post_data[post_leng++] = (uint8_t)(start_addr >> 8);
			post_data[post_leng++] = (uint8_t)leng;
			post_data[post_leng++] = (uint8_t)(leng >> 8);

			AS_FL_BLE_DFU_CommonPackage_Send(1, 0,
				FL_BLE_OPC_PARAM_READ_REQ,
				device_id,
				0, post_data, post_leng);

			start_addr += leng;
			++read_para_Request;//test 
			LOG_PUSH("-----read_para_Request: %d \r\n ", read_para_Request);//test 
			LOG_FLUSH; //test 
			ActionScriptRespondWait(5000);
		}
		else
		{
			AS_Inst.run_step++;
		}
		
	}
	break;

	case 2:
	{
		if (start_addr < end_addr)
		{
			AS_Inst.run_step--;
		}
		else
		{
			AS_Inst.run_step++;
		}

		AS_Inst.status = ACTION_SCRITP_STATUS_RUNNING;
	}
	break;

	default:
	{
		BLE_SilenceMode_Set(false, 0);
		AS_Inst.status = ACTION_SCRITP_STATUS_DONE;
	}
	break;
	}
}


void AS_FL_CANBus_WriteParameter(struct FunctionParameterDefine* paras)
{
	switch (AS_Inst.run_step)
	{
	case 0:
	{
		uint8_t device_id = ConverterToFlDeviceId(paras[0].num.uint8_val);
		uint32_t addr = paras[1].num.uint16_val;
		uint16_t leng = paras[2].num.uint16_val;
		uint8_t bank_index = paras[3].num.int8_val;
		uint8_t* data = paras[4].buff;

		if (device_id != DEVICE_OBJ_UNKNOWN)
		{
			FL_CAN_WriteParameter_Requset(
				device_id,
				bank_index,
				addr,
				leng,
				data,
				AS_FL_ActionStepNext,
				AS_FL_ActionErrorHandler);

			ActionScriptRespondWait(5000);
		}
		else
		{
			AS_Inst.status = ACTION_SCRITP_STATUS_ERROR;
		}		
	}
	break;

	default:
	{
		AS_Inst.status = ACTION_SCRITP_STATUS_DONE;
	}
	break;
	}
}


void AS_FL_BLE_Copy_CanIdBytpassList(struct CANBypass_IdList* id_list)
{
	id_list = &canbus_bypass_listen;
}


void AS_FL_BLE_GetCanIdBypassList_GetRespond(uint8_t device, uint16_t opc, uint8_t response_code, uint8_t* data, uint16_t leng)
{
	if (opc == FL_BLE_OPC_CAN_LISTEN_ID_RES)
	{
		AS_FL_ActionStepNext();
	}
}


void AS_FL_BLE_GetCanIdBypassList(struct FunctionParameterDefine* paras)
{
	switch (AS_Inst.run_step)
	{
	case 0:
	{
		uint8_t post_data[2] = { 0 };

		post_data[0] = canbus_bypass_listen.mode;
		post_data[1] = canbus_bypass_listen.function_code;

		AS_FL_BLE_DFU_CommonPackage_Send(1, 0,
			FL_BLE_OPC_CAN_LISTEN_ID_REQ,
			DEVICE_OBJ_HMI,
			0, post_data, 2);

		ActionScriptRespondWait(2000);
	}
	break;

	default:
	{
		AS_Inst.status = ACTION_SCRITP_STATUS_DONE;
	}
	break;
	}
}


void AS_FL_BLE_SetCanIdBypassAllowList_GetRespond(uint8_t device, uint16_t opc, uint8_t response_code, uint8_t* data, uint16_t leng)
{
	if (opc == FL_BLE_OPC_CAN_LISTEN_ID_RES)
	{
		AS_FL_ActionStepNext();
	}
}


void AS_FL_BLE_SetCanIdBypassAllowList(struct FunctionParameterDefine* paras)
{
	switch (AS_Inst.run_step)
	{
	case 0:
	{
		uint8_t function_code = paras[0].num.uint8_val;
		uint8_t id_count = paras[1].num.uint8_val;
		uint8_t* id_list = paras[2].buff;
		uint8_t post_data[255] = { 0 };
		uint8_t post_leng = 0;
		uint8_t index = 0, copy_leng = 0;

		post_data[post_leng++] = 1;
		post_data[post_leng++] = function_code;
		post_data[post_leng++] = id_count;

		copy_leng = id_count * 4;
		for (index = 0; index < copy_leng; index++)
		{
			post_data[post_leng++] = id_list[index];
		}

		AS_FL_BLE_DFU_CommonPackage_Send(1, 0,
			FL_BLE_OPC_CAN_LISTEN_ID_REQ,
			DEVICE_OBJ_HMI,
			0, post_data, post_leng);

		ActionScriptRespondWait(2000);
	}
	break;

	default:
	{
		AS_Inst.status = ACTION_SCRITP_STATUS_DONE;
	}
	break;
	}
}

void AS_FL_BLE_SetCanIdBypassBlockList_GetRespond(uint8_t device, uint16_t opc, uint8_t response_code, uint8_t* data, uint16_t leng)
{
	if (opc == FL_BLE_OPC_CAN_LISTEN_ID_RES)
	{
		AS_FL_ActionStepNext();
	}
}


void AS_FL_BLE_SetCanIdBypassBlockList(struct FunctionParameterDefine* paras)
{
	switch (AS_Inst.run_step)
	{
	case 0:
	{
		uint8_t function_code = paras[0].num.uint8_val;
		uint8_t id_count = paras[1].num.uint8_val;
		uint8_t* id_list = paras[2].buff;
		uint8_t post_data[255] = { 0 };
		uint8_t post_leng = 0;
		uint8_t index = 0,copy_leng = 0;

		post_data[post_leng++] = 0;
		post_data[post_leng++] = function_code;
		post_data[post_leng++] = id_count;

		copy_leng = id_count * 4;
		for (index = 0; index < copy_leng; index++)
		{
			post_data[post_leng++] = id_list[index];
		}

		AS_FL_BLE_DFU_CommonPackage_Send(1, 0,
			FL_BLE_OPC_CAN_LISTEN_ID_REQ,
			DEVICE_OBJ_HMI,
			0, post_data, post_leng);

		ActionScriptRespondWait(2000);
	}
	break;

	default:
	{
		AS_Inst.status = ACTION_SCRITP_STATUS_DONE;
	}
	break;
	}
}
int write_para_Request; //test
int write_para_Response; //test
int write_para_err; //test
void AS_FL_BLE_WriteParam_GetRespond(uint8_t device, uint16_t opc, uint8_t response_code,
	uint8_t* data, uint16_t leng)
{
	++write_para_Response;//test
	if (opc == FL_BLE_OPC_PARAM_WRITE_RES)
	{
		AS_FL_ActionStepNext();
	}
	if (response_code != 0)//test
		++write_para_err;//test
	LOG_PUSH("-----write_para_Request: %d _____ write_para_Response: %d _____ error: %d \r\n ", write_para_Request, write_para_Response, write_para_err);//test
	LOG_FLUSH; //test
}


void AS_FL_BLE_WriteParameter(struct FunctionParameterDefine* paras)
{
	switch (AS_Inst.run_step)
	{
	case 0:
	{
		uint8_t device_id = ConverterToFlDeviceId(paras[0].num.uint8_val);
		uint16_t addr = paras[1].num.uint16_val;
		uint16_t leng = paras[2].num.uint16_val;
		uint8_t bank_index = paras[3].num.int8_val;
		uint8_t* data = paras[4].buff;
		uint8_t post_data[255] = { 0 };
		uint8_t post_leng = 0;
		uint8_t index = 0;

		post_data[post_leng++] = bank_index;
		post_data[post_leng++] = (uint8_t)addr;
		post_data[post_leng++] = (uint8_t)(addr >> 8);
		post_data[post_leng++] = (uint8_t)leng;
		post_data[post_leng++] = (uint8_t)(leng >> 8);

		for (index = 0 ; index < leng; index++)
		{
			post_data[post_leng++] = data[index];
		}

		uint32_t crc = FarmlandCalCrc32(post_data, post_leng, 0);

		post_data[post_leng++] = (uint8_t)crc;
		post_data[post_leng++] = (uint8_t)(crc >> 8);
		post_data[post_leng++] = (uint8_t)(crc >> 16);
		post_data[post_leng++] = (uint8_t)(crc >> 24);

		if (device_id != DEVICE_OBJ_UNKNOWN)
		{
			BLE_SilenceMode_Set(true, 6);
			AS_FL_BLE_DFU_CommonPackage_Send(1, 0,
				FL_BLE_OPC_PARAM_WRITE_REQ,
				device_id,
				0, post_data, post_leng);
			++write_para_Request;//test
			ActionScriptRespondWait(5000);
			LOG_PUSH("-----write_para_Request: %d  \r\n ", write_para_Request);//test
			LOG_FLUSH; //test
		}
		else
		{
			AS_Inst.status = ACTION_SCRITP_STATUS_ERROR;
		}
	}
	break;

	default:
	{
		BLE_SilenceMode_Set(false, 0);
		AS_Inst.status = ACTION_SCRITP_STATUS_DONE;
	}
	break;
	}
}



void AS_FL_BLE_ResetParam_GetRespond(uint8_t device, uint16_t opc, uint8_t response_code,
	uint8_t* data, uint16_t leng)
{
	if (opc == FL_BLE_OPC_PARAM_RESET_RES)
	{
		AS_FL_ActionStepNext();
	}
}


void AS_FL_BLE_ResetParameter(struct FunctionParameterDefine* paras)
{
	switch (AS_Inst.run_step)
	{
	case 0:
	{
		uint8_t device_id = ConverterToFlDeviceId(paras[0].num.uint8_val);
		uint8_t bank_index = paras[1].num.int8_val;
		uint8_t post_data[255] = { 0 };
		uint8_t post_leng = 0;
		uint8_t index = 0;

		post_data[post_leng++] = bank_index;

		if (device_id != DEVICE_OBJ_UNKNOWN)
		{
			AS_FL_BLE_DFU_CommonPackage_Send(1, 0,
				FL_BLE_OPC_PARAM_RESET_REQ,
				device_id,
				0, post_data, post_leng);

			ActionScriptRespondWait(5000);
		}
		else
		{
			AS_Inst.status = ACTION_SCRITP_STATUS_ERROR;
		}
	}
	break;

	default:
	{
		AS_Inst.status = ACTION_SCRITP_STATUS_DONE;
	}
	break;
	}
}


UpgradeStateMsg_p AS_FL_UpgradeStateMsg;

void AS_FL_UpgradeStateMsgBinding(UpgradeStateMsg_p handler)
{
	AS_FL_UpgradeStateMsg = handler;
}

bool AS_FL_UpgradeSetting(uint8_t device_type,uint8_t* device_mid, uint8_t *data, uint32_t leng)
{
	uint32_t index = 0;

	
	DFU_Setting.bin_size = 0;
	DFU_Setting.block_index = 0;
	DFU_Setting.cache_index = 0;
	DFU_Setting.start_index = 0; 
	DFU_Setting.now_index = 0;
	DFU_Setting.end_index = 0;
	DFU_Setting.deviceInfo.block_index = 0;
	DFU_Setting.deviceInfo.cache_size = 0;
	DFU_Setting.deviceInfo.flash_crc = 0;
	DFU_Setting.deviceInfo.flash_size = 0;
	DFU_Setting.deviceInfo.init_data = 0;
	DFU_Setting.deviceInfo.page_size = 0;


	DFU_Setting.target_device = ConverterToFlDeviceId(device_type);

	BLE_DFU_State.enable = false;

	if (DFU_Setting.target_device != DEVICE_OBJ_UNKNOWN)
	{
		for (index = 0; index < 32; index++)
		{
			if (device_mid[index] < ' ' || device_mid[index] > '~')
			{
				DFU_Setting.target_DMID[index] = 0;
			}

			DFU_Setting.target_DMID[index] = device_mid[index];
		}

		for (index = 0; index < leng; index++)
		{
			DFU_Setting.bin_file[index] = data[index];
		}

		DFU_Setting.bin_size = leng;

		return true;
	}
	else
	{
		return false;
	}
		
}



void AS_FL_CANBusUpgradeFirmware(struct FunctionParameterDefine* paras)
{
	static char return_str[1024] = {0};

	memset(return_str, 0, 1024);

	switch (AS_Inst.run_step)
	{
	case 0:
	{
		FL_CAN_DFU_JumpBootloader_Requset(
			DFU_Setting.target_device, 0, 0, 0,
			AS_FL_ActionStepNext, AS_FL_ActionErrorHandler);

		DFU_Setting.identifier = 0x4600 | DFU_Setting.target_device;

		ActionScriptRespondWait(5000);

		if (AS_FL_UpgradeStateMsg)
		{
			sprintf(return_str, "Set device to startup Upgrade.");
			AS_FL_UpgradeStateMsg(return_str, 1);
		}
	}
	break;

	case 1:
	{
		FL_CAN_DFU_ReadDeviceInfomation_Requset(
			DFU_Setting.target_device,
			AS_FL_ActionStepNext, AS_FL_ActionErrorHandler);

		ActionScriptRespondWait(3000);

		if (AS_FL_UpgradeStateMsg)
		{
			sprintf(return_str, "Read device information.");
			AS_FL_UpgradeStateMsg(return_str, 2);
		}
	}
	break;

	case 2:
	{
		FL_CAN_DFU_DeviceInfo_Get(&DFU_Setting.deviceInfo);

		if (DFU_Setting.bin_size > DFU_Setting.deviceInfo.flash_size)
		{
			AS_Inst.status = ACTION_SCRITP_STATUS_ERROR;
			break;
		}

		sprintf(return_str, "Device information Id:0x%4X.", DFU_Setting.identifier);
		AS_FL_UpgradeStateMsg(return_str, 3);

		DFU_Setting.start_index = 0;
		DFU_Setting.end_index = DFU_Setting.bin_size-1;

		if (DFU_Setting.deviceInfo.identifier != DFU_Setting.identifier)
		{
			FL_CAN_DFU_WriteDeviceInformation_Requset(
				DFU_Setting.target_device,
				DFU_Setting.deviceInfo.identifier,
				AS_FL_ActionStepNext, AS_FL_ActionErrorHandler);

			ActionScriptRespondWait(3000);

			if (AS_FL_UpgradeStateMsg)
			{
				sprintf(return_str, "Start at new Upgrade.");
				AS_FL_UpgradeStateMsg(return_str, 4);
			}
		}
		else
		{
			DFU_Setting.start_index = DFU_Setting.deviceInfo.block_index * DFU_Setting.deviceInfo.page_size;

			AS_FL_ActionStepNext();

			if (AS_FL_UpgradeStateMsg)
			{
				sprintf(return_str, "Keep run Upgrade at block.");
				AS_FL_UpgradeStateMsg(return_str, 4);
			}
		}
	}
	break;

	case 3:
	{
		FL_CAN_DFU_EraseFlash_Requset(
			DFU_Setting.target_device, DFU_Setting.start_index, (DFU_Setting.deviceInfo.flash_size - 1),
			AS_FL_ActionStepNext, AS_FL_ActionErrorHandler);

		ActionScriptRespondWait(3000);

		if (AS_FL_UpgradeStateMsg)
		{
			sprintf(return_str, "Earse Device Flash.");
			AS_FL_UpgradeStateMsg(return_str, 5);
		}
	}
	break;

	case 4:
	{
		uint16_t copy_size = 0;

		if (DFU_Setting.start_index <= DFU_Setting.end_index)
		{
			copy_size = (DFU_Setting.end_index - DFU_Setting.start_index) + 1;
		}

		if (copy_size > DFU_Setting.deviceInfo.page_size)
		{
			copy_size = DFU_Setting.deviceInfo.page_size;
		}

		FL_CAN_DFU_WriteToCache_Requset(
			DFU_Setting.target_device,
			0,
			copy_size,
			&DFU_Setting.bin_file[DFU_Setting.start_index],
			AS_FL_ActionStepNext, AS_FL_ActionErrorHandler);

		DFU_Setting.cache_index += copy_size;

		ActionScriptRespondWait(3000);
	}
	break;

	case 5:
	{
		if (DFU_Setting.cache_index >= DFU_Setting.deviceInfo.page_size)
		{
			FL_CAN_DFU_ProgramFlash_Requset(
				DFU_Setting.target_device,
				DFU_Setting.start_index,
				DFU_Setting.deviceInfo.cache_size,
				AS_FL_ActionStepNext, AS_FL_ActionErrorHandler);

			if (AS_FL_UpgradeStateMsg)
			{
				uint32_t proc = (DFU_Setting.start_index * 100) / DFU_Setting.end_index;
				if (proc < 5)
				{
					proc = 5;
				}
				if (proc > 98)
				{
					proc = 98;
				}
				sprintf(return_str, "Write Flash Addr at : 0x%04X.", DFU_Setting.start_index);
				AS_FL_UpgradeStateMsg(return_str, proc);
			}

			ActionScriptRespondWait(3000);
		}
		else
		{
			AS_FL_ActionStepNext();
			AS_Inst.run_step = 4;
		}		
	}
	break;

	case 6:
	{
		DFU_Setting.start_index += DFU_Setting.deviceInfo.cache_size;
		DFU_Setting.cache_index = 0;

		AS_FL_ActionStepNext();

		if (DFU_Setting.start_index <= DFU_Setting.end_index)
		{			
			AS_Inst.run_step = 4;
		}
	}
	break;

	case 7:
	{
		while ((DFU_Setting.bin_size % 4) != 0)
		{
			DFU_Setting.bin_file[DFU_Setting.bin_size++] = DFU_Setting.deviceInfo.init_data;
		}

		FL_CAN_DFU_VerifyFlash_Requset(
			DFU_Setting.target_device, 0, (DFU_Setting.bin_size - 1),
			AS_FL_ActionStepNext, AS_FL_ActionErrorHandler);

		if (AS_FL_UpgradeStateMsg)
		{
			sprintf(return_str, "Verify Flash Start at.");
			AS_FL_UpgradeStateMsg(return_str, 98);
		}

		ActionScriptRespondWait(5000);
	}
	break;

	case 8:
	{
		uint32_t get_crc = FL_CAN_DFU_FlashCRC_Get();
		uint32_t check_crc = FarmlandCalCrc32(DFU_Setting.bin_file, DFU_Setting.bin_size, 0);

		

		if (get_crc == check_crc)
		{
			FL_CAN_DFU_JumpApplication_Requset(
				DFU_Setting.target_device,
				AS_FL_ActionStepNext, AS_FL_ActionErrorHandler);

			if (AS_FL_UpgradeStateMsg)
			{
				sprintf(return_str, "Device Exit DFU mode.");
				AS_FL_UpgradeStateMsg(return_str, 99);
			}

			ActionScriptRespondWait(3000);
		}
		else
		{
			if (AS_FL_UpgradeStateMsg)
			{
				sprintf(return_str, "Verify Flash CRC Fail !.");
				AS_FL_UpgradeStateMsg(return_str, 99);
			}
		}
	}
	break;

	default:
	{
		if (AS_FL_UpgradeStateMsg)
		{
			sprintf(return_str, "Upgrade Done.");
			AS_FL_UpgradeStateMsg(return_str, 100);
		}

		AS_Inst.status = ACTION_SCRITP_STATUS_DONE;
	}
	break;
	}
}



void AS_FL_BLE_DFU_DataPackage_Send(uint8_t frame_size, uint8_t frame_index,
	uint16_t opc, uint8_t target_device, uint8_t response_code, uint8_t* data, uint8_t leng)
{
	BLE_packet_T packet = { 0 };
	uint16_t copy_index = 0;

	packet.frame_size = frame_size;
	packet.frame_index = frame_index;
	packet.opc = opc;
	packet.target_device = target_device;
	packet.response_code = response_code;

	for (copy_index = 0; copy_index < leng; copy_index++)
	{
		packet.data[copy_index] = data[copy_index];
	}
	packet.leng = leng;

	lib_fifo_write(&ble_dfu_data_queue, &packet);

}

int AS_FL_GetBLEData_TxQueue(uint8_t* out_data, uint16_t out_data_size, uint16_t* leng)
{
	uint16_t packet_leng = 0;
	BLE_packet_T tx = { 0 };

	if (lib_fifo_length(&ble_dfu_data_queue) > 0 && out_data != NULL)
	{
		lib_fifo_read(&ble_dfu_data_queue, &tx);

		if (out_data_size >= packet_leng)
		{
			out_data[packet_leng++] = tx.frame_size;
			out_data[packet_leng++] = tx.frame_index;
			out_data[packet_leng++] = (uint8_t)tx.opc;
			out_data[packet_leng++] = (uint8_t)(tx.opc >> 8);
			out_data[packet_leng++] = tx.target_device;
			out_data[packet_leng++] = tx.response_code;

			for (uint16_t index = 0; index < tx.leng; index++)
			{
				out_data[packet_leng++] = tx.data[index];
			}

			*leng = packet_leng;
		}
		else
		{
			return SDK_RETURN_INVALID_SIZE;
		}
		return SDK_RETURN_SUCCESS;
	}
	else
	{
		return SDK_RETURN_NULL;
	}
}


void AS_FL_BLEUpgradeFirmware_GetRespond(uint8_t device, uint16_t opc, uint8_t response_code,
	uint8_t *data, uint16_t leng)
{
	static char return_str[1024] = { 0 };
	memset(return_str, 0, 1024);

	if ((BLE_DFU_State.enable == true) && (BLE_DFU_State.target_device == device) && (DFU_Setting.NowStep == DFU_WAIT_COMMAND))
	{
		switch (opc)
		{
		case FL_BLE_OPC_DFU_READ_DEV_INFO_RES:
		{
			if (BLE_DFU_State.request_code != FL_BLE_OPC_DFU_READ_DEV_INFO_REQ)
			{
				break;
			}
			if (leng >= 12)
			{
				DFU_Setting.end_index = DFU_Setting.bin_size - 1;

				DFU_Setting.deviceInfo.init_data = data[0];
				DFU_Setting.deviceInfo.identifier = data[1] + ((uint16_t)data[2] << 8);
				DFU_Setting.deviceInfo.block_index = data[3] + ((uint16_t)data[4] << 8);
				DFU_Setting.deviceInfo.flash_size = data[5] + ((uint16_t)data[6] << 8) + ((uint16_t)data[7] << 16);
				DFU_Setting.deviceInfo.page_size = data[8] + ((uint16_t)data[9] << 8);
				DFU_Setting.deviceInfo.cache_size = data[10] + ((uint16_t)data[11] << 8);
				AS_FL_ActionStepNext();
				DFU_Setting.NowStep = DFU_IDLE;
			}
		}
		break;

		case FL_BLE_OPC_DFU_WRITE_DEV_INFO_RES:
		{
			if (BLE_DFU_State.request_code != FL_BLE_OPC_DFU_WRITE_DEV_INFO_REQ)
			{
				break;
			}
			AS_FL_ActionStepNext();
			DFU_Setting.NowStep = DFU_IDLE;
		}
		break;

		case FL_BLE_OPC_DFU_WRITE_DATA_FLASH_RES:
		{
			if (BLE_DFU_State.request_code != FL_BLE_OPC_DFU_WRITE_DATA_FLASH_REQ)
			{
				break;
			}

			if (response_code == RESPONSE_SUCCESS)
			{
				DFU_Setting.NowStep = DFU_IDLE;
				AS_FL_ActionStepNext();
			}
			else
			{
				if (response_code == RESPONSE_CRC_FAIL)
				{
					sprintf(return_str, "Write Flash CRC Fail");
				}
			}
			
		}
		break;

		case FL_BLE_OPC_DFU_VERIFY_FLASH_RES:
		{
			if (BLE_DFU_State.request_code != FL_BLE_OPC_DFU_VERIFY_FLASH_REQ)
			{
				break;
			}
			if (leng >= 4)
			{
				uint32_t get_crc = data[0] + ((uint32_t)data[1] << 8) + ((uint32_t)data[2] << 16) + ((uint32_t)data[3] << 24);
				uint32_t cal_start_addr = DFU_Setting.flash_verify.start_addr;
				uint32_t cal_end_addr = DFU_Setting.flash_verify.end_addr;
				uint8_t unused_byte[1] = { DFU_Setting.deviceInfo.init_data };

				if ((cal_end_addr + 1) > DFU_Setting.bin_size)
				{
					cal_end_addr = (DFU_Setting.bin_size - 1);

					DFU_Setting.flash_verify.crc = FarmlandCalCrc32(&DFU_Setting.bin_file[cal_start_addr], ((cal_end_addr- cal_start_addr) + 1), 0);

					cal_start_addr += ((cal_end_addr - cal_start_addr) + 1);
					cal_end_addr = DFU_Setting.flash_verify.end_addr;

					while (cal_start_addr > cal_end_addr)
					{
						DFU_Setting.flash_verify.crc = FarmlandCalCrc32(unused_byte, cal_start_addr, DFU_Setting.flash_verify.crc);
						cal_start_addr++;
					}
				}
				else
				{
					DFU_Setting.flash_verify.crc = FarmlandCalCrc32(&DFU_Setting.bin_file[cal_start_addr], ((cal_end_addr - cal_start_addr) + 1), 0);
				}
				
				if (AS_FL_UpgradeStateMsg)
				{
					sprintf(return_str, "Cal Start ADDR[0x%x] End ADDR[0x%x] PC CRC:0x%x Device CRC:0x%x.", cal_start_addr, cal_end_addr, DFU_Setting.flash_verify.crc, get_crc);
					AS_FL_UpgradeStateMsg(return_str, 98);
				}

				if (DFU_Setting.flash_verify.crc == get_crc)
				{
					DFU_Setting.NowStep = DFU_IDLE;
					AS_FL_ActionStepNext();
				}
				else
				{
					DFU_Setting.NowStep = DFU_IDLE;
				}
				
			}
			
		}
		break;

		case FL_BLE_OPC_DFU_JUMP_COMMOND_RES:
		{
			if (BLE_DFU_State.request_code == FL_BLE_OPC_DFU_JUMP_COMMOND_REQ)
			{
				DFU_Setting.NowStep = DFU_IDLE;
				AS_FL_ActionStepNext();
			}
		}
		break;

		}
	}
}

void AS_FL_BLEUpgradeFirmware(struct FunctionParameterDefine* paras)
{
	static char return_str[1024] = { 0 };
	static uint8_t post_data[4150] = {0};
	uint16_t post_leng = 0;

	memset(return_str, 0, 1024);
	memset(post_data, 0, 4150);

	switch (AS_Inst.run_step)
	{
	case 0:
	{
		// Set Target device Jump to Bootloader
		BLE_DFU_State.enable = true;
		BLE_DFU_State.request_code = FL_BLE_OPC_DFU_JUMP_COMMOND_REQ;
		BLE_DFU_State.target_device = DFU_Setting.target_device;


		post_data[0] = FL_BLE_JUMP_BOOTLOADER;

		BLE_SilenceMode_Set(true, 3);

		AS_FL_BLE_DFU_CommonPackage_Send(1,0, 
			BLE_DFU_State.request_code,
			BLE_DFU_State.target_device,
			0, post_data, 1);

		ActionScriptRespondWaitAndRetry(1000, 3);

		DFU_Setting.NowStep = DFU_WAIT_COMMAND;

		if (AS_FL_UpgradeStateMsg)
		{
			sprintf(return_str, "Set device(%d) to startup Upgrade.", BLE_DFU_State.target_device);
			AS_FL_UpgradeStateMsg(return_str, 1);
		}
	}
	break;

	case 1:
	{
		// Read device information
		BLE_DFU_State.request_code = FL_BLE_OPC_DFU_READ_DEV_INFO_REQ;

		

		AS_FL_BLE_DFU_CommonPackage_Send(1, 0,
			BLE_DFU_State.request_code,
			BLE_DFU_State.target_device,
			0, NULL, 0);

		ActionScriptRespondWait(1000);

		DFU_Setting.NowStep = DFU_WAIT_COMMAND;

		if (AS_FL_UpgradeStateMsg)
		{
			sprintf(return_str, "Read device Information.");
			AS_FL_UpgradeStateMsg(return_str, 2);
		}
	}
	break;


	case 2:
	{
		// Write deivce information & Earse flash
		uint32_t end_addr = (DFU_Setting.deviceInfo.flash_size - 1);
		BLE_DFU_State.request_code = FL_BLE_OPC_DFU_WRITE_DEV_INFO_REQ;

		post_data[post_leng++] = 'B';
		post_data[post_leng++] = 'T';
		post_data[post_leng++] = 0; // Earse Start Addr 7:0
		post_data[post_leng++] = 0; // Earse Start Addr 15:8
		post_data[post_leng++] = 0; // Earse Start Addr 23:16
		post_data[post_leng++] = (uint8_t)end_addr ; // Earse End Addr 7:0
		post_data[post_leng++] = (uint8_t)(end_addr >> 8); // Earse End Addr 15:8
		post_data[post_leng++] = (uint8_t)(end_addr >> 16); // Earse End Addr 23:16

		BLE_SilenceMode_Set(true, 60);
		AS_FL_BLE_DFU_CommonPackage_Send(1, 0,
			BLE_DFU_State.request_code,
			BLE_DFU_State.target_device,
			0, post_data, (uint8_t)post_leng);

		ActionScriptRespondWait(8000);
		DFU_Setting.NowStep = DFU_WAIT_COMMAND;

		if (AS_FL_UpgradeStateMsg)
		{
			sprintf(return_str, "Earse device Flash from 0x%04x to 0x%04x.",0, end_addr);
			AS_FL_UpgradeStateMsg(return_str, 3);
		}
	}
	break;

	case 3:
	{
		// Write firmware file
		uint32_t copy_index = 0;
		uint32_t flash_addr = DFU_Setting.now_index;
		uint32_t flash_write_leng = 0;
		uint32_t crc;
		uint8_t page_size = 1, page_index = 0;

		BLE_DFU_State.request_code = FL_BLE_OPC_DFU_WRITE_DATA_FLASH_REQ;

		if ( (DFU_Setting.now_index + DFU_Setting.deviceInfo.page_size) >= DFU_Setting.bin_size)
		{
			flash_write_leng = DFU_Setting.bin_size - DFU_Setting.now_index;
		}
		else
		{
			flash_write_leng = DFU_Setting.deviceInfo.page_size;
		}

		copy_index = 0;
		post_leng = 0;
		post_data[post_leng++] = (uint8_t)flash_addr;
		post_data[post_leng++] = (uint8_t)(flash_addr >> 8);
		post_data[post_leng++] = (uint8_t)(flash_addr >> 16);
		post_data[post_leng++] = (uint8_t)flash_write_leng;
		post_data[post_leng++] = (uint8_t)(flash_write_leng >> 8);

		for (copy_index = 0 ; copy_index < flash_write_leng ; copy_index++)
		{
			post_data[post_leng++] = DFU_Setting.bin_file[DFU_Setting.now_index++];
		}

		crc = FarmlandCalCrc32(post_data, post_leng, 0);

		post_data[post_leng++] = (uint8_t)crc;
		post_data[post_leng++] = (uint8_t)(crc >> 8);
		post_data[post_leng++] = (uint8_t)(crc >> 16);
		post_data[post_leng++] = (uint8_t)(crc >> 24);

		page_size = (post_leng / BLE_DFU_DATA_SIZE);

		if ((post_leng % BLE_DFU_DATA_SIZE) != 0)
		{
			page_size++;
		}

		copy_index = 0;

		while (page_size > page_index)
		{
			if ((post_leng - copy_index) >= BLE_DFU_DATA_SIZE)
			{
				AS_FL_BLE_DFU_DataPackage_Send(page_size, page_index,
					FL_BLE_OPC_DFU_WRITE_DATA_FLASH_REQ,
					BLE_DFU_State.target_device,
					0, &post_data[copy_index], BLE_DFU_DATA_SIZE);

				copy_index += BLE_DFU_DATA_SIZE;
			}
			else
			{
				AS_FL_BLE_DFU_DataPackage_Send(page_size, page_index,
					FL_BLE_OPC_DFU_WRITE_DATA_FLASH_REQ,
					BLE_DFU_State.target_device,
					0, &post_data[copy_index], (post_leng - copy_index));

				copy_index += (post_leng - copy_index);
			}

			page_index++;
		}
		
		ActionScriptRespondWait(3000);
		DFU_Setting.NowStep = DFU_WAIT_COMMAND;

		if (AS_FL_UpgradeStateMsg)
		{
			uint32_t proc = (DFU_Setting.now_index * 100) / DFU_Setting.bin_size;
			if (proc < 5)
			{
				proc = 5;
			}
			if (proc > 98)
			{
				proc = 98;
			}
			sprintf(return_str, "Write Flash Addr at : 0x%04X.", DFU_Setting.now_index);
			AS_FL_UpgradeStateMsg(return_str, proc);
		}
	}
	break;

	case 4:
	{
		
		// Wrtie flash not all done
		if (DFU_Setting.now_index < DFU_Setting.end_index)
		{
			AS_Inst.run_step--;
		}
		else
		{
			// Verify flash data

			DFU_Setting.flash_verify.start_addr = 0;
			DFU_Setting.flash_verify.end_addr = DFU_Setting.bin_size - 1;
			BLE_DFU_State.request_code = FL_BLE_OPC_DFU_VERIFY_FLASH_REQ;
			post_data[post_leng++] = (uint8_t)DFU_Setting.flash_verify.start_addr;
			post_data[post_leng++] = (uint8_t)(DFU_Setting.flash_verify.start_addr >> 8);
			post_data[post_leng++] = (uint8_t)(DFU_Setting.flash_verify.start_addr >> 16);
			post_data[post_leng++] = (uint8_t)DFU_Setting.flash_verify.end_addr;
			post_data[post_leng++] = (uint8_t)(DFU_Setting.flash_verify.end_addr >> 8);
			post_data[post_leng++] = (uint8_t)(DFU_Setting.flash_verify.end_addr >> 16);

			AS_FL_BLE_DFU_CommonPackage_Send(1, 0,
				BLE_DFU_State.request_code,
				BLE_DFU_State.target_device,
				0, post_data, (uint8_t)post_leng);

			ActionScriptRespondWait(15000);
			DFU_Setting.NowStep = DFU_WAIT_COMMAND;

			if (AS_FL_UpgradeStateMsg)
			{
				sprintf(return_str, "Get CRC.");
				AS_FL_UpgradeStateMsg(return_str, 98);
			}
		}
	}
	break;

	case 5:
	{
		// Jump to Application
		BLE_DFU_State.request_code = FL_BLE_OPC_DFU_JUMP_COMMOND_REQ;
		post_data[0] = FL_BLE_JUMP_APPLICATION;
		
		AS_FL_BLE_DFU_CommonPackage_Send(1, 0,
			BLE_DFU_State.request_code,
			BLE_DFU_State.target_device,
			0, post_data, 1);		

		ActionScriptRespondWaitAndRetry(1000,3);
		DFU_Setting.NowStep = DFU_WAIT_COMMAND;

		if (AS_FL_UpgradeStateMsg)
		{
			sprintf(return_str, "Exit DFU mode.");
			AS_FL_UpgradeStateMsg(return_str, 99);
		}
	}
	break;

	default:
	{
		AS_Inst.status = ACTION_SCRITP_STATUS_DONE;

		BLE_SilenceMode_Set(false, 0);

		if (AS_FL_UpgradeStateMsg)
		{
			sprintf(return_str, "Done.");
			AS_FL_UpgradeStateMsg(return_str, 100);
		}
	}
	break;

	}
}


void AS_FL_CANBus_SetDebugMode(struct FunctionParameterDefine* paras)
{
	switch (AS_Inst.run_step)
	{
	case 0:
	{
		DeviceObjTypes device_id = ConverterToFlDeviceId(paras[0].num.uint8_val);
		uint8_t debug_index = paras[1].num.uint8_val;
		uint8_t debug_count = paras[2].num.uint8_val;
		uint16_t interval_time = paras[3].num.uint16_val;

		if (device_id != DEVICE_OBJ_UNKNOWN)
		{
			FL_CAN_HostCommon_DebugReq_Send(
				device_id,
				debug_index,
				debug_count,
				interval_time,
				AS_FL_ActionStepNext,
				AS_FL_ActionErrorHandler);

			ActionScriptRespondWait(5000);
		}
		else
		{
			AS_Inst.status = ACTION_SCRITP_STATUS_ERROR;
		}		
	}
	break;

	default:
	{
		BLE_DFU_State.enable = false;
		AS_Inst.status = ACTION_SCRITP_STATUS_DONE;
	}
	break;
	}
}



void AS_FL_BLE_SetDebugMode(struct FunctionParameterDefine* paras)
{
	switch (AS_Inst.run_step)
	{
	case 0:
	{
		uint8_t post_data[32] = { 0 };
		uint8_t post_leng = 0;
		DeviceObjTypes device_id = ConverterToFlDeviceId(paras[0].num.uint8_val);
		uint8_t debug_index = paras[1].num.uint8_val;
		uint8_t debug_count = paras[2].num.uint8_val;
		uint16_t interval_time = paras[3].num.uint16_val;
		uint8_t path = paras[4].num.uint8_val; 

		if (device_id != DEVICE_OBJ_UNKNOWN)
		{
			post_data[post_leng++] = FL_CANID_HOST_DEVICE_DEBUG_REQ;
			post_data[post_leng++] = (uint8_t)(FL_CANID_HOST_DEVICE_DEBUG_REQ >> 8);
			post_data[post_leng++] = (uint8_t)(FL_CANID_HOST_DEVICE_DEBUG_REQ >> 16);
			post_data[post_leng++] = (uint8_t)(FL_CANID_HOST_DEVICE_DEBUG_REQ >> 24);
			post_data[post_leng++] = device_id;
			post_data[post_leng++] = debug_index;
			post_data[post_leng++] = debug_count;
			post_data[post_leng++] = (uint8_t)interval_time;
			post_data[post_leng++] = (uint8_t)(interval_time >> 8);

			if (path == 0)
			{
				AS_FL_BLE_DFU_CommonPackage_Send(1, 0,
					FL_BLE_OPC_CAN_PASS_DATA_REQ,
					0,
					0, post_data, (uint8_t)post_leng);
			}
			else
				Mst_can_pass((MST_SEND_PATH)path, FL_CANID_HOST_DEVICE_RESET_REQ, false, &post_data[4], post_leng - 4); 

			ActionScriptRespondWait(5000);
		}
		else
		{
			AS_Inst.status = ACTION_SCRITP_STATUS_ERROR;
		}
	}
	break;

	default:
	{
		BLE_DFU_State.enable = false;
		AS_Inst.status = ACTION_SCRITP_STATUS_DONE;
	}
	break;
	}
}



void AS_FL_CANBus_SetTestMode(struct FunctionParameterDefine* paras)
{
	switch (AS_Inst.run_step)
	{
	case 0:
	{
		DeviceObjTypes device_id = ConverterToFlDeviceId(paras[0].num.uint8_val);
		uint8_t test_mode = paras[1].num.uint8_val;
		uint32_t test_value = paras[2].num.uint32_val;

		if (device_id != DEVICE_OBJ_UNKNOWN)
		{
			FL_CAN_HostCommon_TestReq_Send(
				device_id,
				test_mode,
				test_value,
				AS_FL_ActionStepNext,
				AS_FL_ActionErrorHandler);

			ActionScriptRespondWait(5000);
		}
		else
		{
			AS_Inst.status = ACTION_SCRITP_STATUS_ERROR;
		}		
	}
	break;

	default:
	{
		AS_Inst.status = ACTION_SCRITP_STATUS_DONE;
	}
	break;
	}
}





void AS_FL_BLE_SetTestMode(struct FunctionParameterDefine* paras)
{
	switch (AS_Inst.run_step)
	{
	case 0:
	{
		uint8_t post_data[32] = {0};
		uint8_t post_leng = 0;
		DeviceObjTypes device_id = ConverterToFlDeviceId(paras[0].num.uint8_val);
		uint8_t test_mode = paras[1].num.uint8_val;
		uint32_t test_value = paras[2].num.uint32_val;
		uint8_t path = paras[4].num.uint8_val; 

		if (device_id != DEVICE_OBJ_UNKNOWN)
		{
			post_data[post_leng++] = FL_CANID_HOST_DEVICE_TEST_REQ;
			post_data[post_leng++] = (uint8_t)(FL_CANID_HOST_DEVICE_TEST_REQ >> 8);
			post_data[post_leng++] = (uint8_t)(FL_CANID_HOST_DEVICE_TEST_REQ >> 16);
			post_data[post_leng++] = (uint8_t)(FL_CANID_HOST_DEVICE_TEST_REQ >> 24);
			post_data[post_leng++] = device_id;
			post_data[post_leng++] = test_mode;
			post_data[post_leng++] = test_value;
			post_data[post_leng++] = (uint8_t)(test_value >> 8);
			post_data[post_leng++] = (uint8_t)(test_value >> 16);
			post_data[post_leng++] = (uint8_t)(test_value >> 24);

			if (path == 0)
			{
				AS_FL_BLE_DFU_CommonPackage_Send(1, 0,
					FL_BLE_OPC_CAN_PASS_DATA_REQ,
					0,
					0, post_data, (uint8_t)post_leng);
			}
			else
				Mst_can_pass((MST_SEND_PATH)path, FL_CANID_HOST_DEVICE_RESET_REQ, false, &post_data[4], post_leng - 4); 

			ActionScriptRespondWait(500);
		}
		else
		{
			AS_Inst.status = ACTION_SCRITP_STATUS_ERROR;
		}
	}
	break;

	default:
	{
		AS_Inst.status = ACTION_SCRITP_STATUS_DONE;
	}
	break;
	}
}


void AS_FL_CANBus_RestartDevice(struct FunctionParameterDefine* paras)
{


}


void AS_FL_BLE_RestartDevice_GetRespond(void)
{
	AS_FL_ActionStepNext();
}

void AS_FL_BLE_RestartDevice(struct FunctionParameterDefine* paras)
{
	switch (AS_Inst.run_step)
	{
	case 0:
	default:
	{
		uint8_t post_data[32] = { 0 };
		uint8_t post_leng = 0;
		DeviceObjTypes device_id = ConverterToFlDeviceId(paras[0].num.uint8_val);
		uint8_t test_mode = paras[1].num.uint8_val;
		uint32_t test_value = paras[2].num.uint32_val;
		uint8_t path = paras[4].num.uint8_val;

		if (device_id != DEVICE_OBJ_UNKNOWN)
		{
			post_data[post_leng++] = FL_CANID_HOST_DEVICE_RESET_REQ;
			post_data[post_leng++] = (uint8_t)(FL_CANID_HOST_DEVICE_RESET_REQ >> 8);
			post_data[post_leng++] = (uint8_t)(FL_CANID_HOST_DEVICE_RESET_REQ >> 16);
			post_data[post_leng++] = (uint8_t)(FL_CANID_HOST_DEVICE_RESET_REQ >> 24);
			post_data[post_leng++] = device_id;

			if (path == 0)
			{
				AS_FL_BLE_DFU_CommonPackage_Send(1, 0,
					FL_BLE_OPC_CAN_PASS_DATA_REQ,
					0,
					0, post_data, post_leng);
			}
			else
				Mst_can_pass((MST_SEND_PATH)path, FL_CANID_HOST_DEVICE_RESET_REQ,  false, &post_data[4], post_leng - 4);

			FL_CAN_HostCommon_RegResponseHandler(device_id, 
				FL_CANID_HOST_DEVICE_RESET_REQ, 
				AS_FL_BLE_RestartDevice_GetRespond);

			AS_Inst.status = ACTION_SCRITP_STATUS_DONE;
		}
		else
		{
			AS_Inst.status = ACTION_SCRITP_STATUS_ERROR;
		}
	}
	break;

	}
}

 void BLE_light_control(struct FunctionParameterDefine* paras)
{
	switch (AS_Inst.run_step)
	{
	case 0:
	{
		uint8_t post_data[10] = { 0 };
		uint8_t post_leng = 0;
		HOST_CONTROLINFO_00_T info = { 0 };

		light_control_parts parts = (light_control_parts)paras[0].num.uint8_val;
		bool on_off = paras[1].num.uint8_val;

		info.bits.set_assist_level = 0xF;
		info.bits.system_power_control = 0xF;
		info.bits.walk_assist_control = 0xF;
		info.bits.front_light_control = parts == LIGHT_CONTROL_FRONT ? on_off : 0xF;
		info.bits.rear_light_control = parts == LIGHT_CONTROL_REAR ? on_off : 0xF;

		post_data[post_leng++] = FL_CANID_HOST_INFO_00;
		post_data[post_leng++] = (uint8_t)(FL_CANID_HOST_INFO_00 >> 8);
		post_data[post_leng++] = (uint8_t)(FL_CANID_HOST_INFO_00 >> 16);
		post_data[post_leng++] = (uint8_t)(FL_CANID_HOST_INFO_00 >> 24);

		post_data[post_leng++] = info.bytes[0];
		post_data[post_leng++] = info.bytes[1];
		post_data[post_leng++] = info.bytes[2];

		AS_FL_BLE_DFU_CommonPackage_Send(1, 0,
			FL_BLE_OPC_CAN_PASS_DATA_REQ,
			DEVICE_OBJ_CONTROLLER, 
			0, post_data, post_leng);
		AS_Inst.status = ACTION_SCRITP_STATUS_DONE;
	}
	break;
	default:
	{
	}
	break;
	}
	 

}

 void BLE_ClearTripInfo(struct FunctionParameterDefine* paras)  
 {
	 switch (AS_Inst.run_step)
	 {
	 case 0:
	 {
		 uint8_t post_data[10] = { 0 };
		 uint8_t post_leng = 0;
		 HOST_DEVICE_TRIP_RESET_T info = { 0 };

		 info.bits.reset_enable = 1;

		 post_data[post_leng++] = FL_CANID_HOST_TRIP_RESET;
		 post_data[post_leng++] = (uint8_t)(FL_CANID_HOST_TRIP_RESET >> 8);
		 post_data[post_leng++] = (uint8_t)(FL_CANID_HOST_TRIP_RESET >> 16);
		 post_data[post_leng++] = (uint8_t)(FL_CANID_HOST_TRIP_RESET >> 24);

		 post_data[post_leng++] = info.bytes[0];

		 AS_FL_BLE_DFU_CommonPackage_Send(1, 0,
			 FL_BLE_OPC_CAN_PASS_DATA_REQ,
			 DEVICE_OBJ_CONTROLLER,
			 0, post_data, post_leng);
		 AS_Inst.status = ACTION_SCRITP_STATUS_DONE;
	 }
	 break;
	 default:
	 {
	 }
	 break;
	 }
 }



void AS_FL_BLE_ConfigSysTime(struct FunctionParameterDefine* paras)
{
	switch (AS_Inst.run_step)
	{
	case 0:
	{
		uint8_t post_data[32] = { 0 };
		uint8_t post_leng = 0;
		DeviceObjTypes device_id = ConverterToFlDeviceId(paras[0].num.uint8_val);
		uint64_t unix_time = paras[1].num.uint64_val;

		if (device_id != DEVICE_OBJ_UNKNOWN)
		{
			post_data[post_leng++] = FL_CANID_HOST_INFO_01;
			post_data[post_leng++] = (uint8_t)(FL_CANID_HOST_INFO_01 >> 8);
			post_data[post_leng++] = (uint8_t)(FL_CANID_HOST_INFO_01 >> 16);
			post_data[post_leng++] = (uint8_t)(FL_CANID_HOST_INFO_01 >> 24);

			post_data[post_leng++] = (uint8_t)(unix_time >> 0);
			post_data[post_leng++] = (uint8_t)(unix_time >> 8);
			post_data[post_leng++] = (uint8_t)(unix_time >> 16);
			post_data[post_leng++] = (uint8_t)(unix_time >> 24);
			post_data[post_leng++] = (uint8_t)(unix_time >> 32);
			post_data[post_leng++] = (uint8_t)(unix_time >> 48);
			post_data[post_leng++] = (uint8_t)(unix_time >> 52);

			AS_FL_BLE_DFU_CommonPackage_Send(1, 0,
				FL_BLE_OPC_CAN_PASS_DATA_REQ,
				0,
				0, post_data, post_leng);

			AS_Inst.status = ACTION_SCRITP_STATUS_DONE;
		}
		else
		{
			AS_Inst.status = ACTION_SCRITP_STATUS_ERROR;
		}
	}
	break;
	}
}


void AS_FL_BLE_SetELock_DEV(struct FunctionParameterDefine* paras)
{
	switch (AS_Inst.run_step)
	{
	case 0:
	{
		uint8_t post_data[32] = { 0 };
		uint8_t post_leng = 0;

		uint8_t release = ConverterToFlDeviceId(paras[0].num.uint8_val);
		uint8_t unlock = ConverterToFlDeviceId(paras[1].num.uint8_val);

		post_data[post_leng++] = (uint8_t)FL_CANID_ELOCK_COMMAND;
		post_data[post_leng++] = (uint8_t)(FL_CANID_ELOCK_COMMAND >> 8);
		post_data[post_leng++] = (uint8_t)(FL_CANID_ELOCK_COMMAND >> 16);
		post_data[post_leng++] = (uint8_t)(FL_CANID_ELOCK_COMMAND >> 24);

		if (release)
		{
			post_data[post_leng++] = 0x80; // Start Byte
			post_data[post_leng++] = 0x10; // Release Command
			post_data[post_leng++] = 0x00; // Data[0]
			post_data[post_leng++] = 0x00; // Data[1]
			post_data[post_leng++] = 0x00; // Data[2]
			post_data[post_leng++] = 0x00; // Data[3]
			post_data[post_leng++] = 0xFF; // Count
			post_data[post_leng++] = ELockCalCheckSum(&post_data[4], 7);
		}
		else if (unlock)
		{
			post_data[post_leng++] = 0x80; // Start Byte
			post_data[post_leng++] = 0x20; // Unlock Command
			post_data[post_leng++] = 0x00; // Data[0]
			post_data[post_leng++] = 0x00; // Data[1]
			post_data[post_leng++] = 0x00; // Data[2]
			post_data[post_leng++] = 0x00; // Data[3]
			post_data[post_leng++] = 0xFF; // Count
			post_data[post_leng++] = ELockCalCheckSum(&post_data[4], 7);
		}
		else
		{
			AS_Inst.status = ACTION_SCRITP_STATUS_TIMEOUT;
			break;
		}

		AS_FL_BLE_DFU_CommonPackage_Send(1, 0,
			FL_BLE_OPC_CAN_PASS_DATA_REQ,
			0,
			0, post_data, post_leng);

		AS_Inst.status = ACTION_SCRITP_STATUS_DONE;
	}
	break;
	}
}



void AS_FL_BLE_GetELock_DEV(struct FunctionParameterDefine* paras)
{
	switch (AS_Inst.run_step)
	{
	case 0:
	{
		uint8_t post_data[32] = { 0 };
		uint8_t post_leng = 0;
		post_data[post_leng++] = (uint8_t)FL_CANID_ELOCK_COMMAND;
		post_data[post_leng++] = (uint8_t)(FL_CANID_ELOCK_COMMAND >> 8);
		post_data[post_leng++] = (uint8_t)(FL_CANID_ELOCK_COMMAND >> 16);
		post_data[post_leng++] = (uint8_t)(FL_CANID_ELOCK_COMMAND >> 24);

		post_data[post_leng++] = 0x80; // Start Byte
		post_data[post_leng++] = 0x30; // Read status Command
		post_data[post_leng++] = 0x00; // Data[0]
		post_data[post_leng++] = 0x00; // Data[1]
		post_data[post_leng++] = 0x00; // Data[2]
		post_data[post_leng++] = 0x00; // Data[3]
		post_data[post_leng++] = 0xFF; // Count
		post_data[post_leng++] = ELockCalCheckSum(&post_data[4], 7);

		AS_FL_BLE_DFU_CommonPackage_Send(1, 0,
			FL_BLE_OPC_CAN_PASS_DATA_REQ,
			0,
			0, post_data, post_leng);

		FL_BLE_ReadELockStatus_Requset(AS_FL_ActionStepNext);
		ActionScriptRespondWait(1000);
	}
	break;

	default:
		AS_Inst.status = ACTION_SCRITP_STATUS_DONE;
		break;
	}
}



uint32_t AS_FL_GetDeviceLogs_Inst(DeviceLogs_T* logs_list)
{
	logs_list = &deviceLogs.list[0];
	return deviceLogs.count;
}

void AS_FL_BLE_ReadDeviceLogs_GetRespond(uint8_t device, uint16_t opc, uint8_t response_code, uint8_t* data, uint16_t leng)
{
	uint32_t get_crc = 0;
	if (opc == FL_BLE_OPC_LOG_READ_RES && leng >= 68)
	{
		if (deviceLogs.count >= MAX_DEVICE_LOGS_SIZE)
		{
			AS_FL_ActionStepNext();
		}
		deviceLogs.list[deviceLogs.count].index = data[0] + ((uint16_t)data[1] << 8);
		deviceLogs.list[deviceLogs.count].dateTime_year = data[2];
		deviceLogs.list[deviceLogs.count].dateTime_month = data[3];
		deviceLogs.list[deviceLogs.count].dateTime_days = data[4];
		deviceLogs.list[deviceLogs.count].dateTime_hour = data[5];
		deviceLogs.list[deviceLogs.count].dateTime_minute = data[6];
		deviceLogs.list[deviceLogs.count].dateTime_senond = data[7];
		deviceLogs.list[deviceLogs.count].odo = data[8] + ((uint32_t)data[9] << 8) + ((uint32_t)data[10] << 16) + ((uint32_t)data[11] << 24);
		deviceLogs.list[deviceLogs.count].charge_fet_on = (data[12] & 0x01) != 0 ? true : false;
		deviceLogs.list[deviceLogs.count].charging = (data[12] & 0x02) != 0 ? true : false;
		deviceLogs.list[deviceLogs.count].fully_charged = (data[12] & 0x04) != 0 ? true : false;
		deviceLogs.list[deviceLogs.count].charge_detected = (data[12] & 0x08) != 0 ? true : false;
		deviceLogs.list[deviceLogs.count].discharge_fet = (data[12] & 0x10) != 0 ? true : false;
		deviceLogs.list[deviceLogs.count].discharging = (data[12] & 0x20) != 0 ? true : false;
		deviceLogs.list[deviceLogs.count].nearly_discharged = (data[12] & 0x40) != 0 ? true : false;
		deviceLogs.list[deviceLogs.count].fully_discharged = (data[12] & 0x80) != 0 ? true : false;
		deviceLogs.list[deviceLogs.count].error_code[0] = data[13];
		deviceLogs.list[deviceLogs.count].error_code[1] = data[14];
		deviceLogs.list[deviceLogs.count].error_code[2] = data[15];
		deviceLogs.list[deviceLogs.count].error_code[3] = data[16];
		deviceLogs.list[deviceLogs.count].error_code[4] = data[17];
		deviceLogs.list[deviceLogs.count].error_code[5] = data[18];
		deviceLogs.list[deviceLogs.count].error_code[6] = data[19];
		deviceLogs.list[deviceLogs.count].error_code[7] = data[20];

		deviceLogs.list[deviceLogs.count].cell_count = data[21];
		deviceLogs.list[deviceLogs.count].cell_volt[0] = data[22] + ((uint16_t)data[23] << 8);
		deviceLogs.list[deviceLogs.count].cell_volt[1] = data[24] + ((uint16_t)data[25] << 8);
		deviceLogs.list[deviceLogs.count].cell_volt[2] = data[26] + ((uint16_t)data[27] << 8);
		deviceLogs.list[deviceLogs.count].cell_volt[3] = data[28] + ((uint16_t)data[29] << 8);
		deviceLogs.list[deviceLogs.count].cell_volt[4] = data[30] + ((uint16_t)data[31] << 8);
		deviceLogs.list[deviceLogs.count].cell_volt[5] = data[32] + ((uint16_t)data[33] << 8);
		deviceLogs.list[deviceLogs.count].cell_volt[6] = data[34] + ((uint16_t)data[35] << 8);
		deviceLogs.list[deviceLogs.count].cell_volt[7] = data[36] + ((uint16_t)data[37] << 8);
		deviceLogs.list[deviceLogs.count].cell_volt[8] = data[38] + ((uint16_t)data[39] << 8);
		deviceLogs.list[deviceLogs.count].cell_volt[9] = data[40] + ((uint16_t)data[41] << 8);
		deviceLogs.list[deviceLogs.count].cell_volt[10] = data[42] + ((uint16_t)data[43] << 8);
		deviceLogs.list[deviceLogs.count].cell_volt[11] = data[44] + ((uint16_t)data[45] << 8);
		deviceLogs.list[deviceLogs.count].cell_volt[12] = data[46] + ((uint16_t)data[47] << 8);
		deviceLogs.list[deviceLogs.count].cell_volt[13] = data[48] + ((uint16_t)data[49] << 8);
		deviceLogs.list[deviceLogs.count].cell_volt[14] = data[50] + ((uint16_t)data[51] << 8);
		deviceLogs.list[deviceLogs.count].cell_volt[15] = data[52] + ((uint16_t)data[53] << 8);

		deviceLogs.list[deviceLogs.count].temp_sensor_count = data[54];
		deviceLogs.list[deviceLogs.count].temp_sensor[0] = data[55];
		deviceLogs.list[deviceLogs.count].temp_sensor[1] = data[56];
		deviceLogs.list[deviceLogs.count].temp_sensor[2] = data[57];

		deviceLogs.list[deviceLogs.count].bike_speed = data[58] + ((uint16_t)data[59] << 8);
		deviceLogs.list[deviceLogs.count].motor_speed = data[60] + ((uint16_t)data[61] << 8);
		deviceLogs.list[deviceLogs.count].RSOC = data[62];
		deviceLogs.list[deviceLogs.count].assist_lv = data[63];
		deviceLogs.list[deviceLogs.count].controller_avg_output = data[64];

		get_crc = data[65] + ((uint32_t)data[66] << 8) + ((uint32_t)data[67] << 16) + ((uint32_t)data[68] << 24);

		deviceLogs.count++;
		AS_FL_ActionStepNext();
	}
	
}

void AS_FL_BLE_ReadDeviceLogs(struct FunctionParameterDefine* paras)
{
	uint8_t post_data[32] = { 0 };
	uint8_t post_leng = 0;
	DeviceObjTypes device_id = ConverterToFlDeviceId(paras[0].num.uint8_val);

	switch (AS_Inst.run_step)
	{
	case 0:
	{
		deviceLogs.count = 0;

		if (device_id != DEVICE_OBJ_UNKNOWN)
		{
			deviceLogs.list[deviceLogs.count].cell_count = 0;
			deviceLogs.list[deviceLogs.count].temp_sensor_count = 0;

			post_data[post_leng++] = (uint8_t)deviceLogs.count;
			post_data[post_leng++] = (uint8_t)(deviceLogs.count >> 8);

			AS_FL_BLE_DFU_CommonPackage_Send(1, 0,
				FL_BLE_OPC_LOG_READ_REQ,
				device_id,
				0, post_data, (uint8_t)post_leng);

			ActionScriptRespondWait(2000);
		}
		else
		{
			AS_Inst.status = ACTION_SCRITP_STATUS_ERROR;
		}
	}
	break;


	case 1:
	{
		if (deviceLogs.count == 0)
		{
			AS_Inst.status = ACTION_SCRITP_STATUS_DONE;
		}
		else
		{
			post_data[post_leng++] = (uint8_t)deviceLogs.count;
			post_data[post_leng++] = (uint8_t)(deviceLogs.count >> 8);

			AS_FL_BLE_DFU_CommonPackage_Send(1, 0,
				FL_BLE_OPC_LOG_READ_REQ,
				device_id,
				0, post_data, (uint8_t)post_leng);

			ActionScriptRespondWait(2000);
		}
		
	}
	break;

	case 2:
	{
		if (deviceLogs.list[(deviceLogs.count-1)].cell_count != 0)
		{
			if (deviceLogs.count >= MAX_DEVICE_LOGS_SIZE)
			{
				AS_Inst.status = ACTION_SCRITP_STATUS_DONE;
			}
			else
			{
				deviceLogs.list[deviceLogs.count].cell_count = 0;
				deviceLogs.list[deviceLogs.count].temp_sensor_count = 0;
				AS_Inst.run_step--;
			}
		}
		else
		{
			AS_Inst.status = ACTION_SCRITP_STATUS_DONE;
		}
	}
	break;

	default:
	{
		AS_Inst.status = ACTION_SCRITP_STATUS_DONE;
	}
	break;
	}
}


void AS_FL_BLE_ClearDeviceLogs_GetRespond(uint8_t device, uint16_t opc, uint8_t response_code, uint8_t* data, uint16_t leng)
{
	if (opc == FL_BLE_OPC_LOG_CLEAR_RES)
	{
		AS_FL_ActionStepNext();
	}
}


void AS_FL_BLE_ClearDeviceLogs(struct FunctionParameterDefine* paras)
{
	uint8_t post_data[32] = { 0 };
	uint8_t post_leng = 0;
	DeviceObjTypes device_id = ConverterToFlDeviceId(paras[0].num.uint8_val);

	switch (AS_Inst.run_step)
	{
	case 0:
	{
		deviceLogs.count = 0;

		if (device_id != DEVICE_OBJ_UNKNOWN)
		{
			
			AS_FL_BLE_DFU_CommonPackage_Send(1, 0,
				FL_BLE_OPC_LOG_CLEAR_REQ,
				device_id,
				0, post_data, 0);

			ActionScriptRespondWait(2000);
		}
		else
		{
			AS_Inst.status = ACTION_SCRITP_STATUS_ERROR;
		}
	}
	break;


	default:
	{
		deviceLogs.list[deviceLogs.count].cell_count = 0;
		AS_Inst.status = ACTION_SCRITP_STATUS_DONE;
	}
	break;
	}
}

