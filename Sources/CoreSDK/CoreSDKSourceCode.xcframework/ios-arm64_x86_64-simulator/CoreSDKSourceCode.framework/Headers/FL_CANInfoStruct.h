#pragma once
#ifndef _FL_CANINFOSTRUCT_H // include guard
#define _FL_CANINFOSTRUCT_H
#include <stdint.h>

#ifdef __cplusplus
extern "C" {
#endif
 
#pragma pack(1)

// Operate code
#define OPC_JUMP_BOOTLOADER		(uint8_t)1
#define OPC_JUMP_APPLICATION	(uint8_t)2
#define OPC_READ_OBJ_INFO		(uint8_t)3
#define OPC_WRITE_OBJ_INFO		(uint8_t)4
#define OPC_EARSE_FLASH			(uint8_t)5
#define OPC_WRITE_TO_CACHE		(uint8_t)6
#define OPC_PROGRAM_FLASH		(uint8_t)7
#define OPC_VERIFY_FLASH		(uint8_t)8
#define OPC_READ_PARAM			(uint8_t)9
#define OPC_WRITE_PARAM			(uint8_t)10
#define OPC_RESET_PARAM			(uint8_t)11
#define OPC_READ_LOG			(uint8_t)12
#define OPC_CLEAR_LOG			(uint8_t)13
#define OPC_UNLOCK_DEVICE		(uint8_t)20

// Response code
#define RESPONSE_SUCCESS		(uint8_t)0
#define RESPONSE_TIMEOUT		(uint8_t)1
#define RESPONSE_INVALID_ADDR	(uint8_t)2
#define RESPONSE_INVALID_SIZE	(uint8_t)3
#define RESPONSE_INVALID_PARAM	(uint8_t)4
#define RESPONSE_CRC_FAIL		(uint8_t)5
#define RESPONSE_NULL			(uint8_t)6


// Other define
#define WARNING_CODE_PAGE_SIZE	(uint8_t)4
#define WARNING_CODE_LIST_SIZE	(uint8_t)28

#define ERROR_CODE_PAGE_SIZE	(uint8_t)4
#define ERROR_CODE_LIST_SIZE	(uint8_t)28

// Device Object Type Define
typedef enum DEVICE_OBJ_TYPE_E
{
	DEVICE_OBJ_HMI = (uint8_t)0,
	DEVICE_OBJ_CONTROLLER,
	DEVICE_OBJ_MAIN_BATT,
	DEVICE_OBJ_SUB_BATT1,
	DEVICE_OBJ_SUB_BATT2,
	DEVICE_OBJ_DISPLAY,
	DEVICE_OBJ_IOT,
	DEVICE_OBJ_E_DERAILLEUR,
	DEVICE_OBJ_E_LOCK,
	DEVICE_OBJ_UNKNOWN = (uint8_t)255,
} DeviceObjTypes;

// ISO-TP CANID define
#define FL_ISOTP_CANID_DFU_ANY_2_HMI			(uint32_t)0x10000
#define FL_ISOTP_CANID_DFU_HMI_2_ANY			(uint32_t)0x10001
#define FL_ISOTP_CANID_DFU_ANY_2_CONTROLLER		(uint32_t)0x10010
#define FL_ISOTP_CANID_DFU_CONTROLLER_2_ANY		(uint32_t)0x10011
#define FL_ISOTP_CANID_DFU_ANY_2_MAINBATT		(uint32_t)0x10020
#define FL_ISOTP_CANID_DFU_MAINBATT_2_ANY		(uint32_t)0x10021
#define FL_ISOTP_CANID_DFU_ANY_2_SUBBATT1		(uint32_t)0x10030
#define FL_ISOTP_CANID_DFU_SUBBATT1_2_ANY		(uint32_t)0x10031
#define FL_ISOTP_CANID_DFU_ANY_2_SUBBATT2		(uint32_t)0x10040
#define FL_ISOTP_CANID_DFU_SUBBATT2_2_ANY		(uint32_t)0x10041

#define FL_ISOTP_CANID_PARAM_ANY_2_HMI			(uint32_t)0x10002
#define FL_ISOTP_CANID_PARAM_HMI_2_ANY			(uint32_t)0x10003
#define FL_ISOTP_CANID_PARAM_ANY_2_CONTROLLER	(uint32_t)0x10012
#define FL_ISOTP_CANID_PARAM_CONTROLLER_2_ANY	(uint32_t)0x10013
#define FL_ISOTP_CANID_PARAM_ANY_2_MAINBATT		(uint32_t)0x10022
#define FL_ISOTP_CANID_PARAM_MAINBATT_2_ANY		(uint32_t)0x10023
#define FL_ISOTP_CANID_PARAM_ANY_2_SUBBATT1		(uint32_t)0x10032
#define FL_ISOTP_CANID_PARAM_SUBBATT1_2_ANY		(uint32_t)0x10033
#define FL_ISOTP_CANID_PARAM_ANY_2_SUBBATT2		(uint32_t)0x10042
#define FL_ISOTP_CANID_PARAM_SUBBATT2_2_ANY		(uint32_t)0x10043

// Test Mode Code
#define FL_TESTMODE_STOP_TEST					(uint8_t)0x0

#define FL_TESTMODE_HMI_SEGMENT_ALL_BLINK		(uint8_t)0x1
#define FL_TESTMODE_HMI_SEGMENT_SCAN			(uint8_t)0x2
#define FL_TESTMODE_HMI_SEGMENT_ALL_ON			(uint8_t)0x3
#define FL_TESTMODE_HMI_SEGMENT_ALL_OFF			(uint8_t)0x4
#define FL_TESTMODE_HMI_BUTTON_DISABLE			(uint8_t)0x5


#define FL_TESTMODE_CTRL_DRIVE_TARGE_AMP		(uint8_t)0x1
#define FL_TESTMODE_CTRL_DRIVE_TARGE_SPEED		(uint8_t)0x2
#define FL_TESTMODE_CTRL_DRIVE_TARGE_CURRENT	(uint8_t)0x3
#define FL_TESTMODE_CTRL_DRIVE_TARGE_POWER		(uint8_t)0x4
#define FL_TESTMODE_CTRL_DRIVE_TARGE_DISTANCE	(uint8_t)0x5
#define FL_TESTMODE_CTRL_DRIVE_CYCLE			(uint8_t)0x6
#define FL_TESTMODE_CTRL_DIRECT_UVW_CONTROL		(uint8_t)0x7

#define FL_TESTMODE_BATT_DIS_SW_OCP_OVP_UVP		(uint8_t)0x1
#define FL_TESTMODE_BATT_DIS_SW_OTP_UTP			(uint8_t)0x2
#define FL_TESTMODE_BATT_AFE_OCP				(uint8_t)0x3	// unit:0.1A
#define FL_TESTMODE_BATT_AFE_OVP_OF_CELL		(uint8_t)0x4	// unit:1mA
#define FL_TESTMODE_BATT_AFE_UVP_OF_CELL		(uint8_t)0x5	// unit:1mA
#define FL_TESTMODE_BATT_SET_CHARGE_OTP			(uint8_t)0x6	// unit:1¢XC
#define FL_TESTMODE_BATT_SET_CHARGE_UTP			(uint8_t)0x7	// unit:1¢XC
#define FL_TESTMODE_BATT_SET_DISCHARGE_OTP		(uint8_t)0x8	// unit:1¢XC
#define FL_TESTMODE_BATT_SET_DISCHARGE_UTP		(uint8_t)0x9	// unit:1¢XC
#define FL_TESTMODE_BATT_BALANCE_CONFIG			(uint8_t)0xA
#define FL_TESTMODE_BATT_INDICATOR_LED_BLINK	(uint8_t)0xB
#define FL_TESTMODE_BATT_INDICATOR_LED_SCAN		(uint8_t)0xC
#define FL_TESTMODE_BATT_INDICATOR_LED_ON		(uint8_t)0xD
#define FL_TESTMODE_BATT_INDICATOR_LED_OFF		(uint8_t)0xE
#define FL_TESTMODE_BATT_BUTTON_DISABLE			(uint8_t)0xF	// unit:sec (max 180sec)
#define FL_TESTMODE_BATT_STOP_COULOMB			(uint8_t)0x10
// Protocol packet struct
#define FL_CANID_HOST_INFO_00	(uint32_t)0x80
typedef union HOST_ControlInfo_00_st
{
	uint8_t bytes[3];

	struct
	{
		//Byte 0
		uint8_t set_assist_level:4;
		uint8_t system_power_control : 4;
		//Byte 1
		uint8_t walk_assist_control : 4;
		uint8_t front_light_control : 4;
		//Byte 2
		uint8_t rear_light_control : 4;
		uint8_t reserved_0 : 4;
	} bits;

} HOST_CONTROLINFO_00_T;

#define FL_CANID_HOST_INFO_01	(uint32_t)0x81
typedef union HOST_ControlInfo_01_st
{
	uint8_t bytes[8];

	struct
	{
		uint64_t unix_time;
	} bits;

} HOST_CONTROLINFO_01_T;

#define FL_CANID_HOST_INFO_02	(uint32_t)0x82
typedef union HOST_ControlInfo_02_st
{
	uint8_t bytes[2];

	struct
	{
		uint8_t silence_mode:1;
		uint8_t reserved_0 : 7;

		uint8_t silence_timeout;
	} bits;

} HOST_CONTROLINFO_02_T;

#define FL_CANID_HOST_DEVICE_RESET_REQ	(uint32_t)0x83
typedef union HOST_DeviceResetRequest_st
{
	uint8_t bytes[1];

	struct
	{
		uint8_t device_type;
	} bits;

} HOST_DEVICE_RESET_REQ_T;


#define FL_CANID_HOST_DEVICE_RESET_RSP	(uint32_t)0x84
typedef union HOST_DeviceResetResponse_st
{
	uint8_t bytes[2];

	struct
	{
		uint8_t device_type;
		uint8_t response_code;
	} bits;

} HOST_DEVICE_RESET_RSP_T;


#define FL_CANID_HOST_DEVICE_TEST_REQ	(uint32_t)0x85
typedef union HOST_DeviceTestRequest_st
{
	uint8_t bytes[6];

	struct
	{
		uint8_t device_type;
		uint8_t test_mode;
		uint32_t test_val;
	} bits;

} HOST_DEVICE_TEST_REQ_T;


#define FL_CANID_HOST_DEVICE_TEST_RSP	(uint32_t)0x86
typedef union HOST_DeviceTestResponse_st
{
	uint8_t bytes[2];

	struct
	{
		uint8_t device_type;
		uint8_t response_code;
	} bits;

} HOST_DEVICE_TEST_RSP_T;



#define FL_CANID_HOST_DEVICE_DEBUG_REQ	(uint32_t)0x87
typedef union HOST_DeviceDebugRequest_st
{
	uint8_t bytes[5];

	struct
	{
		uint8_t device_type;
		uint8_t debug_index;
		uint8_t debug_count;
		uint16_t interval_time;
	} bits;

} HOST_DEVICE_DEBUG_REQ_T;


#define FL_CANID_HOST_DEVICE_DEBUG_RSP	(uint32_t)0x88
typedef union HOST_DeviceDebugResponse_st
{
	uint8_t bytes[2];

	struct
	{
		uint8_t device_type;
		uint8_t response_code;
	} bits;

} HOST_DEVICE_DEBUG_RSP_T;



#define FL_CANID_HOST_BATT_CTL_REQ	(uint32_t)0x89
typedef union HOST_BattControlRequest_st
{
	uint8_t bytes[2];

	struct
	{
		uint8_t battery_index;

		uint8_t charge : 1;
		uint8_t discharge : 1;
		uint8_t reserved_0 : 6;
	} bits;

} HOST_DEVICE_BATT_CTL_REQ_T;


#define FL_CANID_HOST_BATT_CTL_RSP	(uint32_t)0x90
typedef union HOST_BattControlResponse_st
{
	uint8_t bytes[2];

	struct
	{
		uint8_t device_type;
		uint8_t response_code;
	} bits;

} HOST_DEVICE_BATT_CTL_RSP_T;


#define FL_CANID_HOST_TRIP_RESET	(uint32_t)0x91
typedef union HOST_TripReset_st
{
	uint8_t bytes[1];

	struct
	{
		uint8_t reset_enable;
	} bits;

} HOST_DEVICE_TRIP_RESET_T;


#define FL_CANID_HMI_INFO_00	(uint32_t)0x100
typedef union HMI_Info00_st
{
	uint8_t bytes[3];

	struct
	{
		uint8_t support_assist_level : 4;
		uint8_t current_assist_level : 4;
		
		uint8_t system_power_on : 1;
		uint8_t walk_assist_on : 1;
		uint8_t light_on : 1;
		uint8_t reserved_0 : 5;

		uint8_t power_key_status : 1;
		uint8_t up_key_status : 1;
		uint8_t down_key_status : 1;
		uint8_t walk_key_status : 1;
		uint8_t light_key_status : 1;
		uint8_t reserved_1 : 3;
	} bits;

} HMI_INFO_00_T;

#define FL_CANID_HMI_INFO_01	(uint32_t)0x101
typedef union HMI_Info01_st
{
	uint8_t bytes[8];

	struct
	{
		uint32_t trip_odo;
		uint32_t trip_time;
	} bits;

} HMI_INFO_01_T;

#define FL_CANID_HMI_INFO_02	(uint32_t)0x102
typedef union HMI_Info02_st
{
	uint8_t bytes[8];

	struct
	{
		uint16_t trip_avg_speed;
		uint16_t trip_max_speed;
		uint16_t trip_avg_current;
		uint16_t trip_max_current;
	} bits;

} HMI_INFO_02_T;


#define FL_CANID_HMI_INFO_03	(uint32_t)0x103
typedef union HMI_Info03_st
{
	uint8_t bytes[8];

	struct
	{
		uint16_t trip_avg_pedal_speed;
		uint16_t trip_max_pedal_speed;
		uint16_t trip_avg_pedal_torque;
		uint16_t trip_max_pedal_torque;
	} bits;

} HMI_INFO_03_T;


#define FL_CANID_HMI_WARNING	(uint32_t)0x17E
typedef union HMI_WarningInfo_st
{
	uint8_t bytes[8];

	struct
	{
		uint8_t page_num:3;
		uint8_t total_leng:5;

		uint8_t warning_0;
		uint8_t warning_1;
		uint8_t warning_2;
		uint8_t warning_3;
		uint8_t warning_4;
		uint8_t warning_5;
		uint8_t warning_6;
	} bits;

} HMI_WARNINGINFO_T;

#define FL_CANID_HMI_ERROR	(uint32_t)0x17F
typedef union HMI_ErrorInfo_st
{
	uint8_t bytes[8];

	struct
	{
		uint8_t page_num : 3;
		uint8_t total_leng : 5;

		uint8_t error_0;
		uint8_t error_1;
		uint8_t error_2;
		uint8_t error_3;
		uint8_t error_4;
		uint8_t error_5;
		uint8_t error_6;
	} bits;

} HMI_ERRORINFO_T;


#define FL_CANID_HMI_DEBUGINFO_00	(uint32_t)0x1100
typedef union HMI_DebugInfo_00_st
{
	uint8_t bytes[8];

	struct
	{
		uint16_t key_1_count;
		uint16_t key_2_count;
		uint16_t key_3_count;
		uint16_t key_4_count;
	} bits;

} HMI_DEBUGINFO_O0_T;


#define FL_CANID_HMI_DEBUGINFO_01	(uint32_t)0x1101
typedef union HMI_DebugInfo_01_st
{
	uint8_t bytes[8];

	struct
	{
		uint16_t key_5_count;
		uint16_t key_6_count;
		uint16_t key_7_count;
		uint16_t key_8_count;
	} bits;

} HMI_DEBUGINFO_01_T;


#define FL_CANID_CTRL_INFO_00	(uint32_t)0x180
typedef union CTRL_Info00_st
{
	uint8_t bytes[8];

	struct
	{
		uint16_t bike_speed;
		uint16_t motor_speed;
		uint16_t wheel_speed;
		uint16_t limit_speed;
	} bits;

} CTRL_INFO00_T;


#define FL_CANID_CTRL_INFO_01	(uint32_t)0x181
typedef union CTRL_Info01_st
{
	uint8_t bytes[8];

	struct
	{
		uint16_t bus_voltage;
		uint16_t avg_bus_current;
		uint16_t light_current;
		uint8_t avg_output;
		int8_t temperature;
	} bits;

} CTRL_INFO01_T;


#define FL_CANID_CTRL_INFO_02	(uint32_t)0x182
typedef union CTRL_Info02_st
{
	uint8_t bytes[6];

	struct
	{
		uint8_t throttle_amplitube;
		uint8_t pedal_cadence;
		uint16_t pedal_torque;
		uint16_t pedal_power;
	} bits;

} CTRL_INFO02_T;


#define FL_CANID_CTRL_INFO_03	(uint32_t)0x183
typedef union CTRL_Info03_st
{
	uint8_t bytes[4];

	struct
	{
		uint32_t odo;
	} bits;

} CTRL_INFO03_T;


#define FL_CANID_CTRL_INFO_04	(uint32_t)0x184
typedef union CTRL_Info04_st
{
	uint8_t bytes[1];

	struct
	{
		uint8_t controller_range;
	} bits;

} CTRL_INFO04_T;


#define FL_CANID_CTRL_INFO_05	(uint32_t)0x185
typedef union CTRL_Info05_st
{
	uint8_t bytes[2];

	struct
	{
		uint8_t assist_level: 4;
		uint8_t assist_type : 3;
		uint8_t assist_on : 1;

		uint8_t front_light_on:1;
		uint8_t rear_light_on:1;
		uint8_t brake_light_on : 1;
		uint8_t activate_light_ctrl :1;
		uint8_t brake_on:1;
		uint8_t candence_direction : 1;
		uint8_t motor_direction:1;
		uint8_t reserved_1 : 1;
	} bits;

} CTRL_INFO05_T;


#define FL_CANID_CTRL_WARNING_INFO	(uint32_t)0x1FE
typedef union CTRL_WarningInfo_st
{
	uint8_t bytes[8];

	struct
	{
		uint8_t page_num : 3;
		uint8_t total_leng : 5;

		uint8_t warning_0;
		uint8_t warning_1;
		uint8_t warning_2;
		uint8_t warning_3;
		uint8_t warning_4;
		uint8_t warning_5;
		uint8_t warning_6;
	} bits;

} CTRL_WARNINGINFO_T;


#define FL_CANID_CTRL_ERROR_INFO	(uint32_t)0x1FF
typedef union CTRL_ErrorInfo_st
{
	uint8_t bytes[8];

	struct
	{
		uint8_t page_num : 3;
		uint8_t total_leng : 5;

		uint8_t error_0;
		uint8_t error_1;
		uint8_t error_2;
		uint8_t error_3;
		uint8_t error_4;
		uint8_t error_5;
		uint8_t error_6;
	} bits;

} CTRL_ERRORINFO_T;


#define FL_CANID_CTRL_DEBUGINFO_00	(uint32_t)0x1180
typedef union CTRL_DebugInfo00_st
{
	uint8_t bytes[8];

	struct
	{
		uint16_t zero_torque_volt;
		uint16_t current_torque_volt;
		uint16_t zero_throttle_volt;
		uint16_t current_throttle_volt;
	} bits;

} CTRL_DEBUGINFO00_T;


#define FL_CANID_CTRL_DEBUGINFO_01	(uint32_t)0x1181
typedef union CTRL_DebugInfo01_st
{
	uint8_t bytes[8];

	struct
	{
		uint16_t actual_bus_current;
		int16_t u_phase_current;
		int16_t v_phase_current;
		int16_t w_phase_current;
	} bits;

} CTRL_DEBUGINFO01_T;


#define FL_CANID_CTRL_DEBUGINFO_02	(uint32_t)0x1182
typedef union CTRL_DebugInfo02_st
{
	uint8_t bytes[7];

	struct
	{
		uint32_t wheel_rotate_laps;
		uint16_t output_amplitude;

		uint8_t hall_state:4;
		uint8_t sector_state : 4;
	} bits;

} CTRL_DEBUGINFO02_T;


#define FL_CANID_MBAT_INFO_00		(uint32_t)0x200
typedef union Main_BAT_Info00_st
{
	uint8_t bytes[8];

	struct
	{
		uint8_t charge_fet:1;
		uint8_t charging:1;
		uint8_t fully_charged:1;
		uint8_t charge_detected:1;
		uint8_t discharge_fet:1;
		uint8_t discharging:1;
		uint8_t nearly_discharged:1;
		uint8_t fully_discharged:1;

		uint8_t design_volt;		//uint:V
		uint16_t design_capacity;	//uint:AH
		uint16_t cycle_count;		
		uint16_t uncharged_day;
	} bits;

} MAIN_BAT_INFO00_T;


#define FL_CANID_MBAT_INFO_01		(uint32_t)0x201
typedef union Main_BAT_Info01_st
{
	uint8_t bytes[8];

	struct
	{
		uint32_t actual_volt;	//uint:mV
		int32_t actual_current; //uint:mA
	} bits;

} MAIN_BAT_INFO01_T;


#define FL_CANID_MBAT_INFO_02		(uint32_t)0x202
typedef union Main_BAT_Info02_st
{
	uint8_t bytes[1];

	struct
	{
		int8_t temperature;	//uint:C
	} bits;

} MAIN_BAT_INFO02_T;


#define FL_CANID_MBAT_INFO_03		(uint32_t)0x203
typedef union Main_BAT_Info03_st
{
	uint8_t bytes[6];

	struct
	{
		uint8_t rsoc;	//uint:%
		uint16_t asoc;	//uint:mAH
		uint8_t rsoh;	//uint:%
		uint16_t asoh;	//uint:mAH
	} bits;

} MAIN_BAT_INFO03_T;


#define FL_CANID_MBAT_RTC_INFO		(uint32_t)0x204
typedef union Main_BAT_RTCInfo_st
{
	uint8_t bytes[8];

	struct
	{
		uint64_t unix_time;
	} bits;

} MAIN_BAT_RTCINFO_T;


#define FL_CANID_MBAT_WARNING_INFO	(uint32_t)0x27E
typedef union Main_BAT_WarningInfo_st
{
	uint8_t bytes[8];

	struct
	{
		uint8_t page_num : 3;
		uint8_t total_leng : 5;

		uint8_t warning_0;
		uint8_t warning_1;
		uint8_t warning_2;
		uint8_t warning_3;
		uint8_t warning_4;
		uint8_t warning_5;
		uint8_t warning_6;
	} bits;

} BAT_WARNINGINFO_T;


#define FL_CANID_MBAT_ERROR_INFO	(uint32_t)0x27F
typedef union Main_BAT_ErrorInfo_st
{
	uint8_t bytes[8];

	struct
	{
		uint8_t page_num : 3;
		uint8_t total_leng : 5;

		uint8_t error_0;
		uint8_t error_1;
		uint8_t error_2;
		uint8_t error_3;
		uint8_t error_4;
		uint8_t error_5;
		uint8_t error_6;
	} bits;

} BAT_ERRORINFO_T;


#define FL_CANID_MBAT_DEBUGINFO_00	(uint32_t)0x1200
typedef union Main_BAT_DebugInfo00_st
{
	uint8_t bytes[8];

	struct
	{
		uint16_t cell_1_volt;
		uint16_t cell_2_volt;
		uint16_t cell_3_volt;
		uint16_t cell_4_volt;
	} bits;

} BAT_DEBUGINFO00_T;


#define FL_CANID_MBAT_DEBUGINFO_01	(uint32_t)0x1201
typedef union BAT_DebugInfo01_st
{
	uint8_t bytes[8];

	struct
	{
		uint16_t cell_5_volt;
		uint16_t cell_6_volt;
		uint16_t cell_7_volt;
		uint16_t cell_8_volt;
	} bits;

} BAT_DEBUGINFO01_T;


#define FL_CANID_MBAT_DEBUGINFO_02	(uint32_t)0x1202
typedef union BAT_DebugInfo02_st
{
	uint8_t bytes[8];

	struct
	{
		uint16_t cell_9_volt;
		uint16_t cell_10_volt;
		uint16_t cell_11_volt;
		uint16_t cell_12_volt;
	} bits;

} BAT_DEBUGINFO02_T;


#define FL_CANID_MBAT_DEBUGINFO_03	(uint32_t)0x1203
typedef union BAT_DebugInfo03_st
{
	uint8_t bytes[8];

	struct
	{
		uint16_t cell_13_volt;
		uint16_t cell_14_volt;
		uint16_t cell_15_volt;
		uint16_t cell_16_volt;
	} bits;

} BAT_DEBUGINFO03_T;


#define FL_CANID_MBAT_DEBUGINFO_04	(uint32_t)0x1204
typedef union BAT_DebugInfo04_st
{
	uint8_t bytes[8];

	struct
	{
		uint16_t cell_17_volt;
		uint16_t cell_18_volt;
		uint16_t cell_19_volt;
		uint16_t cell_20_volt;
	} bits;

} BAT_DEBUGINFO04_T;


#define FL_CANID_MBAT_DEBUGINFO_05	(uint32_t)0x1205
typedef union BAT_DebugInfo05_st
{
	uint8_t bytes[8];

	struct
	{
		int8_t temperature_1;
		int8_t temperature_2;
		int8_t temperature_3;
		int8_t temperature_4;
		int8_t temperature_5;
		int8_t temperature_6;
		int8_t temperature_7;
		int8_t temperature_8;
	} bits;

} BAT_DEBUGINFO05_T;

#pragma pack()
/*

 Bluetooth Info define

*/

#define FL_BLE_OPC_CAN_LISTEN_ID_REQ			(uint16_t)1
#define FL_BLE_OPC_CAN_LISTEN_ID_RES			(uint16_t)2
#define FL_BLE_OPC_CAN_PASS_DATA_REQ			(uint16_t)5
#define FL_BLE_OPC_CAN_PASS_DATA_RES			(uint16_t)6

#define FL_BLE_OPC_PARAM_READ_REQ				(uint16_t)11
#define FL_BLE_OPC_PARAM_READ_RES				(uint16_t)12
#define FL_BLE_OPC_PARAM_WRITE_REQ				(uint16_t)13
#define FL_BLE_OPC_PARAM_WRITE_RES				(uint16_t)14
#define FL_BLE_OPC_PARAM_RESET_REQ				(uint16_t)15
#define FL_BLE_OPC_PARAM_RESET_RES				(uint16_t)16

#define FL_BLE_OPC_DFU_READ_DEV_INFO_REQ		(uint16_t)31
#define FL_BLE_OPC_DFU_READ_DEV_INFO_RES		(uint16_t)32
#define FL_BLE_OPC_DFU_WRITE_DEV_INFO_REQ		(uint16_t)33
#define FL_BLE_OPC_DFU_WRITE_DEV_INFO_RES		(uint16_t)34
#define FL_BLE_OPC_DFU_WRITE_DATA_FLASH_REQ		(uint16_t)35
#define FL_BLE_OPC_DFU_WRITE_DATA_FLASH_RES		(uint16_t)36
#define FL_BLE_OPC_DFU_VERIFY_FLASH_REQ			(uint16_t)37
#define FL_BLE_OPC_DFU_VERIFY_FLASH_RES			(uint16_t)38
#define FL_BLE_OPC_DFU_JUMP_COMMOND_REQ			(uint16_t)39
#define FL_BLE_OPC_DFU_JUMP_COMMOND_RES			(uint16_t)40

#define FL_BLE_OPC_LOG_READ_REQ					(uint16_t)61
#define FL_BLE_OPC_LOG_READ_RES					(uint16_t)62
#define FL_BLE_OPC_LOG_CLEAR_REQ				(uint16_t)63
#define FL_BLE_OPC_LOG_CLEAR_RES				(uint16_t)64


#define FL_BLE_JUMP_BOOTLOADER			(uint8_t)1
#define FL_BLE_JUMP_APPLICATION			(uint8_t)2




#define FL_CANID_ELOCK_COMMAND	(uint32_t)0x2C3
typedef union ELock_Command_st
{
	uint8_t bytes[8];

	struct
	{
		int8_t start;
		int8_t command;
		int8_t data[6];
	} bits;

} ELOCK_COMMAND_T;



#define FL_CANID_ELOCK_RESPONDS	(uint32_t)0x2C4
typedef union ELock_Responds_st
{
	uint8_t bytes[8];

	struct
	{
		int8_t start;
		int8_t command;
		int8_t data[6];
	} bits;

} ELOCK_RESPONDS_T;


#ifdef __cplusplus
}
#endif


#endif
