/* Includes ------------------------------------------------------------------*/
#include "fl_lib_memory manage.h"


/* Private typedef -----------------------------------------------------------*/

/* Private define ------------------------------------------------------------*/
 

/* Private macro -------------------------------------------------------------*/
#define CONCAT_LINK(tail_link_, current_link_) \
    (tail_link_)->next_link = current_link_ ;           \
    (current_link_)->prev_link =  tail_link_    

#define DELETE_NEXT_LINK(current_link_) \
    (current_link_)->next_link->prev_link = NULL;       \
    (current_link_)->next_link = NULL

#define DELETE_PREV_LINK(current_link_) \
    (current_link_)->prev_link->next_link = NULL;       \
    (current_link_)->prev_link = NULL    

#define DELETE_CURRENT_LINK(current_link_) \
    (current_link_)->prev_link = NULL;                  \
    (current_link_)->next_link = NULL 

#define INSERT_LINK(tail_link_, current_link_) \
    if(tail_link_->next_link != NULL)                   \
    {                                                   \
        CONCAT_LINK(current_link_,                      \
                tail_link_->next_link);                 \
    }                                                   \
    CONCAT_LINK(tail_link_, current_link_)           

#define REMOVE_LINK(current_link_) \
    if(current_link_->prev_link != NULL)                \
    {                                                   \
         if(current_link_->next_link != NULL)           \
         {                                              \
            CONCAT_LINK(current_link_->prev_link,       \
                current_link_->next_link) ;             \
            DELETE_CURRENT_LINK(current_link_) ;        \
         }                                              \
         else                                           \
         {                                              \
             DELETE_PREV_LINK(current_link_);           \
         }                                              \
    }                                                   \
    else                                                \
    {                                                   \
        DELETE_NEXT_LINK(current_link_);                \
    }                                                   

#define UPDATE_AVAILABLE_SIZE() \
    if(p_pool->continu_head != NULL && p_pool->continu_tail != NULL )\
    {                                                                                           \
        if(p_pool->continu_tail->start_block_num >= p_pool->continu_head->start_block_num)      \
            p_pool->top_size = p_pool->continu_head->start_block_num * p_pool->block_size;      \
        else                                                                                    \
            p_pool->top_size = 0;                                                               \
    }                                                                                           \
    else                                                                                        \
         p_pool->top_size = 0;                                                                  \
    p_pool->buttom_size = p_pool->continu_size - p_pool->top_size

#define UPDATE_CONTINU_SIZE() \
    if((extra_block >> 31) != 0)                                                            \
        extra_block += (uint32_t)p_pool->block_max_count;                                   \
    p_pool->continu_size += ((size_t)extra_block + block_count) * p_pool->block_size 

/* Private variables ---------------------------------------------------------*/


/* Private function prototypes -----------------------------------------------*/


/* External functions --------------------------------------------------------*/

void fl_memory_pool_init(memory_pool_st* p_pool)
{
    for (size_t count = 0; count < p_pool->block_max_count; ++count)
    {
        p_pool->block_news[count].p_block = p_pool->pool_begin + count * p_pool->block_size;
    }
    p_pool->buttom_size = p_pool->continu_size = p_pool->pool_size;
}

memory_alloc_st* fl_memory_alloc(memory_pool_st* p_pool, size_t alloc_size)
{
    if (alloc_size > MAX(p_pool->top_size, p_pool->buttom_size))
        return NULL;

    size_t user_number = 0xFFFF;

    alloc_link_st   alloc_begin = p_pool->alloc_head;

    for (size_t user_index = 0; user_index < p_pool->user_max_count; ++user_index)
    {
        if ((alloc_begin + user_index)->use_size == 0)
        {
            user_number = user_index;
            break;
        }
    }

    if (user_number == 0xFFFF)
        return NULL;

    size_t block_count = alloc_size / p_pool->block_size;
    if (block_count * p_pool->block_size != alloc_size)
        ++block_count;

    alloc_link_st const current_link = alloc_begin + user_number;

    size_t  link_start_num = 0;
    size_t  link_end_num = 0;

    if (p_pool->continu_head == NULL)
    {
        p_pool->continu_head = current_link;
    }
    else
    {
        link_start_num = p_pool->continu_head->start_block_num;
        link_end_num = p_pool->continu_tail->end_block_num;

        CONCAT_LINK(p_pool->continu_tail, current_link);
    }
    p_pool->continu_tail = current_link;

    size_t  target_start_num = link_start_num - block_count;
    size_t  target_end_num = link_end_num + block_count;

    size_t  blank_block = 0;
    bool    forward_serial = link_end_num >= link_start_num;

    if ((forward_serial && target_end_num <= p_pool->block_max_count) ||
        (!forward_serial && target_end_num <= link_start_num))
    {
        current_link->start_block_num = (uint16_t)link_end_num;
        current_link->end_block_num = (uint16_t)target_end_num;
    }
    else if (forward_serial && block_count <= link_start_num)
    {
        current_link->start_block_num = 0;
        current_link->end_block_num = (uint16_t)block_count;

        blank_block = p_pool->block_max_count - link_end_num;
    }
    else
        return NULL;

    p_pool->pool_size -= block_count * p_pool->block_size;
    p_pool->continu_size = p_pool->pool_size - blank_block * p_pool->block_size;

    UPDATE_AVAILABLE_SIZE();

    //block
    memory_block_st* p_block_begin = p_pool->block_news + current_link->start_block_num;

    current_link->p_block_buf = p_block_begin->p_block;

    uint8_t number_temp = (uint8_t)(FL_MEM_BLOCK_ALLOC | user_number);
    for (size_t index = 0; index < block_count; ++index)
        (p_block_begin + index)->num_and_mem_state = number_temp;

    current_link->use_size = alloc_size;
    return current_link;
}

void fl_memory_free(memory_pool_st* p_pool, alloc_link_st* p_current_link)
{
    alloc_link_st current_link = *p_current_link;
    if (current_link == NULL)
        return;
    size_t      block_count = current_link->end_block_num - current_link->start_block_num;
    uint32_t    extra_block = 0;

    alloc_link_st prev_link = current_link->prev_link;
    alloc_link_st next_link = current_link->next_link;

    if (current_link == p_pool->continu_head)
    {
        p_pool->continu_head = next_link;
        if (next_link != NULL)
        {
            extra_block = (uint32_t)next_link->start_block_num - (uint32_t)current_link->end_block_num;
            DELETE_NEXT_LINK(current_link);
        }
        UPDATE_CONTINU_SIZE();
    }
    else if (current_link == p_pool->continu_tail)
    {
        p_pool->continu_tail = prev_link;
        if (prev_link != NULL)
        {
            extra_block = (uint32_t)prev_link->end_block_num - (uint32_t)current_link->start_block_num;
            DELETE_PREV_LINK(current_link);
        }
        UPDATE_CONTINU_SIZE();
    }
    else
    {
        REMOVE_LINK(current_link);
    }

    p_pool->pool_size += block_count * p_pool->block_size;


    UPDATE_AVAILABLE_SIZE();


    //block

    memory_block_st* const p_block_begin = p_pool->block_news + (size_t)current_link->start_block_num;

    for (size_t index = 0; index < block_count; ++index)
        (p_block_begin + index)->num_and_mem_state = 0;

    current_link->use_size = 0;
    *p_current_link = NULL;
}

uint32_t fl_memory_combine(memory_alloc_st* insta)
{
    return 0;
}