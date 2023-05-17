#include "FL_CANInfoStruct.h"
#include "FL_Device_HMI.h"


// Form Project Setting
#define APP_START_ADDR	(uint32_t)0
#define APP_FLASH_SIZE	(uint32_t)(256*1024)
#define FLASH_PAGE_SIZE	(uint32_t)2048
#define DFU_CACHE_SIZE	(uint32_t)2048

static uint8_t vm_flash_mem[APP_FLASH_SIZE] = { 0x31, 0x33, 0x39, 0x31, 0x30, 0x38, 'F' ,'a', 'r', 'm', 'L', 'a', 'n', 'd', '-', 'H', 'M', 'I', '-', '!', 0x12, 0x00, 0x00, 0x00};


#define ISO_TP_BUFF_SIZE 1024
#define CREATE_ISO_TP_BUFF(_buff_name_)	static uint8_t _buff_name_[ISO_TP_BUFF_SIZE] = {0};



//static FL_hmi_inst.info_ST hmi_inst.info;
static FL_HMI_INST_T device_inst;


static int DUFRequestHandler(uint8_t* data, uint32_t leng);
static int ParameterRequestHandler(uint8_t* data, uint32_t leng);
static int ParameterResponHandler(uint8_t* data, uint32_t leng);

static int HostControlInfoHandler(uint8_t* data, uint32_t leng);
static int HostConfigRTCHandler(uint8_t* data, uint32_t leng);
static int HostSilenceModeHandler(uint8_t* data, uint32_t leng);
static int HostResetHandler(uint8_t* data, uint32_t leng);
static int HostTestModeHandler(uint8_t* data, uint32_t leng);
static int HostDebugModeHandler(uint8_t* data, uint32_t leng);
static int HostTripResetHandler(uint8_t* data, uint32_t leng);

static struct CAN_ParseHandlerDefine_st vaild_id_list[] =
{
	{ FL_CANID_HOST_INFO_00, false, HostControlInfoHandler},
	{ FL_CANID_HOST_INFO_01, false, HostConfigRTCHandler},
	{ FL_CANID_HOST_INFO_02, false, HostSilenceModeHandler},
	{ FL_CANID_HOST_DEVICE_RESET_REQ, false, HostResetHandler},
	{ FL_CANID_HOST_DEVICE_TEST_REQ, false, HostTestModeHandler},
	{ FL_CANID_HOST_DEVICE_DEBUG_REQ, false, HostDebugModeHandler},
	{ FL_CANID_HOST_TRIP_RESET, false, HostTripResetHandler},
};


CREATE_ISO_TP_BUFF(DFUReviceBuff);
static ISOTP_PortInfo_T ISOTP_Port_DeviceDFURecive =
{
	FL_ISOTP_CANID_DFU_ANY_2_HMI, true, DFUReviceBuff, ISO_TP_BUFF_SIZE, 0, 0, 0, NULL, NULL, DUFRequestHandler
};


CREATE_ISO_TP_BUFF(DFUSendBuff);
static ISOTP_PortInfo_T ISOTP_Port_DeviceDFUSend =
{
	FL_ISOTP_CANID_DFU_HMI_2_ANY, true, DFUSendBuff, ISO_TP_BUFF_SIZE, 0, 0, 0, NULL, NULL, NULL
};

CREATE_ISO_TP_BUFF(ParamReviceBuff);
static ISOTP_PortInfo_T ISOTP_Port_DeviceParamRecive =
{
	FL_ISOTP_CANID_PARAM_ANY_2_HMI, true, ParamReviceBuff, ISO_TP_BUFF_SIZE, 0, 0, 0, NULL, NULL, ParameterRequestHandler
};

CREATE_ISO_TP_BUFF(ParamSendBuff);
static ISOTP_PortInfo_T ISOTP_Port_DeviceParamSend =
{
	FL_ISOTP_CANID_PARAM_HMI_2_ANY, true, ParamSendBuff, ISO_TP_BUFF_SIZE, 0, 0, 0, NULL, NULL, NULL
};

static void HMI_debuginfo_00_broadcast_packet(void);
static void HMI_debuginfo_01_broadcast_packet(void);

static void Virtual_Device_Boradcast_Pause(void);
static void Virtual_Device_Boradcast_Resume(void);


