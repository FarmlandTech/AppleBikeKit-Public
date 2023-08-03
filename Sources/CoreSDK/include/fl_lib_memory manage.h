#pragma once
#ifndef __MEMORY_MANA_H
#define __MEMORY_MANA_H

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
#include <stdlib.h>
       
/* Private includes ----------------------------------------------------------*/


/* Exported types ------------------------------------------------------------*/
#ifndef ALLOC_USING_SYSTEM_LIB
#define ALLOC_USING_SYSTEM_LIB 0 //1:使用C LIB申請
#endif     

    typedef enum
    {
        FL_MEM_BLOCK_UNUSED = 0,
        FL_MEM_BLOCK_ALLOC = 0x40,
        FL_MEM_BLOCK_LOCK = 0x80,

    }memory_block_eu;


    typedef struct
    {
        uint8_t                     num_and_mem_state;
        uint8_t* p_block;
    }memory_block_st;


    typedef struct memory_alloc_st_* alloc_link_st;

    typedef struct memory_alloc_st_
    {
        uint16_t                start_block_num;
        uint16_t                end_block_num;

        uint8_t* p_block_buf;
        size_t                  use_size;

        alloc_link_st           prev_link;
        alloc_link_st           next_link;
    }memory_alloc_st;

    typedef struct
    {
        uint8_t* const      pool_begin;
        uint8_t             user_max_count;
        size_t const        block_size;
        size_t const        block_max_count;

        memory_block_st* block_news;
        alloc_link_st       alloc_head;
        alloc_link_st       continu_head;
        alloc_link_st       continu_tail;
        size_t  const       pool_max_size;
        size_t              pool_size;
        size_t              continu_size;
        size_t              top_size;
        size_t              buttom_size;
    }memory_pool_st;
    /* Exported constants --------------------------------------------------------*/


    /* Exported macro ------------------------------------------------------------*/
#define MIN(a, b) ((a) < (b) ? (a) : (b))

#define MAX(a, b) ((a) < (b) ? (b) : (a))

#define CONCAT_2(p1, p2)      CONCAT_2_(p1, p2)
#define CONCAT_2_(p1, p2)     p1##p2

/*創建*/
#define CREATE_MEMORY_POOL(pool_name, block_count_ ,block_size_, user_count_) \
    uint8_t CONCAT_2(pool_name, _buf) [block_count_ * block_size_] ;\
    memory_block_st CONCAT_2(pool_name, _block) [block_count_];\
    memory_alloc_st CONCAT_2(pool_name, _user) [user_count_];\
    memory_pool_st pool_name = {.pool_begin = CONCAT_2(pool_name, _buf) ,\
        .user_max_count = user_count_,\
        .block_size = block_size_,\
        .block_max_count =  block_count_,\
        .block_news = CONCAT_2(pool_name, _block),\
        .alloc_head = CONCAT_2(pool_name, _user) ,\
        .pool_max_size = sizeof(CONCAT_2(pool_name, _buf)),\
        .pool_size   = sizeof(CONCAT_2(pool_name, _buf)),\
        .continu_size = sizeof(CONCAT_2(pool_name, _buf)) }
     
/* Exported functions prototypes ---------------------------------------------*/
    void fl_memory_pool_init(memory_pool_st* insta);
    uint32_t fl_memory_combine(memory_alloc_st* insta);

    memory_alloc_st* fl_memory_alloc(memory_pool_st* insta, size_t buf_size);
    void fl_memory_free(memory_pool_st* p_pool, alloc_link_st* p_current_link);


         
#ifdef __cplusplus
}
#endif

#endif /* __FARMLAND_SDK_COMMON_H */

