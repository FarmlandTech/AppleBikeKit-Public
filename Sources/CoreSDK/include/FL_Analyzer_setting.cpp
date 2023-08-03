
#include "FL_Analyzer_setting.h"
#include <ctime>
#include <string>
#include <iostream>
#include <chrono>
#include <queue>
#include <thread>

#include "UnixTime.h"
#ifdef __cplusplus
extern "C" {
#endif
     
/* Private typedef -----------------------------------------------------------*/

/* Private define ------------------------------------------------------------*/


/* Private macro -------------------------------------------------------------*/

/* Private variables ---------------------------------------------------------*/
 CREATE_MEMORY_POOL(analy_mem_pool, 16, 256, 5);

analy_observer_st usb_observer_insta;
analy_observer_st ble_observer_insta;
           
analy_data_out_notify soft_interface_out_notify[2];//通知軟體輸出接口
 
/*ST、NRF傳輸者----------------*/
LOOP_FIFO_INSTANCE(short_data_record_t1, FRAME_NUMBER_INTERVAL, analy_transfer_record_st);
LOOP_FIFO_INSTANCE(short_data_store_t1, SHORT_DATA_BUFFER, uint8_t);


static analy_continu_frame_record_st    continu_frame_record_t1[LONG_DATA_FRAME_COUNT];
static analy_long_data_record_st        long_data_record_t1 = { .continu_frame_record = continu_frame_record_t1 };
static uint8_t                          long_data_store_t1[LONG_DATA_BUFFER];

LOOP_FIFO_INSTANCE(ack_record_t1, FRAME_NUMBER_INTERVAL, analy_frame_ack_st);

analy_transfer_st transfer1_insta;


/*CAN傳輸者---------------*/
LOOP_FIFO_INSTANCE(short_data_record_t2, FRAME_NUMBER_INTERVAL, analy_transfer_record_st);
LOOP_FIFO_INSTANCE(short_data_store_t2, SHORT_DATA_BUFFER, uint8_t);



LOOP_FIFO_INSTANCE(ack_record_t2, FRAME_NUMBER_INTERVAL, analy_frame_ack_st);

analy_transfer_st transfer2_insta;


/*通訊傳輸者----------------*/
LOOP_FIFO_INSTANCE(short_data_record_t3, FRAME_NUMBER_INTERVAL, analy_transfer_record_st);
LOOP_FIFO_INSTANCE(short_data_store_t3, SHORT_DATA_BUFFER, uint8_t);


static analy_continu_frame_record_st    continu_frame_record_t3[LONG_DATA_FRAME_COUNT];
static analy_long_data_record_st        long_data_record_t3 = { .continu_frame_record = continu_frame_record_t3 };
static uint8_t                          long_data_store_t3[LONG_DATA_BUFFER];

LOOP_FIFO_INSTANCE(ack_record_t3, FRAME_NUMBER_INTERVAL, analy_frame_ack_st);

analy_transfer_st transfer3_insta;

/*裝置-----------------*/
analy_device_st device_pc_usb;//1
static analy_long_data_frame_states_st  pc_long_frame_states;

analy_device_st device_pc_ble;//2

analy_device_st device_nrf_wired;//3
static analy_frame_control_st nrf_wired_frame_control;

analy_device_st device_nrf_ble;//4
static analy_frame_control_st nrf_ble_frame_control;

analy_device_st device_st;//5
static analy_frame_control_st st_frame_control;

analy_device_st device_communicator;//6
static analy_frame_control_st communi_frame_control;

analy_device_st device_can_bus;//8
static analy_frame_control_st can_frame_control;

/* Private function prototypes -----------------------------------------------*/
int32_t  system_states;
uint32_t analy_tick;
static  std::chrono::steady_clock::time_point sys_old_time;
static  std::chrono::steady_clock::time_point sys_new_time;

#define ANALY_TICK_TYPE 1
void update_analy_tick(void)
{

#if ANALY_TICK_TYPE == 0
   analy_tick = clock();
   printf("%d:", analy_tick);
#else
    if (system_states)
    {
        sys_new_time = std::chrono::steady_clock::now();

        analy_tick = (uint32_t)std::chrono::duration_cast<std::chrono::milliseconds>(sys_new_time - sys_old_time).count();
    }
#endif 
}

static inline uint32_t analy_1ms_tick(void)
{     
    return analy_tick;
}

/*USB--------------------------*/
LOOP_FIFO_INSTANCE(usb_rx_fifo, 8192, uint8_t);
LOOP_FIFO_INSTANCE(usb_tx_fifo, 8192, uint8_t);
static analyzer_interface_st usb_instance;

static analy_data_out_notify usb_data_notify;

static uint32_t fl_usb_interface_move(loop_fifo_st* p_data_src, size_t length)
{
    return fl_loop_fifo_move(&usb_tx_fifo, p_data_src, length);
}

static uint32_t fl_usb_interface_get(void* p_data, size_t length)
{
    return fl_loop_fifo_get(&usb_rx_fifo, p_data, length);
}

static uint32_t fl_usb_interface_put(void* p_data, size_t length)
{
    return  fl_loop_fifo_put(&usb_tx_fifo, p_data, length);
}

static uint32_t fl_analy_usb_data_in(void* p_data, size_t length)
{
    return fl_loop_fifo_put(&usb_rx_fifo, p_data, length);
}

static uint32_t fl_analy_usb_data_out(void* p_data, size_t length)
{
    return fl_loop_fifo_get(&usb_tx_fifo, p_data, length);
}

static bool  usb_buf_clear;
static void fl_analy_usb_data_buf_clear(void)
{
    if (system_states)
    {
        fl_loop_fifo_free(&usb_tx_fifo, usb_tx_fifo.full_len);
        usb_buf_clear = true;
    }
}

bool internal_usb_clear(void)
{
    if (usb_buf_clear)
    {
        fl_loop_fifo_free(&usb_rx_fifo, usb_rx_fifo.full_len);
        usb_buf_clear = false;
        return true;
    }
    return false;
}



 size_t fl_analy_get_usb_sen_buf_len(void)
{
    return usb_tx_fifo.current_len;
}

/* External functions --------------------------------------------------------*/

uint32_t analy_framework_init(void)
{   
    /*USB init----------------------------------------*/
    usb_instance.p_rx_fifo = &usb_rx_fifo;
    usb_instance.p_tx_fifo = &usb_tx_fifo;
    
    usb_instance.rx_get_handler = fl_usb_interface_get;
    usb_instance.tx_put_handler = fl_usb_interface_put;
    usb_instance.tx_move_handler = fl_usb_interface_move;

   

    /*USB接口觀察----------------------------------------*/
    analy_observer_config_st observer_config = { 0 };

    observer_config.self_device_id = PC_USB_DEVICE_ID;

    observer_config.receive_over_time = 150;

    observer_config.long_data_pool_threshold = 1000;

    observer_config.p_observer_interface = &usb_instance;


    analy_interface_observer_init(&usb_observer_insta, &observer_config);

    /*BLE接口觀察----------------------------------------*/

    //memset(&observer_config, 0, sizeof(observer_config));
    //observer_config.self_deviced_id = PC_BLE_DEVICE_ID;

    //observer_config.receive_over_time = 250;

    //observer_config.long_data_pool_threshold = 1000;

    //observer_config.p_observer_interface = NULL;

    //analy_interface_observer_init(&ble_observer_insta, &observer_config);

    /*傳輸1----------------------------------------*/
    analy_transfer_config_st transfer_config = { 0 };
    /*短資料紀錄池*/
    transfer_config.p_short_data_record = &short_data_record_t1;
    /*短資料儲存區*/
    transfer_config.p_short_data_store = &short_data_store_t1;

    /*長資料紀錄*/
    transfer_config.p_long_data_record = &long_data_record_t1;
    /*長資料儲存區*/
    transfer_config.p_long_data_store = long_data_store_t1;

    /*ack資料紀錄池*/
    transfer_config.p_ack_record = &ack_record_t1;


    analy_message_transfer_init(&transfer1_insta, &transfer_config);

    /*傳輸2----------------------------------------*/
    memset(&transfer_config, 0, sizeof(transfer_config));

    //*短資料紀錄池*/
    transfer_config.p_short_data_record = &short_data_record_t2;
    /*短資料儲存區*/
    transfer_config.p_short_data_store = &short_data_store_t2;

    /*長資料紀錄*/
   
    /*長資料儲存區*/
   

    /*ack資料紀錄池*/
    transfer_config.p_ack_record = &ack_record_t2;

    analy_message_transfer_init(&transfer2_insta, &transfer_config);

    /*傳輸3----------------------------------------*/
    memset(&transfer_config, 0, sizeof(transfer_config));
    /*短資料紀錄池*/
    transfer_config.p_short_data_record = &short_data_record_t3;
    /*短資料儲存區*/
    transfer_config.p_short_data_store = &short_data_store_t3;

    /*長資料紀錄*/
    transfer_config.p_long_data_record = &long_data_record_t3;
    /*長資料儲存區*/
    transfer_config.p_long_data_store = long_data_store_t3;

    /*ack資料紀錄池*/
    transfer_config.p_ack_record = &ack_record_t3;

    analy_message_transfer_init(&transfer3_insta, &transfer_config);
    /*裝置初始化  DEVICE 1-----------------------------*/
    analy_device_config_st device_config = { 0 };

    device_config.device_id = PC_USB_DEVICE_ID;

    device_config.device_role = ANALY_SELF;
    device_config.p_long_frame_states = &pc_long_frame_states;

    analy_device_init(&device_pc_usb, &device_config);

    /*裝置初始化  DEVICE 2-----------------------------*/
  /*  memset(&device_config, 0, sizeof(device_config));

    device_config.device_id = PC_BLE_DEVICE_ID;

    device_config.device_role = ANALY_SELF;

    analy_device_init(&device_pc_ble, &device_config);*/

    /*裝置初始化  DEVICE 3-----------------------------*/
    memset(&device_config, 0, sizeof(device_config));

    device_config.device_id = BRIDGE_WIRED_DEVICE_ID;

    device_config.device_role = ANALY_OUTSIDE;

    device_config.short_max_len = USB_AND_UART_DATA_MAX;

    device_config.p_path_interface = &usb_instance; //路由接口

    device_config.transfer_handle = &transfer1_insta;//綁定傳輸者  

    device_config.p_frame_control = &nrf_wired_frame_control;

    device_config.package_overtime = 120;//超時重傳 ms

    analy_device_init(&device_nrf_wired, &device_config);

    /*裝置初始化  DEVICE 4-----------------------------*/
    //memset(&device_config, 0, sizeof(device_config));

    //device_config.device_id = BRIDGE_BLE_DEVICE_ID;

    //device_config.device_role = ANALY_OUTSIDE;

    //device_config.short_max_len = BLE_DATA_MAX;

    //device_config.p_path_interface = NULL; ;//路由接口

    //device_config.transfer_handle = &transfer1_insta;//綁定傳輸者 

    //device_config.p_frame_control = &nrf_ble_frame_control;

    //device_config.package_overtime = 200;//超時重傳 ms

    //analy_device_init(&device_nrf_ble, &device_config);


    /*裝置初始化  DEVICE 5-----------------------------*/
    memset(&device_config, 0, sizeof(device_config));

    device_config.device_id = SIMULATOR_DEVICE_ID;

    device_config.device_role = ANALY_OUTSIDE;

    device_config.short_max_len = USB_AND_UART_DATA_MAX;

    device_config.p_path_interface = &usb_instance; ;//路由接口

    device_config.transfer_handle = &transfer1_insta;//綁定傳輸者  

    device_config.p_frame_control = &st_frame_control;

    device_config.package_overtime = 200;//超時重傳 ms

    analy_device_init(&device_st, &device_config);

    /*裝置初始化  DEVICE 6-----------------------------*/
    memset(&device_config, 0, sizeof(device_config));

    device_config.device_id = COMMUNICATOR_DEVICE_ID;

    device_config.device_role = ANALY_OUTSIDE;

    device_config.short_max_len = USB_AND_UART_DATA_MAX;

    device_config.p_path_interface = &usb_instance; ;//路由接口

    device_config.transfer_handle = &transfer3_insta;//綁定傳輸者  

    device_config.p_frame_control = &communi_frame_control;

    device_config.package_overtime = 200;//超時重傳 ms

    analy_device_init(&device_communicator, &device_config);
    /*裝置初始化  DEVICE 8-----------------------------*/
    memset(&device_config, 0, sizeof(device_config));

    device_config.device_id = CAN_BUS_DEVICE_ID;

    device_config.device_role = ANALY_OUTSIDE;

    device_config.short_max_len = USB_AND_UART_DATA_MAX;

    device_config.p_path_interface = &usb_instance; ;//路由接口

    device_config.transfer_handle = &transfer2_insta;//綁定傳輸者  

    device_config.p_frame_control = &can_frame_control;

    device_config.package_overtime = 200;//超時重傳 ms

    analy_device_init(&device_can_bus, &device_config);






    /*系統初始化-----------------------------*/
    analy_sys_init(analy_1ms_tick, &analy_mem_pool);

    /*事件註冊-----------------------------*/
    system_states = 1;
    return 0;
}

static uint32_t analy_soft_interface_notify_register(analyzer_soft_interface_eu select, analy_data_out_notify interface_notify)
{
    if (soft_interface_out_notify[ANALYZER_INTERFACE_USB] == NULL )
        soft_interface_out_notify[ANALYZER_INTERFACE_USB] = interface_notify;
    return 0;
}

uint32_t analy_usb_init(analyzer_soft_interface_st* user_inatance, analy_data_out_notify user_callback)
{
#if ANALY_TICK_TYPE != 0
    sys_old_time = std::chrono::steady_clock::now();
    sys_new_time = sys_old_time;
#endif

    user_inatance->data_out_len = fl_analy_get_usb_sen_buf_len; 
    user_inatance->data_in_handler = fl_analy_usb_data_in;
    user_inatance->data_out_handler = fl_analy_usb_data_out;
    user_inatance->data_clear = fl_analy_usb_data_buf_clear;

    usb_instance.interface_states = ANALYZER_INTERFACE_RUNNING;
    usb_instance.rx_states = ANALYZER_PORT_READY;
    usb_instance.tx_states = ANALYZER_PORT_READY;

    if (user_callback != NULL)
    {
        analy_soft_interface_notify_register(ANALYZER_INTERFACE_USB, user_callback);
        return 0;
    }
    return 1;
}
int32_t analy_get_system_states()
{  
    return system_states;
}

#ifdef __cplusplus
}
#endif


