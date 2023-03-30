/*
 * File:   lib_fifo_buff.h
 * Author: HsinyiFang
 */

/* Define to prevent recursive inclusion -------------------------------------*/
#ifndef __LIB_FIFO_BUFF_H
#define __LIB_FIFO_BUFF_H

/* Includes ------------------------------------------------------------------*/
#include "CoreSDK.h"
#include <stdbool.h>
#include <stdint.h>
/* Exported constants --------------------------------------------------------*/

/* Exported macro ------------------------------------------------------------*/

/* Exported types ------------------------------------------------------------*/


typedef struct lib_fifo_inst_st
{
    volatile uint32_t start_index;
    volatile uint32_t end_index;
    volatile uint32_t buffer_size;
    volatile uint32_t item_size;
    bool is_full;
    void * buffer;
} LIB_FIFO_INST_T;

typedef LIB_FIFO_INST_T* fifo_t;

/* Exported functions ------------------------------------------------------- */
bool lib_fifo_flush (fifo_t fifo, void * data);
bool lib_fifo_drop (fifo_t fifo);
bool lib_fifo_peek (fifo_t fifo, uint32_t index, void * data);
bool lib_fifo_read (fifo_t fifo, void * data);
bool lib_fifo_write (fifo_t fifo, void * data);
uint32_t lib_fifo_length (fifo_t fifo);
uint32_t lib_fifo_create (fifo_t fifo, uint32_t fifo_size, uint32_t item_size);
#endif /* __LIB_FLASH_H */
