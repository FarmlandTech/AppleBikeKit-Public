/*
 * File:   lib_fifo_buff.c
 * Author: HsinyiFang
 */

/* Includes ------------------------------------------------------------------*/
#include "lib_fifo_buff.h"
#include <string.h>
/* Private define ------------------------------------------------------------*/

/* Private macro -------------------------------------------------------------*/

/* Private typedef -----------------------------------------------------------*/ 

/* Private variables ---------------------------------------------------------*/

/* Private functions ---------------------------------------------------------*/
bool lib_fifo_flush (fifo_t fifo, void * data)
{
    if(fifo == NULL) return false;
    
    fifo->end_index = fifo->start_index = 0;
    
    return true;
}

bool lib_fifo_drop (fifo_t fifo)
{
    if(fifo == NULL) return false;

    if(fifo->start_index == fifo->end_index)
    {
        return false;
    }
    
    fifo->start_index++;
    
    if(fifo->start_index >= fifo->end_index)
    {
        fifo->start_index = fifo->end_index = 0;
        fifo->is_full = false;
    }
    
    return true;
}

bool lib_fifo_peek (fifo_t fifo, uint32_t index, void * data)
{
    uint32_t read_index = fifo->start_index + index;
    uint32_t source_addr = 0;
    
    if(fifo == NULL) return false;
    
    if(fifo->start_index > fifo->end_index)
    {
        fifo->end_index += fifo->buffer_size;
    }
    
    if(read_index >= fifo->end_index)
    {
        fifo->end_index = fifo->end_index % fifo->buffer_size;
        return false;
    }
    
    if(read_index >= fifo->buffer_size)
    {
        read_index = read_index % fifo->buffer_size;
    }

    //*data = fifo->buffer[read_index];
    source_addr = read_index * fifo->item_size;
    memcpy(data, ((char*)fifo->buffer + source_addr), fifo->item_size);

    return true;
}

bool lib_fifo_read (fifo_t fifo, void * data)
{    
    uint32_t source_addr = 0;
    
    if(fifo == NULL) return false;

    if(fifo->start_index == fifo->end_index)
    {
        return false;
    }
    
    //*data = fifo->buffer[fifo->start_index++];

    source_addr = fifo->start_index * fifo->item_size;
    memcpy(data, (char*)fifo->buffer+source_addr, fifo->item_size);
    
    fifo->start_index++;
    
    if(fifo->start_index >= fifo->buffer_size)
    {
        fifo->start_index = fifo->start_index % fifo->buffer_size;
    }
    
    if(fifo->start_index >= fifo->end_index)
    {
        fifo->start_index = fifo->end_index = 0;
        fifo->is_full = false;
    }
    
    return true;
}

bool lib_fifo_write (fifo_t fifo, void * data)
{
    uint32_t next_index = ((fifo->end_index + 1) % fifo->buffer_size);
    uint32_t source_addr = 0; 
    
    if(fifo == NULL) return false;
    
    if(next_index == fifo->start_index)
    {
        fifo->is_full = true;
        return false;
    }
    
    fifo->is_full = false;
    //fifo->buffer[fifo->end_index] = data;
    source_addr = fifo->end_index * fifo->item_size;
    memcpy((char*)fifo->buffer+source_addr, data, fifo->item_size);

    fifo->end_index = next_index;
    
    return true;
}

uint32_t lib_fifo_length (fifo_t fifo)
{
    uint32_t end_index = fifo->end_index;
    
    if(fifo == NULL) return false;
    
    if(fifo->start_index == fifo->end_index)
    {
        return 0;
    }
    
    if(fifo->start_index > fifo->end_index)
    {
        end_index += fifo->buffer_size;
    }
    
    return (end_index - fifo->start_index);
}

uint32_t lib_fifo_create (fifo_t fifo, uint32_t fifo_size, uint32_t item_size)
{
    if (fifo != NULL && fifo_size > 0 && item_size > 0)
    {
        fifo->start_index = 0;
        fifo->end_index = 0;
        fifo->buffer_size = fifo_size;
        fifo->item_size = item_size;
        fifo->is_full = false;

        return SDK_RETURN_SUCCESS;
    }
    else
    {
        return SDK_RETURN_INVALID_PARAM;
    }
}



/* end of file */
