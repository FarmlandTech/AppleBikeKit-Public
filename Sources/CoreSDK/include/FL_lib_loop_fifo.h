#pragma once
#ifndef __LOOP_FIFO_H
#define __LOOP_FIFO_H

#ifdef __cplusplus
extern "C" {
#endif
     
/* Includes ------------------------------------------------------------------*/
#include <stdio.h>
#include <stdint.h>
#include <stdbool.h>
#include <stdint.h>
#include <string.h>
#include <stdarg.h>


/* Private includes ----------------------------------------------------------*/



#define TEST_MODE 1 //測試輸出方式


#if (TEST_MODE == 0)   

#define FL_ASSERT(expr)    

#elif (TEST_MODE == 1)

#define FL_ASSERT(expr)                                                       \
if (expr)                                                                     \
{                                                                             \
}                                                                             \
else                                                                          \
{                                                                             \
    while (1);                                                                \
}

#elif (TEST_MODE == 2) && defined(BOARD_PCA10100)

#include "nrf_log.h"
#include "nrf_log_ctrl.h"
#include "nrf_log_default_backends.h"

#define FL_ASSERT(expr)    ASSERT(expr)  

#else

#define FL_ASSERT(expr)                                                   \
if (expr)                                                                 \
{                                                                         \
}                                                                         \
else                                                                      \
{                                                                         \
    printf("file:%s line:%d\n", __FILE__, __LINE__ );                     \
}     
#endif

/* Exported types ------------------------------------------------------------*/

    typedef enum :size_t
    {
        LOOP_FIFO_EMPTY = 0,
        LOOP_FIFO_EXIST = 1,
        LOOP_FIFO_FULL = 0x7FFFFFFF,
    }loop_fifo_state_eu;

    typedef struct LOOP_FIFO_T
    {
        void* const p_buffer;
        volatile size_t write_level;
        volatile size_t read_level;
        volatile size_t head;
        volatile size_t tail;
        volatile size_t current_len;
        size_t const buffer_max_len;
        size_t const unit_len;
        size_t const full_len;
        volatile size_t states;

    } loop_fifo_st;

    /* Exported constants --------------------------------------------------------*/
    enum return_error
    {
        ERR_NO_ERR = 0,
        ERR_NULL_POINTER,
        ERR_FULL,
        ERR_BUSY,
        ERR_FAIL,
        ERR_TIME_OUT,
        ERR_INVLID_ADDR,
        ERR_INVLID_LENG,
        ERR_INVLID_PARA,
        ERR_ALEADY_EXIST,
    };

    /* Exported macro ------------------------------------------------------------*/
#define MIN(a, b) ((a) < (b) ? (a) : (b))

#define MAX(a, b) ((a) < (b) ? (b) : (a))

#define CONCAT_2(p1, p2)      CONCAT_2_(p1, p2)
#define CONCAT_2_(p1, p2)     p1##p2

#define ARRAY_LENGTH(array) (sizeof((array))/sizeof((array)[0]))


#define FIFO_LENGTH_UPDATE(fifo) ( (fifo)->head <=  (fifo)->tail? \
    (fifo)->tail - (fifo)->head  : (fifo)->buffer_max_len - (fifo)->head + (fifo)->tail)


#define GET_FIFO_COUNT(fifo)   ((fifo)->current_len / (fifo)->unit_len)

#define GET_FIFO_REMAIN_LEN(fifo)   ((fifo)->full_len - (fifo)->current_len)

#define P_FIFO_HEAD(fifo)   ((uint8_t*)(fifo)->p_buffer + (fifo)->head)
#define P_FIFO_TAIL(fifo)   ((uint8_t*)(fifo)->p_buffer + (fifo)->tail)


#define GET_HEAD_OFFSET(fifo, index)   ( index >= (fifo)->head ? \
                                        index - (fifo)->head : index - (fifo)->head + (fifo)->buffer_max_len )

#define P_FIFO_OFFSET(fifo, offset_)    ((fifo)->head + offset_) >= (fifo)->buffer_max_len ?\
                                            ((uint8_t*)(fifo)->p_buffer + (fifo)->head + offset_ - (fifo)->buffer_max_len) :\
                                            ((uint8_t*)(fifo)->p_buffer + (fifo)->head + offset_)

#define POINTER_TO_VAR(addr,_type)  *((volatile _type*)(addr))  

#define FIFO_HEAD_VAR(fifo,_type)   POINTER_TO_VAR(P_FIFO_HEAD(fifo), _type)




/*確認數據有無超出邊界  false->邊界內*/
#define FIFO_HEAD_BEYOND_CHECK(fifo,_length) ((fifo)->head + _length <= (fifo)->buffer_max_len? \
    false : true)

#define FIFO_TAIL_BEYOND_CHECK(fifo,_length) ((fifo)->tail + _length <= (fifo)->buffer_max_len? \
    false : true)



#define FIFO_STATE_UPDATE(fifo) \
    do{                                                         \
        if((fifo)->current_len == 0)                            \
        {                                                       \
            (fifo)->states = LOOP_FIFO_EMPTY;                   \
        }                                                       \
        else if((fifo)->current_len < (fifo)->full_len)         \
        {                                                       \
            (fifo)->states = LOOP_FIFO_EXIST;                   \
        }                                                       \
        else if((fifo)->current_len >= (fifo)->full_len)        \
        {                                                       \
            (fifo)->states = LOOP_FIFO_FULL;                    \
        }                                                       \
    } while(0)                                              


/*初始值*/
#define LOOP_FIFO_INIT_VAR(array_instance) \
    {.p_buffer = array_instance,\
                .buffer_max_len = sizeof(array_instance),\
                .unit_len = sizeof((array_instance)[0]),\
                .full_len = sizeof(array_instance) - sizeof((array_instance)[0]) }

/*創建實例並初始化*/
#define LOOP_FIFO_INSTANCE(_fifo_name, _fifo_len, var_type_) \
    static  var_type_  CONCAT_2(_fifo_name, _buf) [_fifo_len] ;\
    loop_fifo_st _fifo_name = {.p_buffer = CONCAT_2(_fifo_name, _buf),\
        .buffer_max_len =  sizeof(CONCAT_2(_fifo_name, _buf)),\
        .unit_len = sizeof( (CONCAT_2(_fifo_name, _buf) )[0]),\
        .full_len  = sizeof(CONCAT_2(_fifo_name, _buf)) - \
            sizeof((CONCAT_2(_fifo_name, _buf))[0]) }                


/* Exported functions prototypes ---------------------------------------------*/
    uint32_t fl_loop_fifo_read(loop_fifo_st* const p_fifo, void* dest, size_t length, size_t offset);
    uint32_t fl_loop_fifo_copy(loop_fifo_st* const p_fifo_dest, loop_fifo_st* const p_fifo_src, size_t length_copy, size_t offset);
    uint32_t fl_loop_fifo_free(loop_fifo_st* const p_fifo, size_t length);

    uint32_t fl_loop_fifo_get(loop_fifo_st* const p_fifo, void* dest, size_t length);
    uint32_t fl_loop_fifo_put(loop_fifo_st* const p_fifo, void* src, size_t length);

    uint32_t fl_loop_fifo_move(loop_fifo_st* const p_fifo_dest, loop_fifo_st* const p_fifo_src, size_t length_move);
    uint32_t fl_loop_fifo_clear(loop_fifo_st* const p_fifo, size_t length, char fill_var);



#ifdef __cplusplus
}
#endif

#endif /* __FARMLAND_SDK_COMMON_H */