static int DUFRequestHandler(uint8_t* data, uint32_t leng)
{
	static uint16_t identifier = 0xffff;
	static uint16_t block_index = 0;
	uint32_t x = 0;
	uint8_t operate_code = data[0];
	uint8_t resp_code = RESPONSE_SUCCESS;
	ISOTP_PortInfo_T* port = &ISOTP_Port_DeviceDFUSend;
	port->buff_index = 0;
	port->buff_leng = 0;

	switch (operate_code)
	{
	case OPC_JUMP_BOOTLOADER:
	{
		port->buff_p[port->buff_leng++] = OPC_JUMP_BOOTLOADER;
		port->buff_p[port->buff_leng++] = RESPONSE_SUCCESS;
	}
	break;

	case OPC_JUMP_APPLICATION:
	{
		port->buff_p[port->buff_leng++] = OPC_JUMP_APPLICATION;
		port->buff_p[port->buff_leng++] = RESPONSE_SUCCESS;
	}
	break;

	case OPC_READ_OBJ_INFO:
	{
		uint32_t crc32_res = 0;
		port->buff_p[port->buff_leng++] = OPC_READ_OBJ_INFO;
		port->buff_p[port->buff_leng++] = RESPONSE_SUCCESS;
		port->buff_p[port->buff_leng++] = 0xff;
		port->buff_p[port->buff_leng++] = (uint8_t)identifier;
		port->buff_p[port->buff_leng++] = (uint8_t)(identifier >> 8);
		port->buff_p[port->buff_leng++] = (uint8_t)block_index;
		port->buff_p[port->buff_leng++] = (uint8_t)(block_index >> 8);
		port->buff_p[port->buff_leng++] = (uint8_t)APP_FLASH_SIZE;
		port->buff_p[port->buff_leng++] = (uint8_t)(APP_FLASH_SIZE >> 8);
		port->buff_p[port->buff_leng++] = (uint8_t)(APP_FLASH_SIZE >> 16);
		port->buff_p[port->buff_leng++] = (uint8_t)FLASH_PAGE_SIZE;
		port->buff_p[port->buff_leng++] = (uint8_t)(FLASH_PAGE_SIZE >> 8);
		port->buff_p[port->buff_leng++] = (uint8_t)DFU_CACHE_SIZE;
		port->buff_p[port->buff_leng++] = (uint8_t)(DFU_CACHE_SIZE >> 8);

		crc32_res = FarmlandCalCrc32(port->buff_p, port->buff_leng, 0);
		port->buff_p[port->buff_leng++] = (uint8_t)crc32_res;
		port->buff_p[port->buff_leng++] = (uint8_t)(crc32_res >> 8);
		port->buff_p[port->buff_leng++] = (uint8_t)(crc32_res >> 16);
		port->buff_p[port->buff_leng++] = (uint8_t)(crc32_res >> 24);
	}
	break;

	case OPC_WRITE_OBJ_INFO:
	{
		identifier = data[0] + (data[1] << 8);
		port->buff_p[port->buff_leng++] = OPC_WRITE_OBJ_INFO;
		port->buff_p[port->buff_leng++] = RESPONSE_SUCCESS;		
	}
	break;

	case OPC_EARSE_FLASH:
	{
		if (leng < 11)
		{
			break;
		}
		uint32_t erase_start_addr = data[1] + (data[2] << 8) + (data[3] << 16);
		uint32_t erase_end_addr = data[4] + (data[5] << 8) + (data[6] << 16);
		uint32_t get_crc32 = data[7] + (data[8] << 8) + (data[9] << 16) + (data[10] << 24);
		uint32_t check_crc32 = FarmlandCalCrc32(data, (leng-4), 0);
		
		if (check_crc32 != get_crc32)
		{
			
			port->buff_p[port->buff_leng++] = OPC_EARSE_FLASH;
			port->buff_p[port->buff_leng++] = RESPONSE_CRC_FAIL;
			break;
		}

		// flash_earse(erase_start_addr, erase_end_addr);
		
		port->buff_p[port->buff_leng++] = OPC_EARSE_FLASH;
		port->buff_p[port->buff_leng++] = RESPONSE_SUCCESS;
	}
	break;

	case OPC_WRITE_TO_CACHE:
	{
		uint16_t cahche_addr = data[1] + (data[2] << 8);
		uint16_t cahche_leng = data[3] + (data[4] << 8);
		uint32_t crc_index = leng - 4;
		uint32_t get_crc32 = data[crc_index] + 
							(data[(crc_index + 1)] << 8) + 
							(data[(crc_index + 2)] << 16) +
							(data[(crc_index + 3)] << 24);
		uint32_t check_crc32 = FarmlandCalCrc32(data, (leng - 4), 0);
		uint16_t data_index = 5;

		if (get_crc32 != check_crc32)
		{
			port->buff_p[port->buff_leng++] = OPC_WRITE_TO_CACHE;
			port->buff_p[port->buff_leng++] = RESPONSE_CRC_FAIL;
			break;
		}

		for (x= cahche_addr;x< cahche_leng;x++)
		{
			device_inst.cache_mem[x] = data[data_index];
			data_index++;
		}

		
		port->buff_p[port->buff_leng++] = OPC_WRITE_TO_CACHE;
		port->buff_p[port->buff_leng++] = RESPONSE_SUCCESS;
	}
	break;

	case OPC_PROGRAM_FLASH:
	{
		uint32_t offset_index = data[1] + (data[2] << 8) + (data[3] << 16);
		uint32_t prog_leng = data[4] + (data[5] << 8);
		uint32_t cache_index = 0;
		uint32_t prog_start_index = offset_index + APP_START_ADDR;
		uint32_t prog_end_index = prog_start_index + prog_leng;

		while (prog_start_index <= prog_end_index)
		{
			vm_flash_mem[prog_start_index] = device_inst.cache_mem[cache_index];
			cache_index++;
			prog_start_index++;
		}

		block_index = offset_index / FLASH_PAGE_SIZE;

		
		port->buff_p[port->buff_leng++] = OPC_PROGRAM_FLASH;
		port->buff_p[port->buff_leng++] = RESPONSE_SUCCESS;
	}
	break;

	case OPC_VERIFY_FLASH:
	{
		uint32_t verify_start_index = data[1] + (data[2] << 8) + (data[3] << 16);
		uint32_t verify_end_index = data[4] + (data[5] << 8) + (data[6] << 16);
		uint32_t get_crc32 = data[7] +
							(data[8] << 8) +
							(data[9] << 16) +
							(data[10] << 24);
		uint32_t verify_leng = (verify_end_index - verify_start_index) + 1;
		uint32_t crc32_res = FarmlandCalCrc32(data, (leng-4), 0);

		if (get_crc32 != crc32_res)
		{
			
			port->buff_p[port->buff_leng++] = OPC_VERIFY_FLASH;
			port->buff_p[port->buff_leng++] = RESPONSE_CRC_FAIL;
			break;
		}

		crc32_res = FarmlandCalCrc32(&vm_flash_mem[verify_start_index], ((verify_end_index - verify_start_index) + 1), 0);

		port->buff_p[port->buff_leng++] = OPC_VERIFY_FLASH;
		port->buff_p[port->buff_leng++] = RESPONSE_SUCCESS;
		port->buff_p[port->buff_leng++] = (uint8_t)crc32_res;
		port->buff_p[port->buff_leng++] = (uint8_t)(crc32_res >> 8);
		port->buff_p[port->buff_leng++] = (uint8_t)(crc32_res >> 16);
		port->buff_p[port->buff_leng++] = (uint8_t)(crc32_res >> 24);
	}
	break;

	default:
		break;
	}

	ISOTP_SenderDelegate(device_inst.isotp_inst,
		&ISOTP_Port_DeviceDFUSend,
		&ISOTP_Port_DeviceDFURecive);

	return RESPONSE_SUCCESS;
}

