/* Includes ------------------------------------------------------------------*/
#include "FL_lib_Analyzer_protocol.h"


 

/* Private typedef -----------------------------------------------------------*/























/* Private define ------------------------------------------------------------*/
#if BIG_ENDIANNESS == 0
#define PROTOCOL_HEAD_ID 0xC792AAD3
#else 
#define PROTOCOL_HEAD_ID 0xD3AA92C7
#endif


#define HEAD_CHECK_LEN_MIN 4
#define HEAD_CHECK_LACK_LEN 3
#define CRC32_LEN 4
#define PROCESS_ID_LEN 1
#define PROTOCOL_TOTAL_LEN 14

#define HEAD_CHECK_LEN_MAX   (PROTOCOL_HEAD_LEN - HEAD_CHECK_LACK_LEN ) //頭部開始碼長度4  不足不檢驗


//
static const uint8_t crc8_table[] =
{
    0x00,0x31,0x62,0x53,0xc4,0xf5,0xa6,0x97,0xb9,0x88,0xdb,0xea,0x7d,0x4c,0x1f,0x2e,
    0x43,0x72,0x21,0x10,0x87,0xb6,0xe5,0xd4,0xfa,0xcb,0x98,0xa9,0x3e,0x0f,0x5c,0x6d,
    0x86,0xb7,0xe4,0xd5,0x42,0x73,0x20,0x11,0x3f,0x0e,0x5d,0x6c,0xfb,0xca,0x99,0xa8,
    0xc5,0xf4,0xa7,0x96,0x01,0x30,0x63,0x52,0x7c,0x4d,0x1e,0x2f,0xb8,0x89,0xda,0xeb,
    0x3d,0x0c,0x5f,0x6e,0xf9,0xc8,0x9b,0xaa,0x84,0xb5,0xe6,0xd7,0x40,0x71,0x22,0x13,
    0x7e,0x4f,0x1c,0x2d,0xba,0x8b,0xd8,0xe9,0xc7,0xf6,0xa5,0x94,0x03,0x32,0x61,0x50,
    0xbb,0x8a,0xd9,0xe8,0x7f,0x4e,0x1d,0x2c,0x02,0x33,0x60,0x51,0xc6,0xf7,0xa4,0x95,
    0xf8,0xc9,0x9a,0xab,0x3c,0x0d,0x5e,0x6f,0x41,0x70,0x23,0x12,0x85,0xb4,0xe7,0xd6,
    0x7a,0x4b,0x18,0x29,0xbe,0x8f,0xdc,0xed,0xc3,0xf2,0xa1,0x90,0x07,0x36,0x65,0x54,
    0x39,0x08,0x5b,0x6a,0xfd,0xcc,0x9f,0xae,0x80,0xb1,0xe2,0xd3,0x44,0x75,0x26,0x17,
    0xfc,0xcd,0x9e,0xaf,0x38,0x09,0x5a,0x6b,0x45,0x74,0x27,0x16,0x81,0xb0,0xe3,0xd2,
    0xbf,0x8e,0xdd,0xec,0x7b,0x4a,0x19,0x28,0x06,0x37,0x64,0x55,0xc2,0xf3,0xa0,0x91,
    0x47,0x76,0x25,0x14,0x83,0xb2,0xe1,0xd0,0xfe,0xcf,0x9c,0xad,0x3a,0x0b,0x58,0x69,
    0x04,0x35,0x66,0x57,0xc0,0xf1,0xa2,0x93,0xbd,0x8c,0xdf,0xee,0x79,0x48,0x1b,0x2a,
    0xc1,0xf0,0xa3,0x92,0x05,0x34,0x67,0x56,0x78,0x49,0x1a,0x2b,0xbc,0x8d,0xde,0xef,
    0x82,0xb3,0xe0,0xd1,0x46,0x77,0x24,0x15,0x3b,0x0a,0x59,0x68,0xff,0xce,0x9d,0xac
};

static const unsigned int crc32_table[] =
{//不反轉
  0x00000000, 0x04c11db7, 0x09823b6e, 0x0d4326d9,
  0x130476dc, 0x17c56b6b, 0x1a864db2, 0x1e475005,
  0x2608edb8, 0x22c9f00f, 0x2f8ad6d6, 0x2b4bcb61,
  0x350c9b64, 0x31cd86d3, 0x3c8ea00a, 0x384fbdbd,
  0x4c11db70, 0x48d0c6c7, 0x4593e01e, 0x4152fda9,
  0x5f15adac, 0x5bd4b01b, 0x569796c2, 0x52568b75,
  0x6a1936c8, 0x6ed82b7f, 0x639b0da6, 0x675a1011,
  0x791d4014, 0x7ddc5da3, 0x709f7b7a, 0x745e66cd,
  0x9823b6e0, 0x9ce2ab57, 0x91a18d8e, 0x95609039,
  0x8b27c03c, 0x8fe6dd8b, 0x82a5fb52, 0x8664e6e5,
  0xbe2b5b58, 0xbaea46ef, 0xb7a96036, 0xb3687d81,
  0xad2f2d84, 0xa9ee3033, 0xa4ad16ea, 0xa06c0b5d,
  0xd4326d90, 0xd0f37027, 0xddb056fe, 0xd9714b49,
  0xc7361b4c, 0xc3f706fb, 0xceb42022, 0xca753d95,
  0xf23a8028, 0xf6fb9d9f, 0xfbb8bb46, 0xff79a6f1,
  0xe13ef6f4, 0xe5ffeb43, 0xe8bccd9a, 0xec7dd02d,
  0x34867077, 0x30476dc0, 0x3d044b19, 0x39c556ae,
  0x278206ab, 0x23431b1c, 0x2e003dc5, 0x2ac12072,
  0x128e9dcf, 0x164f8078, 0x1b0ca6a1, 0x1fcdbb16,
  0x018aeb13, 0x054bf6a4, 0x0808d07d, 0x0cc9cdca,
  0x7897ab07, 0x7c56b6b0, 0x71159069, 0x75d48dde,
  0x6b93dddb, 0x6f52c06c, 0x6211e6b5, 0x66d0fb02,
  0x5e9f46bf, 0x5a5e5b08, 0x571d7dd1, 0x53dc6066,
  0x4d9b3063, 0x495a2dd4, 0x44190b0d, 0x40d816ba,
  0xaca5c697, 0xa864db20, 0xa527fdf9, 0xa1e6e04e,
  0xbfa1b04b, 0xbb60adfc, 0xb6238b25, 0xb2e29692,
  0x8aad2b2f, 0x8e6c3698, 0x832f1041, 0x87ee0df6,
  0x99a95df3, 0x9d684044, 0x902b669d, 0x94ea7b2a,
  0xe0b41de7, 0xe4750050, 0xe9362689, 0xedf73b3e,
  0xf3b06b3b, 0xf771768c, 0xfa325055, 0xfef34de2,
  0xc6bcf05f, 0xc27dede8, 0xcf3ecb31, 0xcbffd686,
  0xd5b88683, 0xd1799b34, 0xdc3abded, 0xd8fba05a,
  0x690ce0ee, 0x6dcdfd59, 0x608edb80, 0x644fc637,
  0x7a089632, 0x7ec98b85, 0x738aad5c, 0x774bb0eb,
  0x4f040d56, 0x4bc510e1, 0x46863638, 0x42472b8f,
  0x5c007b8a, 0x58c1663d, 0x558240e4, 0x51435d53,
  0x251d3b9e, 0x21dc2629, 0x2c9f00f0, 0x285e1d47,
  0x36194d42, 0x32d850f5, 0x3f9b762c, 0x3b5a6b9b,
  0x0315d626, 0x07d4cb91, 0x0a97ed48, 0x0e56f0ff,
  0x1011a0fa, 0x14d0bd4d, 0x19939b94, 0x1d528623,
  0xf12f560e, 0xf5ee4bb9, 0xf8ad6d60, 0xfc6c70d7,
  0xe22b20d2, 0xe6ea3d65, 0xeba91bbc, 0xef68060b,
  0xd727bbb6, 0xd3e6a601, 0xdea580d8, 0xda649d6f,
  0xc423cd6a, 0xc0e2d0dd, 0xcda1f604, 0xc960ebb3,
  0xbd3e8d7e, 0xb9ff90c9, 0xb4bcb610, 0xb07daba7,
  0xae3afba2, 0xaafbe615, 0xa7b8c0cc, 0xa379dd7b,
  0x9b3660c6, 0x9ff77d71, 0x92b45ba8, 0x9675461f,
  0x8832161a, 0x8cf30bad, 0x81b02d74, 0x857130c3,
  0x5d8a9099, 0x594b8d2e, 0x5408abf7, 0x50c9b640,
  0x4e8ee645, 0x4a4ffbf2, 0x470cdd2b, 0x43cdc09c,
  0x7b827d21, 0x7f436096, 0x7200464f, 0x76c15bf8,
  0x68860bfd, 0x6c47164a, 0x61043093, 0x65c52d24,
  0x119b4be9, 0x155a565e, 0x18197087, 0x1cd86d30,
  0x029f3d35, 0x065e2082, 0x0b1d065b, 0x0fdc1bec,
  0x3793a651, 0x3352bbe6, 0x3e119d3f, 0x3ad08088,
  0x2497d08d, 0x2056cd3a, 0x2d15ebe3, 0x29d4f654,
  0xc5a92679, 0xc1683bce, 0xcc2b1d17, 0xc8ea00a0,
  0xd6ad50a5, 0xd26c4d12, 0xdf2f6bcb, 0xdbee767c,
  0xe3a1cbc1, 0xe760d676, 0xea23f0af, 0xeee2ed18,
  0xf0a5bd1d, 0xf464a0aa, 0xf9278673, 0xfde69bc4,
  0x89b8fd09, 0x8d79e0be, 0x803ac667, 0x84fbdbd0,
  0x9abc8bd5, 0x9e7d9662, 0x933eb0bb, 0x97ffad0c,
  0xafb010b1, 0xab710d06, 0xa6322bdf, 0xa2f33668,
  0xbcb4666d, 0xb8757bda, 0xb5365d03, 0xb1f740b4
};


/*通訊頭---------------------------------------*/

typedef enum
{
    HEADER_SEND_TYPE_NO_RESPONE = 0,
    HEADER_SEND_TYPE_RESPONE,
}header_response_type_eu;

typedef enum
{
    HEADER_TRANS_MODE_STORE = 0,
    HEADER_TRANS_MODE_DIRECT,
}header_transmit_mode_eu;

typedef enum
{
    HEADER_NORMAL_FRAME = 0,
    HEADER_EXTEND_FRAME,
}header_check_type_eu;

typedef enum
{
    HEADER_NORMAL_RESPONSE = 0,
    HEADER_RESPONSE_FRAME
}header_ack_mode_eu;

enum
{
    HEADER_COMMON_FRAME = 0,
    HEADER_CONTROL_FRAME,
    HEADER_STATES_FRAME,
    HEADER_SPARE2_FRAME
}header_control_states_frame_eu;

enum
{
    HEADER_DATA_FRAME = 0,
    HEADER_FIRST_FRAME,
    HEADER_CONTINUOUS_FRAME,
    HEADER_SPARE1_FRAME
}header_frame_type_eu;


/* Private macro -------------------------------------------------------------*/
#define FRAME_TYPE_PARSE(head_) (head_).detail.control_states_frame ? \
          (analy_frame_type_eu)( (head_).detail.control_states_frame + 3 ) : \
          (analy_frame_type_eu)(head_).detail.frame_type


#define ANALY_HEAD_ENCODE(head_,/*結構*/ \
                        dest_device_/*目標*/, src_device_/*自身*/, \
                        src_frame_/*自身幀號*/, des_ack_/*目標要確認*/, frame_type_/*幀類型*/,\
                        data_length_/*資料長*/,\
                        transmit_mode_/*傳輸模式*/, extend_frame_/*擴展帧*/,\
                        ack_frame_/*確認對方之幀號*/, response_frame_/*響應帧*/) \
        do{ (head_).detail.head_start = PROTOCOL_HEAD_ID;                       \
            (head_).detail.dest_device                      = dest_device_;     \
            (head_).detail.extend_frame                     = extend_frame_;      \
            (head_).detail.transmit_mode                    = transmit_mode_;   \
            (head_).detail.src_device                       = src_device_;      \
            frame_type_encode( (analy_protocol_head*)&head_, frame_type_ );     \
            (head_).detail.src_frame                        = src_frame_;       \
            (head_).detail.ack_frame                        = ack_frame_;       \
            (head_).detail.response_frame                   = response_frame_;  \
            (head_).detail.des_ack                          = des_ack_;         \
            (head_).detail.data_length                      = (uint8_t)(data_length_);\
            (head_).detail.data_crc8                        = cal_crc8_table((uint8_t*)&head_, PROTOCOL_HEAD_LEN - 1, 0);\
         }while(0)  

