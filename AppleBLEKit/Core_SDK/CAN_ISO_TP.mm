#include "CAN_ISO_TP.h"
#include <string.h>

static void copy_array(uint8_t* source, uint8_t* target, uint32_t leng)
{
	uint32_t index = 0;
	for (;index< leng;index++)
	{
		target[index] = source[index];
	}
}

static void ISOTP_TimeoutReset(ISOTP_INST_T* isotp_inst)
{
	isotp_inst->timeout.count = 0;
}

static void ISOTP_TimeoutEnable(ISOTP_INST_T* isotp_inst)
{
	isotp_inst->timeout.enable = true;
	isotp_inst->timeout.count = 0;
	isotp_inst->timeout.threshold = ISOTP_TIMEOUT_MS;
}

static void ISOTP_TimeoutDisable(ISOTP_INST_T* isotp_inst)
{
	isotp_inst->timeout.enable = false;
	isotp_inst->timeout.count = 0;
	isotp_inst->timeout.threshold = ISOTP_TIMEOUT_MS;
}

static void ISOTP_SendFlowControl(ISOTP_INST_T* isotp_inst, ISOTP_PortInfo_T* tx, uint8_t block_size, uint16_t delay)
{
	uint8_t tx_data[3] = { 0 };

	tx_data[0] = (FRAME_TYPE_FLOW_CTL << 4);

	if (block_size)
	{
		tx_data[1] = block_size;
	}

	if (delay)
	{
		if (delay <= 127)
		{
			tx_data[2] = 100;
		}
		else if(delay <= 900)
		{
			tx_data[2] = (delay / 100) + 0xF0;
		}
	}

	isotp_inst->send_packet(tx->CAN_ID, tx->is_extend_id, tx_data, 3);
}

static int ISOTP_ParseFlowControl(ISOTP_INST_T* isotp_inst, uint8_t * data, uint8_t leng)
{
	FlowControlFrameHeader flow_frame;
	if (leng == 3)
	{
		memcpy(flow_frame.bytes, data, 3);

		if (flow_frame.bits.type == FRAME_TYPE_FLOW_CTL)
		{
			if (flow_frame.bits.block_size)
			{
				isotp_inst->FC_setting.block_size = flow_frame.bits.block_size;
				isotp_inst->FC_setting.block_leng = flow_frame.bits.block_size;
			}
			else
			{
				isotp_inst->FC_setting.block_size = -1;
			}

			isotp_inst->FC_setting.block_leng = 0;
			isotp_inst->FC_setting.delay_counter = 0;

			if (flow_frame.bits.separation_time <= 127)
			{
				isotp_inst->FC_setting.delay_time_ms = flow_frame.bits.separation_time;
			}
			else
			{
				switch (flow_frame.bits.separation_time)
				{
				case 0xF1:
					isotp_inst->FC_setting.delay_time_ms = 100;
					break;
				case 0xF2:
					isotp_inst->FC_setting.delay_time_ms = 200;
					break;
				case 0xF3:
					isotp_inst->FC_setting.delay_time_ms = 300;
					break;
				case 0xF4:
					isotp_inst->FC_setting.delay_time_ms = 400;
					break;
				case 0xF5:
					isotp_inst->FC_setting.delay_time_ms = 500;
					break;
				case 0xF6:
					isotp_inst->FC_setting.delay_time_ms = 600;
					break;
				case 0xF7:
					isotp_inst->FC_setting.delay_time_ms = 700;
					break;
				case 0xF8:
					isotp_inst->FC_setting.delay_time_ms = 800;
					break;
				case 0xF9:
					isotp_inst->FC_setting.delay_time_ms = 900;
					break;
				default:
					isotp_inst->FC_setting.delay_time_ms = 0;
					break;
				}
			}

			isotp_inst->FC_setting.continuous_index = 1;

			return ISOTP_DELEGATE_SUCCESS;
		}
	}

	return ISOTP_DELEGATE_INVALID_PACKET;
}