static int ParameterRequestHandler(uint8_t* data, uint32_t leng)
{
	uint32_t x = 0;
	uint8_t operate_code = data[0];
	uint8_t bank_index = data[1];
	uint8_t resp_code = RESPONSE_SUCCESS;
	ISOTP_PortInfo_T* port = &ISOTP_Port_DeviceParamSend;
	port->buff_index = 0;
	port->buff_leng = 0;
	port->buff_p[port->buff_leng++] = operate_code;

	if (bank_index > 3)
	{
		port->buff_p[port->buff_leng++] = RESPONSE_INVALID_PARAM;
	}
	else
	{
		switch (operate_code)
		{
		case OPC_READ_PARAM:
		{			
			if (leng < 11)
			{
				port->buff_p[port->buff_leng++] = RESPONSE_INVALID_SIZE;
				break;
			}

			uint32_t start_addr = data[2] + (data[3] << 8);
			uint32_t param_leng = data[4] + (data[5] << 8);
			uint32_t get_crc32 = data[6] + (data[7] << 8) + (data[8] << 16) + (data[9] << 24);
			uint32_t crc32_res = FarmlandCalCrc32(data, (leng -4), 0);

			if (get_crc32 != crc32_res)
			{
				port->buff_p[port->buff_leng++] = RESPONSE_CRC_FAIL;
				break;
			}

			port->buff_p[port->buff_leng++] = RESPONSE_SUCCESS;
			// Bank index
			port->buff_p[port->buff_leng++] = data[1];
			// Address
			port->buff_p[port->buff_leng++] = data[2];
			port->buff_p[port->buff_leng++] = data[3];
			// Leng
			port->buff_p[port->buff_leng++] = data[4];
			port->buff_p[port->buff_leng++] = data[5];
				
			// parameter_read(bank_index, start_addr, leng, out_data);
			for (x=0;x< param_leng;x++)
			{
				port->buff_p[port->buff_leng++] = vm_flash_mem[start_addr + x];
			}
				
			crc32_res = FarmlandCalCrc32(port->buff_p, port->buff_leng, 0);
			port->buff_leng += 4;

		}
		break;

		case OPC_WRITE_PARAM:
		{
			if (leng < 12)
			{
				port->buff_p[port->buff_leng++] = RESPONSE_INVALID_SIZE;
				break;
			}

			uint32_t start_addr = data[2] + (data[3] << 8);
			uint32_t param_leng = data[4] + (data[5] << 8);
			uint32_t get_crc32 = data[(leng-4)] + (data[(leng - 3)] << 8) + (data[(leng - 2)] << 16) + (data[(leng - 1)] << 24);
			uint32_t crc32_res = FarmlandCalCrc32(data, (leng-4), 0);
			
			if (get_crc32 != crc32_res)
			{
				port->buff_p[port->buff_leng++] = RESPONSE_CRC_FAIL;
			}
			else
			{
				// parameter_write(bank_index, start_addr, leng, out_data);

				for (x = 0; x < param_leng; x++)
				{
					vm_flash_mem[start_addr + x] = data[7+x];
				}

				port->buff_p[port->buff_leng++] = RESPONSE_SUCCESS;
			}
		}
		break;

		case OPC_RESET_PARAM:
		{
			if (leng < 6)
			{
				port->buff_p[port->buff_leng++] = RESPONSE_INVALID_SIZE;
				break;
			}

			uint32_t get_crc32 = data[(leng - 4)] + (data[(leng - 3)] << 8) + (data[(leng - 2)] << 16) + (data[(leng - 1)] << 24);
			uint32_t crc32_res = FarmlandCalCrc32(data, (leng - 4), 0);
			if (get_crc32 != crc32_res)
			{
				port->buff_p[port->buff_leng++] = RESPONSE_CRC_FAIL;
			}
			else
			{
				// parameter_reset_default(bank_index);

				port->buff_p[port->buff_leng++] = RESPONSE_SUCCESS;
			}
			
		}
		break;

		default:
		{
			port->buff_p[port->buff_leng++] = RESPONSE_INVALID_PARAM;
		}
		break;

		}
	}

	ISOTP_SenderDelegate(device_inst.isotp_inst,
		&ISOTP_Port_DeviceParamSend,
		&ISOTP_Port_DeviceParamRecive);

	return RESPONSE_SUCCESS;
}