#define FIND_TRANSFER_HANDLE(dest_device_, self_device_)  \
            device_group[self_device_]->device_role != ANALY_PROXY ?   \
                device_group[dest_device_]->transfer_handle :          \
                device_group[self_device_]->transfer_handle            

#define EXCUTE_RECEIVE_DONE_HANDLE(src_device_, self_device_, data_buf_, data_len_, detail_)  \
        if(insta->current_device_role == ANALY_SELF)                                        \
            observer_data_done_self(src_device_, data_buf_, data_len_, detail_);         \
        else                                                                                \
            observer_data_done_proxy(src_device_, self_device_, data_buf_, data_len_, detail_)                  

#define UINT64_SET_BIT(var_, bit_) \
        do{                                                     \
                (var_) |= 0x1ULL << (bit_ );                    \
        }while (0)



#define UINT64_CLEAR_BIT(var_, bit_) \
        do{                                                     \
                (var_) &= ~(0x1ULL << (bit_)) ;                 \
        }while (0)



#define UINT64_READ_BIT(var_, bit_)  ((var_)  &  ( 0x1ULL << (bit_) ) )                  

/* Private variables ---------------------------------------------------------*/
static uint8_t                          observer_and_transfer_id_alloc; //觀察及傳輸者分配ID
static uint8_t                          observer_index_alloc; //observer分配index
static uint8_t                          transfer_index_alloc; //transfer分配index

static memory_pool_st* p_analy_memory;

analy_observer_st* observer_group[DRV_INTERFACE_COUNT];// 觀察者集合
analy_transfer_st* transfer_group[DATA_TRANSFER_COUNT];// 傳輸者集合


static analy_device_st* device_group[DEVICE_MAX_ID + 1];//DEVICE 集合

static uint8_t                          self_proxy_count;
static uint8_t                          self_proxy_id_group[DEVICE_MAX_ID + 1];


static uint8_t                          process_index_alloc; //process分配index
static uint8_t                          process_index[256];//process索引


analy_send_message_notify        process_notify_group[APP_PROCESS_COUNT + APP_PROCESS_BASE + 1];//傳輸通知集合
analy_receive_message_callback   process_receive_group[APP_PROCESS_COUNT + APP_PROCESS_BASE + 1];//接收資料集合

get_1ms_tick get_system_tick;//調用讀取系統節拍

static  uint64_t  src_frame_mask;
bool system_endian;
/* Private function prototypes -----------------------------------------------*/

/*------------共用--------------*/

bool cpu_big_endian()
{
    //false: 小端
    //true: 大端
    union
    {
        uint16_t a;
        uint8_t b;
    }c;

    c.a = 1;
    return c.b == 0;
}



/*計算CRC8*/
static uint8_t cal_crc8_table(const uint8_t* ptr, uint32_t len, uint8_t init)
{
    uint8_t  crc = init;

    while (len--)
    {
        crc = crc8_table[crc ^ *ptr++];
    }
    return crc;
}

uint32_t analy_math_crc32(const uint8_t* buf, uint32_t len, uint32_t init)
{
    uint32_t crc = init;

    while (len--)
    {
        crc = (crc << 8) ^ crc32_table[((crc >> 24) ^ *buf++) & 255];
    }

    return crc;
}



static inline void frame_type_encode(analy_protocol_head* p_protocol_head, analy_frame_type_eu fram_type)
{

    switch (fram_type)
    {
    case ANALY_FRAME_DATA:
    {
        p_protocol_head->detail.control_states_frame = 0;
        p_protocol_head->detail.frame_type = 0;
    }
    break;

    case ANALY_FRAME_FIRST:
    {
        p_protocol_head->detail.control_states_frame = 0;
        p_protocol_head->detail.frame_type = 1;
    }
    break;

    case ANALY_FRAME_CONTINUOUS:
    {
        p_protocol_head->detail.control_states_frame = 0;
        p_protocol_head->detail.frame_type = 2;
    }
    break;

    case ANALY_FRAME_SPARE:
    {
        p_protocol_head->detail.control_states_frame = 0;
        p_protocol_head->detail.frame_type = 3;
    }
    break;

    case ANALY_FRAME_CONTROL:
    {
        p_protocol_head->detail.control_states_frame = 1;
        p_protocol_head->detail.frame_type = 0;
    }
    break;

    case ANALY_FRAME_STATES:
    {
        p_protocol_head->detail.control_states_frame = 2;
        p_protocol_head->detail.frame_type = 0;
    }
    break;

    default:
        break;
    }
    return;
}


static void data_frame_ack_transfer(uint8_t dest_device, uint8_t self_device, uint8_t start_frame, uint8_t end_frame)
{
    analy_protocol_head   head_data;
    analyzer_interface_st* p_interface_tmp = device_group[dest_device]->p_path_interface;

    loop_fifo_st* p_tx_fifo_tmp = p_interface_tmp->p_tx_fifo;

    if (p_tx_fifo_tmp->full_len - p_tx_fifo_tmp->current_len >= PROTOCOL_HEAD_LEN)
    {
        ANALY_HEAD_ENCODE(head_data,
            dest_device,
            self_device,
            start_frame == end_frame ? 0 : start_frame,
            HEADER_SEND_TYPE_NO_RESPONE,
            ANALY_FRAME_DATA,
            0,
            HEADER_TRANS_MODE_STORE,
            HEADER_NORMAL_FRAME,
            end_frame,
            HEADER_RESPONSE_FRAME);

        p_interface_tmp->tx_put_handler(head_data.base, PROTOCOL_HEAD_LEN);
    }
}

static void first_frame_ack_transfer(uint8_t dest_device, uint8_t self_device, uint8_t ack_frame)
{
    analy_protocol_head   head_data;
    analyzer_interface_st* p_interface_tmp = device_group[dest_device]->p_path_interface;

    loop_fifo_st* p_tx_fifo_tmp = p_interface_tmp->p_tx_fifo;

    if (p_tx_fifo_tmp->full_len - p_tx_fifo_tmp->current_len >= PROTOCOL_HEAD_LEN)
    {
        ANALY_HEAD_ENCODE(head_data,
            dest_device,
            self_device,
            0,
            HEADER_SEND_TYPE_NO_RESPONE,
            ANALY_FRAME_FIRST,
            0,
            HEADER_TRANS_MODE_STORE,
            HEADER_NORMAL_FRAME,
            ack_frame,
            HEADER_RESPONSE_FRAME);

        p_interface_tmp->tx_put_handler(head_data.base, PROTOCOL_HEAD_LEN);
    }
}

#pragma pack(1)
typedef union
{
    struct  multy_ack_st_
    {
        uint8_t    frame_state;
        uint64_t   ack_frame;
        uint32_t   crc_check_sum;
    }data;
    uint8_t base[sizeof(struct multy_ack_st_)];
}multy_ack_st;
#pragma pack()

static void multy_ack_transfer(uint8_t dest_device, uint8_t self_device, uint64_t ack_frame)
{
    analy_protocol_head   head_data;
    multy_ack_st          multy_ack_data;
    analyzer_interface_st* p_interface_tmp = device_group[dest_device]->p_path_interface;

    loop_fifo_st* p_tx_fifo_tmp = p_interface_tmp->p_tx_fifo;

    if (p_tx_fifo_tmp->full_len - p_tx_fifo_tmp->current_len >= PROTOCOL_HEAD_LEN + sizeof(multy_ack_st))
    {
        ANALY_HEAD_ENCODE(head_data,
            dest_device,
            self_device,
            0,
            HEADER_SEND_TYPE_NO_RESPONE,
            ANALY_FRAME_STATES,
            sizeof(multy_ack_st) - CRC32_LEN,
            HEADER_TRANS_MODE_STORE,
            HEADER_NORMAL_FRAME,
            0,
            HEADER_NORMAL_RESPONSE);

        multy_ack_data.data.frame_state = ANALY_MULTY_ACK_RESPONSE;
        multy_ack_data.data.ack_frame = BYTE_2_U64_LIT(&ack_frame);

        uint32_t    crc32_result = analy_math_crc32(multy_ack_data.base, sizeof(multy_ack_st) - CRC32_LEN, 0);
        multy_ack_data.data.crc_check_sum = BYTE_2_U32_LIT(&crc32_result);

        p_interface_tmp->tx_put_handler(head_data.base, PROTOCOL_HEAD_LEN);
        p_interface_tmp->tx_put_handler(multy_ack_data.base, sizeof(multy_ack_st));
    }
}

#pragma pack(1)
typedef union
{
    struct  flow_frame_st_
    {
        uint8_t                 frame_state;
        uint8_t                 state;
        uint8_t                 interval_time;
        uint16_t                buf_len;
        uint32_t                crc_check_sum;
    }data;
    uint8_t base[sizeof(struct flow_frame_st_)];
}flow_frame_data_st;
#pragma pack()

static void flow_frame_transfer(uint8_t dest_device, uint8_t self_device, analy_flow_response_eu states, uint8_t interval_time, uint16_t remain_buf, uint8_t ack_frame)
{
    analy_protocol_head   head_data;
    flow_frame_data_st    flow_data;
    analyzer_interface_st* p_interface_tmp = device_group[dest_device]->p_path_interface;


    loop_fifo_st* p_tx_fifo_tmp = p_interface_tmp->p_tx_fifo;

    if (p_tx_fifo_tmp->full_len - p_tx_fifo_tmp->current_len >= PROTOCOL_HEAD_LEN + sizeof(flow_frame_data_st))
    {
        ANALY_HEAD_ENCODE(head_data,
            dest_device,
            self_device,
            0,
            HEADER_SEND_TYPE_NO_RESPONE,
            ANALY_FRAME_STATES,
            sizeof(flow_frame_data_st) - CRC32_LEN,
            HEADER_TRANS_MODE_STORE,
            HEADER_NORMAL_FRAME,
            ack_frame,
            HEADER_NORMAL_RESPONSE);

        flow_data.data.frame_state = ANALY_FRAME_FLOW_STATE;
        flow_data.data.state = states;
        flow_data.data.interval_time = interval_time;

        flow_data.data.buf_len = BYTE_2_U16_LIT(&remain_buf);
        uint32_t    crc32_result = analy_math_crc32(flow_data.base, sizeof(flow_frame_data_st) - CRC32_LEN, 0);
        flow_data.data.crc_check_sum = BYTE_2_U32_LIT(&crc32_result);

        p_interface_tmp->tx_put_handler(head_data.base, PROTOCOL_HEAD_LEN);
        p_interface_tmp->tx_put_handler(flow_data.base, sizeof(flow_frame_data_st));
    }
}
/*---------------觀察者->process接收資料-------------------------------------*/
static  uint32_t observer_data_done_self(uint8_t src_device, uint8_t* p_data, size_t length, analy_receive_detail_st* detail)
{
    analy_receive_message_callback  receive_message_callback;
    uint8_t  precess_id = p_data[1];

    receive_message_callback = device_group[src_device]->receive_callback;

    if (receive_message_callback == NULL)
    {
        receive_message_callback = process_receive_group[process_index[precess_id]];
    }

    if (receive_message_callback != NULL)
        receive_message_callback(src_device, p_data, length, detail);

    return 0;
}


/*---------------觀察者->proxy接收資料-------------------------------------*/
static uint32_t observer_data_done_proxy(uint8_t src_device, uint8_t proxy_device, uint8_t* p_data, size_t length, analy_receive_detail_st* detail)
{

    analy_receive_message_callback  receive_message_callback = device_group[proxy_device]->receive_callback;

    if (receive_message_callback != NULL)
        receive_message_callback(src_device, p_data, length, detail);

    return 0;

}


/*----------觀察者調用----------*/

enum
{
    ANALY_CATCH_OK = 0,
    ANALY_SEARCH_NULL = 0x7FFFFFFF,
}analy_head_catch_eu;

static size_t catch_head_search(uint8_t* ptr, size_t search_len)
{
    for (size_t i = 0; i < search_len; ++i)
    {
        if (*((uint32_t*)(ptr + i)) == PROTOCOL_HEAD_ID)
            return i;
    }
    return ANALY_SEARCH_NULL;
}

static inline void receive_start_time(analy_observer_st* const insta)
{
    if (!insta->start_flag)
    {
        insta->start_flag = true;
        insta->start_tick = get_system_tick();
    }
}

static inline uint16_t receive_current_time(analy_observer_st* const insta)
{
    return (get_system_tick() - insta->start_tick);
}

