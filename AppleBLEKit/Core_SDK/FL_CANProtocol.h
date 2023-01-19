#pragma once

#ifndef _FL_CANPROTOCOL_H // include guard
#define _FL_CANPROTOCOL_H
#include <stdint.h>
#include "CoreSDK.h"

#ifdef __cplusplus
extern "C" {
#endif

typedef int(* CANSenderHandlerFunc)(unsigned int can_id, bool is_extender_id, unsigned char* raw_data, unsigned int leng);


enum ErrorCodeTable
{
	ERR_CODE_NO_ERR = (uint8_t)0,
	ERR_CODE_HMI_COMMUN_FAULT = 1,
	ERR_CODE_BAT_COMMUN_FAULT = 21,
	ERR_CODE_BAT_CAP_TO_LOW = 22,
	ERR_CODE_BAT_EMPTY_CAP = 23,
	ERR_CODE_CTRL_COMMUN_FAULT = 41,
	ERR_CODE_OVER_VOLT = 42,
	ERR_CODE_UNDER_VOLT = 43,
	ERR_CODE_OVER_CURRENT = 44,
	ERR_CODE_OVER_TEMP = 45,
	ERR_CODE_MOTOR_LOCK_WALK = 46,
	ERR_CODE_MOTOR_LOCK_PEDAL = 47,
	ERR_CODE_MOTOR_LOCK_THROTTLE = 48,
	ERR_CODE_HALL_ALL_HIGH = 61,
	ERR_CODE_HALL_ALL_LOW = 62,
	ERR_CODE_HALL_A_FAULT = 63,
	ERR_CODE_HALL_B_FAULT = 64,
	ERR_CODE_HALL_C_FAULT = 65,
	ERR_CODE_SPEED_SENSOR_FAULT = 66,
	ERR_CODE_U_PHASE_OVER_CURRENT = 67,
	ERR_CODE_V_PHASE_OVER_CURRENT = 68,
	ERR_CODE_W_PHASE_OVER_CURRENT = 69,
	ERR_CODE_TORQUE_OVER_VOLT = 81,
	ERR_CODE_TORQUE_UNDER_VOLT = 82,
	ERR_CODE_CADENCE_FAULT = 83,
	ERR_CODE_THROTTLE_OVER_VOLT = 91,
	ERR_CODE_THROTTLE_UNDER_VOLT = 92,
	ERR_CODE_LIGHT_OVER_CURRENT = 101,
	ERR_CODE_NO_CHAIN = 241,
};

enum WarningCodeTable
{
	WARN_CODE_NO_WARN = (uint8_t)0,
	WARN_CODE_NEED_MAINTENANCE = 1,
	WARN_CODE_CTRL_TEMP_TOO_HIGH = 2,
};

struct DFU_device_information_st
{
	uint32_t flash_crc;
	uint32_t flash_size;
	uint16_t page_size;
	uint16_t cache_size;
	uint16_t identifier;
	uint16_t block_index;
	uint8_t init_data;
};


int FL_CAN_TryPaser(uint32_t can_id, bool is_extend, uint8_t* data, uint8_t leng);
int FL_CAN_Init(DeviceInfoDefine* device_info_p, CANSenderHandlerFunc CAN_sender_handler, ISOTP_INST_T* isotp_inst);

typedef void (*RequestDoneCallback_t)(void);
typedef void (*ErrorCallback_t)(uint32_t err_code);
typedef void (*ReadParameterCallback_t)(uint8_t* data, uint16_t leng);


void UpdateDeviceParameter(DeviceObjTypes device_type,	uint8_t bank_index,	uint16_t addr,	uint16_t leng,	uint8_t* new_data);

void FL_CAN_ReadParameter_Requset(uint8_t device_id, uint8_t bank_index, uint32_t addr, uint16_t leng, RequestDoneCallback_t done_callback, ErrorCallback_t err_callback);
void FL_CAN_WriteParameter_Requset(uint8_t device_id, uint8_t bank_index,uint32_t addr,	uint16_t leng, uint8_t* data, RequestDoneCallback_t done_callback, ErrorCallback_t err_callback);

void FL_CAN_DFU_DeviceInfo_Set(struct DFU_device_information_st setting);
void FL_CAN_DFU_DeviceInfo_Get(struct DFU_device_information_st* setting);
uint32_t FL_CAN_DFU_FlashCRC_Get(void);

void FL_CAN_DFU_JumpBootloader_Requset(
	uint8_t device_id,
	uint8_t command_0,
	uint8_t command_1,
	uint8_t command_2,
	RequestDoneCallback_t done_callback, ErrorCallback_t err_callback);

void FL_CAN_DFU_JumpApplication_Requset(
	uint8_t device_id,
	RequestDoneCallback_t done_callback, ErrorCallback_t err_callback);

void FL_CAN_DFU_ReadDeviceInfomation_Requset(
	uint8_t device_id,
	RequestDoneCallback_t done_callback, ErrorCallback_t err_callback);

void FL_CAN_DFU_WriteDeviceInformation_Requset(
	uint8_t device_id,
	uint16_t identifier,
	RequestDoneCallback_t done_callback, ErrorCallback_t err_callback);

void FL_CAN_DFU_EraseFlash_Requset(
	uint8_t device_id,
	uint32_t start_addr,
	uint32_t end_addr,
	RequestDoneCallback_t done_callback, ErrorCallback_t err_callback);

void FL_CAN_DFU_WriteToCache_Requset(
	uint8_t device_id,
	uint16_t cache_addr,
	uint16_t cache_leng,
	uint8_t* cache_data,
	RequestDoneCallback_t done_callback, ErrorCallback_t err_callback);

void FL_CAN_DFU_ProgramFlash_Requset(
	uint8_t device_id,
	uint32_t offset_addr,
	uint32_t data_leng,
	RequestDoneCallback_t done_callback, ErrorCallback_t err_callback);

void FL_CAN_DFU_VerifyFlash_Requset(
	uint8_t device_id,
	uint32_t start_addr,
	uint32_t end_addr,
	RequestDoneCallback_t done_callback, ErrorCallback_t err_callback);


void FL_CAN_ReadParameter(SDKDeviceType_e device_id, uint8_t bank_index, uint32_t addr, uint16_t leng, uint8_t* out_data);

void FL_CAN_HostCommon_TestReq_Send(DeviceObjTypes target_device, uint8_t test_mode, uint32_t test_val,
	RequestDoneCallback_t done_callback,
	ErrorCallback_t err_callback);

void FL_CAN_HostCommon_DebugReq_Send(DeviceObjTypes target_device, uint8_t debug_mode, uint8_t msg_repet, uint16_t msg_interval,
	RequestDoneCallback_t done_callback,
	ErrorCallback_t err_callback);

void FL_CAN_HostCommon_RegResponseHandler(uint8_t device_id, uint8_t req_commond, RequestDoneCallback_t RequestDone_Callback);


#ifdef __cplusplus
}
#endif

#endif /* _FL_CANPROTOCOL_H */