static int HostControlInfoHandler(uint8_t* data, uint32_t leng)
{
	HOST_CONTROLINFO_00_T info = { 0 };
	COPY_MIN_ARRAY(data, leng, &info.bytes[0], sizeof(info.bytes));
	device_inst.info.current_assist_level = info.bits.set_assist_level;
	device_inst.info.power_key_on = info.bits.system_power_control;
	device_inst.info.light_on = info.bits.light_control;
	device_inst.info.walk_assist_on = info.bits.walk_assist_control;

	return RESPONSE_SUCCESS;
}

static int HostConfigRTCHandler(uint8_t* data, uint32_t leng)
{
	HOST_CONTROLINFO_01_T info = { 0 };
	COPY_MIN_ARRAY(data, leng, &info.bytes[0], sizeof(info.bytes));

	return RESPONSE_SUCCESS;
}

static int HostSilenceModeHandler(uint8_t* data, uint32_t leng)
{
	HOST_CONTROLINFO_02_T info = { 0 };
	COPY_MIN_ARRAY(data, leng, &info.bytes[0], sizeof(info.bytes));
	LIB_EVENT_SCHED_EVENT_CONFIG_T new_scheduler = { 0 };

	if (info.bits.silence_mode)
	{
		if (info.bits.silence_timeout > 0)
		{
			Virtual_Device_Boradcast_Pause();
			lib_event_sched_remove_at(Virtual_Device_Boradcast_Resume);

			new_scheduler.type = EVENT_SCHEDLULER_TRIGGER_TIMER;
			new_scheduler.timer_ms = info.bits.silence_timeout;
			new_scheduler.repeat = 1;
			new_scheduler.handler = Virtual_Device_Boradcast_Resume;

			lib_event_sched_add(&new_scheduler);
		}
		else
		{
			Virtual_Device_Boradcast_Resume();
		}
	}

	return RESPONSE_SUCCESS;
}

static int HostResetHandler(uint8_t* data, uint32_t leng)
{
	HOST_DEVICE_RESET_REQ_T requst = { 0 };
	HOST_DEVICE_RESET_RSP_T response = { 0 };

	COPY_MIN_ARRAY(data, leng, &requst.bytes[0], sizeof(requst.bytes));

	if (requst.bits.device_type == DEVICE_OBJ_HMI)
	{
		response.bits.device_type = DEVICE_OBJ_HMI;
		response.bits.response_code = RESPONSE_SUCCESS;

		if (device_inst.send_handler)
		{
			device_inst.send_handler(FL_CANID_HOST_DEVICE_RESET_RSP, false, response.bytes, sizeof(response.bytes));
		}
	}

	return RESPONSE_SUCCESS;
}

