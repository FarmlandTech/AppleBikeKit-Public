#pragma once

#ifndef _CAN_ISO_TP_H // include guard
#define _CAN_ISO_TP_H

#include <stdint.h>

#ifdef __cplusplus
extern "C" {
#endif


#define ISOTP_TIMEOUT_MS				3000	// ISO-TP timeout default set to 3's 

#define ISOTP_DELEGATE_SUCCESS			0U
#define ISOTP_DELEGATE_TIMEOUT			1U
#define ISOTP_DELEGATE_BUSY				2U
#define ISOTP_DELEGATE_NULL				3U
#define ISOTP_DELEGATE_EXISTED			4U
#define ISOTP_DELEGATE_INVALID_PARA		5U
#define ISOTP_DELEGATE_INVALID_PACKET	6U

typedef int (*send_can_packet_func)(unsigned int can_id, bool is_extender_id, unsigned char* raw_data, unsigned int leng);
typedef int (*send_finally_callback)(void);
typedef void (*send_error_callback)(uint32_t error_code);
typedef int (*recive_packet_callback)(uint8_t* data, uint32_t leng);


enum RUN_STATUS_e
{
	ISOTP_STATUS_IDLE = 0,
	ISOTP_STATUS_WAIT_FLOW_CTRL,
	ISOTP_STATUS_WAIT,
	ISOTP_STATUS_KEEPSEND,
	ISOTP_STATUS_KEEPRECIVE,
	ISOTP_STATUS_SEND_TIMEOUT,
	ISOTP_STATUS_REVICE_TIMEOUT
};

typedef struct ISOTP_PortInfo_st
{
	uint32_t CAN_ID;
	bool is_extend_id;
	uint8_t* buff_p;
	uint16_t buff_size;
	uint16_t buff_leng;
	uint16_t buff_index;
	uint8_t block_index;
	// Send action callback
	send_finally_callback send_finally_callback;
	send_error_callback exception_callback;
	// Recive action callback
	recive_packet_callback revice_packet_callback;

}ISOTP_PortInfo_T;

#define LISTEN_PORT_SIZE		32

#define FRAME_TYPE_SINGLE		0U
#define FRAME_TYPE_FIRST		1U
#define FRAME_TYPE_CONSECUTIVE	2U
#define FRAME_TYPE_FLOW_CTL		3U


union SingleFrameHeader_st
{
	struct 
	{
		// LSB
		uint8_t data_leng : 4;
		uint8_t type : 4;
	}bits ;
	uint8_t bytes[1];
};

union FirstFrameHeader_st
{
	struct
	{
		// LSB
		uint8_t data_leng_h_4b : 4;
		uint8_t type : 4;

		uint8_t data_leng_l_8b;
	}bits;
	uint8_t bytes[2];
};

union ContinuousFrameHeader
{
	struct
	{
		// LSB
		uint8_t index : 4;
		uint8_t type : 4;
	}bits;
	uint8_t bytes[1];
};

union FlowControlFrameHeader
{
	struct
	{
		// LSB
		uint8_t FC_flag : 4;
		uint8_t type : 4;

		uint8_t block_size;
		uint8_t separation_time;
	}bits;
	uint8_t bytes[3];
};


struct ListenPort_st
{
	ISOTP_PortInfo_T*tx;
	ISOTP_PortInfo_T*rx;
};


struct TransConfig_st
{
	int block_size;
	int block_leng;
	uint16_t delay_time_ms;
	uint16_t delay_counter;
	uint8_t continuous_index:4;
};

struct TimeoutConfig_st
{
	uint16_t count;
	uint16_t threshold;
	uint8_t enable;
};

typedef struct ISOTPInst_st
{
	bool be_init;
	enum RUN_STATUS_e now_status;
	send_can_packet_func send_packet;
	struct TransConfig_st FC_setting;
	struct ListenPort_st delegate;
	struct ListenPort_st ports[LISTEN_PORT_SIZE];
	struct TimeoutConfig_st timeout;
	uint16_t ports_leng;
	uint16_t select_port_index;
} ISOTP_INST_T;


void ISOTP_Process(ISOTP_INST_T* isotp_inst, uint32_t CAN_ID, bool is_extend_id, uint8_t* data, uint8_t leng);

int ISOTP_RegisterListenPort(ISOTP_INST_T* isotp_inst, ISOTP_PortInfo_T* request_port, ISOTP_PortInfo_T* respond_port);
int ISOTP_SenderDelegate(ISOTP_INST_T* isotp_inst, ISOTP_PortInfo_T* request_port, ISOTP_PortInfo_T* respond_port);
void ISOTP_timer_1ms_tick(ISOTP_INST_T* isotp_inst);
int ISOTP_Init(ISOTP_INST_T* isotp_inst);

#ifdef __cplusplus
}
#endif

#endif