static void ISOTP_SendContinuousPacket(ISOTP_INST_T* isotp_inst, ISOTP_PortInfo_T* sender_info)
{
	union ContinuousFrameHeader frame_heard = { 0 };
	uint8_t tx_data[8] = { 0 };
	uint8_t tx_leng = 0;
	bool already_to_send = false;

	if (sender_info->buff_index < sender_info->buff_leng)
	{
		frame_heard.bits.type = FRAME_TYPE_CONSECUTIVE;
		frame_heard.bits.index = isotp_inst->FC_setting.continuous_index;

		tx_data[tx_leng++] = frame_heard.bytes[0];

		while (tx_leng < sizeof(tx_data))
		{
			if (sender_info->buff_index >= sender_info->buff_leng)
			{
				
				break;
			}
			tx_data[tx_leng++] = sender_info->buff_p[sender_info->buff_index];
			sender_info->buff_index++;
		}

		isotp_inst->FC_setting.continuous_index++;
		isotp_inst->send_packet(sender_info->CAN_ID, sender_info->is_extend_id, tx_data, tx_leng);

		if (sender_info->buff_index >= sender_info->buff_leng)
		{
			isotp_inst->now_status = ISOTP_STATUS_IDLE;
			if (sender_info->send_finally_callback)
			{
				sender_info->send_finally_callback();
			}

			if (isotp_inst->delegate.tx != NULL)
			{
				isotp_inst->delegate.tx = NULL;
				isotp_inst->delegate.rx = NULL;
			}
		}
		else
		{
			ISOTP_TimeoutReset(isotp_inst);
		}
		
	}
	else
	{
		isotp_inst->now_status = ISOTP_STATUS_IDLE;
	}
}


int ISOTP_SearchRxPort(ISOTP_INST_T* isotp_inst, uint32_t CAN_ID, bool is_extend_id)
{
	uint32_t index = 0;
	while (index < isotp_inst->ports_leng)
	{
		if (isotp_inst->ports[index].rx->CAN_ID == CAN_ID &&
			isotp_inst->ports[index].rx->is_extend_id == is_extend_id)
		{
			return index;
		}
		index++;
	}

	return -1;
}