static int HostTestModeHandler(uint8_t* data, uint32_t leng)
{
	HOST_DEVICE_TEST_REQ_T requst = { 0 };
	HOST_DEVICE_TEST_RSP_T response = { 0 };

	COPY_MIN_ARRAY(data, leng, &requst.bytes[0], sizeof(requst.bytes));

	if (requst.bits.device_type == DEVICE_OBJ_HMI)
	{
		response.bits.device_type = DEVICE_OBJ_HMI;
		response.bits.response_code = RESPONSE_SUCCESS;

		switch (requst.bits.test_mode)
		{
		case 0:
			// Maybe LED test 1-2-3-4 4-3-2-1
			// Or LED Blinks. Others
			break;

		default:
			response.bits.response_code = RESPONSE_INVALID_PARAM;
			break;
			
		}


		

		if (device_inst.send_handler)
		{
			device_inst.send_handler(FL_CANID_HOST_DEVICE_RESET_RSP, false, response.bytes, sizeof(response.bytes));
		}
	}

	return RESPONSE_SUCCESS;
}

static int HostDebugModeHandler(uint8_t* data, uint32_t leng)
{
	HOST_DEVICE_DEBUG_REQ_T requst = { 0 };
	HOST_DEVICE_DEBUG_RSP_T response = { 0 };
	LIB_EVENT_SCHED_EVENT_CONFIG_T new_scheduler = { 0 };
	
	COPY_MIN_ARRAY(data, leng, &requst.bytes[0], sizeof(requst.bytes));

	if (requst.bits.device_type == DEVICE_OBJ_HMI)
	{
		response.bits.device_type = DEVICE_OBJ_HMI;
		response.bits.response_code = RESPONSE_SUCCESS;

		new_scheduler.type = EVENT_SCHEDLULER_TRIGGER_TIMER;
		new_scheduler.timer_ms = requst.bits.interval_time;
		new_scheduler.repeat = requst.bits.debug_count >= 255 ? -1 : requst.bits.debug_count;
		

		switch (requst.bits.debug_index)
		{
		case 0:
			if (new_scheduler.repeat == 0)
			{
				lib_event_sched_remove_at(HMI_debuginfo_00_broadcast_packet);
			}
			else
			{
				new_scheduler.handler = HMI_debuginfo_00_broadcast_packet;
				lib_event_sched_add(&new_scheduler);
			}
			break;

		case 1:
			if (new_scheduler.repeat == 0)
			{
				lib_event_sched_remove_at(HMI_debuginfo_01_broadcast_packet);
			}
			else
			{
				new_scheduler.handler = HMI_debuginfo_01_broadcast_packet;
				lib_event_sched_add(&new_scheduler);
			}
			break;

		default:
		{
			response.bits.response_code = RESPONSE_INVALID_PARAM;
		}
		break;

		}

		if (device_inst.send_handler)
		{
			device_inst.send_handler(FL_CANID_HOST_DEVICE_RESET_RSP, false, response.bytes, sizeof(response.bytes));
		}
	}

	return RESPONSE_SUCCESS;
}


static int HostTripResetHandler(uint8_t* data, uint32_t leng)
{
	HOST_DEVICE_TRIP_RESET_T commond = { 0 };

	COPY_MIN_ARRAY(data, leng, &commond.bytes[0], sizeof(commond.bytes));

	if (commond.bits.reset_enable)
	{
		device_inst.info.trip_odo = 0;
		device_inst.info.trip_time = 0;
		device_inst.info.trip_avg_speed = 0;
		device_inst.info.trip_max_speed = 0;
		device_inst.info.trip_avg_current = 0;
		device_inst.info.trip_max_current = 0;
	}
	
	return RESPONSE_SUCCESS;
}


void __stdcall FL_device_HMI_add_warning(uint8_t code)
{
	uint8_t search_index = 0;

	if (code == 0)
	{
		return;
	}

	for (search_index = 0; search_index < VIRTUAL_HMI_WARNING_CODE_SIZE; search_index++)
	{
		if (device_inst.warning_code[search_index] == code)
		{
			break;
		}

		if (device_inst.warning_code[search_index] == 0)
		{
			device_inst.warning_code[search_index] = code;
			device_inst.warning_leng++;
			if (device_inst.update_warning_notify)
			{
				device_inst.update_warning_notify(device_inst.warning_code, device_inst.warning_leng);
			}
			
			break;
		}
	}
}

