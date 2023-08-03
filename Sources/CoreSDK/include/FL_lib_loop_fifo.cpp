/* Includes ------------------------------------------------------------------*/
#include "FL_lib_loop_fifo.h"

/* Private typedef -----------------------------------------------------------*/

/* Private define ------------------------------------------------------------*/

 
/* Private macro -------------------------------------------------------------*/



/* Private variables ---------------------------------------------------------*/


/* Private function prototypes -----------------------------------------------*/


/* External functions --------------------------------------------------------*/

/*只讀取資料，不改變長度*/
uint32_t fl_loop_fifo_read(loop_fifo_st* const p_fifo, void* dest, size_t length_read, size_t offset)
{
    FL_ASSERT(length_read <= p_fifo->full_len);
    //    FL_ASSERT(length_read <= p_fifo->full_len);
    FL_ASSERT(p_fifo != NULL);

    size_t len_tmp = p_fifo->current_len;

    if (length_read == 0 || (len_tmp - offset) < length_read || len_tmp == 0)
        return ERR_INVLID_LENG;

    if (len_tmp <= offset)
        return ERR_INVLID_ADDR;

    if (p_fifo->read_level > 1)
        return ERR_BUSY;//忙碌中
    p_fifo->read_level = 1;//只讀取

    size_t  acc_length = 0;
    // size_t  length_read = MIN(len_tmp - offset, length);  //讀取長度

    uint8_t* position_read = P_FIFO_HEAD(p_fifo) + offset;

    if (p_fifo->head + length_read + offset < p_fifo->buffer_max_len)
    {
        memcpy(dest, position_read, length_read);

        p_fifo->read_level = 0;
    }
    else
    {
        acc_length = p_fifo->buffer_max_len - p_fifo->head - offset;//剩餘提取長度

        memcpy(dest, position_read, acc_length);

        if (length_read == acc_length)
        {
            p_fifo->read_level = 0;
            return 0;
        }
        /*分段----------------*/

        length_read -= acc_length;

        memcpy((uint8_t*)dest + acc_length, (uint8_t*)p_fifo->p_buffer, length_read);

        p_fifo->read_level = 0;
    }

    return 0;
}