static inline void receive_stop_time(analy_observer_st* const insta)
{
    insta->start_flag = false;
    insta->start_tick = get_system_tick();
}


static inline uint32_t catch_head_loop(analy_observer_st* const insta)
{
    analy_protocol_head* p_protocol_head;

    size_t  catch_head_index;

    for (size_t i = 0; i < HEAD_CHECK_LEN_MAX; ++i)
    {
        catch_head_index = catch_head_search(&insta->current_head.base[i], HEAD_CHECK_LEN_MAX);

        if (catch_head_index != ANALY_SEARCH_NULL)//有捕捉到
        {
            i = catch_head_index;

            if (i == 0)//足夠長
            {
                p_protocol_head = (analy_protocol_head*)&insta->current_head.base[i];
                /*head CRC8校驗通過*/
                if (p_protocol_head->detail.data_crc8 == cal_crc8_table(&insta->current_head.base[0], PROTOCOL_HEAD_LEN - 1, 0))
                {
                    insta->head_left_len = 0;
                    insta->observe_states = ANALY_OBSERVER_HEAD_CATCH;//********已捕捉                    

                    /*檢查------------------------*/
                    uint8_t device_tmp = insta->current_head.detail.dest_device;
                    uint8_t  role_tmp = device_group[device_tmp]->device_role;
                    if (device_tmp <= DEVICE_MAX_ID && role_tmp > 0)
                    {
                        insta->current_device_role = (analy_device_def_eu)role_tmp;

                        return true;
                    }
                }
                else
                {
                    continue;
                }
            }
            else
            {
                memmove(&insta->current_head.base[0], &insta->current_head.base[i], PROTOCOL_HEAD_LEN - i);
                insta->head_left_len = PROTOCOL_HEAD_LEN - (uint8_t)i;
                break;
            }
        }
        else
        {
            memmove(&insta->current_head.base[0], &insta->current_head.base[HEAD_CHECK_LEN_MAX], HEAD_CHECK_LACK_LEN);
            insta->head_left_len = HEAD_CHECK_LACK_LEN;
            break;
        }
    }

    return 0;
}

typedef enum
{
    ANALY_OBSERVER_RESPONSE_ACK,
    ANALY_OBSERVER_BUF_FULL,
    ANALY_OBSERVER_RECEIVE_BUSY,
    ANALY_OBSERVER_CRC_ERROR,
    ANALY_OBSERVER_FRAME_REPEAT,
    ANALY_OBSERVER_REJECT,
}observer_deal_result_eu;

#define LONG_RECEIVE_ENDING() \
    do{                       \
        long_frame_states_tmp->receive_states = ANALY_LONG_RECEIVE_IDLE;\
        insta->long_receiveing_device = 0;\
    }while(0) 


#define LONG_RECEIVE_RESPONSE_BUF_FULL() \
    do{                                                                         \
        flow_frame_transfer(src_device, self_device_id, ANALY_FLOW_OVERLOAD, 0, \
                (uint16_t)GET_FIFO_REMAIN_LEN(insta->p_observer_interface->p_rx_fifo),    \
                long_frame_states_tmp->first_frame_num);                        \
        LONG_RECEIVE_ENDING();                                                  \
        return ANALY_OBSERVER_BUF_FULL;                                         \
    }while(0) 

#define LONG_RECEIVE_FIRST_RESPONSE() \
    do{                                                                                                         \
        if(insta->current_head.detail.des_ack)                                                                  \
        {                                                                                                       \
            if(!insta->current_head.detail.extend_frame)                                                        \
                first_frame_ack_transfer(src_device, self_device_id, long_frame_states_tmp->first_frame_num);   \
            else                                                                                                \
                flow_frame_transfer(src_device, self_device_id, ANALY_FLOW_CONTINU, 0,                          \
                         (uint16_t)GET_FIFO_REMAIN_LEN(insta->p_observer_interface->p_rx_fifo),                            \
                        long_frame_states_tmp->first_frame_num);                                                \
        }                                                                                                       \
    }while(0) 

static inline void long_receive_timing(analy_observer_st* const insta)
{
    analy_long_data_frame_states_st* long_frame_states_tmp = device_group[insta->long_receiveing_device]->p_long_frame_states;

    if ((get_system_tick() - long_frame_states_tmp->last_receive_tick) >
        long_frame_states_tmp->over_time)
    {
        fl_memory_free(p_analy_memory, &long_frame_states_tmp->long_data_space);
        LONG_RECEIVE_ENDING();
    }
}

/*觀察者FRAME_DATA*/
static inline observer_deal_result_eu observer_frame_data_deal(analy_observer_st* const insta)
{
    uint8_t src_device = insta->current_head.detail.src_device;
    uint8_t self_device_id = insta->current_head.detail.dest_device;
    uint8_t data_len = insta->current_head.detail.data_length;

    /*收下資料*/
    uint8_t data_buf[SHORT_DATA_MAX_LEN + CRC32_LEN];
    insta->p_observer_interface->rx_get_handler(data_buf, (size_t)data_len + CRC32_LEN);

    uint32_t crc32_receive = BYTE_2_U32_LIT(&data_buf[data_len]);

    if (crc32_receive == analy_math_crc32(data_buf, data_len, 0))
    {
        uint8_t src_frame = insta->current_head.detail.src_frame;
        if (src_frame != 0)
        {
            analy_transfer_st* transfer_handle_tmp = FIND_TRANSFER_HANDLE(src_device, self_device_id);

            analy_frame_ack_st frame_ack_submit = { .device_id = src_device,
                                                    .self_id = self_device_id,
                                                    .ack_frame = src_frame };
            //提交回復幀號
            transfer_handle_tmp->transfer_ack_handler(transfer_handle_tmp, frame_ack_submit);
        }

        analy_receive_detail_st receive_detail = { .data_states = FL_ANALY_DATA_ARRIVE , .frame_number = insta->current_head.detail.src_frame,
                                                     .memory_pool = NULL };

        EXCUTE_RECEIVE_DONE_HANDLE(src_device, self_device_id,
            data_buf, data_len,
            &receive_detail);
        return ANALY_OBSERVER_RESPONSE_ACK;
    }
    return ANALY_OBSERVER_CRC_ERROR;
}


/*觀察者FRAME_FIRST*/
static inline observer_deal_result_eu observer_frame_first_deal(analy_observer_st* const insta)
{
    uint8_t src_device = insta->current_head.detail.src_device;
    uint8_t self_device_id = insta->current_head.detail.dest_device;
    uint8_t data_len = insta->current_head.detail.data_length;


    analy_long_data_frame_states_st* long_frame_states_tmp = device_group[self_device_id]->p_long_frame_states;
    if (long_frame_states_tmp == NULL)
    {
        fl_loop_fifo_free(insta->p_observer_interface->p_rx_fifo, (size_t)data_len + CRC32_LEN);
        return ANALY_OBSERVER_REJECT;
    }

    if (long_frame_states_tmp->receive_states != ANALY_LONG_RECEIVE_IDLE)
    {
        fl_loop_fifo_free(insta->p_observer_interface->p_rx_fifo, (size_t)data_len + CRC32_LEN);
        return ANALY_OBSERVER_RECEIVE_BUSY;
    }
    /*收下資料*/
    uint8_t data_buf[SHORT_DATA_MAX_LEN + CRC32_LEN];
    insta->p_observer_interface->rx_get_handler(data_buf, (size_t)data_len + CRC32_LEN);

    uint32_t crc32_receive = BYTE_2_U32_LIT(&data_buf[data_len]);

    if (crc32_receive != analy_math_crc32(data_buf, data_len, 0))
        return ANALY_OBSERVER_CRC_ERROR;

    long_frame_states_tmp->total_length = BYTE_2_U16_LIT(data_buf);

    long_frame_states_tmp->src_frame_bit = 1;
    long_frame_states_tmp->first_frame_num = insta->current_head.detail.src_frame;
    long_frame_states_tmp->first_frame_len = data_len - FIRST_FRAME_HEAD_LEN;
    long_frame_states_tmp->continu_frame_count = insta->current_head.detail.ack_frame;

    if (long_frame_states_tmp->continu_frame_count)
    {
        if (p_analy_memory == NULL)
        {
            LONG_RECEIVE_ENDING();
            return ANALY_OBSERVER_REJECT;
        }

        long_frame_states_tmp->long_data_space = fl_memory_alloc(p_analy_memory,
            ((size_t)long_frame_states_tmp->continu_frame_count + 1) << 8);

        if (long_frame_states_tmp->long_data_space == NULL)
            LONG_RECEIVE_RESPONSE_BUF_FULL();
        else
            LONG_RECEIVE_FIRST_RESPONSE();

        //開始長包接收
        insta->long_receiveing_device = self_device_id;
        insta->long_source_device = src_device;

        memcpy(long_frame_states_tmp->long_data_space->p_block_buf,
            data_buf + FIRST_FRAME_HEAD_LEN,
            (size_t)long_frame_states_tmp->first_frame_len);

        long_frame_states_tmp->receive_states = ANALY_LONG_RECEIVE_ING;
        long_frame_states_tmp->last_receive_tick = get_system_tick();
        long_frame_states_tmp->over_time = (uint32_t)device_group[src_device]->package_overtime << 1;
        long_frame_states_tmp->continu_single_len = device_group[src_device]->short_max_len;
        long_frame_states_tmp->src_frame_done_state = long_frame_states_tmp->continu_frame_count != 63 ?
            (1ULL << (long_frame_states_tmp->continu_frame_count + 1)) - 1 : 0xFFFFFFFFFFFFFFFF;
    }
    else
    {
        LONG_RECEIVE_FIRST_RESPONSE();

        analy_receive_detail_st receive_detail = { .data_states = FL_ANALY_DATA_ARRIVE , .frame_number = insta->current_head.detail.src_frame,
                                                 .memory_pool = NULL };

        EXCUTE_RECEIVE_DONE_HANDLE(src_device, self_device_id,
            data_buf + FIRST_FRAME_HEAD_LEN, long_frame_states_tmp->first_frame_len,
            &receive_detail);

        LONG_RECEIVE_ENDING();
    }

    return ANALY_OBSERVER_RESPONSE_ACK;
}

/*觀察者FRAME_CONTINUOUS*/
static inline  observer_deal_result_eu observer_frame_continuous_deal(analy_observer_st* const insta)
{
    uint8_t src_device = insta->current_head.detail.src_device;
    uint8_t self_device_id = insta->current_head.detail.dest_device;
    uint8_t data_len = insta->current_head.detail.data_length;

    analy_long_data_frame_states_st* long_frame_states_tmp = device_group[self_device_id]->p_long_frame_states;

    if (long_frame_states_tmp == NULL)
    {
        fl_loop_fifo_free(insta->p_observer_interface->p_rx_fifo, (size_t)data_len + CRC32_LEN);
        return ANALY_OBSERVER_REJECT;
    }

    if (long_frame_states_tmp->receive_states == ANALY_LONG_RECEIVE_IDLE)
    {
        fl_loop_fifo_free(insta->p_observer_interface->p_rx_fifo, (size_t)data_len + CRC32_LEN);
        return ANALY_OBSERVER_REJECT;
    }

    long_frame_states_tmp->last_receive_tick = get_system_tick();
    if (insta->current_head.detail.src_frame != long_frame_states_tmp->first_frame_num ||
        UINT64_READ_BIT(long_frame_states_tmp->src_frame_bit, insta->current_head.detail.ack_frame) ||
        insta->current_head.detail.ack_frame > long_frame_states_tmp->continu_frame_count)
    {
        fl_loop_fifo_free(insta->p_observer_interface->p_rx_fifo, (size_t)data_len + CRC32_LEN);
        return ANALY_OBSERVER_FRAME_REPEAT;
    }


    /*收下資料*/
    uint8_t data_buf[SHORT_DATA_MAX_LEN + CRC32_LEN];
    insta->p_observer_interface->rx_get_handler(data_buf, (size_t)data_len + CRC32_LEN);

    uint32_t crc32_receive = BYTE_2_U32_LIT(&data_buf[data_len]);


    if (crc32_receive != analy_math_crc32(data_buf, data_len, 0))
    {
        return ANALY_OBSERVER_CRC_ERROR;
    }


    UINT64_SET_BIT(long_frame_states_tmp->src_frame_bit, insta->current_head.detail.ack_frame);

    memcpy(long_frame_states_tmp->long_data_space->p_block_buf +
        (size_t)long_frame_states_tmp->first_frame_len +
        ((size_t)insta->current_head.detail.ack_frame - 1) * (size_t)long_frame_states_tmp->continu_single_len,
        data_buf,
        data_len);

    if (insta->current_head.detail.des_ack)
        multy_ack_transfer(src_device, self_device_id, long_frame_states_tmp->src_frame_bit);

    if (long_frame_states_tmp->src_frame_bit == long_frame_states_tmp->src_frame_done_state)
    {
        analy_receive_detail_st receive_detail = { .data_states = FL_ANALY_DATA_POOL , .frame_number = long_frame_states_tmp->first_frame_num,
                                                 .memory_pool = long_frame_states_tmp->long_data_space };

        EXCUTE_RECEIVE_DONE_HANDLE(src_device, self_device_id,
            long_frame_states_tmp->long_data_space->p_block_buf,
            long_frame_states_tmp->total_length,
            &receive_detail);
        LONG_RECEIVE_ENDING();
    }

    return ANALY_OBSERVER_RESPONSE_ACK;
}