void __stdcall FL_device_HMI_remove_warning(uint8_t code)
{
	uint8_t search_index = 0;

	if (code == 0)
	{
		return;
	}

	for (search_index = 0; search_index < VIRTUAL_HMI_WARNING_CODE_SIZE; search_index++)
	{
		if (device_inst.warning_code[search_index] == code)
		{
			device_inst.warning_code[search_index] = 0;
			for (; search_index < (VIRTUAL_HMI_WARNING_CODE_SIZE-1); search_index++)
			{
				if (device_inst.warning_code[(search_index+1)] != 0)
				{
					device_inst.warning_code[search_index] = device_inst.warning_code[(search_index + 1)];
					device_inst.warning_code[(search_index + 1)] = 0;
				}
				else
				{
					break;
				}
			}
			if (device_inst.warning_leng)
			{
				device_inst.warning_leng--;
			}

			if (device_inst.update_warning_notify)
			{
				device_inst.update_warning_notify(device_inst.warning_code, device_inst.warning_leng);
			}
			
			break;
		}

		if (device_inst.warning_code[search_index] == 0)
		{
			break;
		}
	}
}

void Register_UpdateWarning_Callback(update_warning_callback call_func)
{
	device_inst.update_warning_notify = call_func;
}

void __stdcall FL_device_HMI_add_error(uint8_t code)
{
	uint8_t search_index = 0;

	if (code == 0)
	{
		return;
	}

	for (search_index = 0; search_index < VIRTUAL_HMI_ERROR_CODE_SIZE; search_index++)
	{
		if (device_inst.error_code[search_index] == code)
		{
			break;
		}

		if (device_inst.error_code[search_index] == 0)
		{
			device_inst.error_code[search_index] = code;
			device_inst.error_leng++;
			if (device_inst.update_error_notify)
			{
				device_inst.update_error_notify(device_inst.error_code, device_inst.error_leng);
			}

			break;
		}
	}
}

void __stdcall FL_device_HMI_remove_error(uint8_t code)
{
	uint8_t search_index = 0;

	if (code == 0)
	{
		return;
	}

	for (search_index = 0; search_index < VIRTUAL_HMI_ERROR_CODE_SIZE; search_index++)
	{
		if (device_inst.error_code[search_index] == code)
		{
			device_inst.error_code[search_index] = 0;
			for (; search_index < (VIRTUAL_HMI_ERROR_CODE_SIZE - 1); search_index++)
			{
				if (device_inst.error_code[(search_index + 1)] != 0)
				{
					device_inst.error_code[search_index] = device_inst.error_code[(search_index + 1)];
					device_inst.error_code[(search_index + 1)] = 0;
				}
				else
				{
					break;
				}
			}
			if (device_inst.error_leng)
			{
				device_inst.error_leng--;
			}

			if (device_inst.update_error_notify)
			{
				device_inst.update_error_notify(device_inst.error_code, device_inst.error_leng);
			}

			break;
		}

		if (device_inst.error_code[search_index] == 0)
		{
			break;
		}
	}
}

void Register_UpdateError_Callback(update_error_callback call_func)
{
	device_inst.update_error_notify = call_func;
}


static void HMI_INFO_00_broadcast_packet(void)
{
	HMI_INFO_00_T info = { 0 };

	info.bits.current_assist_level = device_inst.info.current_assist_level;
	info.bits.support_assist_level = device_inst.info.support_assist_level;

	info.bits.system_power_on = device_inst.info.system_powe_on;
	info.bits.walk_assist_on = device_inst.info.walk_assist_on;
	info.bits.light_on = device_inst.info.light_on;

	info.bits.power_key_status = device_inst.info.power_key_on ? 1 : 0;
	info.bits.up_key_status = device_inst.info.up_key_on ? 1 : 0;
	info.bits.down_key_status = device_inst.info.down_key_on ? 1 : 0;
	info.bits.walk_key_status = device_inst.info.walk_key_on ? 1 : 0;
	info.bits.light_key_status = device_inst.info.light_key_on ? 1 : 0;

	if (device_inst.send_handler)
	{
		device_inst.send_handler(FL_CANID_HMI_INFO_00, false, info.bytes, sizeof(info.bytes));
	}
}

static void HMI_INFO_01_broadcast_packet(void)
{
	HMI_INFO_01_T info = { 0 };

	info.bits.trip_odo = device_inst.info.trip_odo;
	info.bits.trip_time = device_inst.info.trip_time;

	if (device_inst.send_handler)
	{
		device_inst.send_handler(FL_CANID_HMI_INFO_01, false, info.bytes, sizeof(info.bytes));
	}
}

static void HMI_INFO_02_broadcast_packet(void)
{
	HMI_INFO_02_T info = { 0 };

	info.bits.trip_avg_speed = device_inst.info.trip_avg_speed;
	info.bits.trip_max_speed = device_inst.info.trip_max_speed;
	info.bits.trip_avg_current = device_inst.info.trip_avg_current;
	info.bits.trip_max_current = device_inst.info.trip_max_current;

	if (device_inst.send_handler)
	{
		device_inst.send_handler(FL_CANID_HMI_INFO_02, false, info.bytes, sizeof(info.bytes));
	}
}