uint32_t fl_loop_fifo_copy(loop_fifo_st* const p_fifo_dest, loop_fifo_st* const p_fifo_src, size_t length_copy, size_t offset)
{
    FL_ASSERT(length_copy <= p_fifo_src->full_len);
    FL_ASSERT(length_copy <= p_fifo_dest->full_len);

    FL_ASSERT(p_fifo_src != NULL);
    FL_ASSERT(p_fifo_dest != NULL);


    size_t length_src = p_fifo_src->current_len;//來源剩餘長度

    if (length_copy == 0 || (length_src - offset) < length_copy || length_src == 0)
        return ERR_INVLID_LENG;

    if (length_src <= offset)
        return ERR_INVLID_ADDR;

    size_t length_left_dest = p_fifo_dest->full_len - p_fifo_dest->current_len;//目標剩餘空間

    if (length_copy > length_left_dest)
        return ERR_FULL;//已滿


    if ((p_fifo_dest->write_level != 0) || (p_fifo_src->read_level != 0))
        return ERR_BUSY;

    p_fifo_dest->write_level = 1;//
    p_fifo_src->read_level = 1;//

    size_t position_copy = p_fifo_src->head + offset;

    if (position_copy >= p_fifo_src->buffer_max_len)
        position_copy -= p_fifo_src->buffer_max_len;

    size_t  border_src = p_fifo_src->buffer_max_len - position_copy;
    size_t  border_dest = p_fifo_dest->buffer_max_len - p_fifo_dest->tail;

    if (length_copy < border_src)
    {
        if (length_copy < border_dest)
        {
            memcpy(P_FIFO_TAIL(p_fifo_dest), (uint8_t*)(p_fifo_src)->p_buffer + position_copy, length_copy);

            position_copy += length_copy;
            p_fifo_dest->tail += length_copy;
        }
        else
        {
            memcpy(P_FIFO_TAIL(p_fifo_dest), (uint8_t*)(p_fifo_src)->p_buffer + position_copy, border_dest);


            position_copy = border_dest == border_src ? 0 : position_copy + border_dest;

            p_fifo_dest->tail = 0;

            if (length_copy == border_dest)
            {
                goto end_update;
            }
            /*分段----------------------------------------------------*/

            length_copy -= border_dest;

            memcpy((uint8_t*)p_fifo_dest->p_buffer, (uint8_t*)(p_fifo_src)->p_buffer + position_copy, length_copy);

            position_copy += length_copy;
            p_fifo_dest->tail += length_copy;
        }
    }
    else
    {
        if (length_copy < border_dest)
        {
            memcpy(P_FIFO_TAIL(p_fifo_dest), (uint8_t*)(p_fifo_src)->p_buffer + position_copy, border_src);

            position_copy = 0;
            p_fifo_dest->tail += border_src;


            if (length_copy == border_src)
            {
                goto end_update;
            }
            /*分段----------------------------------------------------*/

            length_copy -= border_src;

            memcpy(P_FIFO_TAIL(p_fifo_dest), (uint8_t*)p_fifo_src->p_buffer, length_copy);

            position_copy += length_copy;
            p_fifo_dest->tail += length_copy;
        }
        else
        {
            if (border_dest == border_src)
            {
                memcpy(P_FIFO_TAIL(p_fifo_dest), (uint8_t*)(p_fifo_src)->p_buffer + position_copy, border_src);

                position_copy = 0;
                p_fifo_dest->tail = 0;


                if (length_copy == border_src)
                {
                    goto end_update;
                }
                /*分段----------------------------------------------------*/

                length_copy -= border_src;

                memcpy((uint8_t*)p_fifo_dest->p_buffer, (uint8_t*)p_fifo_src->p_buffer, length_copy);

                position_copy += length_copy;
                p_fifo_dest->tail += length_copy;
            }

            else if (border_dest > border_src)
            {
                size_t  acc_length = border_src;
                size_t  acc_length2;
                memcpy(P_FIFO_TAIL(p_fifo_dest), (uint8_t*)(p_fifo_src)->p_buffer + position_copy, acc_length);

                position_copy = 0;
                p_fifo_dest->tail += acc_length;


                if (length_copy == acc_length)
                {
                    goto end_update;
                }
                /*第2段-------------------------*/
                acc_length2 = border_dest - border_src;
                acc_length += acc_length2;


                memcpy(P_FIFO_TAIL(p_fifo_dest), (uint8_t*)p_fifo_src->p_buffer, acc_length2);

                position_copy += acc_length2;
                p_fifo_dest->tail = 0;

                if (length_copy == acc_length)
                {
                    goto end_update;
                }
                /*第3段-------------------------*/
                acc_length = length_copy - acc_length;

                memcpy((uint8_t*)p_fifo_dest->p_buffer, P_FIFO_HEAD(p_fifo_src), acc_length);

                position_copy += acc_length;
                p_fifo_dest->tail += acc_length;

            }
            else
            {
                size_t  acc_length = border_dest;
                size_t  acc_length2;
                memcpy(P_FIFO_TAIL(p_fifo_dest), (uint8_t*)(p_fifo_src)->p_buffer + position_copy, acc_length);

                position_copy += acc_length;
                p_fifo_dest->tail = 0;

                if (length_copy == acc_length)
                {
                    goto end_update;
                }

                /*第2段-------------------------*/
                acc_length2 = border_src - border_dest;
                acc_length += acc_length2;

                memcpy((uint8_t*)p_fifo_dest->p_buffer, (uint8_t*)(p_fifo_src)->p_buffer + position_copy, acc_length2);

                position_copy = 0;
                p_fifo_dest->tail += acc_length2;

                if (length_copy == acc_length)
                {
                    goto end_update;
                }
                /*第3段-------------------------*/
                acc_length = length_copy - acc_length;

                memcpy(P_FIFO_TAIL(p_fifo_dest), (uint8_t*)p_fifo_src->p_buffer, acc_length);

                position_copy += acc_length;
                p_fifo_dest->tail += acc_length;
            }
        }
    }
end_update:

    p_fifo_dest->current_len = FIFO_LENGTH_UPDATE(p_fifo_dest);

    FIFO_STATE_UPDATE(p_fifo_dest);



    p_fifo_src->read_level = 0;
    p_fifo_dest->write_level = 0;

    return 0;
}