/*觀察者FRAME_CONTROL*/
static inline observer_deal_result_eu observer_frame_control_deal(analy_observer_st* const insta)
{
    uint8_t data_len = insta->current_head.detail.data_length;
    uint8_t data_buf[CONTROL_FRAME_MAX_LEN + CRC32_LEN];
    insta->p_observer_interface->rx_get_handler(data_buf, (size_t)data_len + CRC32_LEN);

    uint32_t crc32_receive = BYTE_2_U32_LIT(&data_buf[data_len]);

    if (crc32_receive != analy_math_crc32(data_buf, data_len, 0))
        return ANALY_OBSERVER_CRC_ERROR;

    uint8_t src_device = insta->current_head.detail.src_device;
    uint8_t self_device_id = insta->current_head.detail.dest_device;

    analy_transfer_st* transfer_handle_tmp = FIND_TRANSFER_HANDLE(src_device, self_device_id);
    switch (data_buf[0])
    {
    case ANALY_MULTY_ACK_REQUEST:
    {

    }
    break;
    case ANALY_FRAME_FLOW_CONTROL:
    {

    }
    break;
    }
    return ANALY_OBSERVER_RESPONSE_ACK;
}


/*觀察者FRAME_STATES*/
static inline observer_deal_result_eu observer_frame_states_deal(analy_observer_st* const insta)
{
    uint8_t data_len = insta->current_head.detail.data_length;
    uint8_t data_buf[STATES_FRAME_MAX_LEN + CRC32_LEN];
    insta->p_observer_interface->rx_get_handler(data_buf, (size_t)data_len + CRC32_LEN);

    uint32_t crc32_receive = BYTE_2_U32_LIT(&data_buf[data_len]);

    if (crc32_receive != analy_math_crc32(data_buf, data_len, 0))
        return ANALY_OBSERVER_CRC_ERROR;

    uint8_t src_device = insta->current_head.detail.src_device;
    uint8_t self_device_id = insta->current_head.detail.dest_device;
    uint8_t ack_frame = insta->current_head.detail.ack_frame;

    analy_transfer_st* transfer_handle_tmp = FIND_TRANSFER_HANDLE(src_device, self_device_id);


    switch (data_buf[0])
    {
    case ANALY_FRAME_FLOW_STATE:
    {
        analy_transfer_event_st  transfer_event = { .src_device_id = src_device,
                                    .self_device_id = self_device_id,
                                    .frame_ack_number = ack_frame,
                                    .frame_type = ANALY_FRAME_STATES,
                                    .event_type = ANALY_FLOW_ARRIVE,
                                    .p_data = data_buf };

        transfer_handle_tmp->transfer_notify_handler(transfer_handle_tmp, transfer_event);
    }
    break;//多重幀到達
    case ANALY_MULTY_ACK_RESPONSE:
    {
        analy_transfer_event_st  transfer_event = { .src_device_id = src_device,
                                    .self_device_id = self_device_id,
                                    .frame_ack_number = ack_frame,
                                    .frame_type = ANALY_FRAME_STATES,
                                    .event_type = ANALY_MULTY_ACK_ARRIVE,
                                    .p_data = data_buf };

        transfer_handle_tmp->transfer_notify_handler(transfer_handle_tmp, transfer_event);
    }
    break;
    }

    return ANALY_OBSERVER_RESPONSE_ACK;
}

/*觀察者->直接傳遞外部接口-----------------------------------------*/
static inline void observer_outside_deal(analy_observer_st* const insta, uint8_t dest_device, uint8_t src_device, uint8_t data_len)
{
    analyzer_interface_st* interface_tmp = device_group[dest_device]->p_path_interface;

    if (interface_tmp->tx_states != ANALYZER_PORT_CLOSE)
    {
        interface_tmp->tx_put_handler(&insta->current_head, sizeof(analy_protocol_head));

        if (data_len > 0)
        {
            interface_tmp->tx_move_handler(device_group[src_device]->p_path_interface->p_rx_fifo, (size_t)data_len + CRC32_LEN);
        }
    }
    else
        fl_loop_fifo_free(device_group[src_device]->p_path_interface->p_rx_fifo, (size_t)data_len + CRC32_LEN);
}

/*--------------觀察者->傳輸者-----------------------------------------*/
/*未驗證*/
static uint32_t  observe_frame_filter(uint8_t device_id, uint8_t src_frame)
{
    analy_frame_control_st* p_frame_control_tmp = device_group[device_id]->p_frame_control;

    uint8_t frame_tmp = p_frame_control_tmp->uninterrupt_frame;
    uint8_t frame_add = ++frame_tmp;


    if (frame_add > FRAME_NUMBER_MAX)
        frame_add = 1;

    if (frame_add == src_frame)
    {
        p_frame_control_tmp->uninterrupt_frame = frame_add;
        UINT64_SET_BIT(p_frame_control_tmp->src_frame_bit, src_frame);
        UINT64_CLEAR_BIT(p_frame_control_tmp->src_frame_bit, frame_tmp);

    }
    else
    {
        uint8_t  shift_x = frame_tmp - 1;
        uint64_t frame_mask = src_frame_mask << shift_x;
        uint8_t frame_max = frame_tmp + FRAME_NUMBER_INTERVAL;

        if (frame_max > FRAME_NUMBER_MAX)
        {
            frame_mask |= src_frame_mask >> (FRAME_NUMBER_MAX - shift_x);
        }

        if (UINT64_READ_BIT(frame_mask, src_frame))
        {

            UINT64_SET_BIT(p_frame_control_tmp->src_frame_bit, src_frame);
            return true;
        }
        else
        {
            return 0;
        }
    }
    return 0;
}


//觀察者，請求傳輸者回應對方幀號
static void transfer_ack(analy_transfer_st* const insta, analy_frame_ack_st ack_frame_event)
{
    loop_fifo_st* ack_fifo = insta->p_ack_record;


    if (insta->p_short_data_record->current_len != 0)
    {
        fl_loop_fifo_put(ack_fifo, &ack_frame_event, sizeof(analy_frame_ack_st));
    }
    else
    {
        data_frame_ack_transfer(ack_frame_event.device_id, ack_frame_event.self_id, ack_frame_event.ack_frame, ack_frame_event.ack_frame);
    }

    return;
}

//觀察者，通知傳輸者事件
static void transfer_notify(analy_transfer_st* const insta, analy_transfer_event_st event)
{
    //***********************************************************************
    switch (event.event_type)
    {
    case ANALY_SINGLE_ACK_ARRIVE:
    {
        if (event.frame_type == ANALY_FRAME_DATA)
        {
            if (insta->p_short_data_record->current_len)
            {
                if (device_group[event.self_device_id]->device_role != ANALY_PROXY)
                    UINT64_CLEAR_BIT(device_group[event.src_device_id]->p_frame_control->wait_ack_frame_bit, event.frame_ack_number);
                else
                    UINT64_CLEAR_BIT(device_group[event.self_device_id]->p_frame_control->wait_ack_frame_bit, event.frame_ack_number);
            }
        }
        else if (event.frame_type == ANALY_FRAME_FIRST)
        {
            analy_long_data_record_st* p_long_data_record_tmp = insta->p_long_data_record;
            if (p_long_data_record_tmp != NULL)
            {
                if (p_long_data_record_tmp->last_first_frame_num == event.frame_ack_number)
                {
                    device_group[event.src_device_id]->current_flow_states.response_states = (analy_flow_response_eu)ANALY_FLOW_CONTINU;

                    UINT64_CLEAR_BIT(p_long_data_record_tmp->wait_ack_frame_bit, 0);
                }
            }
        }
    }
    break;

    case ANALY_CONTINUE_ACK_ARRIVE:
    {
        if (insta->p_short_data_record->current_len)
        {
            uint32_t number;
            uint64_t ack_bit_tmp;
            analy_frame_control_st* p_frame_control_tmp;

            if (device_group[event.self_device_id]->device_role != ANALY_PROXY)
                p_frame_control_tmp = device_group[event.src_device_id]->p_frame_control;
            else
                p_frame_control_tmp = device_group[event.self_device_id]->p_frame_control;

            ack_bit_tmp = p_frame_control_tmp->wait_ack_frame_bit;

            if (event.frame_ack_begin <= event.frame_ack_number)
            {
                for (number = event.frame_ack_begin; number <= event.frame_ack_number; ++number)
                {
                    UINT64_CLEAR_BIT(ack_bit_tmp, number);
                }
            }
            else
            {
                for (number = event.frame_ack_begin; number <= FRAME_NUMBER_MAX; ++number)
                {
                    UINT64_CLEAR_BIT(ack_bit_tmp, number);
                }

                for (number = 0; number <= event.frame_ack_number; ++number)
                {
                    UINT64_CLEAR_BIT(ack_bit_tmp, number);
                }
            }


            p_frame_control_tmp->wait_ack_frame_bit = ack_bit_tmp;
        }

    }
    break;

    case ANALY_MULTY_ACK_ARRIVE:
    {
        uint64_t multy_ack_frame = BYTE_2_U64_LIT((event.p_data + 1));
        insta->p_long_data_record->wait_ack_frame_bit &= ~multy_ack_frame;
    }
    break;

    case ANALY_FLOW_ARRIVE:
    {
        analy_device_st* const device_temp = device_group[event.src_device_id];
        flow_frame_data_st* src_flow = (flow_frame_data_st*)event.p_data;

        device_temp->current_flow_states.response_states = (analy_flow_response_eu)src_flow->data.state;
        device_temp->current_flow_states.interval_time = src_flow->data.interval_time;
        device_temp->current_flow_states.buf_len = BYTE_2_U16_LIT(&src_flow->data.buf_len);

        analy_long_data_record_st* p_long_data_record_tmp = insta->p_long_data_record;
        if (p_long_data_record_tmp != NULL)
        {
            if (event.frame_ack_number == p_long_data_record_tmp->last_first_frame_num)
                UINT64_CLEAR_BIT(p_long_data_record_tmp->wait_ack_frame_bit, 0);
        }
    }
    break;

    default:
        break;
    }

    return;
}
/*---------------觀察者->傳輸者 END----------------------------------------*/

/*-----------------傳輸者調用----------------*/


static inline bool transfer_delay(bool* ing_flag, uint16_t* delay_tick, uint16_t current_tick, uint16_t delay_time)
{
    if (!(*ing_flag))
    {
        *ing_flag = true;
        *delay_tick = current_tick;
        return true;
    }
    else
    {
        if ((uint16_t)(get_system_tick() - *delay_tick) < delay_time)
        {
            return true;
        }
        else
        {
            *ing_flag = false;
            return false;
        }
    }
}


static void transfer_response_notify(uint8_t dest_device, uint8_t self_device, uint8_t requester_id, uint8_t requester_handle, analy_send_message_notify_eu response_news)
{
    analy_device_st* p_self_device = device_group[self_device];
    analy_send_message_notify message_notify;

    if (p_self_device->device_role == ANALY_SELF)
    {
        message_notify = process_notify_group[process_index[requester_id]];

        if (message_notify == NULL)
            message_notify = device_group[dest_device]->notify_callback;
    }
    else
    {
        message_notify = p_self_device->notify_callback;
    }

    if (message_notify != NULL)
        message_notify(dest_device, requester_handle, response_news);
}



static void transfer_message_done_notify(uint8_t dest_device, uint8_t self_device, uint8_t requester_id, uint8_t requester_handle)
{
    analy_device_st* p_self_device = device_group[self_device];
    analy_send_message_notify message_notify;

    if (p_self_device->device_role == ANALY_SELF)
    {
        message_notify = device_group[dest_device]->notify_callback;

        if (message_notify == NULL)
            message_notify = process_notify_group[process_index[requester_id]];
    }
    else
    {
        message_notify = p_self_device->notify_callback;
    }

    if (message_notify != NULL)
    {
        message_notify(dest_device, requester_handle, FL_ANALY_SEND_MESSAGE_DONE);
    }
}

