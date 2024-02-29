#pragma once

#ifndef _COMMON_H // include guard
#define _COMMON_H

#include <stdint.h>
#include <stdbool.h>
#include <string.h>


#ifdef __cplusplus
extern "C" {
#endif


//巨集:檢查參數是否為空
#define SDK_PARAM_VERIFY_NULL(_param_) if(_param_==NULL){ return SDK_RETURN_NULL;}


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

// 使用Apple平台時重新定義,包含 MacOS及iOS
#if __APPLE__
#undef LOG_PRINT_ENABLE 
#define LOG_PRINT_ENABLE 0

#define PACK( __Declaration__ ) __Declaration__ __attribute__((__packed__))

#endif

#ifdef _WIN32
#define DllExport   __declspec( dllexport )
#else
#define DllExport
#define __stdcall


#define PACK( __Declaration__ ) __pragma( pack(push, 1) ) __Declaration__ __pragma( pack(pop))

#endif // _WIN32

struct CAN_ParseHandlerDefine_st
{
	uint32_t can_id;
	bool is_extend;
	int (*handler)(uint8_t* data, uint32_t leng);
};

typedef int (*canbus_send_handler_p)(uint32_t can_id, bool is_extender, uint8_t* data, uint32_t leng);
typedef void (*ErrorCallback_t)(uint32_t err_code);
typedef void (*RequestDoneCallback_t)(void);
typedef void (*RequestDoneCallbackWithParam_t)(struct FunctionParameterDefine param);

unsigned int FarmlandCalCrc32(const unsigned char* buf, unsigned int len, unsigned int init);
unsigned char ELockCalCheckSum(const unsigned char* buf, unsigned int len);


#ifdef __cplusplus
}
#endif

#endif