/*釋放已有資料*/
uint32_t fl_loop_fifo_free(loop_fifo_st* const p_fifo, size_t length_free)
{
    FL_ASSERT(length_free <= p_fifo->full_len);
    FL_ASSERT(p_fifo != NULL);

    if (length_free == 0)
        return ERR_INVLID_LENG;

    if (p_fifo->current_len == 0)
        return 0;

    if (p_fifo->read_level != 0)
        return ERR_BUSY;//忙碌中
    p_fifo->read_level = 2;//釋放資料

    length_free = MIN(p_fifo->current_len, length_free);  //釋放長度

    length_free += p_fifo->head;

    p_fifo->head = length_free >= p_fifo->buffer_max_len ? \
        length_free - p_fifo->buffer_max_len : length_free;

    p_fifo->current_len = FIFO_LENGTH_UPDATE(p_fifo);
    FIFO_STATE_UPDATE(p_fifo);

    p_fifo->read_level = 0;
    return 0;
}

uint32_t fl_loop_fifo_get(loop_fifo_st* const p_fifo, void* dest, size_t length_get)
{
    FL_ASSERT(length_get <= p_fifo->full_len);
    FL_ASSERT(p_fifo != NULL);

    if (length_get == 0 || p_fifo->current_len < length_get || p_fifo->current_len == 0)
        return ERR_INVLID_LENG;


    if (p_fifo->read_level != 0)
        return ERR_BUSY;//忙碌中
    p_fifo->read_level = 2;//釋放資料

    size_t  acc_length = 0;
    // size_t  length_get = MIN(p_fifo->current_len, length);  //提取長度


    if (p_fifo->head + length_get < p_fifo->buffer_max_len)
    {
        memcpy(dest, P_FIFO_HEAD(p_fifo), length_get);

        p_fifo->head += length_get;

        p_fifo->current_len = FIFO_LENGTH_UPDATE(p_fifo);
        FIFO_STATE_UPDATE(p_fifo);

        p_fifo->read_level = 0;
    }
    else
    {
        acc_length = p_fifo->buffer_max_len - p_fifo->head;//剩餘提取長度

        memcpy(dest, P_FIFO_HEAD(p_fifo), acc_length);
        p_fifo->head = 0;//從0開始


        if (length_get == acc_length)
        {
            p_fifo->current_len = FIFO_LENGTH_UPDATE(p_fifo);
            FIFO_STATE_UPDATE(p_fifo);
            p_fifo->read_level = 0;

            return 0;
        }
        /*分段----------------*/

        length_get -= acc_length;


        memcpy((uint8_t*)dest + acc_length, (uint8_t*)p_fifo->p_buffer, length_get);
        p_fifo->head += length_get;

        p_fifo->current_len = FIFO_LENGTH_UPDATE(p_fifo);
        FIFO_STATE_UPDATE(p_fifo);

        p_fifo->read_level = 0;
    }
    return 0;
}


uint32_t fl_loop_fifo_put(loop_fifo_st* const p_fifo, void* src, size_t length_put)
{
    FL_ASSERT(length_put <= p_fifo->full_len);
    FL_ASSERT(p_fifo != NULL);

    if (length_put == 0)
        return ERR_INVLID_LENG;

    size_t length_left = p_fifo->full_len - p_fifo->current_len;//剩餘長度

    if (length_put > length_left)
        return ERR_FULL;//已滿

    if (p_fifo->write_level != 0)
        return ERR_BUSY;
    p_fifo->write_level = 1;//增加資料

    size_t  acc_length = 0;


    if (p_fifo->tail + length_put < p_fifo->buffer_max_len)
    {
        memcpy(P_FIFO_TAIL(p_fifo), src, length_put);

        p_fifo->tail += length_put;

        p_fifo->current_len = FIFO_LENGTH_UPDATE(p_fifo);
        FIFO_STATE_UPDATE(p_fifo);

        p_fifo->write_level = 0;
    }
    else
    {
        acc_length = p_fifo->buffer_max_len - p_fifo->tail;

        memcpy(P_FIFO_TAIL(p_fifo), src, acc_length);
        p_fifo->tail = 0;

        if (length_put == acc_length)
        {
            p_fifo->current_len = FIFO_LENGTH_UPDATE(p_fifo);
            FIFO_STATE_UPDATE(p_fifo);

            p_fifo->write_level = 0;
            return 0;
        }
        /*分段----------------------------------------------------*/

        length_put -= acc_length;


        memcpy((uint8_t*)p_fifo->p_buffer, (uint8_t*)src + acc_length, length_put);

        p_fifo->tail += length_put;

        p_fifo->current_len = FIFO_LENGTH_UPDATE(p_fifo);
        FIFO_STATE_UPDATE(p_fifo);

        p_fifo->write_level = 0;
    }

    return 0;
}