typedef enum
{
    ANALY_TRANSFER_EXECUTE,
    ANALY_TRANSFER_PASS,
    ANALY_TRANSFER_FREE,
    ANALY_TRANSFER_DELAY,
    ANALY_TRANSFER_AGAIN,
    ANALY_TRANSFER_RETRY_FAIL,
}transfer_deal_result;

static transfer_deal_result analy_transfer_short_deal(analy_transfer_record_st* const single_record, bool allow_send)
{
    analy_frame_control_st* frame_control;

    if (device_group[single_record->self_device]->device_role != ANALY_PROXY)
        frame_control = device_group[single_record->dest_device]->p_frame_control;
    else
        frame_control = device_group[single_record->self_device]->p_frame_control;


    if (allow_send)
    {
        if (!(single_record->data_type & ANALY_SEND_RESPONE))//直接傳輸
            return ANALY_TRANSFER_EXECUTE;

        if (single_record->transfer_count == 0)//未傳輸
        {
            /*分配幀號bit*/
            if (frame_control->alloc_frame >= FRAME_NUMBER_MAX)
                frame_control->alloc_frame = 1;
            else
                ++frame_control->alloc_frame;
            /*用bit紀錄幀號*/
            UINT64_SET_BIT(frame_control->wait_ack_frame_bit, frame_control->alloc_frame);

            single_record->frame_number = frame_control->alloc_frame;

            ++single_record->transfer_count;
            single_record->transfer_tick = get_system_tick();
            return ANALY_TRANSFER_EXECUTE;
        }
        else
        {
            if (!UINT64_READ_BIT(frame_control->wait_ack_frame_bit, single_record->frame_number))//資料已ack 
                return ANALY_TRANSFER_FREE;

            uint16_t current_tick = get_system_tick();

            if (((uint16_t)(current_tick - single_record->transfer_tick)) > device_group[single_record->dest_device]->package_overtime)
            {
                if (single_record->transfer_count > TRANSFER_RETRY_COUNT)
                {
                    UINT64_CLEAR_BIT(frame_control->wait_ack_frame_bit, single_record->frame_number);
                    return ANALY_TRANSFER_RETRY_FAIL;
                }

                ++single_record->transfer_count;
                single_record->transfer_tick = current_tick;

                return ANALY_TRANSFER_EXECUTE;
            }
            else
            {
                return ANALY_TRANSFER_PASS;
            }
        }

    }
    else
    {
        if (single_record->data_type & ANALY_SEND_RESPONE)
        {
            if (single_record->transfer_count > 0 && !UINT64_READ_BIT(frame_control->wait_ack_frame_bit, single_record->frame_number))
                return ANALY_TRANSFER_FREE;

            single_record->transfer_tick = get_system_tick();
            return ANALY_TRANSFER_PASS;
        }
        else
        {
            return ANALY_TRANSFER_PASS;
        }
    }
}

static transfer_deal_result analy_transfer_long_first_deal(analy_long_data_record_st* const p_long_data_record, analy_transfer_record_st* const first_frame, uint16_t delay_time)
{
    if (first_frame->transfer_count == 0)//未傳輸
    {
        ++first_frame->transfer_count;
        if ((first_frame->data_type & ANALY_SEND_MUST_RESPONE) != 0)
        {
            if (p_long_data_record->continu_quantity < 63)
                p_long_data_record->wait_ack_frame_bit = (1ULL << (p_long_data_record->continu_quantity + 1)) - 1;
            else
                p_long_data_record->wait_ack_frame_bit = 0xFFFFFFFFFFFFFFFF;

            first_frame->transfer_tick = get_system_tick();
        }

        return ANALY_TRANSFER_EXECUTE;
    }
    else
    {
        if (!UINT64_READ_BIT(p_long_data_record->wait_ack_frame_bit, 0))//資料已ack 
        {
            return ANALY_TRANSFER_FREE;
        }

        uint16_t current_tick = get_system_tick();

        if (((uint16_t)(current_tick - first_frame->transfer_tick)) > device_group[first_frame->dest_device]->package_overtime
            || p_long_data_record->delay_ing)
        {
            if ((first_frame->transfer_count > TRANSFER_RETRY_COUNT) &&
                !p_long_data_record->delay_ing)
            {
                return ANALY_TRANSFER_RETRY_FAIL;
            }

            if (delay_time != 0)
            {
                if (transfer_delay(&p_long_data_record->delay_ing,
                    &p_long_data_record->transfer_delay_tick,
                    current_tick, delay_time))
                {
                    return ANALY_TRANSFER_DELAY;
                }
            }
            else
            {
                p_long_data_record->delay_ing = false;
            }

            ++first_frame->transfer_count;
            first_frame->transfer_tick = current_tick;
            return ANALY_TRANSFER_EXECUTE;
        }
        else
        {
            return ANALY_TRANSFER_PASS;
        }
    }
}

typedef enum
{
    ANALY_CONTINU_GENERAL,
    ANALY_CONTINU_LAST,
    ANALY_CONTINU_WAIT_ACK
}transfer_continu_deal_select_eu;

static transfer_deal_result analy_transfer_long_continu_deal(analy_long_data_record_st* const p_long_data_record, analy_continu_frame_record_st* const continu_frame, transfer_continu_deal_select_eu select, uint16_t delay_time)
{
    uint16_t current_tick = get_system_tick();

    if (select < ANALY_CONTINU_WAIT_ACK)
    {
        if (!UINT64_READ_BIT(p_long_data_record->wait_ack_frame_bit, continu_frame->frame_number))//資料已ack 
        {
            if (select == ANALY_CONTINU_LAST)
            {
                ++p_long_data_record->continu_transfer_count;
                if ((p_long_data_record->first_frame_record.data_type & ANALY_SEND_MUST_RESPONE) != 0)
                {
                    p_long_data_record->continu_transfer_tick = current_tick;
                }
            }
            return ANALY_TRANSFER_FREE;
        }

        if (delay_time != 0)
        {
            if (transfer_delay(&p_long_data_record->delay_ing,
                &p_long_data_record->transfer_delay_tick
                , current_tick, delay_time))
            {
                return ANALY_TRANSFER_DELAY;
            }
        }
        else
        {
            p_long_data_record->delay_ing = false;
        }

        if (select == ANALY_CONTINU_LAST)
        {
            ++p_long_data_record->continu_transfer_count;
            if ((p_long_data_record->first_frame_record.data_type & ANALY_SEND_MUST_RESPONE) != 0)
            {
                p_long_data_record->continu_transfer_tick = current_tick;
            }
        }
        return ANALY_TRANSFER_EXECUTE;
    }
    else
    {
        if (p_long_data_record->wait_ack_frame_bit == 0)
            return ANALY_TRANSFER_FREE;

        if (((current_tick - p_long_data_record->continu_transfer_tick)) > p_long_data_record->continu_over_time)
        {
            if (p_long_data_record->continu_transfer_count > TRANSFER_RETRY_COUNT)
            {
                return ANALY_TRANSFER_RETRY_FAIL;
            }

            return ANALY_TRANSFER_AGAIN;
        }
    }

    return ANALY_TRANSFER_PASS;
}

static void free_finish_ack(loop_fifo_st* const p_ack_record, size_t index_max, size_t total_count)
{
    if (total_count > 0)
    {
        bool    over_flag = false;
        size_t index = 0;
        size_t count = 0;

        analy_frame_ack_st* ack_begin = (analy_frame_ack_st*)P_FIFO_HEAD(p_ack_record);

        while (count < total_count)
        {
            if (ack_begin[index].ack_finish)
                ++count;
            else
                break;

            ++index;
            if (!over_flag)
            {
                if (index == index_max)
                {
                    ack_begin = (analy_frame_ack_st*)p_ack_record->p_buffer;
                    index = 0;
                    over_flag = true;
                }
            }
        }

        if (count > 0)
            fl_loop_fifo_free(p_ack_record, count * sizeof(analy_frame_ack_st));

        return;
    }
}

static uint8_t transfer_first_ack(analy_frame_ack_st* ack_begin, analy_frame_ack_st* ack_again, size_t index_max, size_t total_count)
{
    if (total_count > 0)
    {
        bool    over_flag = false;
        size_t index = 0;

        for (size_t count = 0; count < total_count; ++count)
        {
            if (!ack_begin[index].ack_finish)
            {
                ack_begin[index].ack_finish = true;
                data_frame_ack_transfer(ack_begin[index].device_id, ack_begin[index].self_id, ack_begin[index].ack_frame, ack_begin[index].ack_frame);

                break;
            }

            ++index;
            if (!over_flag)
            {
                if (index == index_max)
                {
                    ack_begin = ack_again;
                    index = 0;
                    over_flag = true;
                }
            }
        }
    }
    return 0;
}


static uint8_t get_specify_ack(analy_frame_ack_st* ack_begin, analy_frame_ack_st* ack_again, uint8_t dest_device, uint8_t self_device, size_t index_max, size_t total_count)
{
    if (total_count > 0)
    {
        bool    over_flag = false;
        size_t index = 0;

        for (size_t count = 0; count < total_count; ++count)
        {
            if (ack_begin[index].device_id == dest_device)
            {
                if (ack_begin[index].self_id == self_device)
                {
                    if (!ack_begin[index].ack_finish)
                    {
                        ack_begin[index].ack_finish = true;
                        return ack_begin[index].ack_frame;
                    }
                }
            }

            ++index;
            if (!over_flag)
            {
                if (index == index_max)
                {
                    ack_begin = ack_again;
                    index = 0;
                    over_flag = true;
                }
            }
        }
    }
    return 0;
}

static void transfer_all_ack(loop_fifo_st* const p_ack_record, analy_frame_ack_st* ack_begin, analy_frame_ack_st* ack_again, uint8_t self_device, size_t index_max, size_t total_count)
{
    size_t  ack_len = p_ack_record->current_len;

    if (ack_len > 0)
    {
        uint64_t ack[DEVICE_MAX_ID + 1] = { 0 };
        size_t true_count = 0;

        bool    over_flag = false;
        size_t index = 0;

        for (size_t count = 0; count < total_count; ++count)
        {
            if (!ack_begin[index].ack_finish)
            {
                if (ack_begin[index].self_id == self_device)
                {
                    ack_begin[index].ack_finish = true;
                    UINT64_SET_BIT(ack[ack_begin[index].device_id], ack_begin[index].ack_frame);
                    ++true_count;
                }
            }

            ++index;
            if (!over_flag)
            {
                if (index == index_max)
                {
                    ack_begin = ack_again;
                    index = 0;
                    over_flag = true;
                }
            }
        }

        size_t dest_id;
        uint32_t reg_tmp;
        uint32_t count;

        uint32_t start_frame;
        uint32_t end_frame;

        while (true_count)
        {
            for (dest_id = 1; dest_id <= DEVICE_MAX_ID; ++dest_id)
            {
                start_frame = 0;

                reg_tmp = (uint32_t)ack[dest_id];
                if (reg_tmp)
                {
                    count = 1;
                    reg_tmp >>= 1;

                    end_frame = 0;

                    while (reg_tmp)
                    {
                        if (!(reg_tmp & 0x00000001))
                        {
                            if (start_frame)
                            {
                                data_frame_ack_transfer((uint8_t)dest_id, self_device, start_frame, end_frame);
                                start_frame = 0;
                                end_frame = 0;
                            }
                        }
                        else
                        {
                            --true_count;
                            if (start_frame)
                            {
                                ++end_frame;
                            }
                            else
                            {
                                start_frame = count;
                                end_frame = count;
                            }
                        }

                        reg_tmp >>= 1;
                        ++count;
                    }
                }

                reg_tmp = ack[dest_id] >> 32;
                if (reg_tmp)
                {
                    count = 0;
                    if (!start_frame)
                    {
                        start_frame = 0;
                        end_frame = 0;
                    }

                    while (reg_tmp)
                    {
                        if (!(reg_tmp & 0x00000001))
                        {
                            if (start_frame)
                            {
                                data_frame_ack_transfer((uint8_t)dest_id, self_device, start_frame, end_frame);
                                start_frame = 0;
                                end_frame = 0;
                            }
                        }
                        else
                        {
                            --true_count;
                            if (start_frame)
                            {
                                ++end_frame;
                            }
                            else
                            {
                                start_frame = count + 32;
                                end_frame = count + 32;
                            }
                        }
                        reg_tmp >>= 1;
                        ++count;
                    }
                }

                if (start_frame)
                {
                    data_frame_ack_transfer((uint8_t)dest_id, self_device, start_frame, end_frame);
                }
            }
        }
    }
    return;
}

