#pragma once

#ifndef _FL_DEVICE_HMI_H // include guard
#define _FL_DEVICE_HMI_H
#include <stdint.h>
#include "CoreSDK.h"

#ifdef __cplusplus
extern "C" {
#endif

#define VIRTUAL_HMI_WARNING_CODE_SIZE	16
#define VIRTUAL_HMI_ERROR_CODE_SIZE		16

typedef int (*canbus_send_handler_p)(uint32_t can_id, bool is_extender, uint8_t* data, uint32_t leng);
DllExport typedef int (__stdcall *update_warning_callback)(uint8_t* warning_list, uint8_t leng);
DllExport typedef int(__stdcall* update_error_callback)(uint8_t* error_list, uint8_t leng);

typedef DllExport struct fl_hmi_info_st
{
	uint8_t support_assist_level;
	uint8_t current_assist_level;
	bool system_powe_on;
	bool walk_assist_on;
	bool light_on;
	bool power_key_on;
	bool up_key_on;
	bool down_key_on;
	bool walk_key_on;
	bool light_key_on;
	uint32_t trip_odo;
	uint32_t trip_time;
	uint16_t trip_avg_speed;
	uint16_t trip_max_speed;
	uint16_t trip_avg_current;
	uint16_t trip_max_current;
	uint16_t trip_avg_pedal_speed;
	uint16_t trip_max_pedal_speed;
	uint16_t trip_avg_pedal_torque;
	uint16_t trip_max_pedal_torque;

	uint16_t key_1_count;
	uint16_t key_2_count;
	uint16_t key_3_count;
	uint16_t key_4_count;
	uint16_t key_5_count;
	uint16_t key_6_count;
	uint16_t key_7_count;
	uint16_t key_8_count;
	
} FL_HMI_INFO_ST;


typedef struct fl_hmi_inst_st
{
	ISOTP_INST_T *isotp_inst;
	canbus_send_handler_p send_handler;
	update_warning_callback update_warning_notify;
	uint8_t warning_code[VIRTUAL_HMI_WARNING_CODE_SIZE];
	uint8_t warning_leng;
	update_error_callback update_error_notify;
	uint8_t error_code[VIRTUAL_HMI_ERROR_CODE_SIZE];
	uint8_t error_leng;

	FL_HMI_INFO_ST info;

	uint8_t param_bank_0[1024];
	uint8_t param_bank_1[1024];
	uint8_t param_bank_2[1024];
	uint8_t param_bank_3[1024];

	uint8_t cache_mem[2048];
} FL_HMI_INST_T;

DllExport void __stdcall FL_device_HMI_update_info(FL_HMI_INFO_ST* new_info);
DllExport uint32_t __stdcall Virtual_Device_HMI_Startup(void);
DllExport uint32_t __stdcall Virtual_Device_HMI_Stop(void);

DllExport void __stdcall FL_device_HMI_add_warning(uint8_t code);
DllExport void __stdcall FL_device_HMI_remove_warning(uint8_t code);
void Register_UpdateWarning_Callback(update_warning_callback call_func);


DllExport void __stdcall FL_device_HMI_add_error(uint8_t code);
DllExport void __stdcall FL_device_HMI_remove_error(uint8_t code);

int FL_HMI_CAN_TryPaser(uint32_t can_id, bool is_extend, uint8_t* data, uint8_t leng);
uint32_t FL_device_HML_Init(ISOTP_INST_T* isotp_inst, canbus_send_handler_p send_hander);

#ifdef __cplusplus
}
#endif

#endif /* _FL_DEVICE_HMI_H */
