#pragma once

#ifndef _ACTION_SCRIPT_H // include guard
#define _ACTION_SCRIPT_H


#include "CoreSDK.h"

#define FUNCTION_PARAM_SIZE	12

#ifdef __cplusplus
extern "C" {
#endif
	 
	enum ActionScritpStatus
	{
		ACTION_SCRITP_STATUS_IDLE = 0U,
		ACTION_SCRITP_STATUS_RUNNING,
		ACTION_SCRITP_STATUS_DONE,
		ACTION_SCRITP_STATUS_ERROR,
		ACTION_SCRITP_STATUS_TIMEOUT,
		ACTION_SCRITP_STATUS_RESPOND_WAIT,
		ACTION_SCRITP_STATUS_WAIT,
	};

	enum ParameterTypeDefine
	{
		PARA_TYPE_UINT64 = 0U,
		PARA_TYPE_INT64,
		PARA_TYPE_UINT32,
		PARA_TYPE_INT32,
		PARA_TYPE_UINT16,
		PARA_TYPE_INT16,
		PARA_TYPE_UINT8,
		PARA_TYPE_INT8,
		PARA_TYPE_BYTE_ARRAY,
		PARA_TYPE_FLOAT,
		PARA_TYPE_DEVICE_TYPE,
	};

	union ParameterNumberUnion
	{
		uint64_t uint64_val;
		uint32_t uint32_val;
		uint16_t uint16_val;
		uint8_t uint8_val;
		int64_t int64_val;
		int32_t int32_val;
		int16_t int16_val;
		int8_t int8_val;
		float float_val;
		double double_val;
	};

	union CAN_Id_define
	{
		uint8_t Bytes[4];
		struct
		{
			uint32_t id : 31;
			uint32_t is_extender : 1;
		}Bits;
	};

	struct CANBypass_IdList
	{
		uint8_t mode;
		uint8_t function_code;
		uint8_t count;
		union CAN_Id_define list[64];
	};

#pragma pack(push)
#pragma pack(8)

	struct FunctionParameterDefine
	{
		enum ParameterTypeDefine type;
		union ParameterNumberUnion num;
		uint8_t *buff;
		uint32_t buff_leng;
		void (*set_value)(enum ParameterTypeDefine type, union ParameterNumberUnion num);
	};

	typedef void (*ScriptFunction)(struct FunctionParameterDefine* paras);

	typedef void (ActionFinally_Callback)(struct FunctionParameterDefine* action_param);
	typedef void (ActionError_Callback)(struct FunctionParameterDefine* action_param, uint32_t err_code);

	typedef struct ActionDefine_st
	{
		struct FunctionParameterDefine paras[FUNCTION_PARAM_SIZE];
		ScriptFunction run_script;
		ActionFinally_Callback *finally_callback;
		ActionError_Callback *error_callback;
	} ACTION_DEFINE_T;

#pragma pack(pop)

	void ActionScript_timer_1ms_tick(void);

	void AS_FL_CANBus_ReadParameter(struct FunctionParameterDefine* paras);
	void AS_FL_BLE_ReadParam_GetRespond(uint8_t device, uint16_t opc, uint8_t response_code,
		uint8_t* data, uint16_t leng);
	void AS_FL_BLE_ReadParameter(struct FunctionParameterDefine* paras);
	void AS_FL_CANBus_WriteParameter(struct FunctionParameterDefine* paras);

	void AS_FL_BLE_Copy_CanIdBytpassList(struct CANBypass_IdList* id_list);
	void AS_FL_BLE_GetCanIdBypassList_GetRespond(uint8_t device, uint16_t opc, uint8_t response_code, uint8_t* data, uint16_t leng);
	void AS_FL_BLE_GetCanIdBypassList(struct FunctionParameterDefine* paras);

	void AS_FL_BLE_SetCanIdBypassAllowList_GetRespond(uint8_t device, uint16_t opc, uint8_t response_code, uint8_t* data, uint16_t leng);
	void AS_FL_BLE_SetCanIdBypassAllowList(struct FunctionParameterDefine* paras);

	void AS_FL_BLE_SetCanIdBypassBlockList_GetRespond(uint8_t device, uint16_t opc, uint8_t response_code, uint8_t* data, uint16_t leng);
	void AS_FL_BLE_SetCanIdBypassBlockList(struct FunctionParameterDefine* paras);

	void AS_FL_BLE_WriteParam_GetRespond(uint8_t device, uint16_t opc, uint8_t response_code, uint8_t* data, uint16_t leng);
	void AS_FL_BLE_WriteParameter(struct FunctionParameterDefine* paras);

	void AS_FL_BLE_ResetParam_GetRespond(uint8_t device, uint16_t opc, uint8_t response_code, uint8_t* data, uint16_t leng);
	void AS_FL_BLE_ResetParameter(struct FunctionParameterDefine* paras);
	

	void AS_FL_UpgradeStateMsgBinding(UpgradeStateMsg_p handler);
	bool AS_FL_UpgradeSetting(uint8_t device_type, uint8_t* device_mid, uint8_t* data, uint32_t leng);
	void AS_FL_CANBusUpgradeFirmware(struct FunctionParameterDefine* paras);
	
	void AS_FL_BLEUpgradeFirmware_GetRespond(uint8_t device, uint16_t opc, uint8_t response_code,uint8_t* data, uint16_t leng);
	void AS_FL_BLEUpgradeFirmware(struct FunctionParameterDefine* paras);


	int AS_FL_GetBLECommon_TxQueue(uint8_t* out_data, uint16_t out_data_size, uint16_t* leng);
	int AS_FL_GetBLEData_TxQueue(uint8_t* out_data, uint16_t out_data_size, uint16_t* leng);

	void AS_FL_CANBus_SetDebugMode(struct FunctionParameterDefine* paras);
	void AS_FL_BLE_SetDebugMode(struct FunctionParameterDefine* paras);

	void AS_FL_CANBus_SetTestMode(struct FunctionParameterDefine* paras);
	void AS_FL_BLE_SetTestMode(struct FunctionParameterDefine* paras);

	void AS_FL_CANBus_RestartDevice(struct FunctionParameterDefine* paras);
	void AS_FL_BLE_RestartDevice(struct FunctionParameterDefine* paras);

	void BLE_light_control(struct FunctionParameterDefine* paras);

	void BLE_ClearTripInfo(struct FunctionParameterDefine* paras);


	//void AS_FL_CANBus_ReadDeviceLogs(struct FunctionParameterDefine* paras);

	uint32_t AS_FL_GetDeviceLogs_Inst(DeviceLogs_T* logs_list);

	void AS_FL_BLE_ReadDeviceLogs_GetRespond(uint8_t device, uint16_t opc, uint8_t response_code, uint8_t* data, uint16_t leng);
	void AS_FL_BLE_ReadDeviceLogs(struct FunctionParameterDefine* paras);



	void AS_FL_BLE_ClearDeviceLogs_GetRespond(uint8_t device, uint16_t opc, uint8_t response_code, uint8_t* data, uint16_t leng);
	void AS_FL_BLE_ClearDeviceLogs(struct FunctionParameterDefine* paras);


	void AS_FL_BLE_ConfigSysTime(struct FunctionParameterDefine* paras);

	void AS_FL_BLE_SetELock_DEV(struct FunctionParameterDefine* paras);

	void AS_FL_BLE_GetELock_DEV(struct FunctionParameterDefine* paras);

	void BLE_light_control(struct FunctionParameterDefine* paras);

	void ActionScriptInit(void);
	int ActionScriptCreate(ACTION_DEFINE_T new_action);
	void ActionScriptRun(void);

	void print_time(void);

	enum DEVICE_OBJ_TYPE_E ConverterToFlDeviceId(uint8_t sdk_device_id_type);

	void ActionScriptRespondWait(uint32_t timeout_ms_set);
	void AS_FL_ActionScriptResume(void);
	void ActionScriptDone(void);

#ifdef __cplusplus
}
#endif


#endif