static void transfer_ack_process(analy_transfer_st* const insta)
{
    loop_fifo_st* const p_ack_record = insta->p_ack_record;
    size_t  ack_len = p_ack_record->current_len;
    if (ack_len == 0)
        return;

    size_t ack_count = ack_len / p_ack_record->unit_len;
    analy_frame_ack_st* ack_begin = (analy_frame_ack_st*)P_FIFO_HEAD(p_ack_record);
    analy_frame_ack_st* ack_again = (analy_frame_ack_st*)p_ack_record->p_buffer;
    size_t ack_index_max = (p_ack_record->buffer_max_len - p_ack_record->head) / p_ack_record->unit_len;
    size_t i;

    if (ack_count < 6)
    {
        for (i = ack_count; i; --i)
        {
            transfer_first_ack(ack_begin, ack_again, ack_index_max, ack_count);
        }
    }
    else
    {
        for (i = 0; i < self_proxy_count; ++i)
        {
            transfer_all_ack(p_ack_record, ack_begin, ack_again, self_proxy_id_group[i], ack_index_max, ack_count);
        }
    }

    free_finish_ack(p_ack_record, ack_index_max, ack_count);
}
/* External functions --------------------------------------------------------*/
uint32_t analy_sys_init(get_1ms_tick tick_handler, memory_pool_st* mem_pool)
{
    FL_ASSERT(tick_handler);
    get_system_tick = tick_handler;


    size_t id;
    size_t count;


    for (id = 1; id <= DEVICE_MAX_ID; ++id)
    {
        if (device_group[id] == NULL)
            continue;

        if (device_group[id]->device_role & (ANALY_SELF | ANALY_PROXY))
        {
            for (count = 0; count < self_proxy_count; ++count)
            {
                if (self_proxy_id_group[count] == device_group[id]->device_id)
                {
                    break;
                }

            }

            if (count == self_proxy_count)
            {
                self_proxy_id_group[self_proxy_count] = device_group[id]->device_id;
                ++self_proxy_count;
            }
        }
    }

    system_endian = cpu_big_endian();

    FL_ASSERT(FRAME_NUMBER_INTERVAL + 1 <= FRAME_NUMBER_MAX)
        for (size_t i = 1; i <= FRAME_NUMBER_INTERVAL + 1; ++i)
        {
            src_frame_mask |= 0x1ULL << i;
        }
    if (mem_pool != NULL)
    {
        p_analy_memory = mem_pool;
        fl_memory_pool_init(mem_pool);
    }
    return 0;
}

uint32_t analy_interface_observer_init(analy_observer_st* observer_insta, analy_observer_config_st* observer_config)
{
    ++observer_and_transfer_id_alloc;
    observer_insta->observer_id = observer_and_transfer_id_alloc;

    observer_insta->long_data_pool_threshold = observer_config->long_data_pool_threshold;

    if (observer_config->receive_over_time > 0)
        observer_insta->receive_over_time = observer_config->receive_over_time;
    else
        observer_insta->receive_over_time = 100;


    FL_ASSERT(observer_config->self_device_id);
    observer_insta->self_device_id = observer_config->self_device_id;


    FL_ASSERT(observer_config->p_observer_interface);
    observer_insta->p_observer_interface = observer_config->p_observer_interface;


    FL_ASSERT(DRV_INTERFACE_COUNT > observer_index_alloc);
    observer_group[observer_index_alloc++] = observer_insta;



    return 0;
}

uint32_t analy_message_transfer_init(analy_transfer_st* transfer_insta, analy_transfer_config_st* transfer_config)
{
    ++observer_and_transfer_id_alloc;
    transfer_insta->transfer_id = observer_and_transfer_id_alloc;


    transfer_insta->transfer_notify_handler = transfer_notify;


    transfer_insta->transfer_ack_handler = transfer_ack;


    /*短資料紀錄池*/
    FL_ASSERT(transfer_config->p_short_data_record);
    transfer_insta->p_short_data_record = transfer_config->p_short_data_record;


    /*短資料儲存區*/
    FL_ASSERT(transfer_config->p_short_data_store);
    transfer_insta->p_short_data_store = transfer_config->p_short_data_store;


    /*長資料紀錄*/
    FL_ASSERT(FRAME_NUMBER_INTERVAL >= LONG_DATA_FRAME_COUNT);

    transfer_insta->p_long_data_record = transfer_config->p_long_data_record;

    /*長資料儲存區*/
    transfer_insta->p_long_data_store = transfer_config->p_long_data_store;

    /*ack資料紀錄池*/
    FL_ASSERT(transfer_config->p_ack_record);
    transfer_insta->p_ack_record = transfer_config->p_ack_record;


    FL_ASSERT(DATA_TRANSFER_COUNT > transfer_index_alloc);
    transfer_group[transfer_index_alloc++] = transfer_insta;

    return 0;
}

uint32_t analy_device_init(analy_device_st* device_insta, analy_device_config_st* device_config)
{
    FL_ASSERT(device_config->device_id);
    device_insta->device_id = device_config->device_id;


    device_insta->device_role = device_config->device_role;

    switch (device_config->device_role)
    {
    case ANALY_SELF:
    {
        device_insta->p_long_frame_states = device_config->p_long_frame_states;
    }
    break;
    case ANALY_OUTSIDE:
    {
        FL_ASSERT(device_config->p_path_interface);
        device_insta->p_path_interface = device_config->p_path_interface;

        FL_ASSERT(device_config->transfer_handle);
        device_insta->transfer_handle = device_config->transfer_handle;

        FL_ASSERT(device_config->p_frame_control);
        device_insta->p_frame_control = device_config->p_frame_control;

        FL_ASSERT(device_config->short_max_len);
        device_insta->short_max_len = device_config->short_max_len;


        if (device_config->receive_callback)
            device_insta->receive_callback = device_config->receive_callback;

        if (device_config->notify_callback)
            device_insta->notify_callback = device_config->notify_callback;

        if (device_config->package_overtime > 0)
            device_insta->package_overtime = device_config->package_overtime;
        else
            device_insta->package_overtime = 100;
    }
    break;
    case ANALY_PROXY:
    {
        FL_ASSERT(device_config->transfer_handle);
        device_insta->transfer_handle = device_config->transfer_handle;

        FL_ASSERT(device_config->p_frame_control);
        device_insta->p_frame_control = device_config->p_frame_control;

        if (device_config->receive_callback)
            device_insta->receive_callback = device_config->receive_callback;

        if (device_config->notify_callback)
            device_insta->notify_callback = device_config->notify_callback;

    }
    break;
    }

    FL_ASSERT(device_group[device_config->device_id] == 0);
    device_group[device_config->device_id] = device_insta;

    return 0;

}


//註冊process 接收事件
uint32_t analy_register_process_receive(uint8_t process_number, analy_receive_message_callback receive_callback)
{
    FL_ASSERT(receive_callback);

    if (process_index[process_number] == 0)
    {
        ++process_index_alloc;
    }
    if (process_receive_group[process_index_alloc] == 0)
    {
        process_index[process_number] = process_index_alloc;
    }
    process_receive_group[process_index[process_number]] = receive_callback;

    return 0;
}

uint32_t analy_register_process_transfer(uint8_t process_number, analy_send_message_notify send_callback)
{
    FL_ASSERT(send_callback);

    if (process_index[process_number] == 0)
    {
        ++process_index_alloc;
    }
    if (process_notify_group[process_index_alloc] == 0)
    {
        process_index[process_number] = process_index_alloc;
    }
    process_notify_group[process_index[process_number]] = send_callback;

    return 0;
}

//註冊device 接收事件
uint32_t analy_register_device_receive(uint8_t device_id, analy_receive_message_callback receive_callback)
{
    FL_ASSERT(receive_callback);
    device_group[device_id]->receive_callback = receive_callback;

    return 0;
}

uint32_t analy_register_device_transfer(uint8_t device_id, analy_send_message_notify send_callback)
{
    FL_ASSERT(send_callback);
    device_group[device_id]->notify_callback = send_callback;

    return 0;
}

/*接口觀察者運行*/
uint32_t analy_observer_runtime(analy_observer_st* const insta)
{
    bool next_flag = true;

    if (insta->long_receiveing_device != 0)
        long_receive_timing(insta);


    do {
        switch (insta->observe_states)
        {
        case ANALY_OBSERVER_HEAD_LACK:  //不足
        {
            next_flag = false;
            size_t   head_read_length;
            analyzer_interface_st* const p_interface = insta->p_observer_interface;
            loop_fifo_st* const p_rx_fifo_tmp = p_interface->p_rx_fifo;
            size_t  current_len_tmp = p_rx_fifo_tmp->current_len;
            bool filter_head = true;

            size_t  search_index;
            size_t  beyond_length;
            size_t  search_length;

            if (current_len_tmp > HEAD_CHECK_LACK_LEN)
            {
                if (insta->start_flag)
                {
                    if (receive_current_time(insta) > insta->receive_over_time)
                    {
                        fl_loop_fifo_free(p_rx_fifo_tmp, HEAD_CHECK_LEN_MIN);
                        receive_stop_time(insta);
                    }
                }

                if (FIFO_HEAD_VAR(p_rx_fifo_tmp, uint32_t) == PROTOCOL_HEAD_ID)
                {
                    if (!(FIFO_HEAD_BEYOND_CHECK(p_rx_fifo_tmp, 4)))
                    {
                        filter_head = false;

                        receive_start_time(insta);
                    }
                }
            }

            while (current_len_tmp >= (head_read_length = PROTOCOL_HEAD_LEN - insta->head_left_len))
            {
                if (!filter_head || insta->head_left_len != 0)
                {
                    receive_stop_time(insta);

                    p_interface->rx_get_handler(&insta->current_head.base[insta->head_left_len], head_read_length);

                    if (catch_head_loop(insta))
                    {
                        next_flag = true;
                        break;
                    }

                    filter_head = true;
                    current_len_tmp -= head_read_length;
                }
                else
                {
                    search_length = current_len_tmp - HEAD_CHECK_LACK_LEN;
                    beyond_length = p_rx_fifo_tmp->buffer_max_len - p_rx_fifo_tmp->head;


                    if (search_length < beyond_length)
                    {
                        search_index = catch_head_search(P_FIFO_HEAD(p_rx_fifo_tmp), search_length);

                        if (search_index != ANALY_SEARCH_NULL)//找到
                        {
                            fl_loop_fifo_free(p_rx_fifo_tmp, search_index);
                            current_len_tmp -= search_index;
                            receive_start_time(insta);
                        }
                        else
                        {
                            fl_loop_fifo_free(p_rx_fifo_tmp, search_length);
                            current_len_tmp -= search_length;
                        }

                        filter_head = false;
                    }
                    else
                    {
                        if (beyond_length > HEAD_CHECK_LACK_LEN)
                        {
                            search_index = catch_head_search(P_FIFO_HEAD(p_rx_fifo_tmp), beyond_length - HEAD_CHECK_LACK_LEN);

                            if (search_index != ANALY_SEARCH_NULL)
                            {
                                fl_loop_fifo_free(p_rx_fifo_tmp, search_index);
                                current_len_tmp -= search_index;
                                receive_start_time(insta);
                            }
                            else
                            {
                                fl_loop_fifo_free(p_rx_fifo_tmp, beyond_length - HEAD_CHECK_LACK_LEN);
                                current_len_tmp -= beyond_length - HEAD_CHECK_LACK_LEN;
                            }

                            filter_head = false;
                        }
                        else
                        {
                            filter_head = false; //無法過濾
                        }
                    }
                }
            }
        }
        break;

        case ANALY_OBSERVER_HEAD_CATCH:  //已捕捉
        {

            uint8_t src_device = insta->current_head.detail.src_device;
            uint8_t self_device_id = insta->current_head.detail.dest_device;
            uint8_t data_len = insta->current_head.detail.data_length;

            /*提交回復及通知收到確認*/
            if (insta->current_device_role & (ANALY_PROXY | ANALY_SELF))
            {
                analy_frame_type_eu  frame_type = FRAME_TYPE_PARSE(insta->current_head);

                uint8_t             src_frame = insta->current_head.detail.src_frame;
                uint8_t             ack_frame = insta->current_head.detail.ack_frame;
                analy_transfer_st* const transfer_handle_tmp = FIND_TRANSFER_HANDLE(src_device, self_device_id);

                analy_transfer_event_st transfer_event = { .src_device_id = src_device,
                                                    .self_device_id = self_device_id,
                                                    .frame_ack_begin = src_frame,
                                                    .frame_ack_number = ack_frame,
                                                    .frame_type = frame_type,
                                                    .response_frame = insta->current_head.detail.response_frame != 0 };

                if (transfer_event.frame_ack_number != 0)
                {
                    transfer_event.event_type = transfer_event.frame_ack_begin != 0 &&
                        transfer_event.frame_type == ANALY_FRAME_DATA &&
                        transfer_event.response_frame ?
                        ANALY_CONTINUE_ACK_ARRIVE : ANALY_SINGLE_ACK_ARRIVE;

                    transfer_handle_tmp->transfer_notify_handler(transfer_handle_tmp, transfer_event);

                }
            }
            else
            {
                if (data_len == 0)
                {
                    observer_outside_deal(insta, self_device_id, src_device, data_len);
                }
            }

            if (data_len)
            {
                insta->observe_states = ANALY_OBSERVER_FRAME_RECEIVING;
                receive_start_time(insta);
            }
            else
            {
                insta->observe_states = ANALY_OBSERVER_HEAD_LACK;
            }

            next_flag = true;
        }
        break;

        case ANALY_OBSERVER_FRAME_RECEIVING:
        {
            next_flag = false;
            size_t package_len = insta->current_head.detail.data_length;

            if (receive_current_time(insta) <= insta->receive_over_time)
            {
                switch (insta->current_device_role)
                {
                case ANALY_SELF:
                {
                    if (insta->p_observer_interface->p_rx_fifo->current_len >= package_len + CRC32_LEN)
                    {
                        insta->observe_states = ANALY_OBSERVER_FRAME_RECEIVE_DONE;
                        receive_stop_time(insta);
                        next_flag = true;
                    }
                }
                break;
                case ANALY_PROXY:
                {
                    if (insta->p_observer_interface->p_rx_fifo->current_len >= package_len + CRC32_LEN)
                    {
                        insta->observe_states = ANALY_OBSERVER_FRAME_RECEIVE_DONE;
                        receive_stop_time(insta);
                        next_flag = true;
                    }
                }
                break;
                case ANALY_OUTSIDE:
                {
                    if (insta->p_observer_interface->p_rx_fifo->current_len >= package_len + CRC32_LEN)
                    {
                        insta->observe_states = ANALY_OBSERVER_FRAME_RECEIVE_DONE;
                        receive_stop_time(insta);
                        next_flag = true;
                    }

                }
                break;
                }
            }
            else
            {
                loop_fifo_st* const p_rx_fifo_tmp = insta->p_observer_interface->p_rx_fifo;

                size_t current_len = p_rx_fifo_tmp->current_len;

                fl_loop_fifo_free(p_rx_fifo_tmp, MIN(package_len + CRC32_LEN, current_len));
                insta->observe_states = ANALY_OBSERVER_HEAD_LACK;
                receive_stop_time(insta);
            }
        }
        break;

        case ANALY_OBSERVER_FRAME_RECEIVE_DONE:  //接收完成
        {
            next_flag = false;
            analy_frame_type_eu frame_type = FRAME_TYPE_PARSE(insta->current_head);

            if (insta->current_device_role & (ANALY_PROXY | ANALY_SELF))
            {
                switch (frame_type)
                {
                case ANALY_FRAME_DATA:
                {
                    observer_frame_data_deal(insta);
                }
                break;
                case ANALY_FRAME_FIRST:
                {
                    observer_frame_first_deal(insta);
                }
                break;
                case ANALY_FRAME_CONTINUOUS:
                {
                    observer_frame_continuous_deal(insta);
                }
                break;

                case ANALY_FRAME_CONTROL:
                { observer_frame_control_deal(insta); }
                break;
                case ANALY_FRAME_STATES:
                { observer_frame_states_deal(insta); }
                break;

                default:
                    break;
                }
            }
            else
            {
                uint8_t src_device = insta->current_head.detail.src_device;
                uint8_t data_len = insta->current_head.detail.data_length;
                uint8_t dest_device = insta->current_head.detail.dest_device;

                observer_outside_deal(insta, dest_device, src_device, data_len);
            }

            /*繼續觀測*/
            insta->observe_states = ANALY_OBSERVER_HEAD_LACK;
            next_flag = true;
        }
        break;

        default:
            break;
        }
    } while (next_flag);
    return 0;
}

