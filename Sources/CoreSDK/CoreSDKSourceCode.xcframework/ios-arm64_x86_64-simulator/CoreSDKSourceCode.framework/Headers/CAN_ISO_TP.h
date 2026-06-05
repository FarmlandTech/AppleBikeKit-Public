#pragma once

#ifndef _CAN_ISO_TP_H // include guard
#define _CAN_ISO_TP_H

#include <stdint.h>
#include <CoreSDKSourceCode/Common.h>

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

#define LISTEN_PORT_SIZE		        32

#define FRAME_TYPE_SINGLE		        0U
#define FRAME_TYPE_FIRST		        1U
#define FRAME_TYPE_CONSECUTIVE	        2U
#define FRAME_TYPE_FLOW_CTL		        3U

/* Exported macro ------------------------------------------------------------*/

/* Exported types ------------------------------------------------------------*/

	//typedef uint32_t(*send_can_packet_func)(uint32_t can_id, bool is_extender, uint8_t* data, uint32_t leng);
	typedef int (*send_finally_callback)(void);
	typedef void (*send_error_callback)(uint32_t error_code);
	typedef int(__cdecl*recive_packet_callback)(uint8_t* data, uint32_t leng);

	typedef enum
	{
		ISOTP_STATUS_IDLE = 0,
		ISOTP_STATUS_WAIT_FLOW_CTRL,
		ISOTP_STATUS_WAIT,
		ISOTP_STATUS_KEEPSEND,
		ISOTP_STATUS_KEEPRECIVE,
		ISOTP_STATUS_SEND_TIMEOUT,
		ISOTP_STATUS_REVICE_TIMEOUT
	} RUN_STATUS_e;

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
	} ISOTP_PortInfo_T;

	typedef union
	{
		struct
		{
			// LSB
			uint8_t data_leng : 4;
			uint8_t type : 4;
		}bits;
		uint8_t bytes[1];
	} SingleFrameHeader_st;

	typedef union
	{
		struct
		{
			// LSB
			uint8_t data_leng_h_4b : 4;
			uint8_t type : 4;

			uint8_t data_leng_l_8b;
		}bits;
		uint8_t bytes[2];
	} FirstFrameHeader_st;

	typedef union
	{
		struct
		{
			// LSB
			uint8_t index : 4;
			uint8_t type : 4;
		}bits;
		uint8_t bytes[1];
	} ContinuousFrameHeader;

	typedef union
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
	} FlowControlFrameHeader;

	typedef struct
	{
		ISOTP_PortInfo_T* tx;
		ISOTP_PortInfo_T* rx;
	} ListenPort_st;

	typedef struct
	{
		int block_size;
		int block_leng;
		uint16_t delay_time_ms;
		uint16_t delay_counter;
		uint8_t continuous_index : 4;
	} TransConfig_st;

	typedef struct
	{
		uint16_t count;
		uint16_t threshold;
		uint8_t enable;
	} TimeoutConfig_st;

	typedef struct ISOTPInst_st
	{
		bool be_init;
		RUN_STATUS_e now_status;
		canbus_send_handler_p send_packet;
		TransConfig_st FC_setting;
		ListenPort_st delegate;
		ListenPort_st ports[LISTEN_PORT_SIZE];
		TimeoutConfig_st timeout;
		uint16_t ports_leng;
		uint16_t select_port_index;
		uint16_t delay;
	} ISOTP_INST_T;

	/* Exported functions prototypes ---------------------------------------------*/
	void ISOTP_Process(ISOTP_INST_T* isotp_inst, uint32_t CAN_ID, bool is_extend_id, uint8_t* data, uint8_t leng);

	uint32_t ISOTP_RegisterListenPort(ISOTP_INST_T* isotp_inst, ISOTP_PortInfo_T* request_port, ISOTP_PortInfo_T* respond_port);
	uint32_t ISOTP_SenderDelegate(ISOTP_INST_T* isotp_inst, ISOTP_PortInfo_T* request_port, ISOTP_PortInfo_T* respond_port);
	void ISOTP_timer_1ms_tick(ISOTP_INST_T* isotp_inst);
	uint32_t ISOTP_Init(ISOTP_INST_T* isotp_inst);


#ifdef __cplusplus
}
#endif

#endif
