#pragma once
#pragma warning(disable:4996)
#pragma warning(disable:26812)
//
#ifndef _FL_CORE_SDK_COMMON_H
#define _FL_CORE_SDK_COMMON_H


#import <CoreSDKSourceCode/Common.h>


#ifdef __cplusplus
extern "C" {
#endif


//參數暫存記憶體大小(勿任意改動)
#define PARAMETER_ARR_SIZE	4096


//SDK回傳碼定義
enum DllExport SDKReturnCode
{
	//操作成功
	SDK_RETURN_SUCCESS = 0U,
	//操作逾時
	SDK_RETURN_TIMEOUT,
	//非法的位址
	SDK_RETURN_INVALID_ADDR,
	//非法的長度
	SDK_RETURN_INVALID_SIZE,
	//非法的參數
	SDK_RETURN_INVALID_PARAM,
	//校驗碼錯誤
	SDK_RETURN_CRC_FAIL,
	//數值異常未定義
	SDK_RETURN_NULL,
	//尚未初始化
	SDK_RETURN_NO_INIT,
	//記憶體空間不足
	SDK_RETURN_NO_MEM,
	//已有相同操作
	SDK_RETURN_ALREADY_EXIST,
};


// E Lock狀態類型定義
typedef DllExport enum ELockStates_enum
{
	// 未上鎖
	ELOCK_STATES_UNLOCKED = (uint8_t)0,
	// 環形鎖上鎖
	ELOCK_STATES_RING_LOCK,
	// 插銷鎖上鎖
	ELOCK_STATES_LATCH_LOCK,
	// 全上鎖
	ELOCK_STATES_ALL_LOCK,
	// 未知狀態或無法讀取到狀態
	ELOCK_STATES_UNKNOW
} ELockStates;


//裝置類型定義
typedef DllExport enum DeviceType_enum
{
	SDK_FL_HMI = 1U,
	SDK_FL_CONTROLLER,
	SDK_FL_MAIN_BATT,
	SDK_FL_SUB_BATT1,
	SDK_FL_SUB_BATT2,
	SDK_FL_DISPLAY,
	SDK_FL_IOT,
	SDK_FL_E_DERAILLEUR,
	SDK_FL_E_LOCK,
	SDK_FL_DONGLE,
	SDK_UNKNOWN = 255U
} SDKDeviceType_e;

// 路由類型定義
typedef DllExport enum RouterType_enum
{
	//藍芽路由
	SDK_ROUTER_BLE = (uint8_t)0,
	//CANBUS路由
	SDK_ROUTER_CANBUS,
	//MST板 USB路由
	SDK_ROUTER_MST_USB,
	//麥思 PCAN USB路由
	SDK_ROUTER_MIVICE_PCAN,
} RouterType;

// 通訊協議類型定義
typedef DllExport enum ProtocolType_enum
{
	//農田協議
	SDK_PROTOCOL_FL = (uint8_t)0,
	//麥思協議
	SDK_PROTOCOL_MI,
	//萊克協議
	SDK_PROTOCOL_LX
} ProtocolType;

// 燈號控制
typedef DllExport enum light_control_enum
{
	//前燈
	LIGHT_CONTROL_FRONT = (uint8_t)0,
	//後燈
	LIGHT_CONTROL_REAR
} light_control_parts;


// ReadParameter讀取回傳結構定義
typedef DllExport struct fReadParameter_Params_st
{
	//資料
	unsigned char data[PARAMETER_ARR_SIZE];
	//位址
	unsigned int addr;
	//長度
	unsigned int leng;
	//區塊
	unsigned char bank_index;
	//裝置類別
	SDKDeviceType_e device_type;
} fReadParameter_Params_T;

// 裝置紀錄格式宣告
typedef DllExport struct DeviceLogs_st
{
	// 引索值
	unsigned int index;
	// 紀錄日期時間
	unsigned char dateTime_year;
	unsigned char dateTime_month;
	unsigned char dateTime_days;
	unsigned char dateTime_hour;
	unsigned char dateTime_minute;
	unsigned char dateTime_senond;
	// 里程
	unsigned int odo;
	// 電池狀態
	bool charge_fet_on;
	bool charging;
	bool fully_charged;
	bool charge_detected;
	bool discharge_fet;
	bool discharging;
	bool nearly_discharged;
	bool fully_discharged;
	// 錯誤代碼清單
	unsigned char error_code[8];
	// 電芯數量
	unsigned char cell_count;
	// 電芯電壓
	unsigned int cell_volt[16];
	// 溫度感測數量
	unsigned char temp_sensor_count;
	// 溫度值
	char temp_sensor[3];
	// 車速
	unsigned short bike_speed;
	// 馬達轉速
	unsigned short motor_speed;
	// 電池電量
	unsigned char RSOC;
	// 助力等級
	unsigned char assist_lv;
	// 控制器平均輸出
	unsigned char controller_avg_output;
	// 單筆校驗碼
	unsigned char crc8;
} DeviceLogs_T;

// 麥思系統電壓定義
typedef enum mivice_sys_volt_type_enum
{
	MIVICE_SYS_VOLT_24V = (uint8_t)0,
	MIVICE_SYS_VOLT_36V = (uint8_t)1,
	MIVICE_SYS_VOLT_48V = (uint8_t)2,
} MIVICE_SYS_VOLT_TYPE_E;


// 麥思輪徑類型定義
typedef DllExport enum mivice_wheel_type_enum
{
	MIVICE_WHEEL_SIZE_12_INCH = (uint8_t)0,
	MIVICE_WHEEL_SIZE_14_INCH,
	MIVICE_WHEEL_SIZE_16_INCH,
	MIVICE_WHEEL_SIZE_18_INCH,
	MIVICE_WHEEL_SIZE_20_INCH,
	MIVICE_WHEEL_SIZE_22_INCH,
	MIVICE_WHEEL_SIZE_24_INCH,
	MIVICE_WHEEL_SIZE_26_INCH,
	MIVICE_WHEEL_SIZE_27_INCH,
	MIVICE_WHEEL_SIZE_27d5_INCH,
	MIVICE_WHEEL_SIZE_700C,
	MIVICE_WHEEL_SIZE_28_INCH,
	MIVICE_WHEEL_SIZE_29_INCH,
} mivice_wheel_type;

// 麥思助力檔位參照表設置定義
typedef DllExport enum mivice_assist_profile_type_en
{
	MIVICE_ASSIST_PROFILE_0_3 = (uint8_t)0,
	MIVICE_ASSIST_PROFILE_1_3,
	MIVICE_ASSIST_PROFILE_0_5,
	MIVICE_ASSIST_PROFILE_1_5,
	MIVICE_ASSIST_PROFILE_0_9,
	MIVICE_ASSIST_PROFILE_1_9,
} MIVICE_ASSIST_PROFILE_TYPE_E;

// 萊克車輛狀態
typedef DllExport enum lexy_bike_status_en
{
	LEXY_BIKE_STATUS_IDLE = (uint8_t)0x01,
	LEXY_BIKE_STATUS_START_RIDE,
	LEXY_BIKE_STATUS_RIDING,
	LEXY_BIKE_STATUS_PAUSE_RIDE,
	LEXY_BIKE_STATUS_STOP_RIDE,
	LEXY_BIKE_STATUS_ERROR,
	LEXY_BIKE_STATUS_AUTO_TEST,
	LEXY_BIKE_STATUS_MANUAL_TEST,
	LEXY_BIKE_STATUS_CHARGING,
	LEXY_BIKE_STATUS_DFU,
	LEXY_BIKE_STATUS_OTHER,
} LEXY_BIKE_STATUS_E;

// 萊克自動測試返回狀態值
typedef DllExport enum lexy_auto_test_res_type_en
{
	LEXY_AUTO_TEST_RES_TESTING = (uint8_t)1,
	LEXY_AUTO_TEST_RES_PASS = (uint8_t)2,
	LEXY_AUTO_TEST_RES_FAIL = (uint8_t)3,
} LEXY_AUTO_TEST_RES_E;

// 萊克手動測試指令
typedef DllExport enum lexy_manual_test_type_en
{
	LEXY_MANUAL_TEST_PEDAL_CADENCE = (uint16_t)0x0001,
	LEXY_MANUAL_TEST_PEDAL_TORQUE = (uint16_t)0x0002,
	LEXY_MANUAL_TEST_SPEED_SENSOR = (uint16_t)0x0004,
	LEXY_MANUAL_TEST_BRAKE_SENSOR = (uint16_t)0x0008,
	LEXY_MANUAL_TEST_THROTTLE = (uint16_t)0x0010,
	LEXY_MANUAL_TEST_FRONT_LIGHT = (uint16_t)0x0020,
	LEXY_MANUAL_TEST_HMI_BGLIGHT = (uint16_t)0x0040,
	LEXY_MANUAL_TEST_HMI_DISP = (uint16_t)0x0080,
	LEXY_MANUAL_TEST_ROTOR_SENSOR = (uint16_t)0x0100,
	LEXY_MANUAL_TEST_WALK_ASSIST = (uint16_t)0x0200,
} LEXY_MANUAL_TEST_TYPE_E;

// 萊克手動測試返回狀態值
typedef DllExport enum lexy_manual_test_res_type_en
{
	LEXY_MANUAL_TEST_RES_REQ = (uint8_t)1,
	LEXY_MANUAL_TEST_RES_TESTING = (uint8_t)2,
	LEXY_MANUAL_TEST_RES_PASS = (uint8_t)3,
	LEXY_MANUAL_TEST_RES_FAIL = (uint8_t)4,
} LEXY_MANUAL_TEST_RES_E;

#ifdef __cplusplus
}
#endif

#endif