void ISOTP_Process(ISOTP_INST_T* isotp_inst, uint32_t CAN_ID, bool is_extend_id, uint8_t * data, uint8_t leng)
{
	int find_index = 0;

	switch (isotp_inst->now_status)
	{

	case ISOTP_STATUS_IDLE:
	{
		uint8_t frame_type = 0;

		if (data == NULL || leng == 0)
		{
			return;
		}

		find_index = ISOTP_SearchRxPort(isotp_inst, CAN_ID, is_extend_id);

		if (find_index < 0)
		{
			break;
		}

		frame_type = (data[0] >> 4) & 0xF;

		switch (frame_type)
		{
		case FRAME_TYPE_SINGLE:
		{
			isotp_inst->ports[find_index].rx->buff_leng = leng - 1;

			copy_array(&data[1], 
				isotp_inst->ports[find_index].rx->buff_p, 
				isotp_inst->ports[find_index].rx->buff_leng);

			if (isotp_inst->ports[find_index].rx->revice_packet_callback)
			{
				isotp_inst->ports[find_index].rx->revice_packet_callback(
					isotp_inst->ports[find_index].rx->buff_p,
					isotp_inst->ports[find_index].rx->buff_leng);
			}
		}
		break;

		case FRAME_TYPE_FIRST:
		{
			if (leng < 8) break;

			isotp_inst->ports[find_index].rx->buff_leng = ((uint16_t)(data[0]&0xF) << 8) + data[1];

			copy_array(&data[2], isotp_inst->ports[find_index].rx->buff_p, 6);

			isotp_inst->ports[find_index].rx->buff_index = 6;
			isotp_inst->ports[find_index].rx->block_index = 1;
			isotp_inst->now_status = ISOTP_STATUS_KEEPRECIVE;
			isotp_inst->select_port_index = find_index;
			ISOTP_SendFlowControl(isotp_inst, isotp_inst->ports[find_index].tx, 0, 0);
		}
		break;

		default:
		{

		}
		break;
		}
	}
	break;

	case ISOTP_STATUS_WAIT_FLOW_CTRL:
	{
		if (isotp_inst->delegate.rx != NULL)
		{
			if (isotp_inst->delegate.rx->CAN_ID == CAN_ID
				&& isotp_inst->delegate.rx->is_extend_id == is_extend_id)
			{
				if (ISOTP_ParseFlowControl(isotp_inst, data, leng) == ISOTP_DELEGATE_SUCCESS)
				{
					ISOTP_TimeoutReset(isotp_inst);

					if (isotp_inst->FC_setting.delay_time_ms)
					{
						isotp_inst->FC_setting.delay_counter = 0;
						isotp_inst->now_status = ISOTP_STATUS_WAIT;
					}
					else
					{
						isotp_inst->now_status = ISOTP_STATUS_KEEPSEND;
					}
					
				}
				else
				{
					// 
				}
			}
		}
		
	}
	break;

	case ISOTP_STATUS_WAIT:
	{
		if (isotp_inst->FC_setting.delay_counter >= isotp_inst->FC_setting.delay_time_ms)
		{
			isotp_inst->now_status = ISOTP_STATUS_KEEPSEND;
		}
	}
	break;

	
	case ISOTP_STATUS_KEEPSEND:
	{
		if (isotp_inst->FC_setting.block_size < 0)
		{
			ISOTP_SendContinuousPacket(isotp_inst, isotp_inst->delegate.tx);
		}
		else
		{
			if (isotp_inst->FC_setting.block_leng == 0)
			{
				isotp_inst->now_status = ISOTP_STATUS_WAIT_FLOW_CTRL;
				break;
			}

			ISOTP_SendContinuousPacket(isotp_inst, isotp_inst->delegate.tx);
			isotp_inst->FC_setting.block_leng--;
		}

		if (isotp_inst->FC_setting.delay_time_ms && isotp_inst->now_status == ISOTP_STATUS_KEEPSEND)
		{
			isotp_inst->FC_setting.delay_counter = 0;
			isotp_inst->now_status = ISOTP_STATUS_WAIT;
		}
	}
	break;


	case ISOTP_STATUS_KEEPRECIVE:
	{
		if (ISOTP_SearchRxPort(isotp_inst, CAN_ID, is_extend_id) == isotp_inst->select_port_index)
		{
			find_index = isotp_inst->select_port_index;
			uint8_t block_index = data[0] & 0xf;
			uint8_t copy_leng = (leng - 1);

			if ((data[0] >> 4 & 0xf) != FRAME_TYPE_CONSECUTIVE)
			{
				isotp_inst->now_status = ISOTP_STATUS_IDLE;
				break;
			}

			if (block_index != isotp_inst->ports[find_index].rx->block_index)
			{
				isotp_inst->now_status = ISOTP_STATUS_IDLE;
				break;
			}

			copy_array(&data[1],
				&isotp_inst->ports[find_index].rx->buff_p[isotp_inst->ports[find_index].rx->buff_index],
				copy_leng);

			isotp_inst->ports[find_index].rx->buff_index += copy_leng;

			if (isotp_inst->ports[find_index].rx->buff_index >= isotp_inst->ports[find_index].rx->buff_leng)
			{
				isotp_inst->now_status = ISOTP_STATUS_IDLE;

				if (isotp_inst->ports[find_index].rx->revice_packet_callback)
				{
					isotp_inst->ports[find_index].rx->revice_packet_callback(
						isotp_inst->ports[find_index].rx->buff_p,
						isotp_inst->ports[find_index].rx->buff_leng);
				}

				break;
			}

			isotp_inst->ports[find_index].rx->block_index++;

			if (isotp_inst->ports[find_index].rx->block_index > 0xf)
			{
				isotp_inst->ports[find_index].rx->block_index = 0x0;
			}
		}
	}
	break;

	case ISOTP_STATUS_SEND_TIMEOUT:
	{
		if (isotp_inst->delegate.tx)
		{
			if (isotp_inst->delegate.tx->exception_callback)
			{
				isotp_inst->delegate.tx->exception_callback(ISOTP_DELEGATE_TIMEOUT);
			}
		}

		isotp_inst->now_status = ISOTP_STATUS_IDLE;
	}
	break;

	case ISOTP_STATUS_REVICE_TIMEOUT:
	{
		isotp_inst->now_status = ISOTP_STATUS_IDLE;

		if (isotp_inst->delegate.rx)
		{
			if (isotp_inst->delegate.rx->exception_callback)
			{
				isotp_inst->delegate.rx->exception_callback(ISOTP_DELEGATE_TIMEOUT);
			}
		}
	}
	break;

	default:
		break;
	}
}

