#pragma once
#pragma warning(disable:4996)
#pragma warning(disable:26812)

#ifndef _FL_CORE_SDK_H // include guard
#define _FL_CORE_SDK_H



#include "lib_event_scheduler.h"
#include "FL_CANInfoStruct.h"
#include "Common.h"
#include "CAN_ISO_TP.h"
#include "FL_Logs.h"

#define CSHARP_PLATORM	0
#define JAVA_PLATORM	1

#define SELECT_PLATORM	CSHARP_PLATORM

#if SELECT_PLATORM == JAVA_PLATORM

#include "android/log.h"

#define LOG_TAG "JNI/CPP_Log"

#define LogD(...) __android_log_print(ANDROID_LOG_DEBUG, LOG_TAG, __VA_ARGS__)
#define LogE(...) __android_log_print(ANDROID_LOG_ERROR, LOG_TAG, __VA_ARGS__)

#else

#define LogD(...) printf(__VA_ARGS__)
#define LogE(...) printf(__VA_ARGS__)

#endif

#ifdef _WIN32
#define DllExport   __declspec( dllexport )
#else
#define DllExport
#define __stdcall
#endif // _WIN32


#ifdef __cplusplus
extern "C" {
#endif

#define PARAMETER_ARR_SIZE	4096

	enum DllExport SDKReturnCode
	{
		SDK_RETURN_SUCCESS = 0U,
		SDK_RETURN_TIMEOUT,
		SDK_RETURN_INVALID_ADDR,
		SDK_RETURN_INVALID_SIZE,
		SDK_RETURN_INVALID_PARAM,
		SDK_RETURN_CRC_FAIL,
		SDK_RETURN_NULL,
		SDK_RETURN_NO_INIT,
		SDK_RETURN_NO_MEM,
		SDK_RETURN_ALREADY_EXIST,
	};

#define SDK_PARAM_VERIFY_NULL(_param_) if(_param_==NULL){ return SDK_RETURN_NULL;}


struct DllExport FL_Info_st
{
	unsigned int current_assist_lv;
	bool system_power_control;
	bool walk_assist_control;
	bool light_control;

	unsigned int support_assist_lv;
	bool power_key_status;
	bool up_key_status;
	bool down_key_status;
	bool walk_key_status;
	bool light_key_status;

	float trip_odo;	// Unit:1 km
	unsigned int trip_time_sec;

	float trip_avg_speed;	// Unit:0.1 km/hr
	float trip_max_speed;	// Unit:0.1 km/hr
	unsigned int trip_avg_current;	// Unit:1mA
	unsigned int trip_max_current;	// Unit:1mA
	unsigned int trip_avg_pedal_speed;	// Unit:RPM
	unsigned int trip_max_pedal_speed;	// Unit:RPM
	unsigned int trip_avg_pedal_torque; // Unit:1Nm
	unsigned int trip_max_pedal_torque; // Unit:1Nm

	unsigned int HMI_warning_list[28];
	unsigned int HMI_warning_leng;

	unsigned int HMI_error_list[28];
	unsigned int HMI_error_leng;

	unsigned int key_1_count;
	unsigned int key_2_count;
	unsigned int key_3_count;
	unsigned int key_4_count;

	unsigned int key_5_count;
	unsigned int key_6_count;
	unsigned int key_7_count;
	unsigned int key_8_count;

	float bike_speed;
	unsigned int motor_speed;
	unsigned int wheel_speed;
	float limit_speed;

	float bus_voltage;
	float avg_bus_current;
	float light_current;
	unsigned int avg_output_amplitube;
	int controller_temperature;

	unsigned int throttle_amplitube;
	unsigned int pedal_cadence;
	float pedal_torque;
	float pedal_power;
	float total_odo;		
	float range_odo;

	unsigned int assist_level;
	unsigned int assist_type;
	bool assist_on;
	bool front_light_on;
	bool rear_light_on;
	bool activate_light_ctrl;
	bool brake_on;
	bool candence_direction;
	bool motor_direction;

	unsigned int controller_warning_list[28];
	unsigned int controller_warning_leng;

	unsigned int controller_error_list[28];
	unsigned int controller_error_leng;

	unsigned int zero_torque_volt;
	unsigned int current_torque_volt;
	unsigned int zero_throttle_volt;
	unsigned int current_throttle_volt;

	float actual_bus_current;
	float u_phase_current;
	float v_phase_current;
	float w_phase_current;

	unsigned int wheel_rotate_laps;
	unsigned int output_amplitude;
	unsigned char hall_state;
	unsigned char sector_state;

	bool charge_fet;
	bool charging;
	bool fully_charged;
	bool charge_detected;
	bool discharge_fet;
	bool discharging;
	bool nearly_discharged;
	bool fully_discharged;
	unsigned int design_volt;
	float design_capacity;
	unsigned int battery_cycle_count;
	unsigned int battery_uncharged_day;

	unsigned int battery_actual_volt;
	unsigned int battery_actual_current;

	signed char battery_temperature;

	unsigned int battery_rsoc;
	unsigned int battery_asoc;
	unsigned int battery_rsoh;
	unsigned int battery_asoh;

	unsigned long long sys_unix_time;

	unsigned int battery_warning_list[28];
	unsigned int battery_warning_leng;
	unsigned int battery_error_list[28];
	unsigned int battery_error_leng;

	unsigned int cell_1_volt;
	unsigned int cell_2_volt;
	unsigned int cell_3_volt;
	unsigned int cell_4_volt;
	unsigned int cell_5_volt;
	unsigned int cell_6_volt;
	unsigned int cell_7_volt;
	unsigned int cell_8_volt;
	unsigned int cell_9_volt;
	unsigned int cell_10_volt;
	unsigned int cell_11_volt;
	unsigned int cell_12_volt;
	unsigned int cell_13_volt;
	unsigned int cell_14_volt;
	unsigned int cell_15_volt;
	unsigned int cell_16_volt;
	unsigned int cell_17_volt;
	unsigned int cell_18_volt;
	unsigned int cell_19_volt;
	unsigned int cell_20_volt;

	int battery_temperature_1;
	int battery_temperature_2;
	int battery_temperature_3;
	int battery_temperature_4;
	int battery_temperature_5;
	int battery_temperature_6;
	int battery_temperature_7;
	int battery_temperature_8;
};


	typedef DllExport enum DeviceType_enum
	{
		SDK_FL_HMI = 1U,
		SDK_FL_CONTROLLER,
		SDK_FL_MAIN_BATT,
		SDK_FL_SUB_BATT1,
		SDK_FL_SUB_BATT2,
		SDK_FL_DISPLAY,
		SDK_FL_IOT,
		SDK_FL_E_DERAILLEUR,
		SDK_FL_E_LOCK,
		SDK_FL_DONGLE,
		SDK_UNKNOWN = 255U
	} SDKDeviceType_e;

	typedef DllExport enum RouterType_enum
	{
		SDK_ROUTER_BLE = 0U,
		SDK_ROUTER_CANBUS,
	} RouterType;


	typedef DllExport struct fReadParameter_Params_st
	{
		unsigned char data[PARAMETER_ARR_SIZE];
		unsigned int addr;
		unsigned int leng;
		unsigned char bank_index;
		SDKDeviceType_e device_type;
	} fReadParameter_Params_T;

	typedef DllExport struct DeviceLogs_st
	{
		unsigned int index;
		unsigned char dateTime_year;
		unsigned char dateTime_month;
		unsigned char dateTime_days;
		unsigned char dateTime_hour;
		unsigned char dateTime_minute;
		unsigned char dateTime_senond;
		unsigned int odo;

		bool charge_fet_on;
		bool charging;
		bool fully_charged;
		bool charge_detected;
		bool discharge_fet;
		bool discharging;
		bool nearly_discharged;
		bool fully_discharged;

		unsigned char error_code[8];
		unsigned char cell_count;
		unsigned int cell_volt[16];
		unsigned char temp_sensor_count;
		char temp_sensor[3];
		unsigned short bike_speed;
		unsigned short motor_speed;
		unsigned char RSOC;
		unsigned char assist_lv;
		unsigned char controller_avg_output;

	} DeviceLogs_T;

	typedef DllExport struct DeviceInfoDefine
	{
		struct FL_Info_st FL;

	}DeviceInformation_T;


	typedef void(__stdcall* fpCallback_ReadParameters)(int return_state, SDKDeviceType_e target_device, unsigned char* read_buff, unsigned short addr, unsigned short leng, unsigned char bank_index);
	typedef void(__stdcall* fpCallback_WriteParameters)(int return_state);
	typedef void(__stdcall* fpCallback_ResetParameters)(int return_state);
	typedef void(__stdcall* fpCallback_UpgradeFirmware)(int return_state);
	typedef void(__stdcall* fpCallback_SetDebugMode)(int return_state);
	typedef void(__stdcall* fpCallback_SetTestMode)(int return_state);
	typedef void(__stdcall* fpCallback_GetCanIdBypassList)(int return_state, unsigned char mode, unsigned char id_count, unsigned char* id_list);
	typedef void(__stdcall* fpCallback_SetCanIdBypassAllowList)(int return_state);
	typedef void(__stdcall* fpCallback_SetCanIdBypassBlockList)(int return_state);
	typedef void(__stdcall* fpCallback_RestartDevice)(int return_state);
	typedef void(__stdcall* fpCallback_ReadDeviceLogs)(int return_state, SDKDeviceType_e target_device, DeviceLogs_T* logs_list, int logs_leng);
	typedef void(__stdcall* fpCallback_ClearDeviceLogs)(int return_state);
	typedef void(__stdcall* fpCallback_ConfigSysTime)(int return_state);

	typedef void (__stdcall *UpgradeStateMsg_p)(const char* out_msg, int progress_value);

	typedef struct DllExport DelegateFuncDefine_st
	{
		int (__stdcall *ReadParameters)(RouterType router, SDKDeviceType_e target_device, unsigned short addr, unsigned short leng, unsigned char bank_index, fpCallback_ReadParameters callback);
		int (__stdcall *WriteParameters)(RouterType router, SDKDeviceType_e target_device,	unsigned short addr, unsigned short leng,	unsigned char bank_index, unsigned char* data, fpCallback_WriteParameters callback);
		int(__stdcall* ResetParameters)(RouterType router, SDKDeviceType_e target_device, unsigned char bank_index, fpCallback_ResetParameters callback);

		
		int(__stdcall* UpgradeFirmware)(RouterType router, SDKDeviceType_e target_device, unsigned char* device_MID, unsigned char* data, unsigned int data_size, UpgradeStateMsg_p upgrade_msg_callback, fpCallback_UpgradeFirmware callback);
		int(__stdcall* SetDebugMode)(RouterType router, SDKDeviceType_e target_device, unsigned char mode, unsigned char repet_cnt, unsigned short interval_time, fpCallback_SetDebugMode callback);
		int(__stdcall* SetTestMode)(RouterType router, SDKDeviceType_e target_device, unsigned char mode, unsigned int value, fpCallback_SetTestMode callback);
		int(__stdcall* GetCanIdBypassList)(RouterType router, fpCallback_GetCanIdBypassList callback);
		int(__stdcall* SetCanIdBypassAllowList)(RouterType router, unsigned char function_code, unsigned char id_list_count, unsigned char* id_list_data, fpCallback_SetCanIdBypassAllowList callback);
		int(__stdcall* SetCanIdBypassBlockList)(RouterType router, unsigned char function_code, unsigned char id_list_count, unsigned char* id_list_data, fpCallback_SetCanIdBypassBlockList callback);
		int(__stdcall* RestartDevice)(RouterType router, SDKDeviceType_e target_device, fpCallback_RestartDevice callback);
		int(__stdcall* ReadDeviceLogs)(RouterType router, SDKDeviceType_e target_device, fpCallback_ReadDeviceLogs callback);
		int(__stdcall* ClearDeviceLogs)(RouterType router, SDKDeviceType_e target_device, fpCallback_ClearDeviceLogs callback);

		// Unix time +0
		int(__stdcall* ConfigSysTime)(RouterType router, SDKDeviceType_e target_device, uint64_t unix_time, fpCallback_ConfigSysTime callback);
	} DelegateFuncDefine_T;


	typedef struct DllExport MethodDefine_st
	{
		int(__stdcall* CANBusPacket_IN)(unsigned int can_id, bool is_extender_id, unsigned char* raw_data, unsigned int leng);
		int (__stdcall *CANBusPacket_OUT)(unsigned int* can_id, bool* is_extender_id, unsigned char* data, unsigned int* leng);
		int(__stdcall* BLECommandPacket_IN)(unsigned char* data, unsigned int leng);
		int(__stdcall* BLECommandPacket_OUT)(unsigned char* data, unsigned int* leng);
		int(__stdcall* BLEDataPacket_IN)(unsigned char* data, unsigned int leng);
		int(__stdcall* BLEDataPacket_OUT)(unsigned char* data, unsigned int* leng);
	} MethodDefine_T;


	typedef DllExport struct FLCoreSDK_st
	{
		DeviceInformation_T DeviceInfo;
		unsigned char ParametersArray[PARAMETER_ARR_SIZE];
		unsigned char Version[20];
		int (__stdcall *Enable)(void);
		int (__stdcall *Disable)(void);
		void(__stdcall *InfoUpdateEvent)(DeviceInformation_T DeviceInfo);
		MethodDefine_T Method;
		DelegateFuncDefine_T DelegateMethod;
	} CoreSDKInst_T;
	

	DllExport int FarmLandCoreSDK_Init(CoreSDKInst_T* SDK_Inst);



#ifdef __cplusplus
}
#endif

#endif

