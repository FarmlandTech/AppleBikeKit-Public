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

// 螢幕鎖
typedef DllExport enum ScreenLockStates_enum
{
	// Lock
	SCREEN_LOCK_STATE_LOCK = 0,
	// Unlock
	SCREEN_LOCK_STATE_UNLOCK = 1,
	// Disabled
	SCREEN_LOCK_STATE_DISABLE = 2,
	// 未知狀態
	SCREEN_LOCK_STATE_UNKNOW = 255

} ScreenLockStates;


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

// Log等級宣告
typedef DllExport enum log_lv_en
{
	LOG_LV_ERROR = 0U,
	LOG_LV_DEBUG,
	LOG_LV_RD
} LogLevel_E;

// 路由類型定義
typedef DllExport enum RouterType_enum
{
	//藍芽路由
	SDK_ROUTER_BLE = (uint8_t)0,
	//CANBUS路由
	SDK_ROUTER_CANBUS,
	//MST板 USB路由
	SDK_ROUTER_MST_USB,
	//Cherry PCAN USB路由
	SDK_ROUTER_CHERRY_PCAN,
} RouterType;

// 通訊協議類型定義
typedef DllExport enum ProtocolType_enum
{
	SDK_PROTOCOL_APPLE = (uint8_t)0,
	SDK_PROTOCOL_CHERRY,
	SDK_PROTOCOL_ORANGE
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

// Cherry版本序號相關資訊定義
typedef DllExport struct cherry_boot_info_st
{
	uint8_t fw_boot_version[10];
	uint8_t fw_app_version[10];
	uint8_t platform[16];
	uint8_t part_number[16];
	uint8_t serial_num[16];
	uint8_t model_name[8];
	uint8_t project_code[16];
	uint8_t bike_num[32];
	uint8_t bike_model[32];
	uint8_t uid[16];
} CHERRY_BOOT_INFO_T;

// Cherry各段數累積里程
typedef DllExport struct cherry_assist_lv_odo_info_st
{
	uint32_t assist_0_odo;
	uint32_t assist_1_odo;
	uint32_t assist_2_odo;
	uint32_t assist_3_odo;
	uint32_t assist_4_odo;
	uint32_t assist_5_odo;
	uint32_t assist_6_odo;
	uint32_t assist_7_odo;
	uint32_t assist_8_odo;
	uint32_t assist_9_odo;
} CHERRY_ASSIST_LV_ODO_INFO_T;

// Cherry各段數助力強度
// 實際數值範圍應為 0-6(刻度是0.001)
// 顯示百分比的方式為 (設定值 / 6) * 100%
typedef DllExport struct cherry_assist_lv_power_info_st
{
	uint16_t assist_0_power;
	uint16_t assist_1_power;
	uint16_t assist_2_power;
	uint16_t assist_3_power;
	uint16_t assist_4_power;
	uint16_t assist_5_power;
	uint16_t assist_6_power;
	uint16_t assist_7_power;
	uint16_t assist_8_power;
	uint16_t assist_9_power;
} CHERRY_ASSIST_LV_POWER_INFO_T;

// Cherry速限資訊
typedef DllExport struct cherry_preset_combination_st
{
	//助力檔位
	uint8_t assistance_mode;
	//能源檔位
	uint8_t energy_mode;
	//動態檔位
	uint8_t dynamic_mode;

} CHERRY_PRESET_COMBINATION_T;

typedef DllExport struct cherry_speed_limit_st
{
	// 速限值 單位:0.01Km/hr 未轉
	uint32_t speed_limit_0d01;

	CHERRY_PRESET_COMBINATION_T preset_combination[5];

	//總檔位
	uint8_t total_presets;
	//0檔
	uint8_t neutral_gear;
	//助推檔
	uint8_t was_gear;
	//輪徑更改
	uint8_t wheel_diameter;
	//開機大燈
	bool starup_light_on;
	//開機映射檔位
	uint8_t power_up_preset;

	//單位(0-千米kph/時)、(1-英里mph/吋)
	bool unit;
	//語系 0-英文(美國)、1-法語、2-德語、3-荷蘭語、4-西班牙語、5-義大利語、6-葡萄牙語
	uint8_t language;

	// 速度單位 true = MPH, false = KPH
	//bool unit;
	// 開機預設開燈狀態 0:OFF 1:ON
	//bool starup_light_on;

} CHERRY_SPEED_LIMIT_T;

// Cherry歷史故障紀錄
typedef DllExport struct cherry_error_history_item_st
{
	// 索引值
	uint8_t index;
	// 錯誤碼
	uint8_t error_code;
	// 第幾次騎乘循環
	uint16_t ride_cycle;
	// 系統上電到錯誤代碼發生累積時間
	uint16_t power_on_time_sec;
	// 系統上電後累積騎乘距離
	uint16_t power_on_ride_km;
	// 總里程
	uint32_t total_odo;
} CHERRY_ERROR_HSITORY_ITEM_T;

// Cherry歷史故障紀錄表
typedef DllExport struct cherry_error_history_info_st
{
	// 總累積錯誤數量
	uint8_t count;
	// 錯誤紀錄清單
	CHERRY_ERROR_HSITORY_ITEM_T list[10];
} CHERRY_ERROR_HSITORY_INFO_T;

//Cherry傳動參數 
typedef DllExport struct cherry_transmission_parameters_info_st
{
	//牙盤數
	uint16_t chain_wheel;
	//飛輪最大齒數
	uint16_t free_wheel_max;
	//飛輪最小齒數
	uint16_t free_wheel_min;
	//內花鼓最大比率
	uint16_t geared_hub_ratio_max;
	//內花鼓最小比率
	uint16_t geared_hub_ratio_min;

}CHERRY_TRANSMISSION_PARAMETERS_INFO_T;

// Cherry系統電壓定義
typedef DllExport enum cherry_sys_volt_type_enum
{
	CHERRY_SYS_VOLT_24V = (uint8_t)0,
	CHERRY_SYS_VOLT_36V = (uint8_t)1,
	CHERRY_SYS_VOLT_48V = (uint8_t)2,
} CHERRY_SYS_VOLT_TYPE_E;


// Cherry輪徑類型定義
typedef DllExport enum cherry_wheel_type_enum
{
	CHERRY_WHEEL_SIZE_12_INCH = (uint8_t)0,
	CHERRY_WHEEL_SIZE_14_INCH,
	CHERRY_WHEEL_SIZE_16_INCH,
	CHERRY_WHEEL_SIZE_18_INCH,
	CHERRY_WHEEL_SIZE_20_INCH,
	CHERRY_WHEEL_SIZE_22_INCH,
	CHERRY_WHEEL_SIZE_24_INCH,
	CHERRY_WHEEL_SIZE_26_INCH,
	CHERRY_WHEEL_SIZE_27_INCH,
	CHERRY_WHEEL_SIZE_27d5_INCH,
	CHERRY_WHEEL_SIZE_700C,
	CHERRY_WHEEL_SIZE_28_INCH,
	CHERRY_WHEEL_SIZE_29_INCH,
} cherry_wheel_type;

// Cherry助力檔位參照表設置定義
typedef DllExport enum cherry_assist_profile_type_en
{
	CHERRY_ASSIST_PROFILE_0_3 = (uint8_t)0,
	CHERRY_ASSIST_PROFILE_1_3,
	CHERRY_ASSIST_PROFILE_0_5,
	CHERRY_ASSIST_PROFILE_1_5,
	CHERRY_ASSIST_PROFILE_0_9,
	CHERRY_ASSIST_PROFILE_1_9,
} CHERRY_ASSIST_PROFILE_TYPE_E;

// Cherry錯誤代碼
typedef DllExport enum cherry_error_code_en
{
	CHERRY_ERROR_CTRL_OCP = (uint8_t)81,
	CHERRY_ERROR_HALL = (uint8_t)82,
	CHERRY_ERROR_TORQUE = (uint8_t)83,
	CHERRY_ERROR_THROTTLE = (uint8_t)84,
	CHERRY_ERROR_BRAKE = (uint8_t)85,
	CHERRY_ERROR_CTRL_OVP = (uint8_t)86,
	CHERRY_ERROR_CTRL_UVP = (uint8_t)87,
	CHERRY_ERROR_BATT_UVP = (uint8_t)88,
	CHERRY_ERROR_CTRL_OTP = (uint8_t)89,
	CHERRY_ERROR_MOTOR_LOCK = (uint8_t)90,
	CHERRY_ERROR_MOTOR_OTP = (uint8_t)91,
	CHERRY_ERROR_WHEEL_SENSOR = (uint8_t)92,
	CHERRY_ERROR_TRANSMISSION = (uint8_t)93,
	CHERRY_ERROR_BATT = (uint8_t)94,
} CHERRY_ERROR_CODE_E;


// Orange車輛狀態
typedef DllExport enum orange_bike_status_en
{
	ORANGE_BIKE_STATUS_IDLE = (uint8_t)0x01,
	ORANGE_BIKE_STATUS_START_RIDE,
	ORANGE_BIKE_STATUS_RIDING,
	ORANGE_BIKE_STATUS_PAUSE_RIDE,
	ORANGE_BIKE_STATUS_STOP_RIDE,
	ORANGE_BIKE_STATUS_AUTO_TEST,
	ORANGE_BIKE_STATUS_MANUAL_TEST,
	ORANGE_BIKE_STATUS_DFU,
	ORANGE_BIKE_STATUS_DFU_FINISH,
	ORANGE_BIKE_STATUS_OTHER,
} ORANGE_BIKE_STATUS_E;

// Orange自動測試返回狀態值
typedef DllExport enum orange_auto_test_res_type_en
{
	ORANGE_AUTO_TEST_RES_TESTING = (uint8_t)1,
	ORANGE_AUTO_TEST_RES_PASS = (uint8_t)2,
	ORANGE_AUTO_TEST_RES_FAIL = (uint8_t)3,
} ORANGE_AUTO_TEST_RES_E;

// Orange手動測試指令
typedef DllExport enum orange_manual_test_type_en
{
	ORANGE_MANUAL_TEST_PEDAL_CADENCE = (uint16_t)0x0001,
	ORANGE_MANUAL_TEST_PEDAL_TORQUE = (uint16_t)0x0002,
	ORANGE_MANUAL_TEST_SPEED_SENSOR = (uint16_t)0x0004,
	ORANGE_MANUAL_TEST_BRAKE_SENSOR = (uint16_t)0x0008,
	ORANGE_MANUAL_TEST_THROTTLE = (uint16_t)0x0010,
	ORANGE_MANUAL_TEST_FRONT_LIGHT = (uint16_t)0x0020,
	ORANGE_MANUAL_TEST_HMI_BGLIGHT = (uint16_t)0x0040,
	ORANGE_MANUAL_TEST_HMI_DISP = (uint16_t)0x0080,
	ORANGE_MANUAL_TEST_ROTOR_SENSOR = (uint16_t)0x0100,
	ORANGE_MANUAL_TEST_WALK_ASSIST = (uint16_t)0x0200,
} ORANGE_MANUAL_TEST_TYPE_E;

// Orange手動測試返回狀態值
typedef DllExport enum orange_manual_test_res_type_en
{
	ORANGE_MANUAL_TEST_RES_REQ = (uint8_t)1,
	ORANGE_MANUAL_TEST_RES_TESTING = (uint8_t)2,
	ORANGE_MANUAL_TEST_RES_PASS = (uint8_t)3,
	ORANGE_MANUAL_TEST_RES_FAIL = (uint8_t)4,
} ORANGE_MANUAL_TEST_RES_E;





#ifdef __cplusplus
}
#endif

#endif

