/*
 * File:   lib_event_scheduler.h
 * Author: HsinyiFang
 */

/* Define to prevent recursive inclusion -------------------------------------*/
#ifndef __LIB_EVENT_SCHEDLULER_H
#define __LIB_EVENT_SCHEDLULER_H

/* Includes ------------------------------------------------------------------*/
#include <stdbool.h>
#include <stdint.h>
/* Exported constants --------------------------------------------------------*/
#ifndef LIB_EVENT_SCHEDLULER_QUEUE_SIZE
#define LIB_EVENT_SCHEDLULER_QUEUE_SIZE           (uint8_t)32
#endif
/* Exported macro ------------------------------------------------------------*/

/* Exported types ------------------------------------------------------------*/
enum LIB_EVENT_SCHEDLULER_TRIGGER_TYPE
{
    EVENT_SCHEDLULER_TRIGGER_EVENT = 00U,
    EVENT_SCHEDLULER_TRIGGER_TIMER,    
};


typedef void (*event_func)(void);


typedef struct lib_event_sched_event_config_st
{
    uint32_t timer_ms;
    int16_t repeat;
    uint8_t alarm;
    enum LIB_EVENT_SCHEDLULER_TRIGGER_TYPE type;
    event_func handler;
}LIB_EVENT_SCHED_EVENT_CONFIG_T;


typedef struct lib_event_sched_event_status_st
{
    uint32_t alarm_timestamp;
    uint8_t is_pause;
    uint8_t is_unused;
}LIB_EVENT_SCHED_EVENT_STATUS_T;


typedef struct lib_event_sched_queue_st
{
    LIB_EVENT_SCHED_EVENT_STATUS_T status;
    LIB_EVENT_SCHED_EVENT_CONFIG_T config;
}LIB_EVENT_SCHED_QUEUE_T;


typedef struct lib_event_sched_inst_st
{
    uint8_t use_queue_size;
    uint8_t max_queue_size;
    uint8_t running;
    LIB_EVENT_SCHED_QUEUE_T queue[LIB_EVENT_SCHEDLULER_QUEUE_SIZE];
} LIB_EVENT_SCHED_INST_T;


/* Exported functions ------------------------------------------------------- */

uint32_t lib_event_sched_init (LIB_EVENT_SCHED_INST_T * p_init_event_sched);
uint32_t lib_event_sched_add (LIB_EVENT_SCHED_EVENT_CONFIG_T * sched_config);
uint32_t lib_event_sched_run (void);
uint32_t lib_event_sched_pause (void);
uint32_t lib_event_sched_resume (void);
uint32_t lib_event_sched_remove_at(event_func remove_handler);
uint32_t lib_event_sched_pause_at(event_func remove_handler);
uint32_t lib_event_sched_resume_at(event_func remove_handler);
void lib_event_sched_1ms_timer_callback (void);

#endif /* __LIB_EVENT_SCHEDLULER_H */

