#pragma once

#ifndef _FL_DEVICE_CONTROLLER_H // include guard
#define _FL_DEVICE_CONTROLLER_H
#include <stdint.h>
#include "CoreSDK.h"

#ifdef __cplusplus
extern "C" {
#endif


typedef DllExport struct fl_controller_info_st
{
	uint16_t bike_speed;
	uint16_t motor_speed;
	uint16_t wheel_speed;
	uint16_t limit_speed;
	uint16_t bus_volt;
	uint16_t bus_avg_current;
	uint16_t light_current;
	uint8_t avg_output_amplitude;
	int8_t temperature;

	uint8_t throttle_amplitude;
	uint8_t cadence_speed;
	uint16_t pedal_torque;
	uint16_t pedal_power;

	uint32_t odo;
	uint8_t range;
	uint8_t assist_level;
	uint8_t assist_type;
	uint8_t assist_status;
	
	bool front_light_on;
	bool brake_light_on;
	bool activate_light_control;
	bool brake_on;
	bool cadence_direction;
	bool motor_direction;

	uint16_t zero_torque_volt;
	uint16_t current_torque_volt;
	uint16_t zero_throttle_volt;
	uint16_t current_throttle_volt;

	uint16_t actual_bus_current;
	int16_t u_phase_current;
	int16_t v_phase_current;
	int16_t w_phase_current;

	uint32_t wheel_rotate_laps;
	uint16_t actual_output_amplitude;
	uint8_t hall_state;
	uint8_t sector_state;


} FL_CONTROLLER_INFO_ST;


typedef struct fl_hmi_inst_st
{
	ISOTP_INST_T *isotp_inst;
	canbus_send_handler_p send_handler;
	uint8_t warning_code[WARNING_CODE_SIZE];
	uint8_t warning_leng;
	uint8_t error_code[ERROR_CODE_SIZE];
	uint8_t error_leng;

	FL_CONTROLLER_INFO_ST info;

	uint8_t param_bank_0[1024];
	uint8_t param_bank_1[1024];
	uint8_t param_bank_2[1024];
	uint8_t param_bank_3[1024];

	uint8_t cache_mem[2048];
} FL_CONTROLLER_INST_T;

DllExport void __stdcall FL_device_Controller_update_info(FL_CONTROLLER_INFO_ST* new_info);
DllExport uint32_t __stdcall Virtual_Device_Controller_Startup(void);
DllExport uint32_t __stdcall Virtual_Device_Controller_Stop(void);

DllExport void __stdcall FL_device_Controller_add_warning(uint8_t code);
DllExport void __stdcall FL_device_Controller_remove_warning(uint8_t code);

DllExport void __stdcall FL_device_Controller_add_error(uint8_t code);
DllExport void __stdcall FL_device_Controller_remove_error(uint8_t code);

int FL_Controller_CAN_TryPaser(uint32_t can_id, bool is_extend, uint8_t* data, uint8_t leng);
uint32_t FL_device_Controller_Init(ISOTP_INST_T* isotp_inst, canbus_send_handler_p send_hander);

#ifdef __cplusplus
}
#endif

#endif /* _FL_DEVICE_CONTROLLER_H */
