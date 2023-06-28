/*
 * File:   lib_event_scheduler.c
 * Author: HsinyiFang
 */

/* Includes ------------------------------------------------------------------*/
#include "lib_event_scheduler.h"

/* Private define ------------------------------------------------------------*/

/* Private macro -------------------------------------------------------------*/

/* Private typedef -----------------------------------------------------------*/

/* Private variables ---------------------------------------------------------*/
static LIB_EVENT_SCHED_INST_T *gp_sched_inst;
static bool gb_event_sched_be_init = false;
static uint32_t gu_event_sched_timestamp = 0;

/* Private functions ---------------------------------------------------------*/

void lib_event_sched_1ms_timer_callback (void)
{
    uint32_t queue_index = 0;

    if (!gb_event_sched_be_init && gp_sched_inst->running)
    {
        return;
    }

    gu_event_sched_timestamp++;

    while (queue_index < LIB_EVENT_SCHEDLULER_QUEUE_SIZE)
    {
        if (gp_sched_inst->queue[queue_index].status.alarm_timestamp <= gu_event_sched_timestamp
            && gp_sched_inst->queue[queue_index].config.repeat != 0
            && gp_sched_inst->queue[queue_index].config.handler != NULL
            && gp_sched_inst->queue[queue_index].config.type == EVENT_SCHEDLULER_TRIGGER_TIMER
            && gp_sched_inst->queue[queue_index].config.alarm == false
            && gp_sched_inst->queue[queue_index].status.is_pause == false)
        {
            if (gp_sched_inst->queue[queue_index].config.repeat > 0)
            {
                gp_sched_inst->queue[queue_index].config.repeat--;
            }
            gp_sched_inst->queue[queue_index].status.alarm_timestamp =
                gu_event_sched_timestamp + gp_sched_inst->queue[queue_index].config.timer_ms;
            gp_sched_inst->queue[queue_index].config.alarm = true;
        }

        queue_index++;
    }
}

uint32_t lib_event_sched_add (LIB_EVENT_SCHED_EVENT_CONFIG_T * sched_config)
{
    uint32_t add_index = 0;
    uint32_t next_timestamp = gu_event_sched_timestamp + sched_config->timer_ms;

    SDK_PARAM_VERIFY_NULL(sched_config);
    SDK_PARAM_VERIFY_NULL(sched_config->handler);

    if (!gb_event_sched_be_init)
    {
        return SDK_RETURN_NO_INIT;
    }

    if ((gp_sched_inst->use_queue_size + 1) >= LIB_EVENT_SCHEDLULER_QUEUE_SIZE)
    {
        return SDK_RETURN_NO_MEM;
    }

    add_index = 0; 
    while(add_index < gp_sched_inst->use_queue_size)
    {
        if((gp_sched_inst->queue[add_index].config.handler == sched_config->handler )
        && (gp_sched_inst->queue[add_index].config.alarm != 0))
        {
            gp_sched_inst->queue[add_index].status.is_pause = false;
            return SDK_RETURN_ALREADY_EXIST;
        }        
        add_index++;
    }
    
    add_index = 0;
    while (add_index < LIB_EVENT_SCHEDLULER_QUEUE_SIZE)
    {
        if (gp_sched_inst->queue[add_index].status.is_unused)
        {
            break;
        }
        add_index++;
    }

    memcpy (&gp_sched_inst->queue[add_index].config, sched_config,
            sizeof (LIB_EVENT_SCHED_EVENT_CONFIG_T));

    if (gp_sched_inst->queue[add_index].config.type == EVENT_SCHEDLULER_TRIGGER_TIMER)
    {
        if(sched_config->timer_ms > 50)
        {
            gp_sched_inst->queue[add_index].status.alarm_timestamp = next_timestamp + add_index*7;
        }else
        {
            gp_sched_inst->queue[add_index].status.alarm_timestamp = next_timestamp;
        }
        
        gp_sched_inst->queue[add_index].config.alarm = false;
    } else
    {
        gp_sched_inst->queue[add_index].config.alarm = true;
    }

    gp_sched_inst->queue[add_index].status.is_unused = false;
    gp_sched_inst->queue[add_index].status.is_pause = false;
    gp_sched_inst->use_queue_size++;

    return SDK_RETURN_SUCCESS;
}


uint32_t lib_event_sched_run (void)
{
    uint8_t sched_index = 0;

    if (gb_event_sched_be_init && gp_sched_inst->running)
    {
        while (sched_index < gp_sched_inst->use_queue_size)
        {
            if (gp_sched_inst->queue[sched_index].config.alarm
                && gp_sched_inst->queue[sched_index].config.handler != NULL
                && gp_sched_inst->queue[sched_index].status.is_pause == false)
            {
                gp_sched_inst->queue[sched_index].config.handler ();

                if (gp_sched_inst->queue[sched_index].config.type == EVENT_SCHEDLULER_TRIGGER_TIMER)
                {
                    if (gp_sched_inst->queue[sched_index].config.repeat == 0)
                    {
                        lib_event_sched_remove_at(gp_sched_inst->queue[sched_index].config.handler);
                    }else
                    {
                        gp_sched_inst->queue[sched_index].config.alarm = false;
                    }                    
                    sched_index++;
                    
                } else
                {
                    if (gp_sched_inst->queue[sched_index].config.repeat > 0)
                    {
                        gp_sched_inst->queue[sched_index].config.repeat--;
                    }
                    
                    lib_event_sched_remove_at(gp_sched_inst->queue[sched_index].config.handler);
                }
            }else
            {
                sched_index++;
            }            
        }
    }

    return SDK_RETURN_SUCCESS;
}