static void HMI_INFO_03_broadcast_packet(void)
{
	HMI_INFO_03_T info = { 0 };

	info.bits.trip_avg_pedal_speed = device_inst.info.trip_avg_pedal_speed;
	info.bits.trip_max_pedal_speed = device_inst.info.trip_max_pedal_speed;
	info.bits.trip_avg_pedal_torque = device_inst.info.trip_avg_pedal_torque;
	info.bits.trip_max_pedal_torque = device_inst.info.trip_max_pedal_torque;

	if (device_inst.send_handler)
	{
		device_inst.send_handler(FL_CANID_HMI_INFO_03, false, info.bytes, sizeof(info.bytes));
	}
}

static void HMI_warning_broadcast_packet(void)
{
	HMI_WARNINGINFO_T warning = { 0 };
	static uint8_t page = 0;
	uint8_t start_index = page * 7;
	uint8_t end_index = (page+1) * 7;
	uint8_t code_index = 0;

	warning.bits.page_num = page;
	warning.bits.total_leng = device_inst.warning_leng;

	while (start_index < end_index)
	{
		if (device_inst.warning_code[start_index] == 0)
		{
			break;
		}

		switch (code_index)
		{
		case 0:
			warning.bits.warning_0 = device_inst.warning_code[start_index];
			break;

		case 1:
			warning.bits.warning_1 = device_inst.warning_code[start_index];
			break;

		case 2:
			warning.bits.warning_2 = device_inst.warning_code[start_index];
			break;

		case 3:
			warning.bits.warning_3 = device_inst.warning_code[start_index];
			break;

		case 4:
			warning.bits.warning_4 = device_inst.warning_code[start_index];
			break;

		case 5:
			warning.bits.warning_5 = device_inst.warning_code[start_index];
			break;

		case 6:
			warning.bits.warning_6 = device_inst.warning_code[start_index];
			break;
		}

		code_index++;
		start_index++;
	}

	if (start_index < warning.bits.total_leng)
	{
		page++;
	}
	else
	{
		page = 0;
	}

	if (device_inst.send_handler)
	{
		device_inst.send_handler(FL_CANID_HMI_WARNING, false, warning.bytes, sizeof(warning.bytes));
	}

}




static void HMI_error_broadcast_packet(void)
{
	HMI_ERRORINFO_T error = { 0 };
	static uint8_t page = 0;
	uint8_t start_index = page * 7;
	uint8_t end_index = (page + 1) * 7;
	uint8_t code_index = 0;

	error.bits.page_num = page;
	error.bits.total_leng = device_inst.error_leng;

	while (start_index < end_index)
	{
		if (device_inst.error_code[start_index] == 0)
		{
			break;
		}

		switch (code_index)
		{
		case 0:
			error.bits.error_0 = device_inst.error_code[start_index];
			break;

		case 1:
			error.bits.error_1 = device_inst.error_code[start_index];
			break;

		case 2:
			error.bits.error_2 = device_inst.error_code[start_index];
			break;

		case 3:
			error.bits.error_3 = device_inst.error_code[start_index];
			break;

		case 4:
			error.bits.error_4 = device_inst.error_code[start_index];
			break;

		case 5:
			error.bits.error_5 = device_inst.error_code[start_index];
			break;

		case 6:
			error.bits.error_6 = device_inst.error_code[start_index];
			break;
		}

		code_index++;
		start_index++;
	}

	if (start_index < error.bits.total_leng)
	{
		page++;
	}
	else
	{
		page = 0;
	}

	if (device_inst.send_handler)
	{
		device_inst.send_handler(FL_CANID_HMI_ERROR, false, error.bytes, sizeof(error.bytes));
	}

}


static void HMI_debuginfo_00_broadcast_packet(void)
{
	HMI_DEBUGINFO_O0_T debug_info = { 0 };

	debug_info.bits.key_1_count = device_inst.info.key_1_count;
	debug_info.bits.key_2_count = device_inst.info.key_2_count;
	debug_info.bits.key_3_count = device_inst.info.key_3_count;
	debug_info.bits.key_4_count = device_inst.info.key_4_count;

	if (device_inst.send_handler)
	{
		device_inst.send_handler(FL_CANID_HMI_DEBUGINFO_00, true, debug_info.bytes, sizeof(debug_info.bytes));
	}
}