int ISOTP_RegisterListenPort(ISOTP_INST_T* isotp_inst, ISOTP_PortInfo_T* sender, ISOTP_PortInfo_T* receiver)
{
	uint16_t index = 0;

	if (sender==NULL || receiver==NULL)
	{
		return ISOTP_DELEGATE_NULL;
	}
	
	while (index < LISTEN_PORT_SIZE)
	{
		if (isotp_inst->ports[index].tx == NULL)
		{
			isotp_inst->ports[index].tx = sender;
			isotp_inst->ports[index].rx = receiver;
			isotp_inst->ports_leng++;

			break;
		}

		if (isotp_inst->ports[index].tx->CAN_ID == sender->CAN_ID &&
			isotp_inst->ports[index].tx->is_extend_id == sender->is_extend_id)
		{
			isotp_inst->ports[index].tx = sender;
			isotp_inst->ports[index].rx = receiver;

			return ISOTP_DELEGATE_EXISTED;
		}

		index++;
	}

	

	return ISOTP_DELEGATE_SUCCESS;
}


int ISOTP_SenderDelegate(ISOTP_INST_T* isotp_inst, ISOTP_PortInfo_T* tx, ISOTP_PortInfo_T* rx)
{
	uint8_t tx_leng = 0;
	uint8_t tx_data[8] = {0};
	SingleFrameHeader_st single_header;
	FirstFrameHeader_st first_header;

	if (isotp_inst->now_status != ISOTP_STATUS_IDLE)
	{
		return -1;
	}
	else
	{
		if (tx->buff_leng > 7)
		{
			// Use multiple frame transmission
			first_header.bits.type = FRAME_TYPE_FIRST;
			first_header.bits.data_leng_h_4b = ((tx->buff_leng >> 8) & 0xF);
			first_header.bits.data_leng_l_8b = (tx->buff_leng & 0xFF);
			tx_data[0] = first_header.bytes[0];
			tx_data[1] = first_header.bytes[1];

			copy_array(tx->buff_p, &tx_data[2], 6);
			tx->buff_index = 6;
			tx_leng = 8;

			isotp_inst->send_packet(tx->CAN_ID, tx->is_extend_id, tx_data, tx_leng);


			isotp_inst->now_status = ISOTP_STATUS_WAIT_FLOW_CTRL;
			isotp_inst->delegate.tx = tx;
			isotp_inst->delegate.rx = rx;
			ISOTP_TimeoutEnable(isotp_inst);
		}
		else
		{
			// Use single frame transmission
			if (isotp_inst->send_packet)
			{
				single_header.bits.type = FRAME_TYPE_SINGLE;
				single_header.bits.data_leng = tx->buff_leng;
				
				tx_data[0] = single_header.bytes[0];
				copy_array(tx->buff_p, &tx_data[1], tx->buff_leng);
				tx_leng = tx->buff_leng + 1;

				isotp_inst->send_packet(tx->CAN_ID, tx->is_extend_id, tx_data, tx_leng);

				isotp_inst->delegate.tx = NULL;
				isotp_inst->delegate.rx = NULL;

				if (tx->send_finally_callback)
				{
					tx->send_finally_callback();
				}
			}
		}
	}

	return 0;
}


void ISOTP_timer_1ms_tick(ISOTP_INST_T* isotp_inst)
{
	if (isotp_inst->FC_setting.delay_counter < isotp_inst->FC_setting.delay_time_ms)
	{
		isotp_inst->FC_setting.delay_counter++;
	}

	if (isotp_inst->timeout.enable)
	{
		if (isotp_inst->timeout.threshold > isotp_inst->timeout.count)
		{
			isotp_inst->timeout.count++;
		}
		else
		{
			switch (isotp_inst->now_status)
			{
			case ISOTP_STATUS_KEEPSEND:
			case ISOTP_STATUS_WAIT_FLOW_CTRL:
				isotp_inst->now_status = ISOTP_STATUS_SEND_TIMEOUT;
				break;

			case ISOTP_STATUS_KEEPRECIVE:
				isotp_inst->now_status = ISOTP_STATUS_REVICE_TIMEOUT;
				break;
			}

			ISOTP_TimeoutDisable(isotp_inst);
		}
	}
}

int ISOTP_Init(ISOTP_INST_T* isotp_inst)
{
	if (isotp_inst)
	{
		if (isotp_inst->send_packet == NULL)
		{
			return ISOTP_DELEGATE_NULL;
		}

		isotp_inst->be_init = true;
		isotp_inst->now_status = ISOTP_STATUS_IDLE;
		return ISOTP_DELEGATE_SUCCESS;
	}
	else
	{
		return ISOTP_DELEGATE_NULL;
	}
}