uint32_t fl_loop_fifo_move(loop_fifo_st* const p_fifo_dest, loop_fifo_st* const p_fifo_src, size_t length_move)
{
    FL_ASSERT(length_move <= p_fifo_src->full_len);
    FL_ASSERT(length_move <= p_fifo_dest->full_len);

    FL_ASSERT(p_fifo_src != NULL);
    FL_ASSERT(p_fifo_dest != NULL);

    size_t length_src = p_fifo_src->current_len;//來源剩餘長度

    if (length_move == 0 || length_src < length_move || length_src == 0)
        return ERR_INVLID_LENG;

    size_t length_left_dest = p_fifo_dest->full_len - p_fifo_dest->current_len;//目標剩餘空間

    if (length_move > length_left_dest)
        return ERR_FULL;//已滿


    if ((p_fifo_dest->write_level != 0) || (p_fifo_src->read_level != 0))
        return ERR_BUSY;

    p_fifo_dest->write_level = 1;//
    p_fifo_src->read_level = 2;//

    size_t  border_src = p_fifo_src->buffer_max_len - p_fifo_src->head;
    size_t  border_dest = p_fifo_dest->buffer_max_len - p_fifo_dest->tail;

    if (length_move < border_src)
    {
        if (length_move < border_dest)
        {
            memcpy(P_FIFO_TAIL(p_fifo_dest), P_FIFO_HEAD(p_fifo_src), length_move);

            p_fifo_src->head += length_move;
            p_fifo_dest->tail += length_move;
        }
        else
        {
            memcpy(P_FIFO_TAIL(p_fifo_dest), P_FIFO_HEAD(p_fifo_src), border_dest);


            p_fifo_src->head = border_dest == border_src ? 0 : p_fifo_src->head + border_dest; 
            p_fifo_dest->tail = 0;

            if (length_move == border_dest)
            {
                goto end_update;
            }
            /*分段----------------------------------------------------*/

            length_move -= border_dest;

            memcpy((uint8_t*)p_fifo_dest->p_buffer, P_FIFO_HEAD(p_fifo_src), length_move);

            p_fifo_src->head += length_move;
            p_fifo_dest->tail += length_move;
        }
    }
    else
    {
        if (length_move < border_dest)
        {
            memcpy(P_FIFO_TAIL(p_fifo_dest), P_FIFO_HEAD(p_fifo_src), border_src);

            p_fifo_src->head = 0;
            p_fifo_dest->tail += border_src;


            if (length_move == border_src)
            {
                goto end_update;
            }
            /*分段----------------------------------------------------*/

            length_move -= border_src;

            memcpy(P_FIFO_TAIL(p_fifo_dest), (uint8_t*)p_fifo_src->p_buffer, length_move);

            p_fifo_src->head += length_move;
            p_fifo_dest->tail += length_move;
        }
        else
        {
            if (border_dest == border_src)
            {
                memcpy(P_FIFO_TAIL(p_fifo_dest), P_FIFO_HEAD(p_fifo_src), border_src);

                p_fifo_src->head = 0;
                p_fifo_dest->tail = 0;


                if (length_move == border_src)
                {
                    goto end_update;
                }
                /*分段----------------------------------------------------*/

                length_move -= border_src;

                memcpy((uint8_t*)p_fifo_dest->p_buffer, (uint8_t*)p_fifo_src->p_buffer, length_move);

                p_fifo_src->head += length_move;
                p_fifo_dest->tail += length_move;
            }

            else if (border_dest > border_src)
            {
                size_t  acc_length = border_src;
                size_t acc_length2;
                memcpy(P_FIFO_TAIL(p_fifo_dest), P_FIFO_HEAD(p_fifo_src), acc_length);

                p_fifo_src->head = 0;
                p_fifo_dest->tail += acc_length;


                if (length_move == acc_length)
                {
                    goto end_update;
                }
                /*第2段-------------------------*/
                acc_length2 = border_dest - border_src;
                acc_length += acc_length2;

                memcpy(P_FIFO_TAIL(p_fifo_dest), (uint8_t*)p_fifo_src->p_buffer, acc_length2);

                p_fifo_src->head += acc_length2;
                p_fifo_dest->tail = 0;

                if (length_move == acc_length)
                {
                    goto end_update;
                }
                /*第3段-------------------------*/
                acc_length = length_move - acc_length;

                memcpy((uint8_t*)p_fifo_dest->p_buffer, P_FIFO_HEAD(p_fifo_src), acc_length);

                p_fifo_src->head += acc_length;
                p_fifo_dest->tail += acc_length;

            }
            else
            {
                size_t  acc_length = border_dest;
                size_t acc_length2;
                memcpy(P_FIFO_TAIL(p_fifo_dest), P_FIFO_HEAD(p_fifo_src), acc_length);

                p_fifo_src->head += acc_length;
                p_fifo_dest->tail = 0;

                if (length_move == acc_length)
                {
                    goto end_update;
                }

                /*第2段-------------------------*/
                acc_length2 = border_src - border_dest;
                acc_length += acc_length2;

                memcpy((uint8_t*)p_fifo_dest->p_buffer, P_FIFO_HEAD(p_fifo_src), acc_length2);

                p_fifo_src->head = 0;
                p_fifo_dest->tail += acc_length2;

                if (length_move == acc_length)
                {
                    goto end_update;
                }
                /*第3段-------------------------*/
                acc_length = length_move - acc_length;

                memcpy(P_FIFO_TAIL(p_fifo_dest), (uint8_t*)p_fifo_src->p_buffer, acc_length);

                p_fifo_src->head += acc_length;
                p_fifo_dest->tail += acc_length;
            }
        }
    }
end_update:

    p_fifo_src->current_len = FIFO_LENGTH_UPDATE(p_fifo_src);
    p_fifo_dest->current_len = FIFO_LENGTH_UPDATE(p_fifo_dest);

    FIFO_STATE_UPDATE(p_fifo_src);
    FIFO_STATE_UPDATE(p_fifo_dest);

    p_fifo_src->read_level = 0;
    p_fifo_dest->write_level = 0;

    return 0;
}




