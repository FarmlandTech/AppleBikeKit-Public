#pragma once

#ifndef _FL_DEVICE_MAINBATT_H // include guard
#define _FL_DEVICE_MAINBATT_H
#include <stdint.h>
#include "CoreSDK.h"

#ifdef __cplusplus
extern "C" {
#endif


typedef DllExport struct fl_mainbatt_info_st
{
	bool charge_fet_on;
	bool charging;
	bool fully_charged;
	bool charger_detected;
	bool discharge_fet_on;
	bool discharging;
	bool nearly_discharged;
	bool fully_discharged;

	uint8_t design_voltage;
	uint16_t design_capacity;
	uint16_t cycle_count;
	uint16_t uncharged_day;

	uint16_t actual_voltage;
	uint16_t actual_current;

	int8_t temperature;

	uint8_t rsoc;
	uint16_t asoc;
	uint8_t rsoh;
	uint16_t asoh;

	uint64_t unix_time;

	uint16_t cell_1_volt;
	uint16_t cell_2_volt;
	uint16_t cell_3_volt;
	uint16_t cell_4_volt;
	uint16_t cell_5_volt;
	uint16_t cell_6_volt;
	uint16_t cell_7_volt;
	uint16_t cell_8_volt;
	uint16_t cell_9_volt;
	uint16_t cell_10_volt;
	uint16_t cell_11_volt;
	uint16_t cell_12_volt;
	uint16_t cell_13_volt;
	uint16_t cell_14_volt;
	uint16_t cell_15_volt;
	uint16_t cell_16_volt;
	uint16_t cell_17_volt;
	uint16_t cell_18_volt;
	uint16_t cell_19_volt;
	uint16_t cell_20_volt;

	int8_t sensor_temperature_1;
	int8_t sensor_temperature_2;
	int8_t sensor_temperature_3;
	int8_t sensor_temperature_4;
	int8_t sensor_temperature_5;
	int8_t sensor_temperature_6;
	int8_t sensor_temperature_7;
	int8_t sensor_temperature_8;
} FL_MAINBATT_INFO_T;


typedef struct fl_hmi_inst_st
{
	ISOTP_INST_T *isotp_inst;
	canbus_send_handler_p send_handler;
	uint8_t warning_code[WARNING_CODE_SIZE];
	uint8_t warning_leng;
	uint8_t error_code[ERROR_CODE_SIZE];
	uint8_t error_leng;

	FL_MAINBATT_INFO_T info;

	uint8_t param_bank_0[1024];
	uint8_t param_bank_1[1024];
	uint8_t param_bank_2[1024];
	uint8_t param_bank_3[1024];

	uint8_t cache_mem[2048];
} FL_MAINBATT_INST_T;

DllExport void __stdcall FL_device_MainBatt_update_info(FL_MAINBATT_INFO_T* new_info);
DllExport uint32_t __stdcall Virtual_Device_MainBatt_Startup(void);
DllExport uint32_t __stdcall Virtual_Device_MainBatt_Stop(void);

DllExport void __stdcall FL_device_MainBatt_add_warning(uint8_t code);
DllExport void __stdcall FL_device_MainBatt_remove_warning(uint8_t code);


DllExport void __stdcall FL_device_MainBatt_add_error(uint8_t code);
DllExport void __stdcall FL_device_MainBatt_remove_error(uint8_t code);

int FL_MainBatt_CAN_TryPaser(uint32_t can_id, bool is_extend, uint8_t* data, uint8_t leng);
uint32_t FL_device_MainBatt_Init(ISOTP_INST_T* isotp_inst, canbus_send_handler_p send_hander);

#ifdef __cplusplus
}
#endif

#endif /* _FL_DEVICE_HMI_H */