static uint32_t analy_transfer_long_data_process(analy_transfer_st* const insta)
{
    bool next_flag = true;
    analy_long_data_record_st* const p_long_record = insta->p_long_data_record;

    analy_transfer_record_st* p_first_record = &p_long_record->first_frame_record;
    analyzer_interface_st* p_long_data_interface = device_group[p_first_record->dest_device]->p_path_interface;
    analy_continu_frame_record_st* p_continu_record = p_long_record->continu_frame_record;
    loop_fifo_st* p_long_tx_fifo_tmp = p_long_data_interface->p_tx_fifo;

    while (next_flag)
    {
        switch (insta->transfer_states)
        {
        case ANALY_LONG_SEND_INIT:
        {
            /*分配幀號bit*/
            if (p_long_record->last_first_frame_num == FRAME_NUMBER_MAX)
                p_long_record->last_first_frame_num = 1;
            else
                ++p_long_record->last_first_frame_num;

            p_first_record->frame_number = p_long_record->last_first_frame_num;

            ANALY_HEAD_ENCODE(p_long_record->first_head_data,
                p_first_record->dest_device,
                p_first_record->self_device,
                p_first_record->frame_number,
                (p_first_record->data_type & ANALY_SEND_MUST_RESPONE) != 0,
                ANALY_FRAME_FIRST,
                p_first_record->data_len,
                (p_first_record->data_type & ANALY_SEND_DIRECT) != 0,
                (p_first_record->data_type & ANALY_SEND_WAIT_FLOW) != 0,
                p_long_record->continu_quantity,
                HEADER_NORMAL_RESPONSE);

            if (p_long_record->continu_quantity)
            {
                ANALY_HEAD_ENCODE(p_long_record->continu_head_data,
                    p_first_record->dest_device,
                    p_first_record->self_device,
                    p_first_record->frame_number,
                    0,
                    ANALY_FRAME_CONTINUOUS,
                    1,
                    (p_first_record->data_type & ANALY_SEND_DIRECT) != 0,
                    0,
                    1,
                    HEADER_NORMAL_RESPONSE);
            }
            insta->transfer_states = ANALY_LONG_SEND_FIRST;
            next_flag = true;
        }
        break;

        case ANALY_LONG_SEND_FIRST:
        {
            if (GET_FIFO_REMAIN_LEN(p_long_tx_fifo_tmp) < (PROTOCOL_HEAD_LEN + p_first_record->data_len + CRC32_LEN))
                return 0;

            next_flag = false;

            switch (analy_transfer_long_first_deal(p_long_record, p_first_record, 0))
            {
            case ANALY_TRANSFER_EXECUTE:
            {
                /*傳入頭部*/
                p_long_data_interface->tx_put_handler(p_long_record->first_head_data.base, PROTOCOL_HEAD_LEN);
                /*複製資料*/
                fl_loop_fifo_put(p_long_tx_fifo_tmp, insta->p_long_data_store, (size_t)p_first_record->data_len + CRC32_LEN);

                if ((p_first_record->data_type & ANALY_SEND_MUST_RESPONE) == 0)//不響應
                {
                    if (p_long_record->continu_quantity == 0)//單包
                        insta->transfer_states = ANALY_LONG_SEND_IDLE;
                    else
                        insta->transfer_states = ANALY_LONG_SEND_CONTINUOUS;
                }
            }
            break;
            case ANALY_TRANSFER_FREE:
            {
                if (p_long_record->continu_quantity == 0)
                {
                    insta->transfer_states = ANALY_LONG_SEND_IDLE; 
                    transfer_message_done_notify(p_first_record->dest_device, p_first_record->self_device, p_first_record->requester_id, p_first_record->requester_handle);
                }
                else
                {
                    if (device_group[p_first_record->dest_device]->current_flow_states.response_states == ANALY_FLOW_OVERLOAD)
                    {
                        insta->transfer_states = ANALY_LONG_SEND_IDLE; 
                        transfer_response_notify(p_first_record->dest_device, p_first_record->self_device,
                            p_first_record->requester_id, p_first_record->requester_handle,
                            FL_ANALY_RECEIVER_FULL);

                        return 0;
                    }


                    insta->transfer_states = ANALY_LONG_SEND_CONTINUOUS;
                    next_flag = true;
                }
            }
            break;
            case ANALY_TRANSFER_RETRY_FAIL:
            {
                insta->transfer_states = ANALY_LONG_SEND_IDLE; 
                transfer_response_notify(p_first_record->dest_device, p_first_record->self_device, p_first_record->requester_id, p_first_record->requester_handle, FL_ANALY_ERROR_RETRY_SEND);
            }
            break;

            default:
                break;
            }
        }
        break;

        case ANALY_LONG_SEND_CONTINUOUS:
        {
            next_flag = false;
            size_t const last_send_index = p_long_record->continu_quantity - 1;
            size_t index_tmp = p_long_record->send_index;
            bool last_flag = false;

            while (index_tmp < p_long_record->continu_quantity)
            {
                if (GET_FIFO_REMAIN_LEN(p_long_tx_fifo_tmp) < (PROTOCOL_HEAD_LEN + p_continu_record[index_tmp].data_len + CRC32_LEN))
                    return 0;

                last_flag = index_tmp == last_send_index;
                switch (analy_transfer_long_continu_deal(p_long_record, &p_continu_record[index_tmp], last_flag ? ANALY_CONTINU_LAST : ANALY_CONTINU_GENERAL, 0))
                {
                case ANALY_TRANSFER_EXECUTE:
                {
                    p_long_record->continu_head_data.detail.ack_frame = p_continu_record[index_tmp].frame_number;
                    p_long_record->continu_head_data.detail.data_length = (uint8_t)p_continu_record[index_tmp].data_len;
                    if (last_flag)
                        p_long_record->continu_head_data.detail.des_ack = 1;

                    p_long_record->continu_head_data.detail.data_crc8 = cal_crc8_table(p_long_record->continu_head_data.base, PROTOCOL_HEAD_LEN - 1, 0);

                    /*傳入頭部*/
                    p_long_data_interface->tx_put_handler(p_long_record->continu_head_data.base, PROTOCOL_HEAD_LEN);
                    /*複製資料*/
                    fl_loop_fifo_put(p_long_tx_fifo_tmp, p_continu_record[index_tmp].p_data, (size_t)p_continu_record[index_tmp].data_len + CRC32_LEN);
                }
                break;
                case ANALY_TRANSFER_DELAY:
                {
                    return 0;
                }
                break;

                default:
                    break;
                }

                ++index_tmp;
                p_long_record->send_index = index_tmp;

                if (index_tmp > last_send_index)
                {
                    if (index_tmp == p_long_record->continu_quantity)
                    {
                        p_long_record->send_index = 0;

                        if ((p_long_record->first_frame_record.data_type & ANALY_SEND_MUST_RESPONE) == 0)//不響應
                        {
                            insta->transfer_states = ANALY_LONG_SEND_IDLE;
                            break;
                        }
                    }

                    insta->transfer_states = ANALY_LONG_SEND_WAIT_ACK;
                    next_flag = true;
                    break;
                }
            }
        }
        break;
        case ANALY_LONG_SEND_WAIT_ACK:
        {
            next_flag = false;
            switch (analy_transfer_long_continu_deal(p_long_record, p_continu_record, ANALY_CONTINU_WAIT_ACK, 0))
            {
            case ANALY_TRANSFER_AGAIN:
            {
                insta->transfer_states = ANALY_LONG_SEND_CONTINUOUS;
                next_flag = true;
            }
            break;
            case ANALY_TRANSFER_FREE:
            {
                insta->transfer_states = ANALY_LONG_SEND_IDLE; 
                transfer_message_done_notify(p_first_record->dest_device, p_first_record->self_device, p_first_record->requester_id, p_first_record->requester_handle);
            }
            break;
            case ANALY_TRANSFER_RETRY_FAIL:
            {
                insta->transfer_states = ANALY_LONG_SEND_IDLE; 
                transfer_response_notify(p_first_record->dest_device, p_first_record->self_device, p_first_record->requester_id, p_first_record->requester_handle, FL_ANALY_ERROR_RETRY_SEND);
            }
            break;

            default:
                break;
            }
        }
        break;

        default:
            break;
        }
    };
    return 0;
}

