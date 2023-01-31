
#include "CoreSDK.h"
#include "FL_Logs.h"
#include "UnixTime.h"

union battery_info_byte
{
	uint8_t bytes[1];

	struct
	{
		uint8_t charge_fet : 1;
		uint8_t charging : 1;
		uint8_t fully_charged : 1;
		uint8_t charge_detected : 1;
		uint8_t discharge_fet : 1;
		uint8_t discharging : 1;
		uint8_t nearly_discharged : 1;
		uint8_t fully_discharged : 1;
	} bits;
};

FL_LOG_ITME_T fl_logs[FL_LOG_SIZE];
static uint16_t fl_log_leng = 0;

void Farmland_Log_Clear(void)
{
	fl_log_leng = 0;
}

uint32_t Farmland_Log_Parse(uint8_t * data, uint32_t leng)
{
	FL_LOG_ITME_T log;
	DateTime_st datetime;
	uint8_t index = 0;
	uint8_t parse_index = 0;
	battery_info_byte batt_info = { 0 };
	uint16_t log_index = data[0] + ((uint16_t)data[1] << 8);
	
	datetime.year = 2000 + data[2];
	datetime.month = data[3];
	datetime.day = data[4];
	datetime.hour = data[5];
	datetime.minute = data[6];
	datetime.second = data[7];

	log.unix_time = DateTime2Unix(datetime);

	log.odo = data[8] + ((uint32_t)data[9] << 8) + ((uint32_t)data[10] << 16) + ((uint32_t)data[11] << 24);

	batt_info.bytes[0] = data[12];

	log.charge_fet = batt_info.bits.charge_fet;
	log.charging = batt_info.bits.charging;
	log.fully_charged = batt_info.bits.fully_charged;
	log.charge_detected = batt_info.bits.charge_detected;
	log.discharge_fet = batt_info.bits.discharge_fet;
	log.discharging = batt_info.bits.discharging;
	log.nearly_discharged = batt_info.bits.nearly_discharged;
	log.fully_discharged = batt_info.bits.fully_discharged;

	for (index = 0; index < FL_LOG_ERROR_CODE_SIZE; index++)
	{
		log.error[index] = data[(13 + index)];
	}

	if (data[13] > FL_LOG_CELL_SIZE_SIZE) return SDK_RETURN_INVALID_PARAM;

	parse_index = 14;

	for (index = 0; index < data[13]; index++)
	{
		log.cell_volt[index] = data[parse_index++];
		log.cell_volt[index] += ((uint16_t)data[parse_index++] << 8);
	}

	uint8_t sensor_cnt = data[parse_index++];

	for (index = 0; index < sensor_cnt; index++)
	{
		log.temp_sensor[index] = data[parse_index++];
	}

	log.bike_speed = data[parse_index++];
	log.bike_speed += ((uint16_t)data[parse_index++] << 8);

	log.motor_speed = data[parse_index++];
	log.motor_speed += ((uint16_t)data[parse_index++] << 8);

	log.rsoc = data[parse_index++];
	log.assis_info = data[parse_index++];
	log.controller_avg_output = data[parse_index++];


	if (log_index < FL_LOG_SIZE)
	{
		memcpy(&fl_logs[log_index], &log, sizeof(FL_LOG_ITME_T));
		fl_log_leng++;
	}

	return SDK_RETURN_SUCCESS;
}


void Farmland_Log_Read(FL_LOG_ITME_T* logs, uint16_t logs_size)
{
	logs = fl_logs;
	logs_size = fl_log_leng;
}
