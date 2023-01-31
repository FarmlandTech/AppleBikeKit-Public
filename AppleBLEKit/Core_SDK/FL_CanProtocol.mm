#include "FL_CanProtocol.h"
#include "FL_CANInfoStruct.h"
#include "CoreSDK.h"
#include <chrono>
#include <iostream>

#ifdef __cplusplus
extern "C" {
#endif

#define ERROR_TABLE_SIZE	64
#define ISO_TP_BUFF_SIZE	4096
#define FL_DEVICE_PARAM_SIZE	1024U

#define CREATE_ISO_TP_BUFF(_buff_name_)	static uint8_t _buff_name_[ISO_TP_BUFF_SIZE] = {0};

int ParameterResponHandler(uint8_t* data, uint32_t leng);

int DFUResponseHandler(uint8_t* data, uint32_t leng);

int HostControlInfoHandler(uint8_t* data, uint32_t leng);
int HostConfigRTCHandler(uint8_t* data, uint32_t leng);
int HostSilenceModeHandler(uint8_t* data, uint32_t leng);
int HostResetResponseHandler(uint8_t* data, uint32_t leng);
int HostTestModeResponseHandler(uint8_t* data, uint32_t leng);
int HostDebugModeResponseHandler(uint8_t* data, uint32_t leng);
int LogsResponHandler(uint8_t* data, uint32_t leng);

int HMIInfo00Handler(uint8_t* data, uint32_t leng);
int HMIInfo01Handler(uint8_t* data, uint32_t leng);
int HMIInfo02Handler(uint8_t* data, uint32_t leng);
int HMIInfo03Handler(uint8_t* data, uint32_t leng);
int HMIWarningHandler(uint8_t* data, uint32_t leng);
int HMIErrorHandler(uint8_t* data, uint32_t leng);
int HMIDebugInfo00Handler(uint8_t* data, uint32_t leng);
int HMIDebugInfo01Handler(uint8_t* data, uint32_t leng);
int ControllerInfo00Handler(uint8_t* data, uint32_t leng);
int ControllerInfo01Handler(uint8_t* data, uint32_t leng);
int ControllerInfo02Handler(uint8_t* data, uint32_t leng);
int ControllerInfo03Handler(uint8_t* data, uint32_t leng);
int ControllerInfo04Handler(uint8_t* data, uint32_t leng);
int ControllerInfo05Handler(uint8_t* data, uint32_t leng);
int ControllerWarningHandler(uint8_t* data, uint32_t leng);
int ControllerErrorHandler(uint8_t* data, uint32_t leng);
int ControllerDebugInfo00Handler(uint8_t* data, uint32_t leng);
int ControllerDebugInfo01Handler(uint8_t* data, uint32_t leng);
int ControllerDebugInfo02Handler(uint8_t* data, uint32_t leng);
int MainBattInfo00Handler(uint8_t* data, uint32_t leng);
int MainBattInfo01Handler(uint8_t* data, uint32_t leng);
int MainBattInfo02Handler(uint8_t* data, uint32_t leng);
int MainBattInfo03Handler(uint8_t* data, uint32_t leng);
int MainBattRTCHandler(uint8_t* data, uint32_t leng);
int MainBattWarningHandler(uint8_t* data, uint32_t leng);
int MainBattErrorHandler(uint8_t* data, uint32_t leng);
int MainBattDebugInfo00Handler(uint8_t* data, uint32_t leng);
int MainBattDebugInfo01Handler(uint8_t* data, uint32_t leng);
int MainBattDebugInfo02Handler(uint8_t* data, uint32_t leng);
int MainBattDebugInfo03Handler(uint8_t* data, uint32_t leng);
int MainBattDebugInfo04Handler(uint8_t* data, uint32_t leng);
int MainBattDebugInfo05Handler(uint8_t* data, uint32_t leng);

uint8_t now_error_happen[ERROR_TABLE_SIZE] = { 0 };
DeviceInfoDefine* FL_DeviceInfo;;

struct FL_DeviceParameterTable_st
{
	uint8_t bank0[FL_DEVICE_PARAM_SIZE];
	uint8_t bank1[FL_DEVICE_PARAM_SIZE];
	uint8_t bank2[FL_DEVICE_PARAM_SIZE];
	uint8_t bank3[FL_DEVICE_PARAM_SIZE];
};

struct FL_DeviceParameterList_st
{
	uint8_t actived_device;
	struct FL_DeviceParameterTable_st HMI;
	struct FL_DeviceParameterTable_st Display;
	struct FL_DeviceParameterTable_st Controller;
	struct FL_DeviceParameterTable_st MainBatt;
	struct FL_DeviceParameterTable_st Slave1Batt;
	struct FL_DeviceParameterTable_st Slave2Batt;
	struct FL_DeviceParameterTable_st Slave3Batt;
};

struct FL_DeviceParameterList_st FL_DevicePara;

struct FL_HostCommon_st
{
	bool actived;
	uint8_t device_id;
	uint8_t common;
};

struct FL_HostCommon_st FL_HostCommon = {0};

static struct CAN_ParseHandlerDefine_st vaild_id_list[] =
{
	
	{ FL_CANID_HOST_INFO_00, false, HostControlInfoHandler},
	{ FL_CANID_HOST_INFO_01, false, HostConfigRTCHandler},
	{ FL_CANID_HOST_INFO_02, false, HostSilenceModeHandler},
	{ FL_CANID_HOST_DEVICE_RESET_RSP, false, HostResetResponseHandler},
	{ FL_CANID_HOST_DEVICE_TEST_RSP, false, HostTestModeResponseHandler},
	{ FL_CANID_HOST_DEVICE_DEBUG_RSP, false, HostDebugModeResponseHandler},

	{ FL_CANID_HMI_INFO_00, false, HMIInfo00Handler},
	{ FL_CANID_HMI_INFO_01, false, HMIInfo01Handler},
	{ FL_CANID_HMI_INFO_02, false, HMIInfo02Handler},
	{ FL_CANID_HMI_INFO_03, false, HMIInfo03Handler},
	{ FL_CANID_HMI_WARNING, false, HMIWarningHandler},
	{ FL_CANID_HMI_ERROR, false, HMIErrorHandler},
	{ FL_CANID_HMI_DEBUGINFO_00, true, HMIDebugInfo00Handler},
	{ FL_CANID_HMI_DEBUGINFO_01, true, HMIDebugInfo01Handler},

	{ FL_CANID_CTRL_INFO_00, false, ControllerInfo00Handler},
	{ FL_CANID_CTRL_INFO_01, false, ControllerInfo01Handler},
	{ FL_CANID_CTRL_INFO_02, false, ControllerInfo02Handler},
	{ FL_CANID_CTRL_INFO_03, false, ControllerInfo03Handler},
	{ FL_CANID_CTRL_INFO_04, false, ControllerInfo04Handler},
	{ FL_CANID_CTRL_INFO_05, false, ControllerInfo05Handler},
	{ FL_CANID_CTRL_WARNING_INFO, false, ControllerWarningHandler},
	{ FL_CANID_CTRL_ERROR_INFO, false, ControllerErrorHandler},
	{ FL_CANID_CTRL_DEBUGINFO_00, true, ControllerDebugInfo00Handler},
	{ FL_CANID_CTRL_DEBUGINFO_01, true, ControllerDebugInfo01Handler},
	{ FL_CANID_CTRL_DEBUGINFO_02, true, ControllerDebugInfo02Handler},

	{ FL_CANID_MBAT_INFO_00, false, MainBattInfo00Handler},
	{ FL_CANID_MBAT_INFO_01, false, MainBattInfo01Handler},
	{ FL_CANID_MBAT_INFO_02, false, MainBattInfo02Handler},
	{ FL_CANID_MBAT_INFO_03, false, MainBattInfo03Handler},
	{ FL_CANID_MBAT_RTC_INFO, false, MainBattRTCHandler},
	{ FL_CANID_MBAT_WARNING_INFO, false, MainBattWarningHandler},
	{ FL_CANID_MBAT_ERROR_INFO, false, MainBattErrorHandler},
	{ FL_CANID_MBAT_DEBUGINFO_00, true, MainBattDebugInfo00Handler},
	{ FL_CANID_MBAT_DEBUGINFO_01, true, MainBattDebugInfo01Handler},
	{ FL_CANID_MBAT_DEBUGINFO_02, true, MainBattDebugInfo02Handler},
	{ FL_CANID_MBAT_DEBUGINFO_03, true, MainBattDebugInfo03Handler},
	{ FL_CANID_MBAT_DEBUGINFO_04, true, MainBattDebugInfo04Handler},
	{ FL_CANID_MBAT_DEBUGINFO_05, true, MainBattDebugInfo05Handler},
};

CREATE_ISO_TP_BUFF(DFUSendBuff);
static ISOTP_PortInfo_T ISOTP_Port_DeviceDFUSend =
{
	0x11, false, DFUSendBuff, ISO_TP_BUFF_SIZE, 0, 0, 0, NULL, NULL, NULL
};

CREATE_ISO_TP_BUFF(DFUReviceBuff);
static ISOTP_PortInfo_T ISOTP_Port_DeviceDFURecive =
{
	0x10, false, DFUReviceBuff, ISO_TP_BUFF_SIZE, 0, 0, 0, NULL, NULL, DFUResponseHandler
};

CREATE_ISO_TP_BUFF(ParamSendBuff);
static ISOTP_PortInfo_T ISOTP_Port_DeviceParamSend =
{
	FL_ISOTP_CANID_PARAM_ANY_2_HMI, true, ParamSendBuff, ISO_TP_BUFF_SIZE, 0, 0, 0, NULL, NULL, NULL
};

CREATE_ISO_TP_BUFF(ParamReviceBuff);
static ISOTP_PortInfo_T ISOTP_Port_DeviceParamRecive =
{
	FL_ISOTP_CANID_PARAM_HMI_2_ANY, true, ParamReviceBuff, ISO_TP_BUFF_SIZE, 0, 0, 0, NULL, NULL, ParameterResponHandler
};

CREATE_ISO_TP_BUFF(LogsSendBuff);
static ISOTP_PortInfo_T ISOTP_Port_LogsParamSend =
{
	FL_ISOTP_CANID_PARAM_ANY_2_HMI, true, LogsSendBuff, ISO_TP_BUFF_SIZE, 0, 0, 0, NULL, NULL, NULL
};

CREATE_ISO_TP_BUFF(LogsReviceBuff);
static ISOTP_PortInfo_T ISOTP_Port_LogsParamRecive =
{
	FL_ISOTP_CANID_PARAM_HMI_2_ANY, true, LogsReviceBuff, ISO_TP_BUFF_SIZE, 0, 0, 0, NULL, NULL, LogsResponHandler
};

CANSenderHandlerFunc CAN_sender = NULL;
ISOTP_INST_T *FL_ISOTP = NULL;



RequestDoneCallback_t RequestDoneCall;

static void LoadDeviceParameter(
	struct FL_DeviceParameterTable_st* device_param,
	uint8_t bank_index,
	uint16_t addr,
	uint16_t leng,
	uint8_t* out_data)
{
	uint8_t* bank = 0;
	uint16_t start_index = addr;
	uint16_t end_index = addr + leng;

	switch (bank_index)
	{
	case 0:
	{
		bank = device_param->bank0;
	}
	break;

	case 1:
	{
		bank = device_param->bank1;
	}
	break;

	case 2:
	{
		bank = device_param->bank2;
	}
	break;

	case 3:
	{
		bank = device_param->bank3;
	}
	break;

	default:
		return;
	}

	for (;start_index < end_index;start_index++)
	{
		if (start_index >= FL_DEVICE_PARAM_SIZE)
		{
			*out_data = 0xff;
		}
		else
		{
			*out_data = bank[start_index];
		}

		out_data++;
	}
}

void UpdateDeviceParameter(
	DeviceObjTypes device_type,
	uint8_t bank_index,
	uint16_t addr,
	uint16_t leng,
	uint8_t* new_data)
{
	uint8_t *bank = 0;
	uint16_t start_index = addr;
	uint16_t end_index = addr + leng;
	struct FL_DeviceParameterTable_st* device_param;
	switch (device_type)
	{
	case DEVICE_OBJ_HMI:
	{
		device_param = &FL_DevicePara.HMI;
	}
	break;

	case DEVICE_OBJ_CONTROLLER:
	{
		device_param = &FL_DevicePara.Controller;
	}
	break;

	case DEVICE_OBJ_MAIN_BATT:
	{
		device_param = &FL_DevicePara.MainBatt;
	}
	break;

	case DEVICE_OBJ_SUB_BATT1:
	{
		device_param = &FL_DevicePara.Slave1Batt;
	}
	break;

	case DEVICE_OBJ_DISPLAY:
	{
		device_param = &FL_DevicePara.Display;
	}
	break;

	default:
		return;
	}

	switch (bank_index)
	{
	case 0:
	{
		bank = device_param->bank0;
	}
	break;

	case 1:
	{
		bank = device_param->bank1;
	}
	break;

	case 2:
	{
		bank = device_param->bank2;
	}
	break;

	case 3:
	{
		bank = device_param->bank3;
	}
	break;

	default:
		return;
	}

	if (end_index > FL_DEVICE_PARAM_SIZE)
	{
		end_index = FL_DEVICE_PARAM_SIZE;
	}

	for (;start_index < end_index;start_index++)
	{
		bank[start_index] = *new_data;
		new_data++;
	}
}



int ParameterResponHandler(uint8_t* data, uint32_t leng)
{
	uint8_t operate_code = data[0];
	uint8_t respond = data[1];
	uint8_t bank_index = data[2];
	uint32_t param_addr = data[3] + (data[4] << 8);
	uint16_t param_leng = data[5] + (data[6] << 8);

	if (respond == RESPONSE_SUCCESS && bank_index < 4)
	{
		if (operate_code == OPC_READ_PARAM)
		{
			UpdateDeviceParameter((DeviceObjTypes)FL_DevicePara.actived_device, bank_index, param_addr, param_leng, &data[8]);

			RequestDoneCall();
		}
		else if (operate_code == OPC_WRITE_PARAM)
		{
			RequestDoneCall();
		}

	}

	return 0;
}


int LogsResponHandler(uint8_t* data, uint32_t leng)
{
	if (leng < 4)
	{
		return SDK_RETURN_INVALID_SIZE;
	}

	uint8_t opc = data[0];
	uint8_t response_code = data[1];

	switch (opc)
	{
	case OPC_READ_LOG:
	{
		if (response_code == RESPONSE_SUCCESS)
		{
			if (leng > 40)
			{
				uint32_t crc_index = leng - 4;
				uint32_t get_crc = data[crc_index] + (data[crc_index+1] << 8) + (data[crc_index + 1] << 16) + (data[crc_index + 1] << 24);
				uint32_t check_crc = FarmlandCalCrc32(data, crc_index, 0);

				if (check_crc == get_crc)
				{
					return Farmland_Log_Parse(&data[2], (leng - 6));
				}
				else
				{
					return SDK_RETURN_CRC_FAIL;
				}

			}
		}
		else if (response_code == RESPONSE_NULL)
		{

		}
	}
	break;

	case OPC_CLEAR_LOG:
	{

	}
	break;

	}

	return SDK_RETURN_SUCCESS;
}


int DebugTestRequestHandler(uint8_t* data, uint32_t leng)
{

	return 0;
}

int DebugTestResponHandler(uint8_t* data, uint32_t leng)
{

	return 0;
}


int HostControlInfoHandler(uint8_t* data, uint32_t leng)
{
	HOST_CONTROLINFO_00_T ctl_info = { 0 };
	COPY_MIN_ARRAY(data, leng, &ctl_info.bytes[0], sizeof(ctl_info.bytes));
	FL_DeviceInfo->FL.current_assist_lv = ctl_info.bits.set_assist_level;
	FL_DeviceInfo->FL.system_power_control = ctl_info.bits.system_power_control;
	FL_DeviceInfo->FL.walk_assist_control = ctl_info.bits.walk_assist_control;
	FL_DeviceInfo->FL.light_control = ctl_info.bits.light_control;

	return RESPONSE_SUCCESS;
}


int HostConfigRTCHandler(uint8_t* data, uint32_t leng)
{
	HOST_CONTROLINFO_01_T config_rtc = { 0 };
	COPY_MIN_ARRAY(data, leng, &config_rtc.bytes[0], sizeof(config_rtc.bytes));
	FL_DeviceInfo->FL.sys_unix_time = config_rtc.bits.unix_time;

	return RESPONSE_SUCCESS;
}


int HostSilenceModeHandler(uint8_t* data, uint32_t leng)
{
	return RESPONSE_SUCCESS;
}


int HostResetResponseHandler(uint8_t* data, uint32_t leng)
{
	HOST_DEVICE_RESET_RSP_T reset_rsp = { 0 };
	COPY_MIN_ARRAY(data, leng, &reset_rsp.bytes[0], sizeof(reset_rsp.bytes));

	if (FL_HostCommon.actived &&
		FL_HostCommon.device_id == reset_rsp.bits.device_type &&
		FL_HostCommon.common == FL_CANID_HOST_DEVICE_RESET_REQ &&
		reset_rsp.bits.response_code == RESPONSE_SUCCESS)
	{
		if (RequestDoneCall)
		{
			RequestDoneCall();
		}

		FL_HostCommon.actived = false;
	}

	return RESPONSE_SUCCESS;
}

int HostTestModeResponseHandler(uint8_t* data, uint32_t leng)
{
	HOST_DEVICE_TEST_RSP_T test_rsp = { 0 };
	COPY_MIN_ARRAY(data, leng, &test_rsp.bytes[0], sizeof(test_rsp.bytes));

	if (FL_HostCommon.actived &&
		FL_HostCommon.device_id == test_rsp.bits.device_type &&
		FL_HostCommon.common == FL_CANID_HOST_DEVICE_TEST_REQ &&
		test_rsp.bits.response_code == RESPONSE_SUCCESS)
	{
		if (RequestDoneCall)
		{
			RequestDoneCall();
		}

		FL_HostCommon.actived = false;
	}

	return RESPONSE_SUCCESS;
}

int HostDebugModeResponseHandler(uint8_t* data, uint32_t leng)
{
	HOST_DEVICE_DEBUG_RSP_T debug_rsp = { 0 };
	COPY_MIN_ARRAY(data, leng, &debug_rsp.bytes[0], sizeof(debug_rsp.bytes));

	if (FL_HostCommon.actived &&
		FL_HostCommon.device_id == debug_rsp.bits.device_type &&
		FL_HostCommon.common == FL_CANID_HOST_DEVICE_DEBUG_REQ &&
		debug_rsp.bits.response_code == RESPONSE_SUCCESS)
	{
		if (RequestDoneCall)
		{
			RequestDoneCall();
		}

		FL_HostCommon.actived = false;
	}

	return RESPONSE_SUCCESS;
}

int HMIInfo00Handler(uint8_t* data, uint32_t leng)
{
	HMI_INFO_00_T info = { 0 };
	COPY_MIN_ARRAY(data, leng, &info.bytes[0], sizeof(info.bytes));
	FL_DeviceInfo->FL.support_assist_lv = info.bits.support_assist_level;
	FL_DeviceInfo->FL.current_assist_lv = info.bits.current_assist_level;

	FL_DeviceInfo->FL.power_key_status = info.bits.power_key_status;
	FL_DeviceInfo->FL.up_key_status = info.bits.up_key_status;
	FL_DeviceInfo->FL.down_key_status = info.bits.down_key_status;
	FL_DeviceInfo->FL.walk_key_status = info.bits.walk_key_status;
	FL_DeviceInfo->FL.light_key_status = info.bits.light_key_status;

	return RESPONSE_SUCCESS;
}


int HMIInfo01Handler(uint8_t* data, uint32_t leng)
{
	HMI_INFO_01_T info = { 0 };
	COPY_MIN_ARRAY(data, leng, &info.bytes[0], sizeof(info.bytes));
	FL_DeviceInfo->FL.trip_odo = info.bits.trip_odo * 0.001f;
	FL_DeviceInfo->FL.trip_time_sec = info.bits.trip_time;
	return RESPONSE_SUCCESS;
}

int HMIInfo02Handler(uint8_t* data, uint32_t leng)
{
	HMI_INFO_02_T info = { 0 };
	COPY_MIN_ARRAY(data, leng, &info.bytes[0], sizeof(info.bytes));
	FL_DeviceInfo->FL.trip_avg_speed = info.bits.trip_avg_speed;
	FL_DeviceInfo->FL.trip_max_speed = info.bits.trip_max_speed;
	FL_DeviceInfo->FL.trip_avg_current = info.bits.trip_avg_current;
	FL_DeviceInfo->FL.trip_max_current = info.bits.trip_max_current;

	return RESPONSE_SUCCESS;
}

int HMIInfo03Handler(uint8_t* data, uint32_t leng)
{
	HMI_INFO_03_T info = { 0 };
	COPY_MIN_ARRAY(data, leng, &info.bytes[0], sizeof(info.bytes));
	FL_DeviceInfo->FL.trip_avg_pedal_speed = info.bits.trip_avg_pedal_speed;
	FL_DeviceInfo->FL.trip_max_pedal_speed = info.bits.trip_max_pedal_speed;
	FL_DeviceInfo->FL.trip_avg_pedal_torque = info.bits.trip_avg_pedal_torque;
	FL_DeviceInfo->FL.trip_max_pedal_torque = info.bits.trip_max_pedal_torque;

	return RESPONSE_SUCCESS;
}




int HMIWarningHandler(uint8_t* data, uint32_t leng)
{
	uint8_t start_index;
	uint8_t copy_index;
	static uint8_t HMI_warning_list[WARNING_CODE_LIST_SIZE] = { 0 };
	HMI_WARNINGINFO_T warning = {0};
	COPY_MIN_ARRAY(data, leng, &warning.bytes[0], sizeof(warning.bytes));

	if (warning.bits.total_leng > WARNING_CODE_LIST_SIZE || warning.bits.page_num >= WARNING_CODE_PAGE_SIZE)
	{
		return RESPONSE_INVALID_PARAM;
	}

	if (warning.bits.total_leng)
	{
		start_index = warning.bits.page_num * 7;		
		HMI_warning_list[start_index++] = warning.bits.warning_0;
		HMI_warning_list[start_index++] = warning.bits.warning_1;
		HMI_warning_list[start_index++] = warning.bits.warning_2;
		HMI_warning_list[start_index++] = warning.bits.warning_3;
		HMI_warning_list[start_index++] = warning.bits.warning_4;
		HMI_warning_list[start_index++] = warning.bits.warning_5;
		HMI_warning_list[start_index++] = warning.bits.warning_6;

		if (start_index >= warning.bits.total_leng)
		{
			for (copy_index=0;copy_index< warning.bits.total_leng;copy_index++)
			{
				FL_DeviceInfo->FL.HMI_warning_list[copy_index] = HMI_warning_list[copy_index];
			}
			FL_DeviceInfo->FL.HMI_warning_leng = warning.bits.total_leng;
		}
	}
	else
	{
		memset(HMI_warning_list, 0, sizeof(HMI_warning_list));
		memset(FL_DeviceInfo->FL.HMI_warning_list, 0, sizeof(FL_DeviceInfo->FL.HMI_warning_list));
		FL_DeviceInfo->FL.HMI_warning_leng = 0;
	}

	return RESPONSE_SUCCESS;
}

int HMIErrorHandler(uint8_t* data, uint32_t leng)
{
	uint8_t start_index;
	uint8_t copy_index;
	static uint8_t HMI_error_list[WARNING_CODE_LIST_SIZE] = { 0 };
	HMI_ERRORINFO_T error = { 0 };
	COPY_MIN_ARRAY(data, leng, &error.bytes[0], sizeof(error.bytes));

	if (error.bits.total_leng > WARNING_CODE_LIST_SIZE || error.bits.page_num >= WARNING_CODE_PAGE_SIZE)
	{
		return RESPONSE_INVALID_PARAM;
	}

	if (error.bits.total_leng)
	{
		start_index = error.bits.page_num * 7;
		HMI_error_list[start_index++] = error.bits.error_0;
		HMI_error_list[start_index++] = error.bits.error_1;
		HMI_error_list[start_index++] = error.bits.error_2;
		HMI_error_list[start_index++] = error.bits.error_3;
		HMI_error_list[start_index++] = error.bits.error_4;
		HMI_error_list[start_index++] = error.bits.error_5;
		HMI_error_list[start_index++] = error.bits.error_6;

		if (start_index >= error.bits.total_leng)
		{
			for (copy_index = 0;copy_index < error.bits.total_leng;copy_index++)
			{
				FL_DeviceInfo->FL.HMI_error_list[copy_index] = HMI_error_list[copy_index];
			}
			FL_DeviceInfo->FL.HMI_error_leng = error.bits.total_leng;
		}
	}
	else
	{
		memset(HMI_error_list, 0, sizeof(HMI_error_list));
		memset(FL_DeviceInfo->FL.HMI_error_list, 0, sizeof(FL_DeviceInfo->FL.HMI_error_list));
		FL_DeviceInfo->FL.HMI_error_leng = 0;
	}

	return RESPONSE_SUCCESS;
}

int HMIDebugInfo00Handler(uint8_t* data, uint32_t leng)
{
	HMI_DEBUGINFO_O0_T debugInfo = { 0 };
	COPY_MIN_ARRAY(data, leng, &debugInfo.bytes[0], sizeof(debugInfo.bytes));

	FL_DeviceInfo->FL.key_1_count = debugInfo.bits.key_1_count;
	FL_DeviceInfo->FL.key_2_count = debugInfo.bits.key_2_count;
	FL_DeviceInfo->FL.key_3_count = debugInfo.bits.key_3_count;
	FL_DeviceInfo->FL.key_4_count = debugInfo.bits.key_4_count;

	LogD("%s [KeyCnt:%d, KeyCnt:%d, KeyCnt:%d, KeyCnt:%d]\n",
		__func__ ,
		FL_DeviceInfo->FL.key_1_count,
		FL_DeviceInfo->FL.key_2_count,
		FL_DeviceInfo->FL.key_3_count,
		FL_DeviceInfo->FL.key_4_count);

	return RESPONSE_SUCCESS;
}

int HMIDebugInfo01Handler(uint8_t* data, uint32_t leng)
{
	HMI_DEBUGINFO_01_T debugInfo = { 0 };
	COPY_MIN_ARRAY(data, leng, &debugInfo.bytes[0], sizeof(debugInfo.bytes));

	FL_DeviceInfo->FL.key_5_count = debugInfo.bits.key_5_count;
	FL_DeviceInfo->FL.key_6_count = debugInfo.bits.key_6_count;
	FL_DeviceInfo->FL.key_7_count = debugInfo.bits.key_7_count;
	FL_DeviceInfo->FL.key_8_count = debugInfo.bits.key_8_count;

	LogD("%s [KeyCnt:%d, KeyCnt:%d, KeyCnt:%d, KeyCnt:%d]\n",
		__func__,
		debugInfo.bits.key_5_count,
		debugInfo.bits.key_6_count,
		debugInfo.bits.key_7_count,
		debugInfo.bits.key_8_count);

	return RESPONSE_SUCCESS;
}

int ControllerInfo00Handler(uint8_t* data, uint32_t leng)
{
	CTRL_INFO00_T ctrl_info = { 0 };
	COPY_MIN_ARRAY(data, leng, &ctrl_info.bytes[0], sizeof(ctrl_info.bytes));

	FL_DeviceInfo->FL.bike_speed = ctrl_info.bits.bike_speed * 0.1f;
	FL_DeviceInfo->FL.motor_speed = ctrl_info.bits.motor_speed;
	FL_DeviceInfo->FL.wheel_speed = ctrl_info.bits.wheel_speed;
	FL_DeviceInfo->FL.limit_speed = ctrl_info.bits.limit_speed * 0.1f;

	return RESPONSE_SUCCESS;
}

int ControllerInfo01Handler(uint8_t* data, uint32_t leng)
{
	CTRL_INFO01_T ctrl_info = { 0 };
	COPY_MIN_ARRAY(data, leng, &ctrl_info.bytes[0], sizeof(ctrl_info.bytes));

	FL_DeviceInfo->FL.bus_voltage = ctrl_info.bits.bus_voltage * 0.01f;
	FL_DeviceInfo->FL.avg_bus_current = ctrl_info.bits.avg_bus_current * 0.01f;
	FL_DeviceInfo->FL.light_current = ctrl_info.bits.light_current * 0.01f;
	FL_DeviceInfo->FL.avg_output_amplitube = ctrl_info.bits.avg_output;
	FL_DeviceInfo->FL.controller_temperature = ctrl_info.bits.temperature;

	return RESPONSE_SUCCESS;
}


int ControllerInfo02Handler(uint8_t* data, uint32_t leng)
{
	CTRL_INFO02_T ctrl_info = { 0 };
	COPY_MIN_ARRAY(data, leng, &ctrl_info.bytes[0], sizeof(ctrl_info.bytes));

	FL_DeviceInfo->FL.throttle_amplitube = ctrl_info.bits.throttle_amplitube;
	FL_DeviceInfo->FL.pedal_cadence = ctrl_info.bits.pedal_cadence;
	FL_DeviceInfo->FL.pedal_torque = ctrl_info.bits.pedal_torque * 0.1f;
	FL_DeviceInfo->FL.pedal_power = ctrl_info.bits.pedal_power * 0.1f;

	return RESPONSE_SUCCESS;
}


int ControllerInfo03Handler(uint8_t* data, uint32_t leng)
{
	CTRL_INFO03_T ctrl_info = { 0 };
	COPY_MIN_ARRAY(data, leng, &ctrl_info.bytes[0], sizeof(ctrl_info.bytes));
	FL_DeviceInfo->FL.total_odo = ctrl_info.bits.odo * 0.001f;

	return RESPONSE_SUCCESS;
}


int ControllerInfo04Handler(uint8_t* data, uint32_t leng)
{
	CTRL_INFO04_T ctrl_info = { 0 };
	COPY_MIN_ARRAY(data, leng, &ctrl_info.bytes[0], sizeof(ctrl_info.bytes));

	FL_DeviceInfo->FL.range_odo = ctrl_info.bits.controller_range * 1.0f;

	return RESPONSE_SUCCESS;
}

int ControllerInfo05Handler(uint8_t* data, uint32_t leng)
{
	CTRL_INFO05_T info = { 0 };
	COPY_MIN_ARRAY(data, leng, &info.bytes[0], sizeof(info.bytes));

	FL_DeviceInfo->FL.assist_level = info.bits.assist_level;
	FL_DeviceInfo->FL.assist_type = info.bits.assist_type;
	FL_DeviceInfo->FL.assist_on = info.bits.assist_on;
	FL_DeviceInfo->FL.front_light_on = info.bits.front_light_on;
	FL_DeviceInfo->FL.rear_light_on = info.bits.rear_light_on;
	FL_DeviceInfo->FL.activate_light_ctrl = info.bits.activate_light_ctrl;
	FL_DeviceInfo->FL.brake_on = info.bits.brake_on;
	FL_DeviceInfo->FL.candence_direction = info.bits.candence_direction;
	FL_DeviceInfo->FL.motor_direction = info.bits.motor_direction;

	return RESPONSE_SUCCESS;
}


int ControllerWarningHandler(uint8_t* data, uint32_t leng)
{
	uint8_t start_index;
	uint8_t copy_index;
	static uint8_t CTRL_warning_list[WARNING_CODE_LIST_SIZE] = { 0 };
	CTRL_WARNINGINFO_T warning = { 0 };
	COPY_MIN_ARRAY(data, leng, &warning.bytes[0], sizeof(warning.bytes));

	if (warning.bits.total_leng > WARNING_CODE_LIST_SIZE || warning.bits.page_num >= WARNING_CODE_PAGE_SIZE)
	{
		return RESPONSE_INVALID_PARAM;
	}

	if (warning.bits.total_leng)
	{
		start_index = warning.bits.page_num * 7;
		CTRL_warning_list[start_index++] = warning.bits.warning_0;
		CTRL_warning_list[start_index++] = warning.bits.warning_1;
		CTRL_warning_list[start_index++] = warning.bits.warning_2;
		CTRL_warning_list[start_index++] = warning.bits.warning_3;
		CTRL_warning_list[start_index++] = warning.bits.warning_4;
		CTRL_warning_list[start_index++] = warning.bits.warning_5;
		CTRL_warning_list[start_index++] = warning.bits.warning_6;

		if (start_index >= warning.bits.total_leng)
		{
			for (copy_index = 0;copy_index < warning.bits.total_leng;copy_index++)
			{
				FL_DeviceInfo->FL.controller_warning_list[copy_index] = CTRL_warning_list[copy_index];
			}
			FL_DeviceInfo->FL.controller_warning_leng = warning.bits.total_leng;
		}
	}
	else
	{
		memset(CTRL_warning_list, 0, sizeof(CTRL_warning_list));
		memset(FL_DeviceInfo->FL.controller_warning_list, 0, sizeof(FL_DeviceInfo->FL.controller_warning_list));
		FL_DeviceInfo->FL.controller_warning_leng = 0;
	}

	return RESPONSE_SUCCESS;
}


int ControllerErrorHandler(uint8_t* data, uint32_t leng)
{
	uint8_t start_index;
	uint8_t copy_index;
	static uint8_t CTRL_error_list[WARNING_CODE_LIST_SIZE] = { 0 };
	CTRL_ERRORINFO_T error = { 0 };
	COPY_MIN_ARRAY(data, leng, &error.bytes[0], sizeof(error.bytes));

	if (error.bits.total_leng > WARNING_CODE_LIST_SIZE || error.bits.page_num >= WARNING_CODE_PAGE_SIZE)
	{
		return RESPONSE_INVALID_PARAM;
	}

	if (error.bits.total_leng)
	{
		start_index = error.bits.page_num * 7;
		CTRL_error_list[start_index++] = error.bits.error_0;
		CTRL_error_list[start_index++] = error.bits.error_1;
		CTRL_error_list[start_index++] = error.bits.error_2;
		CTRL_error_list[start_index++] = error.bits.error_3;
		CTRL_error_list[start_index++] = error.bits.error_4;
		CTRL_error_list[start_index++] = error.bits.error_5;
		CTRL_error_list[start_index++] = error.bits.error_6;

		if (start_index >= error.bits.total_leng)
		{
			for (copy_index = 0;copy_index < error.bits.total_leng;copy_index++)
			{
				FL_DeviceInfo->FL.controller_error_list[copy_index] = CTRL_error_list[copy_index];
			}
			FL_DeviceInfo->FL.controller_error_leng = error.bits.total_leng;
		}
	}
	else
	{
		memset(CTRL_error_list, 0, sizeof(CTRL_error_list));
		memset(FL_DeviceInfo->FL.controller_error_list, 0, sizeof(FL_DeviceInfo->FL.controller_error_list));
		FL_DeviceInfo->FL.controller_error_leng = 0;
	}

	return RESPONSE_SUCCESS;
}


int ControllerDebugInfo00Handler(uint8_t* data, uint32_t leng)
{
	CTRL_DEBUGINFO00_T debug_info = { 0 };
	COPY_MIN_ARRAY(data, leng, &debug_info.bytes[0], sizeof(debug_info.bytes));

	FL_DeviceInfo->FL.zero_torque_volt = debug_info.bits.zero_torque_volt;
	FL_DeviceInfo->FL.current_torque_volt = debug_info.bits.current_torque_volt;
	FL_DeviceInfo->FL.zero_throttle_volt = debug_info.bits.zero_throttle_volt;
	FL_DeviceInfo->FL.current_throttle_volt = debug_info.bits.current_throttle_volt;

	return RESPONSE_SUCCESS;
}


int ControllerDebugInfo01Handler(uint8_t* data, uint32_t leng)
{
	CTRL_DEBUGINFO01_T debug_info = { 0 };
	COPY_MIN_ARRAY(data, leng, &debug_info.bytes[0], sizeof(debug_info.bytes));

	FL_DeviceInfo->FL.actual_bus_current = debug_info.bits.actual_bus_current * 0.01f;
	FL_DeviceInfo->FL.u_phase_current = debug_info.bits.u_phase_current * 0.01f;
	FL_DeviceInfo->FL.v_phase_current = debug_info.bits.v_phase_current * 0.01f;
	FL_DeviceInfo->FL.w_phase_current = debug_info.bits.w_phase_current * 0.01f;

	return RESPONSE_SUCCESS;
}


int ControllerDebugInfo02Handler(uint8_t* data, uint32_t leng)
{
	CTRL_DEBUGINFO02_T debug_info = { 0 };
	COPY_MIN_ARRAY(data, leng, &debug_info.bytes[0], sizeof(debug_info.bytes));

	FL_DeviceInfo->FL.wheel_rotate_laps = debug_info.bits.wheel_rotate_laps;
	FL_DeviceInfo->FL.output_amplitude = debug_info.bits.output_amplitude;
	FL_DeviceInfo->FL.hall_state = debug_info.bits.hall_state;
	FL_DeviceInfo->FL.sector_state = debug_info.bits.sector_state;

	return RESPONSE_SUCCESS;
}

int MainBattInfo00Handler(uint8_t* data, uint32_t leng)
{
	MAIN_BAT_INFO00_T info = { 0 };
	COPY_MIN_ARRAY(data, leng, &info.bytes[0], sizeof(info.bytes));

	FL_DeviceInfo->FL.charge_fet = info.bits.charge_fet;
	FL_DeviceInfo->FL.charging = info.bits.charging;
	FL_DeviceInfo->FL.fully_charged = info.bits.fully_charged;
	FL_DeviceInfo->FL.charge_detected = info.bits.charge_detected;
	FL_DeviceInfo->FL.discharge_fet = info.bits.discharge_fet;
	FL_DeviceInfo->FL.discharging = info.bits.discharging;
	FL_DeviceInfo->FL.nearly_discharged = info.bits.nearly_discharged;
	FL_DeviceInfo->FL.fully_discharged = info.bits.fully_discharged;

	FL_DeviceInfo->FL.design_volt = info.bits.design_volt;
	FL_DeviceInfo->FL.design_capacity = info.bits.design_capacity * 0.001f;
	FL_DeviceInfo->FL.battery_cycle_count = info.bits.cycle_count;
	FL_DeviceInfo->FL.battery_uncharged_day = info.bits.uncharged_day;

	return RESPONSE_SUCCESS;
}


int MainBattInfo01Handler(uint8_t* data, uint32_t leng)
{
	MAIN_BAT_INFO01_T info = { 0 };
	COPY_MIN_ARRAY(data, leng, &info.bytes[0], sizeof(info.bytes));

	FL_DeviceInfo->FL.battery_actual_volt = info.bits.actual_volt;
	FL_DeviceInfo->FL.battery_actual_current = info.bits.actual_current;

	return RESPONSE_SUCCESS;
}

int MainBattInfo02Handler(uint8_t* data, uint32_t leng)
{
	MAIN_BAT_INFO02_T info = { 0 };
	COPY_MIN_ARRAY(data, leng, &info.bytes[0], sizeof(info.bytes));

	FL_DeviceInfo->FL.battery_temperature = info.bits.temperature;
	return RESPONSE_SUCCESS;
}

int MainBattInfo03Handler(uint8_t* data, uint32_t leng)
{
	MAIN_BAT_INFO03_T info = { 0 };
	COPY_MIN_ARRAY(data, leng, &info.bytes[0], sizeof(info.bytes));

	FL_DeviceInfo->FL.battery_rsoc = info.bits.rsoc;
	FL_DeviceInfo->FL.battery_asoc = info.bits.asoc;
	FL_DeviceInfo->FL.battery_rsoh = info.bits.rsoh;
	FL_DeviceInfo->FL.battery_asoh = info.bits.asoh;

	return RESPONSE_SUCCESS;
}

int MainBattRTCHandler(uint8_t* data, uint32_t leng)
{
	MAIN_BAT_RTCINFO_T RTC = { 0 };
	COPY_MIN_ARRAY(data, leng, &RTC.bytes[0], sizeof(RTC.bytes));

	FL_DeviceInfo->FL.sys_unix_time = RTC.bits.unix_time;

	return RESPONSE_SUCCESS;
}

int MainBattWarningHandler(uint8_t* data, uint32_t leng)
{
	uint8_t start_index;
	uint8_t copy_index;
	static uint8_t MainBattery_warning_list[WARNING_CODE_LIST_SIZE] = { 0 };
	BAT_WARNINGINFO_T warning = { 0 };
	COPY_MIN_ARRAY(data, leng, &warning.bytes[0], sizeof(warning.bytes));

	if (warning.bits.total_leng > WARNING_CODE_LIST_SIZE || 
		warning.bits.page_num >= WARNING_CODE_PAGE_SIZE)
	{
		return RESPONSE_INVALID_PARAM;
	}

	if (warning.bits.total_leng)
	{
		start_index = warning.bits.page_num * 7;
		MainBattery_warning_list[start_index++] = warning.bits.warning_0;
		MainBattery_warning_list[start_index++] = warning.bits.warning_1;
		MainBattery_warning_list[start_index++] = warning.bits.warning_2;
		MainBattery_warning_list[start_index++] = warning.bits.warning_3;
		MainBattery_warning_list[start_index++] = warning.bits.warning_4;
		MainBattery_warning_list[start_index++] = warning.bits.warning_5;
		MainBattery_warning_list[start_index++] = warning.bits.warning_6;

		if (start_index >= warning.bits.total_leng)
		{
			for (copy_index = 0;copy_index < warning.bits.total_leng;copy_index++)
			{
				FL_DeviceInfo->FL.battery_warning_list[copy_index] = MainBattery_warning_list[copy_index];
			}
			FL_DeviceInfo->FL.battery_warning_leng = warning.bits.total_leng;
		}
	}
	else
	{
		memset(MainBattery_warning_list, 0, sizeof(MainBattery_warning_list));
		memset(FL_DeviceInfo->FL.battery_warning_list, 0, sizeof(FL_DeviceInfo->FL.battery_warning_list));
		FL_DeviceInfo->FL.battery_warning_leng = 0;
	}

	return RESPONSE_SUCCESS;
}


int MainBattErrorHandler(uint8_t* data, uint32_t leng)
{
	uint8_t start_index;
	uint8_t copy_index;
	static uint8_t MainBattery_error_list[WARNING_CODE_LIST_SIZE] = { 0 };
	HMI_ErrorInfo_st error = { 0 };
	COPY_MIN_ARRAY(data, leng, &error.bytes[0], sizeof(error.bytes));

	if (error.bits.total_leng > WARNING_CODE_LIST_SIZE || error.bits.page_num >= WARNING_CODE_PAGE_SIZE)
	{
		return RESPONSE_INVALID_PARAM;
	}

	if (error.bits.total_leng)
	{
		start_index = error.bits.page_num * 7;
		MainBattery_error_list[start_index++] = error.bits.error_0;
		MainBattery_error_list[start_index++] = error.bits.error_1;
		MainBattery_error_list[start_index++] = error.bits.error_2;
		MainBattery_error_list[start_index++] = error.bits.error_3;
		MainBattery_error_list[start_index++] = error.bits.error_4;
		MainBattery_error_list[start_index++] = error.bits.error_5;
		MainBattery_error_list[start_index++] = error.bits.error_6;

		if (start_index >= error.bits.total_leng)
		{
			for (copy_index = 0;copy_index < error.bits.total_leng;copy_index++)
			{
				FL_DeviceInfo->FL.battery_error_list[copy_index] = MainBattery_error_list[copy_index];
			}
			FL_DeviceInfo->FL.battery_error_leng = error.bits.total_leng;
		}
	}
	else
	{
		memset(MainBattery_error_list, 0, sizeof(MainBattery_error_list));
		memset(FL_DeviceInfo->FL.battery_error_list, 0, sizeof(FL_DeviceInfo->FL.battery_error_list));
		FL_DeviceInfo->FL.battery_error_leng = 0;
	}

	return RESPONSE_SUCCESS;
}


int MainBattDebugInfo00Handler(uint8_t* data, uint32_t leng)
{
	BAT_DEBUGINFO00_T debug_info = {0};
	COPY_MIN_ARRAY(data, leng, &debug_info.bytes[0], sizeof(debug_info.bytes));

	FL_DeviceInfo->FL.cell_1_volt = debug_info.bits.cell_1_volt;
	FL_DeviceInfo->FL.cell_2_volt = debug_info.bits.cell_2_volt;
	FL_DeviceInfo->FL.cell_3_volt = debug_info.bits.cell_3_volt;
	FL_DeviceInfo->FL.cell_4_volt = debug_info.bits.cell_4_volt;

	return RESPONSE_SUCCESS;
}


int MainBattDebugInfo01Handler(uint8_t* data, uint32_t leng)
{
	BAT_DEBUGINFO01_T debug_info = { 0 };
	COPY_MIN_ARRAY(data, leng, &debug_info.bytes[0], sizeof(debug_info.bytes));

	FL_DeviceInfo->FL.cell_5_volt = debug_info.bits.cell_5_volt;
	FL_DeviceInfo->FL.cell_6_volt = debug_info.bits.cell_6_volt;
	FL_DeviceInfo->FL.cell_7_volt = debug_info.bits.cell_7_volt;
	FL_DeviceInfo->FL.cell_8_volt = debug_info.bits.cell_8_volt;

	return RESPONSE_SUCCESS;
}


int MainBattDebugInfo02Handler(uint8_t* data, uint32_t leng)
{
	BAT_DEBUGINFO02_T debug_info = { 0 };
	COPY_MIN_ARRAY(data, leng, &debug_info.bytes[0], sizeof(debug_info.bytes));

	FL_DeviceInfo->FL.cell_9_volt = debug_info.bits.cell_9_volt;
	FL_DeviceInfo->FL.cell_10_volt = debug_info.bits.cell_10_volt;
	FL_DeviceInfo->FL.cell_11_volt = debug_info.bits.cell_11_volt;
	FL_DeviceInfo->FL.cell_12_volt = debug_info.bits.cell_12_volt;

	return RESPONSE_SUCCESS;
}


int MainBattDebugInfo03Handler(uint8_t* data, uint32_t leng)
{
	BAT_DEBUGINFO03_T debug_info = { 0 };
	COPY_MIN_ARRAY(data, leng, &debug_info.bytes[0], sizeof(debug_info.bytes));

	FL_DeviceInfo->FL.cell_13_volt = debug_info.bits.cell_13_volt;
	FL_DeviceInfo->FL.cell_14_volt = debug_info.bits.cell_14_volt;
	FL_DeviceInfo->FL.cell_15_volt = debug_info.bits.cell_15_volt;
	FL_DeviceInfo->FL.cell_16_volt = debug_info.bits.cell_16_volt;

	return RESPONSE_SUCCESS;
}


int MainBattDebugInfo04Handler(uint8_t* data, uint32_t leng)
{
	BAT_DEBUGINFO04_T debug_info = { 0 };
	COPY_MIN_ARRAY(data, leng, &debug_info.bytes[0], sizeof(debug_info.bytes));

	FL_DeviceInfo->FL.cell_17_volt = debug_info.bits.cell_17_volt;
	FL_DeviceInfo->FL.cell_18_volt = debug_info.bits.cell_18_volt;
	FL_DeviceInfo->FL.cell_19_volt = debug_info.bits.cell_19_volt;
	FL_DeviceInfo->FL.cell_20_volt = debug_info.bits.cell_20_volt;

	return RESPONSE_SUCCESS;
}


int MainBattDebugInfo05Handler(uint8_t* data, uint32_t leng)
{
	BAT_DEBUGINFO05_T debug_info = { 0 };
	COPY_MIN_ARRAY(data, leng, &debug_info.bytes[0], sizeof(debug_info.bytes));

	FL_DeviceInfo->FL.battery_temperature_1 = debug_info.bits.temperature_1;
	FL_DeviceInfo->FL.battery_temperature_2 = debug_info.bits.temperature_2;
	FL_DeviceInfo->FL.battery_temperature_3 = debug_info.bits.temperature_3;
	FL_DeviceInfo->FL.battery_temperature_4 = debug_info.bits.temperature_4;
	FL_DeviceInfo->FL.battery_temperature_5 = debug_info.bits.temperature_5;
	FL_DeviceInfo->FL.battery_temperature_6 = debug_info.bits.temperature_6;
	FL_DeviceInfo->FL.battery_temperature_7 = debug_info.bits.temperature_7;
	FL_DeviceInfo->FL.battery_temperature_8 = debug_info.bits.temperature_8;

	return RESPONSE_SUCCESS;
}



/*
	Parameter Operation function
*/

void FL_CAN_ReadParameter_Requset(
	uint8_t device_id, 
	uint8_t bank_index, 
	uint32_t addr,
	uint16_t leng, 
	RequestDoneCallback_t done_callback,
	ErrorCallback_t err_callback)
{
	ISOTP_PortInfo_T* Sender = &ISOTP_Port_DeviceParamSend;
	ISOTP_PortInfo_T* Reciver = &ISOTP_Port_DeviceParamRecive;

	uint32_t crc = 0;
	Sender->buff_leng = 0;

	switch (device_id)
	{
	case SDK_FL_HMI:
		FL_DevicePara.actived_device = DEVICE_OBJ_HMI;
		Sender->CAN_ID = FL_ISOTP_CANID_PARAM_ANY_2_HMI;
		Sender->is_extend_id = true;
		Reciver->CAN_ID = FL_ISOTP_CANID_PARAM_HMI_2_ANY;
		Reciver->is_extend_id = true;
		break;

	case SDK_FL_CONTROLLER:
		FL_DevicePara.actived_device = DEVICE_OBJ_CONTROLLER;
		Sender->CAN_ID = FL_ISOTP_CANID_PARAM_ANY_2_CONTROLLER;
		Sender->is_extend_id = true;
		Reciver->CAN_ID = FL_ISOTP_CANID_PARAM_CONTROLLER_2_ANY;
		Reciver->is_extend_id = true;
		break;

	case SDK_FL_MAIN_BATT:
		FL_DevicePara.actived_device = DEVICE_OBJ_MAIN_BATT;
		Sender->CAN_ID = FL_ISOTP_CANID_PARAM_ANY_2_MAINBATT;
		Sender->is_extend_id = true;
		Reciver->CAN_ID = FL_ISOTP_CANID_PARAM_MAINBATT_2_ANY;
		Reciver->is_extend_id = true;
		break;

	case SDK_FL_SUB_BATT1:
		FL_DevicePara.actived_device = DEVICE_OBJ_MAIN_BATT;
		Sender->CAN_ID = FL_ISOTP_CANID_PARAM_ANY_2_SUBBATT1;
		Sender->is_extend_id = true;
		Reciver->CAN_ID = FL_ISOTP_CANID_PARAM_SUBBATT1_2_ANY;
		Reciver->is_extend_id = true;
		break;

	case SDK_FL_SUB_BATT2:
		FL_DevicePara.actived_device = DEVICE_OBJ_MAIN_BATT;
		Sender->CAN_ID = FL_ISOTP_CANID_PARAM_ANY_2_SUBBATT2;
		Sender->is_extend_id = true;
		Reciver->CAN_ID = FL_ISOTP_CANID_PARAM_SUBBATT2_2_ANY;
		Reciver->is_extend_id = true;
		break;

	}

	Sender->buff_p[Sender->buff_leng++] = OPC_READ_PARAM;
	Sender->buff_p[Sender->buff_leng++] = bank_index;
	Sender->buff_p[Sender->buff_leng++] = (uint8_t)(addr);
	Sender->buff_p[Sender->buff_leng++] = (uint8_t)(addr >> 8);
	Sender->buff_p[Sender->buff_leng++] = (uint8_t)(leng );
	Sender->buff_p[Sender->buff_leng++] = (uint8_t)(leng >> 8);

	crc = FarmlandCalCrc32(Sender->buff_p, Sender->buff_leng, 0);

	Sender->buff_p[Sender->buff_leng++] = (uint8_t)(crc);
	Sender->buff_p[Sender->buff_leng++] = (uint8_t)(crc >> 8);
	Sender->buff_p[Sender->buff_leng++] = (uint8_t)(crc >> 16);
	Sender->buff_p[Sender->buff_leng++] = (uint8_t)(crc >> 24);
	

	Sender->exception_callback = err_callback;
	Reciver->revice_packet_callback = ParameterResponHandler;
	Reciver->exception_callback = err_callback;

	RequestDoneCall = done_callback;

	ISOTP_SenderDelegate(FL_ISOTP, Sender, Reciver);

}


void FL_CAN_WriteParameter_Requset(
	uint8_t device_id,
	uint8_t bank_index,
	uint32_t addr,
	uint16_t leng,
	uint8_t* data,
	RequestDoneCallback_t done_callback,
	ErrorCallback_t err_callback)
{
	ISOTP_PortInfo_T* Sender = &ISOTP_Port_DeviceParamSend;
	ISOTP_PortInfo_T* Reciver = &ISOTP_Port_DeviceParamRecive;

	uint32_t crc = 0;
	uint16_t index = 0;
	Sender->buff_leng = 0;

	switch (device_id)
	{
	case SDK_FL_HMI:
		FL_DevicePara.actived_device = DEVICE_OBJ_HMI;
		Sender->CAN_ID = FL_ISOTP_CANID_PARAM_ANY_2_HMI;
		Sender->is_extend_id = true;
		Reciver->CAN_ID = FL_ISOTP_CANID_PARAM_HMI_2_ANY;
		Reciver->is_extend_id = true;
		break;

	case SDK_FL_CONTROLLER:
		FL_DevicePara.actived_device = DEVICE_OBJ_CONTROLLER;
		Sender->CAN_ID = FL_ISOTP_CANID_PARAM_ANY_2_CONTROLLER;
		Sender->is_extend_id = true;
		Reciver->CAN_ID = FL_ISOTP_CANID_PARAM_CONTROLLER_2_ANY;
		Reciver->is_extend_id = true;
		break;

	case SDK_FL_MAIN_BATT:
		FL_DevicePara.actived_device = DEVICE_OBJ_MAIN_BATT;
		Sender->CAN_ID = FL_ISOTP_CANID_PARAM_ANY_2_MAINBATT;
		Sender->is_extend_id = true;
		Reciver->CAN_ID = FL_ISOTP_CANID_PARAM_MAINBATT_2_ANY;
		Reciver->is_extend_id = true;
		break;

	case SDK_FL_SUB_BATT1:
		FL_DevicePara.actived_device = DEVICE_OBJ_MAIN_BATT;
		Sender->CAN_ID = FL_ISOTP_CANID_PARAM_ANY_2_SUBBATT1;
		Sender->is_extend_id = true;
		Reciver->CAN_ID = FL_ISOTP_CANID_PARAM_SUBBATT1_2_ANY;
		Reciver->is_extend_id = true;
		break;

	case SDK_FL_SUB_BATT2:
		FL_DevicePara.actived_device = DEVICE_OBJ_MAIN_BATT;
		Sender->CAN_ID = FL_ISOTP_CANID_PARAM_ANY_2_SUBBATT2;
		Sender->is_extend_id = true;
		Reciver->CAN_ID = FL_ISOTP_CANID_PARAM_SUBBATT2_2_ANY;
		Reciver->is_extend_id = true;
		break;

	}

	Sender->buff_p[Sender->buff_leng++] = OPC_WRITE_PARAM;
	Sender->buff_p[Sender->buff_leng++] = bank_index;
	Sender->buff_p[Sender->buff_leng++] = (uint8_t)(addr);
	Sender->buff_p[Sender->buff_leng++] = (uint8_t)(addr >> 8);
	Sender->buff_p[Sender->buff_leng++] = (uint8_t)(leng);
	Sender->buff_p[Sender->buff_leng++] = (uint8_t)(leng >> 8);

	for (index = 0 ; index < leng ; index++ )
	{
		Sender->buff_p[Sender->buff_leng++] = data[index];
	}

	crc = FarmlandCalCrc32(Sender->buff_p, Sender->buff_leng, 0);

	Sender->buff_p[Sender->buff_leng++] = (uint8_t)(crc);
	Sender->buff_p[Sender->buff_leng++] = (uint8_t)(crc >> 8);
	Sender->buff_p[Sender->buff_leng++] = (uint8_t)(crc >> 16);
	Sender->buff_p[Sender->buff_leng++] = (uint8_t)(crc >> 24);


	Sender->exception_callback = err_callback;
	Reciver->revice_packet_callback = ParameterResponHandler;
	Reciver->exception_callback = err_callback;

	RequestDoneCall = done_callback;

	ISOTP_SenderDelegate(FL_ISOTP, Sender, Reciver);

}

void FL_CAN_ReadParameter(SDKDeviceType_e sdk_device_type, uint8_t bank_index, uint32_t addr, uint16_t leng, uint8_t *out_data)
{
	switch (sdk_device_type)
	{
	case SDK_FL_HMI:
	{
		LoadDeviceParameter(&FL_DevicePara.HMI, bank_index, addr, leng, out_data);
	}
	break;

	case SDK_FL_CONTROLLER:
	{
		LoadDeviceParameter(&FL_DevicePara.Controller, bank_index, addr, leng, out_data);
	}
	break;

	case SDK_FL_MAIN_BATT:
	{
		LoadDeviceParameter(&FL_DevicePara.MainBatt, bank_index, addr, leng, out_data);
	}
	break;

	case SDK_FL_SUB_BATT1:
	{
		LoadDeviceParameter(&FL_DevicePara.Slave1Batt, bank_index, addr, leng, out_data);
	}
	break;

	case SDK_FL_DISPLAY:
	{
		LoadDeviceParameter(&FL_DevicePara.Display, bank_index, addr, leng, out_data);
	}

	default:
		break;
	}
}




/*
	Upgrade Frimware functions
*/

static bool SetISOTPPortToDFU(uint8_t sdk_device_type, ISOTP_PortInfo_T* sender_port, ISOTP_PortInfo_T* reciver_port)
{
	switch (sdk_device_type)
	{
	case SDK_FL_HMI:
		sender_port->CAN_ID = FL_ISOTP_CANID_DFU_ANY_2_HMI;
		sender_port->is_extend_id = true;
		reciver_port->CAN_ID = FL_ISOTP_CANID_DFU_HMI_2_ANY;
		reciver_port->is_extend_id = true;
		break;

	case SDK_FL_CONTROLLER:
		sender_port->CAN_ID = FL_ISOTP_CANID_DFU_ANY_2_CONTROLLER;
		sender_port->is_extend_id = true;
		reciver_port->CAN_ID = FL_ISOTP_CANID_DFU_CONTROLLER_2_ANY;
		reciver_port->is_extend_id = true;
		break;

	case SDK_FL_MAIN_BATT:
		sender_port->CAN_ID = FL_ISOTP_CANID_DFU_ANY_2_MAINBATT;
		sender_port->is_extend_id = true;
		reciver_port->CAN_ID = FL_ISOTP_CANID_DFU_MAINBATT_2_ANY;
		reciver_port->is_extend_id = true;
		break;

	case SDK_FL_SUB_BATT1:
		sender_port->CAN_ID = FL_ISOTP_CANID_DFU_ANY_2_SUBBATT1;
		sender_port->is_extend_id = true;
		reciver_port->CAN_ID = FL_ISOTP_CANID_DFU_SUBBATT1_2_ANY;
		reciver_port->is_extend_id = true;
		break;

	case SDK_FL_SUB_BATT2:
		sender_port->CAN_ID = FL_ISOTP_CANID_DFU_ANY_2_SUBBATT2;
		sender_port->is_extend_id = true;
		reciver_port->CAN_ID = FL_ISOTP_CANID_DFU_SUBBATT2_2_ANY;
		reciver_port->is_extend_id = true;
		break;


	default:
		return false;
	}

	sender_port->buff_index = 0;
	sender_port->buff_leng = 0;

	reciver_port->buff_leng = 0;
	reciver_port->buff_index = 0;

	return true;
}




struct DFU_device_information_st dfu_device_info;


void FL_CAN_DFU_DeviceInfo_Set(struct DFU_device_information_st setting)
{
	dfu_device_info.flash_size = setting.flash_size;
	dfu_device_info.page_size = setting.page_size;
	dfu_device_info.cache_size = setting.cache_size;
	dfu_device_info.identifier = setting.identifier;
	dfu_device_info.block_index = setting.block_index;
	dfu_device_info.init_data = setting.init_data;
}


void FL_CAN_DFU_DeviceInfo_Get(struct DFU_device_information_st* setting)
{
	setting->flash_size = dfu_device_info.flash_size;
	setting->page_size = dfu_device_info.page_size;
	setting->cache_size = dfu_device_info.cache_size;
	setting->identifier = dfu_device_info.identifier;
	setting->block_index = dfu_device_info.block_index;
	setting->init_data = dfu_device_info.init_data;
}

static void FL_CAN_DFU_FlashCRC_Set(uint32_t crc)
{
	dfu_device_info.flash_crc = crc;
}

uint32_t FL_CAN_DFU_FlashCRC_Get(void)
{
	return dfu_device_info.flash_crc;
}

int DFUResponseHandler(uint8_t* data, uint32_t leng)
{
	uint8_t operation_code = data[0];
	uint8_t response_code = data[1];

	if (response_code != RESPONSE_SUCCESS)
	{

	}

	switch (operation_code)
	{
	case OPC_JUMP_BOOTLOADER:
	{
		
	}
	break;

	case OPC_JUMP_APPLICATION:
	{

	}
	break;

	case OPC_READ_OBJ_INFO:
	{
		if (leng < 18)
		{
			break;
		}
		uint8_t flash_init = data[2];
		uint16_t identifier = data[3] + (data[4] << 8);
		uint16_t block_index = data[5] + (data[6] << 8);
		uint32_t flash_size = data[7] + (data[8] << 8) + (data[9] << 16);
		uint16_t page_size = data[10] + (data[11] << 8);
		uint16_t cache_size = data[12] + (data[13] << 8);
		uint32_t get_crc = data[14] + (data[15] << 8) + (data[16] << 16) + (data[17] << 24);
		uint32_t check_crc = FarmlandCalCrc32(data, (leng - 4), 0);

		if (check_crc == get_crc)
		{
			dfu_device_info.init_data = flash_init;
			dfu_device_info.identifier = identifier;
			dfu_device_info.block_index = block_index;
			dfu_device_info.flash_size = flash_size;
			dfu_device_info.page_size = page_size;
			dfu_device_info.cache_size = cache_size;
		}
	}
	break;

	case OPC_WRITE_OBJ_INFO:
	{
		
	}
	break;

	case OPC_EARSE_FLASH:
	{

	}
	break;

	case OPC_WRITE_TO_CACHE:
	{

	}
	break;

	case OPC_PROGRAM_FLASH:
	{

	}
	break;

	case OPC_VERIFY_FLASH:
	{
		uint32_t crc = data[2] + (data[3] << 8) + (data[4] << 16) + (data[5] << 24);
		FL_CAN_DFU_FlashCRC_Set(crc);
	}
	break;

	}

	if (RequestDoneCall)
	{
		RequestDoneCall();
	}

	return 0;
}


void FL_CAN_DFU_JumpBootloader_Requset(
	uint8_t device_id,
	uint8_t command_0,
	uint8_t command_1,
	uint8_t command_2,
	RequestDoneCallback_t done_callback,
	ErrorCallback_t err_callback)
{
	ISOTP_PortInfo_T* Sender = &ISOTP_Port_DeviceDFUSend;
	ISOTP_PortInfo_T* Reciver = &ISOTP_Port_DeviceDFURecive;	

	if (SetISOTPPortToDFU(device_id, Sender, Reciver))
	{
		Sender->buff_p[Sender->buff_leng++] = OPC_JUMP_BOOTLOADER;
		Sender->buff_p[Sender->buff_leng++] = command_0;
		Sender->buff_p[Sender->buff_leng++] = command_1;
		Sender->buff_p[Sender->buff_leng++] = command_2;

		Sender->exception_callback = err_callback;
		Reciver->exception_callback = err_callback;

		RequestDoneCall = done_callback;

		ISOTP_SenderDelegate(FL_ISOTP, Sender, Reciver);
	}
}


void FL_CAN_DFU_JumpApplication_Requset(
	uint8_t device_id,
	RequestDoneCallback_t done_callback,
	ErrorCallback_t err_callback)
{
	ISOTP_PortInfo_T* Sender = &ISOTP_Port_DeviceDFUSend;
	ISOTP_PortInfo_T* Reciver = &ISOTP_Port_DeviceDFURecive;

	if (SetISOTPPortToDFU(device_id, Sender, Reciver))
	{
		Sender->buff_p[Sender->buff_leng++] = OPC_JUMP_APPLICATION;
		Sender->buff_p[Sender->buff_leng++] = 0;
		Sender->buff_p[Sender->buff_leng++] = 0;
		Sender->buff_p[Sender->buff_leng++] = 0;

		Sender->exception_callback = err_callback;
		Reciver->exception_callback = err_callback;

		RequestDoneCall = done_callback;

		ISOTP_SenderDelegate(FL_ISOTP, Sender, Reciver);
	}
}


void FL_CAN_DFU_ReadDeviceInfomation_Requset(
	uint8_t device_id,
	RequestDoneCallback_t done_callback,
	ErrorCallback_t err_callback)
{
	ISOTP_PortInfo_T* Sender = &ISOTP_Port_DeviceDFUSend;
	ISOTP_PortInfo_T* Reciver = &ISOTP_Port_DeviceDFURecive;

	if (SetISOTPPortToDFU(device_id, Sender, Reciver))
	{
		Sender->buff_p[Sender->buff_leng++] = OPC_READ_OBJ_INFO;

		Sender->exception_callback = err_callback;
		Reciver->exception_callback = err_callback;

		RequestDoneCall = done_callback;

		ISOTP_SenderDelegate(FL_ISOTP, Sender, Reciver);
	}
}


void FL_CAN_DFU_WriteDeviceInformation_Requset(
	uint8_t device_id,
	uint16_t identifier,
	RequestDoneCallback_t done_callback,
	ErrorCallback_t err_callback)
{
	ISOTP_PortInfo_T* Sender = &ISOTP_Port_DeviceDFUSend;
	ISOTP_PortInfo_T* Reciver = &ISOTP_Port_DeviceDFURecive;

	if (SetISOTPPortToDFU(device_id, Sender, Reciver))
	{
		Sender->buff_p[Sender->buff_leng++] = OPC_WRITE_OBJ_INFO;
		Sender->buff_p[Sender->buff_leng++] = (uint8_t)identifier;
		Sender->buff_p[Sender->buff_leng++] = (uint8_t)(identifier >> 8);

		Sender->exception_callback = err_callback;
		Reciver->exception_callback = err_callback;

		RequestDoneCall = done_callback;

		ISOTP_SenderDelegate(FL_ISOTP, Sender, Reciver);
	}
}


void FL_CAN_DFU_EraseFlash_Requset(
	uint8_t device_id,
	uint32_t start_addr,
	uint32_t end_addr,
	RequestDoneCallback_t done_callback,
	ErrorCallback_t err_callback)
{
	ISOTP_PortInfo_T* Sender = &ISOTP_Port_DeviceDFUSend;
	ISOTP_PortInfo_T* Reciver = &ISOTP_Port_DeviceDFURecive;

	if (SetISOTPPortToDFU(device_id, Sender, Reciver))
	{
		Sender->buff_p[Sender->buff_leng++] = OPC_EARSE_FLASH;
		Sender->buff_p[Sender->buff_leng++] = start_addr;
		Sender->buff_p[Sender->buff_leng++] = (start_addr >> 8);
		Sender->buff_p[Sender->buff_leng++] = (start_addr >> 16);
		Sender->buff_p[Sender->buff_leng++] = end_addr;
		Sender->buff_p[Sender->buff_leng++] = (end_addr >> 8);
		Sender->buff_p[Sender->buff_leng++] = (end_addr >> 16);

		uint32_t crc = FarmlandCalCrc32(Sender->buff_p, (uint32_t)Sender->buff_leng, 0);

		Sender->buff_p[Sender->buff_leng++] = (uint8_t)(crc);
		Sender->buff_p[Sender->buff_leng++] = (uint8_t)(crc >> 8);
		Sender->buff_p[Sender->buff_leng++] = (uint8_t)(crc >> 16);
		Sender->buff_p[Sender->buff_leng++] = (uint8_t)(crc >> 24);

		Sender->exception_callback = err_callback;
		Reciver->exception_callback = err_callback;

		RequestDoneCall = done_callback;

		ISOTP_SenderDelegate(FL_ISOTP, Sender, Reciver);
	}
}



void FL_CAN_DFU_WriteToCache_Requset(
	uint8_t device_id,
	uint16_t cache_addr,
	uint16_t cache_leng,
	uint8_t * cache_data,
	RequestDoneCallback_t done_callback,
	ErrorCallback_t err_callback)
{
	uint16_t index = 0;
	ISOTP_PortInfo_T* Sender = &ISOTP_Port_DeviceDFUSend;
	ISOTP_PortInfo_T* Reciver = &ISOTP_Port_DeviceDFURecive;

	if (SetISOTPPortToDFU(device_id, Sender, Reciver))
	{
		Sender->buff_p[Sender->buff_leng++] = OPC_WRITE_TO_CACHE;
		Sender->buff_p[Sender->buff_leng++] = (uint8_t)cache_addr;
		Sender->buff_p[Sender->buff_leng++] = (uint8_t)(cache_addr >> 8);
		Sender->buff_p[Sender->buff_leng++] = (uint8_t)cache_leng;
		Sender->buff_p[Sender->buff_leng++] = (uint8_t)(cache_leng >> 8);

		for (index = 0 ; index < cache_leng ; index++)
		{
			Sender->buff_p[Sender->buff_leng++] = cache_data[index];
		}

		uint32_t crc = FarmlandCalCrc32(Sender->buff_p, Sender->buff_leng, 0);

		Sender->buff_p[Sender->buff_leng++] = (uint8_t)(crc);
		Sender->buff_p[Sender->buff_leng++] = (uint8_t)(crc >> 8);
		Sender->buff_p[Sender->buff_leng++] = (uint8_t)(crc >> 16);
		Sender->buff_p[Sender->buff_leng++] = (uint8_t)(crc >> 24);

		Sender->exception_callback = err_callback;
		Reciver->exception_callback = err_callback;

		RequestDoneCall = done_callback;

		ISOTP_SenderDelegate(FL_ISOTP, Sender, Reciver);
	}
}



void FL_CAN_DFU_ProgramFlash_Requset(
	uint8_t device_id,
	uint32_t offset_addr,
	uint32_t data_leng,
	RequestDoneCallback_t done_callback,
	ErrorCallback_t err_callback)
{
	ISOTP_PortInfo_T* Sender = &ISOTP_Port_DeviceDFUSend;
	ISOTP_PortInfo_T* Reciver = &ISOTP_Port_DeviceDFURecive;

	if (SetISOTPPortToDFU(device_id, Sender, Reciver))
	{
		Sender->buff_p[Sender->buff_leng++] = OPC_PROGRAM_FLASH;
		Sender->buff_p[Sender->buff_leng++] = offset_addr;
		Sender->buff_p[Sender->buff_leng++] = (offset_addr >> 8);
		Sender->buff_p[Sender->buff_leng++] = (offset_addr >> 16);
		Sender->buff_p[Sender->buff_leng++] = data_leng;
		Sender->buff_p[Sender->buff_leng++] = (data_leng >> 8);

		Sender->exception_callback = err_callback;
		Reciver->exception_callback = err_callback;

		RequestDoneCall = done_callback;

		ISOTP_SenderDelegate(FL_ISOTP, Sender, Reciver);
	}
}


void FL_CAN_DFU_VerifyFlash_Requset(
	uint8_t device_id,
	uint32_t start_addr,
	uint32_t end_addr,
	RequestDoneCallback_t done_callback,
	ErrorCallback_t err_callback)
{
	ISOTP_PortInfo_T* Sender = &ISOTP_Port_DeviceDFUSend;
	ISOTP_PortInfo_T* Reciver = &ISOTP_Port_DeviceDFURecive;

	if (SetISOTPPortToDFU(device_id, Sender, Reciver))
	{
		Sender->buff_p[Sender->buff_leng++] = OPC_VERIFY_FLASH;
		Sender->buff_p[Sender->buff_leng++] = start_addr;
		Sender->buff_p[Sender->buff_leng++] = (start_addr >> 8);
		Sender->buff_p[Sender->buff_leng++] = (start_addr >> 16);
		Sender->buff_p[Sender->buff_leng++] = end_addr;
		Sender->buff_p[Sender->buff_leng++] = (end_addr >> 8);
		Sender->buff_p[Sender->buff_leng++] = (start_addr >> 16);

		uint32_t crc = FarmlandCalCrc32(Sender->buff_p, Sender->buff_leng, 0);

		Sender->buff_p[Sender->buff_leng++] = (uint8_t)(crc);
		Sender->buff_p[Sender->buff_leng++] = (uint8_t)(crc >> 8);
		Sender->buff_p[Sender->buff_leng++] = (uint8_t)(crc >> 16);
		Sender->buff_p[Sender->buff_leng++] = (uint8_t)(crc >> 24);

		Sender->exception_callback = err_callback;
		Reciver->exception_callback = err_callback;

		RequestDoneCall = done_callback;

		ISOTP_SenderDelegate(FL_ISOTP, Sender, Reciver);
	}
}

/*

	Send Common

*/

void FL_CAN_HostCommon_Info_00_Create( uint8_t assist_lv, bool sys_power_on, bool walk_assit_on, bool light_on)
{
	HOST_CONTROLINFO_00_T info = { 0 };

	info.bits.set_assist_level = assist_lv;
	info.bits.system_power_control = sys_power_on;
	info.bits.walk_assist_control = walk_assit_on;
	info.bits.light_control = light_on;

	if (CAN_sender)
	{
		CAN_sender(FL_CANID_HOST_INFO_00, false, info.bytes, sizeof(info.bytes));
	}
}



void FL_CAN_HostCommon_Info_01_Create(uint64_t unix_time)
{
	HOST_CONTROLINFO_01_T info = { 0 };

	info.bits.unix_time = unix_time;

	if (CAN_sender)
	{
		CAN_sender(FL_CANID_HOST_INFO_01, false, info.bytes, sizeof(info.bytes));
	}
}


void FL_CAN_HostCommon_Info_02_Send(bool silence_mode_en, uint8_t timeout)
{
	HOST_CONTROLINFO_02_T info = { 0 };

	info.bits.silence_mode = silence_mode_en;
	info.bits.silence_timeout = timeout;

	if (CAN_sender)
	{
		CAN_sender(FL_CANID_HOST_INFO_02, false, info.bytes, sizeof(info.bytes));
	}
}


void FL_CAN_HostCommon_ResetReq_Send(DeviceObjTypes target_device)
{
	HOST_DEVICE_RESET_REQ_T request = { 0 };

	request.bits.device_type = target_device;


	if (CAN_sender)
	{
		CAN_sender(FL_CANID_HOST_INFO_02, false, request.bytes, sizeof(request.bytes));
	}
}


void FL_CAN_HostCommon_TestReq_Send(DeviceObjTypes target_device, uint8_t test_mode, uint32_t test_val,
	RequestDoneCallback_t done_callback,
	ErrorCallback_t err_callback)
{
	HOST_DEVICE_TEST_REQ_T request = { 0 };

	request.bits.device_type = target_device;
	request.bits.test_mode = test_mode;
	request.bits.test_val = test_val;

	RequestDoneCall = done_callback;

	if (CAN_sender)
	{
		CAN_sender(FL_CANID_HOST_DEVICE_TEST_REQ, false, request.bytes, sizeof(request.bytes));
	}
}


void FL_CAN_HostCommon_DebugReq_Send(DeviceObjTypes target_device, uint8_t debug_mode, uint8_t msg_repet, uint16_t msg_interval,
	RequestDoneCallback_t done_callback,
	ErrorCallback_t err_callback)
{
	HOST_DEVICE_DEBUG_REQ_T request = { 0 };

	request.bits.device_type = target_device;
	request.bits.debug_index = debug_mode;
	request.bits.debug_count = msg_repet;
	request.bits.interval_time = msg_interval;

	RequestDoneCall = done_callback;

	FL_HostCommon.actived = true;
	FL_HostCommon.common = FL_CANID_HOST_DEVICE_DEBUG_REQ;
	FL_HostCommon.device_id = target_device;

	if (CAN_sender)
	{
		CAN_sender(FL_CANID_HOST_DEVICE_DEBUG_REQ, false, request.bytes, sizeof(request.bytes));
	}
}

void FL_CAN_HostCommon_BattCTRL_Send(uint8_t battery_index, bool charge_on, bool discharge_on)
{
	HOST_DEVICE_BATT_CTL_REQ_T request = { 0 };

	request.bits.battery_index = battery_index;
	request.bits.charge = charge_on;
	request.bits.discharge = discharge_on;

	if (CAN_sender)
	{
		CAN_sender(FL_CANID_HOST_BATT_CTL_REQ, false, request.bytes, sizeof(request.bytes));
	}
}

void FL_CAN_HostCommon_RegResponseHandler(uint8_t device_id, uint8_t req_commond, RequestDoneCallback_t RequestDone_Callback)
{
	FL_HostCommon.actived = true;
	FL_HostCommon.device_id = device_id;
	FL_HostCommon.common = req_commond;
	RequestDoneCall = RequestDone_Callback;
}



int FL_CAN_TryPaser(uint32_t can_id, bool is_extend, uint8_t* data, uint8_t leng)
{
	uint32_t search_index = 0;
	uint32_t list_leng = GET_ARRAY_SIZE(vaild_id_list);

	if (data == NULL || leng == 0)
	{
		return -1;
	}

	while (search_index < list_leng)
	{
		if (vaild_id_list[search_index].is_extend == is_extend &&
			vaild_id_list[search_index].can_id == can_id)
		{
			return vaild_id_list[search_index].handler(data, leng);
		}
		search_index++;
	}
	return -1;
}

int FL_CAN_Init(DeviceInfoDefine* device_info_p, CANSenderHandlerFunc CAN_sender_handler, ISOTP_INST_T* isotp_inst)
{
	if (device_info_p && CAN_sender_handler && isotp_inst)
	{
		FL_DeviceInfo = device_info_p;
		CAN_sender = CAN_sender_handler;
		FL_ISOTP = isotp_inst;
		ISOTP_RegisterListenPort(FL_ISOTP, &ISOTP_Port_DeviceParamSend, &ISOTP_Port_DeviceParamRecive);
		ISOTP_RegisterListenPort(FL_ISOTP, &ISOTP_Port_DeviceDFUSend, &ISOTP_Port_DeviceDFURecive);


		return RESPONSE_SUCCESS;
	}
	else
	{
		return RESPONSE_NULL;
	}

}

#ifdef __cplusplus
}
#endif
