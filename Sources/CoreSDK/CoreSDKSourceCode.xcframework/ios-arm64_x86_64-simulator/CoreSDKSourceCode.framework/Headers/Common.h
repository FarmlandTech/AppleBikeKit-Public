#pragma once

#ifndef _COMMON_H // include guard
#define _COMMON_H

#include <stdint.h>
#include <stdbool.h>
#include <string.h>


#ifdef __cplusplus
extern "C" {
#endif

#define GET_ARRAY_SIZE(_array) sizeof(_array) / sizeof(_array[0])

#define COPY_MIN_ARRAY(_source_data, _source_size, _target_data, _target_size) \
	if((_source_size) > (_target_size)) \
	{ \
		memcpy((_target_data), (_source_data), (_target_size)); \
	} \
	else \
	{ \
		memcpy((_target_data), (_source_data), (_source_size)); \
	}

#define SWAP_16(_source)	\
	_source = ((_source << 8)&0xFF00) + ((_source >> 8)&0x00FF);

#define SWAP_32(_source)	\
	_source = ((_source << 24)&0xFF000000) + ((_source << 8)&0x00FF0000) + ((_source >> 8)&0x0000FF00) + ((_source >> 24)&0x000000FF);

#define SWAP_64(_source)	\
	_source = ((_source << 56)&0xFF00000000000000) + ((_source << 40)&0x00FF000000000000) + ((_source << 24)&0x0000FF0000000000) + ((_source << 8)&0x000000FF00000000)\
	+ ((_source >> 8)&0x00000000FF000000) + ((_source >> 24)&0x0000000000FF0000) + ((_source >> 40)&0x000000000000FF00) + ((_source >> 56)&0x00000000000000FF);


#ifndef WARNING_CODE_SIZE
#define WARNING_CODE_SIZE	16
#endif

#ifndef ERROR_CODE_SIZE
#define ERROR_CODE_SIZE		16
#endif


	struct CAN_ParseHandlerDefine_st
	{
		uint32_t can_id;
		bool is_extend;
		int (*handler)(uint8_t* data, uint32_t leng);
	};

	typedef int (*canbus_send_handler_p)(uint32_t can_id, bool is_extender, uint8_t* data, uint32_t leng);

	unsigned int FarmlandCalCrc32(const unsigned char* buf, unsigned int len, unsigned int init);


	unsigned char ELockCalCheckSum(const unsigned char* buf, unsigned int len);
#ifdef __cplusplus
}
#endif

#endif