/*資料傳輸者運行*/
uint32_t analy_transfer_runtime(analy_transfer_st* const insta)
{
    if (insta->transfer_states != ANALY_LONG_SEND_IDLE)
        analy_transfer_long_data_process(insta);

    size_t short_data_len = insta->p_short_data_record->current_len;
    if (short_data_len > 0)
    {
        bool    over_flag = false;
        bool    free_record = true;
        analy_protocol_head   head_data;

        loop_fifo_st* const p_short_data_record = insta->p_short_data_record;
        analy_transfer_record_st* record_begin = (analy_transfer_record_st*)P_FIFO_HEAD(p_short_data_record);
        size_t  record_count = short_data_len / p_short_data_record->unit_len;
        size_t record_index_max = (p_short_data_record->buffer_max_len - p_short_data_record->head) / p_short_data_record->unit_len;

        loop_fifo_st* const p_ack_record = insta->p_ack_record;
        size_t  ack_len = p_ack_record->current_len;
        analy_frame_ack_st* ack_begin = NULL;
        analy_frame_ack_st* ack_again = NULL;
        size_t ack_count = 0;
        size_t ack_index_max = 0;

        if (ack_len > 0)
        {
            ack_begin = (analy_frame_ack_st*)P_FIFO_HEAD(p_ack_record);
            ack_again = (analy_frame_ack_st*)p_ack_record->p_buffer;
            ack_count = ack_len / p_ack_record->unit_len;
            ack_index_max = (p_ack_record->buffer_max_len - p_ack_record->head) / p_ack_record->unit_len;
        }

        analyzer_interface_st* p_interface_tmp;
        loop_fifo_st* p_tx_fifo_tmp;

        for (size_t count = 0, index = 0, store_offset = 0; count < record_count; ++count)
        {
            p_interface_tmp = device_group[record_begin[index].dest_device]->p_path_interface;
            p_tx_fifo_tmp = p_interface_tmp->p_tx_fifo;

            if (GET_FIFO_REMAIN_LEN(p_tx_fifo_tmp) < (PROTOCOL_HEAD_LEN + record_begin[index].data_len + CRC32_LEN))
                return 0;

            switch (analy_transfer_short_deal(&record_begin[index], true))
            {
            case ANALY_TRANSFER_EXECUTE:
            {
                ANALY_HEAD_ENCODE(head_data,
                    record_begin[index].dest_device,
                    record_begin[index].self_device,
                    record_begin[index].frame_number,
                    record_begin[index].data_type & ANALY_SEND_RESPONE,
                    ANALY_FRAME_DATA,
                    record_begin[index].data_len,
                    (record_begin[index].data_type & ANALY_SEND_DIRECT) != 0,
                    HEADER_NORMAL_FRAME,
                    get_specify_ack(ack_begin, ack_again, record_begin[index].dest_device,
                        record_begin[index].self_device, ack_index_max, ack_count),
                    HEADER_NORMAL_RESPONSE);

                /*傳入頭部*/
                p_interface_tmp->tx_put_handler(head_data.base, PROTOCOL_HEAD_LEN);
                /*複製資料*/
                fl_loop_fifo_copy(p_tx_fifo_tmp, insta->p_short_data_store, (size_t)record_begin[index].data_len + CRC32_LEN,
                    store_offset);

                if ((record_begin[index].data_type & ANALY_SEND_RESPONE))//響應
                {
                    free_record = false;
                }
            }
            break;
            case ANALY_TRANSFER_PASS:
            {
                free_record = false;
            }
            break;
            case ANALY_TRANSFER_FREE:
            {
                if (record_begin[index].frame_number)
                {
                    transfer_message_done_notify(record_begin[index].dest_device, record_begin[index].self_device, record_begin[index].requester_id, record_begin[index].requester_handle);
                    record_begin[index].frame_number = 0;
                }
            }
            break;
            case ANALY_TRANSFER_RETRY_FAIL:
            {
                if (record_begin[index].frame_number)
                {
                    transfer_response_notify(record_begin[index].dest_device, record_begin[index].self_device, record_begin[index].requester_id, record_begin[index].requester_handle, FL_ANALY_ERROR_RETRY_SEND);
                    record_begin[index].frame_number = 0;
                }
            }
            break;

            default:
                break;
            }

            if (free_record)
            {
                fl_loop_fifo_free(p_short_data_record, sizeof(analy_transfer_record_st));
                fl_loop_fifo_free(insta->p_short_data_store, (size_t)record_begin[index].data_len + CRC32_LEN);
            }
            else
            {
                store_offset = store_offset + (size_t)record_begin[index].data_len + CRC32_LEN;
            }

            ++index;

            if (!over_flag)
            {
                if (index == record_index_max)
                {
                    record_begin = (analy_transfer_record_st*)p_short_data_record->p_buffer;
                    index = 0;
                    over_flag = true;
                }
            }
        }
        free_finish_ack(p_ack_record, ack_index_max, ack_count);

    }
    else
    {
        transfer_ack_process(insta);
    }

    return 0;
}


/*發送短資料*/
analy_send_return_eu  analy_send_short_message(uint8_t dest_device, uint8_t self_id, uint16_t requester_id, analy_send_type_eu type, void* p_data_src, size_t length)
{
    if (length == 0)
        return ANALY_ERROR_LENGTH_INVALID;

    if (device_group[dest_device] == NULL || device_group[self_id] == NULL)
        return ANALY_ERROR_NOT_FOUND_DEVICE;

    if (length > device_group[dest_device]->short_max_len)
        return ANALY_ERROR_OVER_LENGTH;

    analy_transfer_st* transfer_tmp = FIND_TRANSFER_HANDLE(dest_device, self_id);
    loop_fifo_st* p_short_data_record = transfer_tmp->p_short_data_record;

    if (p_short_data_record->states == LOOP_FIFO_FULL)
        return ANALY_BUSY_MESSAGE_POOL_FULL;

    loop_fifo_st* p_short_data_store = transfer_tmp->p_short_data_store;

    /*儲存資料*/
    if ((p_short_data_store->full_len - p_short_data_store->current_len) >= (length + CRC32_LEN))
    {
        uint32_t crc32_result;

        fl_loop_fifo_put(p_short_data_store, p_data_src, length);

        crc32_result = analy_math_crc32((uint8_t*)p_data_src, (uint32_t)length, 0); 

        crc32_result = BYTE_2_U32_LIT(&crc32_result);

        /*儲存CRC32*/
        fl_loop_fifo_put(p_short_data_store, &crc32_result, CRC32_LEN);

        /*紀錄*/
        analy_transfer_record_st short_data_record = { .dest_device = dest_device, .self_device = self_id, .requester_id = (uint8_t)requester_id ,
                                                  .requester_handle = (uint8_t)(requester_id >> 8),
                                                  .data_type = type,  .transfer_count = 0, .frame_number = 0, .transfer_tick = 0,
                                                  .data_len = (uint16_t)length, .p_data = (uint8_t*)p_short_data_store->tail };

        fl_loop_fifo_put(p_short_data_record, &short_data_record, sizeof(analy_transfer_record_st));

        return ANALY_MESSAGE_SUBMIT_SUCCESS;
    }
    else
    {
        return ANALY_BUSY_MESSAGE_POOL_FULL;
    }
}

/*發送長資料*/
analy_send_return_eu  analy_send_long_message(uint8_t dest_device, uint8_t self_id, uint16_t requester_id, analy_send_type_eu type, void* p_data_src, size_t length)
{
    if (length == 0)
        return ANALY_ERROR_LENGTH_INVALID;

    if (device_group[dest_device] == NULL || device_group[self_id] == NULL)
        return ANALY_ERROR_NOT_FOUND_DEVICE;

    analy_transfer_st* transfer_tmp = FIND_TRANSFER_HANDLE(dest_device, self_id);

    analy_long_data_record_st* p_long_data_record = transfer_tmp->p_long_data_record;
    uint8_t* p_long_data_store = transfer_tmp->p_long_data_store;

    if (p_long_data_record == NULL || p_long_data_store == NULL)
        return ANALY_ERROR_NOT_SUPPORT;

    if (transfer_tmp->transfer_states != ANALY_LONG_SEND_IDLE)
        return ANALY_BUSY_MESSAGE_PROGRESS;

    size_t single_max_len = (size_t)device_group[dest_device]->short_max_len;
    size_t total_len = length + FIRST_FRAME_HEAD_LEN;
    if (total_len > (single_max_len << 6))
        return ANALY_ERROR_OVER_LENGTH;

    size_t continu_count = total_len / single_max_len;
    /*儲存資料*/
    if (total_len <= LONG_DATA_BUFFER - CRC32_LEN * (continu_count + 1) &&
        continu_count <= LONG_DATA_FRAME_COUNT)
    {
        uint16_t first_len;
        uint16_t revise_len = 0;
        if (continu_count)
        {
            first_len = (uint16_t)(total_len - (continu_count * single_max_len));
            if (first_len < FIRST_FRAME_HEAD_LEN)
            {
                revise_len = FIRST_FRAME_HEAD_LEN - first_len;
                first_len = FIRST_FRAME_HEAD_LEN;
            }
        }
        else
        {
            first_len = (uint16_t)total_len;
        }
        transfer_tmp->p_long_data_record->continu_quantity = (uint8_t)continu_count;


        /*儲存全長*/
        uint32_t crc32_result;
        uint16_t data_total_len = BYTE_2_U16_LIT(&length);
        *(uint16_t*)p_long_data_store = data_total_len;

        crc32_result = analy_math_crc32((uint8_t*)&data_total_len, FIRST_FRAME_HEAD_LEN, 0);
        crc32_result = BYTE_2_U32_LIT(&crc32_result);

        /*儲存資料*/
        if (first_len > FIRST_FRAME_HEAD_LEN)
        {
            crc32_result = analy_math_crc32((uint8_t*)p_data_src, first_len - FIRST_FRAME_HEAD_LEN, crc32_result);
            crc32_result = BYTE_2_U32_LIT(&crc32_result);
            memcpy(p_long_data_store + FIRST_FRAME_HEAD_LEN, p_data_src, first_len - FIRST_FRAME_HEAD_LEN);
        }

        /*紀錄first*/
        p_long_data_record->first_frame_record.dest_device = dest_device;
        p_long_data_record->first_frame_record.self_device = self_id;
        p_long_data_record->first_frame_record.requester_id = (uint8_t)requester_id;
        p_long_data_record->first_frame_record.requester_handle = (uint8_t)(requester_id >> 8);
        p_long_data_record->first_frame_record.data_type = type;
        p_long_data_record->first_frame_record.transfer_count = 0;
        p_long_data_record->first_frame_record.frame_number = 0;
        p_long_data_record->first_frame_record.transfer_tick = 0;
        p_long_data_record->first_frame_record.p_data = p_long_data_store;
        p_long_data_record->first_frame_record.data_len = first_len;

        /*儲存CRC32*/
        memcpy(p_long_data_store + first_len, &crc32_result, CRC32_LEN);

        if (continu_count != 0)
        {
            /*紀錄continu*/
            analy_continu_frame_record_st* fram_record_tmp = p_long_data_record->continu_frame_record;
            size_t     p_src_shift = first_len - FIRST_FRAME_HEAD_LEN;
            size_t     p_store_shift = (size_t)first_len + CRC32_LEN;

            for (size_t count = 0; count < continu_count; ++count)
            {
                fram_record_tmp[count].frame_number = (uint8_t)(count + 1);

                fram_record_tmp[count].p_data = p_long_data_store + p_store_shift;
                fram_record_tmp[count].data_len = (uint16_t)single_max_len;
                if (revise_len)
                {
                    if (fram_record_tmp[count].frame_number == continu_count)
                        fram_record_tmp[count].data_len = (uint16_t)single_max_len - revise_len;
                }

                crc32_result = analy_math_crc32((uint8_t*)p_data_src + p_src_shift, fram_record_tmp[count].data_len, 0);
                crc32_result = BYTE_2_U32_LIT(&crc32_result);

                /*儲存DATA*/
                memcpy(p_long_data_store + p_store_shift, (uint8_t*)p_data_src + p_src_shift, fram_record_tmp[count].data_len);
                p_store_shift += fram_record_tmp[count].data_len;
                p_src_shift += fram_record_tmp[count].data_len;

                /*儲存CRC32*/
                memcpy(p_long_data_store + p_store_shift, &crc32_result, CRC32_LEN);
                p_store_shift += CRC32_LEN;
            }
            p_long_data_record->continu_over_time = device_group[dest_device]->package_overtime;

            p_long_data_record->send_index = 0;
            p_long_data_record->delay_ing = false;
            p_long_data_record->continu_transfer_count = 0;
        }

        transfer_tmp->transfer_states = ANALY_LONG_SEND_INIT;
        return ANALY_MESSAGE_SUBMIT_SUCCESS;
    }
    else
    {
        return ANALY_BUSY_MESSAGE_POOL_FULL;
    }
}

void analy_memory_free(void* p_current_link)
{
    if (p_analy_memory != NULL)
    {
        if (p_current_link != NULL)
            fl_memory_free(p_analy_memory, (alloc_link_st*)p_current_link);
    }
    return;
} 