uint32_t lib_event_sched_pause (void)
{
    gp_sched_inst->running = false;
    return SDK_RETURN_SUCCESS;
}

uint32_t lib_event_sched_resume (void)
{
    gp_sched_inst->running = true;
    return SDK_RETURN_SUCCESS;
}

uint32_t lib_event_sched_remove_at (event_func remove_handler)
{
    uint8_t search_index = 0;
    uint8_t last_index = gp_sched_inst->use_queue_size > 0 ? (gp_sched_inst->use_queue_size - 1) : 0;  

    SDK_PARAM_VERIFY_NULL(remove_handler);
    SDK_PARAM_VERIFY_NULL(gp_sched_inst->use_queue_size);

    while (search_index < LIB_EVENT_SCHEDLULER_QUEUE_SIZE)
    {
        if (gp_sched_inst->queue[search_index].config.handler == remove_handler)
        {
            if(search_index < last_index)
            {
                gp_sched_inst->queue[search_index].config.alarm = gp_sched_inst->queue[last_index].config.alarm;
                gp_sched_inst->queue[search_index].config.handler = gp_sched_inst->queue[last_index].config.handler;
                gp_sched_inst->queue[search_index].config.repeat = gp_sched_inst->queue[last_index].config.repeat;
                gp_sched_inst->queue[search_index].config.timer_ms = gp_sched_inst->queue[last_index].config.timer_ms;
                gp_sched_inst->queue[search_index].config.type = gp_sched_inst->queue[last_index].config.type;
                gp_sched_inst->queue[search_index].status.alarm_timestamp = gp_sched_inst->queue[last_index].status.alarm_timestamp;
                gp_sched_inst->queue[search_index].status.is_unused = gp_sched_inst->queue[last_index].status.is_unused;
                gp_sched_inst->queue[search_index].status.is_pause = gp_sched_inst->queue[last_index].status.is_unused;
                
                search_index = last_index;
            }
            gp_sched_inst->queue[search_index].config.alarm = false;
            gp_sched_inst->queue[search_index].config.handler = NULL;
            gp_sched_inst->queue[search_index].config.repeat = 0;
            gp_sched_inst->queue[search_index].config.timer_ms = 0;
            gp_sched_inst->queue[search_index].config.type = EVENT_SCHEDLULER_TRIGGER_EVENT;
            gp_sched_inst->queue[search_index].status.alarm_timestamp = 0;
            gp_sched_inst->queue[search_index].status.is_unused = true;
            gp_sched_inst->queue[search_index].status.is_pause = false;
            gp_sched_inst->use_queue_size--;
            
            break;
        }
        search_index++;
    }

    return SDK_RETURN_SUCCESS;
}

uint32_t lib_event_sched_pause_at (event_func remove_handler)
{
    uint8_t sched_index = 0;

    SDK_PARAM_VERIFY_NULL(remove_handler);
    SDK_PARAM_VERIFY_NULL(gp_sched_inst->use_queue_size);


    while (sched_index < LIB_EVENT_SCHEDLULER_QUEUE_SIZE)
    {
        if (gp_sched_inst->queue[sched_index].config.handler == remove_handler)
        {
            gp_sched_inst->queue[sched_index].status.is_pause = true;
        }
        sched_index++;
    }

    return SDK_RETURN_SUCCESS;
}

uint32_t lib_event_sched_resume_at (event_func remove_handler)
{
    uint8_t sched_index = 0;

    SDK_PARAM_VERIFY_NULL(remove_handler);
    SDK_PARAM_VERIFY_NULL(gp_sched_inst->use_queue_size);

    while (sched_index < LIB_EVENT_SCHEDLULER_QUEUE_SIZE)
    {
        if (gp_sched_inst->queue[sched_index].config.handler == remove_handler)
        {
            gp_sched_inst->queue[sched_index].status.is_pause = false;
            gp_sched_inst->queue[sched_index].status.alarm_timestamp = gp_sched_inst->queue[sched_index].config.timer_ms + gu_event_sched_timestamp;
        }
        sched_index++;
    }

    return SDK_RETURN_SUCCESS;
}

/**@brief event scheduler initial function
 *
 * @note
 *
 */
uint32_t lib_event_sched_init (LIB_EVENT_SCHED_INST_T * p_init_event_sched)
{
    uint8_t queue_index = 0;
    SDK_PARAM_VERIFY_NULL(p_init_event_sched);

    gp_sched_inst = p_init_event_sched;

    gp_sched_inst->use_queue_size = 0;

    while (queue_index < LIB_EVENT_SCHEDLULER_QUEUE_SIZE)
    {
        gp_sched_inst->queue[queue_index].config.alarm = false;
        gp_sched_inst->queue[queue_index].config.repeat = 0;
        gp_sched_inst->queue[queue_index].config.handler = NULL;
        gp_sched_inst->queue[queue_index].config.timer_ms = 0;
        gp_sched_inst->queue[queue_index].config.type = EVENT_SCHEDLULER_TRIGGER_EVENT;

        gp_sched_inst->queue[queue_index].status.alarm_timestamp = 0;
        gp_sched_inst->queue[queue_index].status.is_unused = true;

        queue_index++;
    }

    gb_event_sched_be_init = true;
    gp_sched_inst->running = true;

    return SDK_RETURN_SUCCESS;
}


/* end of file */
