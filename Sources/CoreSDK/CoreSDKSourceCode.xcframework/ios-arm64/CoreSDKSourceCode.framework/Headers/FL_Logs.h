#pragma once

#ifndef _FL_LOGS_H // include guard
#define _FL_LOGS_H

#include <stdint.h>
#include <stdbool.h>


#ifdef __cplusplus
extern "C" {
#endif

#define FL_LOG_ERROR_CODE_SIZE	8
#define FL_LOG_CELL_SIZE_SIZE	20
#define FL_LOG_SIZE				1024


	typedef struct farmland_log_item_st
	{
		uint64_t unix_time;
		uint32_t odo;
		bool charge_fet;
		bool charging;
		bool fully_charged;
		bool charge_detected;
		bool discharge_fet;
		bool discharging;
		bool nearly_discharged;
		bool fully_discharged;
		uint8_t error[FL_LOG_ERROR_CODE_SIZE];
		uint16_t cell_volt[FL_LOG_CELL_SIZE_SIZE];
		int8_t temp_sensor[3];
		uint16_t bike_speed;
		uint16_t motor_speed;
		uint8_t rsoc;
		uint8_t assis_info;
		uint8_t controller_avg_output;
	} FL_LOG_ITME_T;

	uint32_t Farmland_Log_Parse(uint8_t* data, uint32_t leng);

	void Farmland_Log_Read(FL_LOG_ITME_T* logs, uint16_t logs_size);

#ifdef __cplusplus
}
#endif

#endif