static void HMI_debuginfo_01_broadcast_packet(void)
{
	HMI_DEBUGINFO_01_T debug_info = { 0 };

	debug_info.bits.key_5_count = device_inst.info.key_5_count;
	debug_info.bits.key_6_count = device_inst.info.key_6_count;
	debug_info.bits.key_7_count = device_inst.info.key_7_count;
	debug_info.bits.key_8_count = device_inst.info.key_8_count;

	if (device_inst.send_handler)
	{
		device_inst.send_handler(FL_CANID_HMI_DEBUGINFO_01, true, debug_info.bytes, sizeof(debug_info.bytes));
	}
}



static void HMI_broadcast_per_100ms(void)
{
	HMI_INFO_00_broadcast_packet();
}

static void HMI_broadcast_per_200ms(void)
{
	HMI_warning_broadcast_packet();
	HMI_error_broadcast_packet();
}

static void HMI_broadcast_per_1000ms(void)
{
	HMI_INFO_01_broadcast_packet();
	HMI_INFO_02_broadcast_packet();
	HMI_INFO_03_broadcast_packet();
}

static void HMI_broadcast_per_3000ms(void)
{

}


int FL_HMI_CAN_TryPaser(uint32_t can_id, bool is_extend, uint8_t* data, uint8_t leng)
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


uint32_t FL_device_HMI_Init(ISOTP_INST_T * isotp_inst, canbus_send_handler_p sender)
{
	if (isotp_inst && sender)
	{
		device_inst.isotp_inst = isotp_inst;
		device_inst.isotp_inst->send_packet = sender;
		device_inst.send_handler = sender;

		ISOTP_Init(device_inst.isotp_inst);

		ISOTP_RegisterListenPort(device_inst.isotp_inst,
			&ISOTP_Port_DeviceDFUSend,
			&ISOTP_Port_DeviceDFURecive);

		ISOTP_RegisterListenPort(device_inst.isotp_inst,
			&ISOTP_Port_DeviceParamSend,
			&ISOTP_Port_DeviceParamRecive);
	}
	else
	{
		return SDK_RETURN_NULL;
	}


	return SDK_RETURN_SUCCESS;
}

// SDK used functional

void __stdcall FL_device_HMI_update_info(FL_HMI_INFO_ST* new_info)
{
	memcpy(&device_inst.info, new_info, sizeof(device_inst.info));
}

uint32_t __stdcall Virtual_Device_HMI_Startup(void)
{
	uint32_t ret_val = SDK_RETURN_SUCCESS;
	LIB_EVENT_SCHED_EVENT_CONFIG_T new_scheduler = { 0 };

	new_scheduler.type = EVENT_SCHEDLULER_TRIGGER_TIMER;
	new_scheduler.timer_ms = 100;
	new_scheduler.repeat = -1;
	new_scheduler.handler = HMI_broadcast_per_100ms;
	ret_val |= lib_event_sched_add(&new_scheduler);

	new_scheduler.type = EVENT_SCHEDLULER_TRIGGER_TIMER;
	new_scheduler.timer_ms = 200;
	new_scheduler.repeat = -1;
	new_scheduler.handler = HMI_broadcast_per_200ms;
	ret_val |= lib_event_sched_add(&new_scheduler);

	new_scheduler.type = EVENT_SCHEDLULER_TRIGGER_TIMER;
	new_scheduler.timer_ms = 1000;
	new_scheduler.repeat = -1;
	new_scheduler.handler = HMI_broadcast_per_1000ms;
	ret_val |= lib_event_sched_add(&new_scheduler);

	new_scheduler.type = EVENT_SCHEDLULER_TRIGGER_TIMER;
	new_scheduler.timer_ms = 3000;
	new_scheduler.repeat = -1;
	new_scheduler.handler = HMI_broadcast_per_3000ms;
	ret_val |= lib_event_sched_add(&new_scheduler);

	return ret_val;
}


static void Virtual_Device_Boradcast_Pause(void)
{
	lib_event_sched_pause_at(HMI_broadcast_per_100ms);
	lib_event_sched_pause_at(HMI_broadcast_per_200ms);
	lib_event_sched_pause_at(HMI_broadcast_per_1000ms);
	lib_event_sched_pause_at(HMI_broadcast_per_3000ms);
}


static void Virtual_Device_Boradcast_Resume(void)
{
	lib_event_sched_resume_at(HMI_broadcast_per_100ms);
	lib_event_sched_resume_at(HMI_broadcast_per_200ms);
	lib_event_sched_resume_at(HMI_broadcast_per_1000ms);
	lib_event_sched_resume_at(HMI_broadcast_per_3000ms);
}


uint32_t __stdcall Virtual_Device_HMI_Stop(void)
{
	lib_event_sched_remove_at(HMI_broadcast_per_100ms);
	lib_event_sched_remove_at(HMI_broadcast_per_200ms);
	lib_event_sched_remove_at(HMI_broadcast_per_1000ms);
	lib_event_sched_remove_at(HMI_broadcast_per_3000ms);

	return SDK_RETURN_SUCCESS;
}