uint32_t fl_loop_fifo_clear(loop_fifo_st* const p_fifo, size_t length_clear, char fill_var)
{
    FL_ASSERT(length_clear <= p_fifo->full_len);
    FL_ASSERT(p_fifo != NULL);

    if (length_clear == 0)
        return ERR_INVLID_LENG;

    if (p_fifo->current_len == 0)
        return 0;

    if (p_fifo->read_level != 0)
        return ERR_BUSY;//忙碌中
    p_fifo->read_level = 3;//刪除資料

    size_t  acc_length = 0;
    length_clear = MIN(p_fifo->current_len, length_clear);  //清除長度


    if (p_fifo->head + length_clear < p_fifo->buffer_max_len)
    {
        memset(P_FIFO_HEAD(p_fifo), fill_var, length_clear);
        p_fifo->head += length_clear;

        p_fifo->current_len = FIFO_LENGTH_UPDATE(p_fifo);
        FIFO_STATE_UPDATE(p_fifo);

        p_fifo->read_level = 0;
    }
    else
    {
        acc_length = p_fifo->buffer_max_len - p_fifo->head;//剩餘清除長度

        memset(P_FIFO_HEAD(p_fifo), fill_var, acc_length);
        p_fifo->head = 0;//從0開始

        if (length_clear == acc_length)
        {
            p_fifo->current_len = FIFO_LENGTH_UPDATE(p_fifo);
            FIFO_STATE_UPDATE(p_fifo);

            p_fifo->read_level = 0;

            return 0;
        }
        /*分段----------------*/

        length_clear -= acc_length;

        memset((uint8_t*)p_fifo->p_buffer, fill_var, length_clear);
        p_fifo->head += length_clear;

        p_fifo->current_len = FIFO_LENGTH_UPDATE(p_fifo);
        FIFO_STATE_UPDATE(p_fifo);

        p_fifo->read_level = 0;
    }
    return 0;
}