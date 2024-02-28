#pragma once
#pragma warning(disable:4996)
#pragma warning(disable:26812)
//
#ifndef _FL_CORE_SDK_DEVICE_INFO_H
#define _FL_CORE_SDK_DEVICE_INFO_H



#import <CoreSDKSourceCode/Common.h>
#import <CoreSDKSourceCode/CoreSDK_Common.h>



#define LOG_PRINT_ENABLE 1


// 使用Apple平台時重新定義,包含 MacOS及iOS
#if __APPLE__
#undef LOG_PRINT_ENABLE 
#define LOG_PRINT_ENABLE 0
#endif


#ifdef _WIN32
#define DllExport   __declspec( dllexport )
#else
#define DllExport
#define __stdcall
#endif // _WIN32


#ifdef __cplusplus
extern "C" {
#endif


// 農田電控零件即時狀態定義
struct DllExport FL_Info_st
{
	//當前助力段數
	unsigned int current_assist_lv;
	//系統電源控制狀態
	bool system_power_control;
	//助推控制狀態
	bool walk_assist_control;
	//燈控制狀態
	bool light_control;
	//系統支援的最大助力段數
	unsigned int support_assist_lv;
	//電源鍵狀態
	bool power_key_status;
	//上鍵狀態
	bool up_key_status;
	//下鍵狀態
	bool down_key_status;
	//助推鍵狀態
	bool walk_key_status;
	//燈控制鍵狀態
	bool light_key_status;
	//旅行里程
	float trip_odo;	// Unit:1 km
	//旅行時間
	unsigned int trip_time_sec;
	//旅行平均時速
	float trip_avg_speed;	// Unit:0.1 km/hr
	//旅行最大時速
	float trip_max_speed;	// Unit:0.1 km/hr
	//旅行平均電流
	unsigned int trip_avg_current;	// Unit:1mA
	//旅行最大電流
	unsigned int trip_max_current;	// Unit:1mA
	//旅行平均踏板速度
	unsigned int trip_avg_pedal_speed;	// Unit:RPM
	//旅行最大踏板速度
	unsigned int trip_max_pedal_speed;	// Unit:RPM
	//旅行平均踏板扭矩
	unsigned int trip_avg_pedal_torque; // Unit:1Nm
	//旅行最大踏板扭矩
	unsigned int trip_max_pedal_torque; // Unit:1Nm
	//HMI 當前發送警告碼清單
	unsigned int HMI_warning_list[28];
	//HMI 當前發送警告碼清單長度
	unsigned int HMI_warning_leng;
	//HMI 當前發送錯誤碼清單長度
	unsigned int HMI_error_list[28];
	//HMI 當前發送錯誤碼清單長度
	unsigned int HMI_error_leng;
	//HMI KEY NUMBER 1累積按壓計數次數
	unsigned int key_1_count;
	//HMI KEY NUMBER 2累積按壓計數次數
	unsigned int key_2_count;
	//HMI KEY NUMBER 3累積按壓計數次數
	unsigned int key_3_count;
	//HMI KEY NUMBER 4累積按壓計數次數
	unsigned int key_4_count;
	//HMI KEY NUMBER 5累積按壓計數次數
	unsigned int key_5_count;
	//HMI KEY NUMBER 6累積按壓計數次數
	unsigned int key_6_count;
	//HMI KEY NUMBER 7累積按壓計數次數
	unsigned int key_7_count;
	//HMI KEY NUMBER 8累積按壓計數次數
	unsigned int key_8_count;
	//當前車速
	float bike_speed; // Unit:1Km/hr
	//馬達轉速
	unsigned int motor_speed; 
	//輪轉速
	unsigned int wheel_speed;
	//系統限速
	float limit_speed; // Unit:1Km/hr
	//控制器偵測電壓
	float bus_voltage; 
	//控制器偵測電流
	float avg_bus_current;
	//燈電流
	float light_current;
	//控制器平均輸出百分比
	unsigned int avg_output_amplitube;
	//控制器溫度
	int controller_temperature;
	//油門輸出百分比
	unsigned int throttle_amplitube;
	//踏板轉速
	unsigned int pedal_cadence;
	//踏板扭矩
	float pedal_torque;
	//踏板輸入功率
	float pedal_power;
	//系統累積總里程
	float total_odo;	// Unit:1Km
	//可行駛剩餘里程
	float range_odo;	// Unit:1Km
	//助力等級
	unsigned int assist_level;
	//助力類型
	unsigned int assist_type;
	//當前助力啟動狀態
	bool assist_on;
	//當前前燈輸出狀態
	bool front_light_on;
	//當前尾燈輸出狀態
	bool rear_light_on;
	//當前剎車燈輸出狀態
	bool brake_light_on;
	//是否可控燈
	bool activate_light_ctrl;
	//當前煞車感測觸發狀態
	bool brake_on;
	//當前踏板旋轉方向狀態
	bool candence_direction;
	//當前馬達旋轉方向狀態
	bool motor_direction;
	//控制器當前發送警告碼清單
	unsigned int controller_warning_list[28];
	//控制器當前發送警告碼清單長度
	unsigned int controller_warning_leng;
	//控制器當前發送錯誤碼清單
	unsigned int controller_error_list[28];
	//控制器當前發送錯誤碼清單長度
	unsigned int controller_error_leng;
	//無扭矩電壓值
	unsigned int zero_torque_volt;
	//當前扭矩電壓值
	unsigned int current_torque_volt;
	//無油門電壓值
	unsigned int zero_throttle_volt;
	//當前油門電壓值
	unsigned int current_throttle_volt;
	//即時主線電流
	float actual_bus_current;
	//馬達U相電流
	float u_phase_current;
	//馬達V相電流
	float v_phase_current;
	//馬達W相電流
	float w_phase_current;
	//輪轉動累積圈數
	unsigned int wheel_rotate_laps;
	//控制器輸出百分比
	unsigned int output_amplitude;
	//馬達HALL狀態
	unsigned char hall_state;
	//預估角度扇區狀態
	unsigned char sector_state;
	//當前充電MOSFET啟動狀態
	bool charge_fet;
	//當前是否為充電中
	bool charging;
	//是否已接近滿充電
	bool fully_charged;
	//是否偵測到充電器接入
	bool charge_detected;
	//放電MOSFET狀態
	bool discharge_fet;
	//當前是否為放電中
	bool discharging;
	//電量為低點
	bool nearly_discharged;
	//電量為空
	bool fully_discharged;
	//電池設計電壓值
	unsigned int design_volt;
	//電池設計容量值
	float design_capacity;
	//電池累積循環沖放次數
	unsigned int battery_cycle_count;
	//電池累積未充電天數
	unsigned int battery_uncharged_day;
	//電池當前電壓值
	unsigned int battery_actual_volt;
	//電池當前電流值
	unsigned int battery_actual_current;
	//電池當前溫度值
	signed char battery_temperature;
	//電池當前相對容量
	unsigned int battery_rsoc;
	//電池當前實際容量
	unsigned int battery_asoc;
	//電池當前相對健康度
	unsigned int battery_rsoh;
	//電池當前實際健康度
	unsigned int battery_asoh;
	//系統當前UNIX時間
	unsigned long long sys_unix_time;
	//電池當前發送警告碼清單
	unsigned int battery_warning_list[28];
	//電池當前發送警告碼清單長度
	unsigned int battery_warning_leng;
	//電池當前發送錯誤碼清單
	unsigned int battery_error_list[28];
	//電池當前發送錯誤碼清單長度
	unsigned int battery_error_leng;
	//第1節電芯電壓值
	unsigned int cell_1_volt;	// Unit:1mV
	//第2節電芯電壓值
	unsigned int cell_2_volt;	// Unit:1mV
	//第3節電芯電壓值
	unsigned int cell_3_volt;	// Unit:1mV
	//第4節電芯電壓值
	unsigned int cell_4_volt;	// Unit:1mV
	//第5節電芯電壓值
	unsigned int cell_5_volt;	// Unit:1mV
	//第6節電芯電壓值
	unsigned int cell_6_volt;	// Unit:1mV
	//第7節電芯電壓值
	unsigned int cell_7_volt;	// Unit:1mV
	//第8節電芯電壓值
	unsigned int cell_8_volt;	// Unit:1mV
	//第9節電芯電壓值
	unsigned int cell_9_volt;	// Unit:1mV
	//第10節電芯電壓值
	unsigned int cell_10_volt;	// Unit:1mV
	//第11節電芯電壓值
	unsigned int cell_11_volt;	// Unit:1mV
	//第12節電芯電壓值
	unsigned int cell_12_volt;	// Unit:1mV
	//第13節電芯電壓值
	unsigned int cell_13_volt;	// Unit:1mV
	//第14節電芯電壓值
	unsigned int cell_14_volt;	// Unit:1mV
	//第15節電芯電壓值
	unsigned int cell_15_volt;	// Unit:1mV
	//第16節電芯電壓值
	unsigned int cell_16_volt;	// Unit:1mV
	//第17節電芯電壓值
	unsigned int cell_17_volt;	// Unit:1mV
	//第18節電芯電壓值
	unsigned int cell_18_volt;	// Unit:1mV
	//第19節電芯電壓值
	unsigned int cell_19_volt;	// Unit:1mV
	//第20節電芯電壓值
	unsigned int cell_20_volt;	// Unit:1mV
	//電池溫度感測器1 溫度值
	int battery_temperature_1;
	//電池溫度感測器2 溫度值
	int battery_temperature_2;
	//電池溫度感測器3 溫度值
	int battery_temperature_3;
	//電池溫度感測器4 溫度值
	int battery_temperature_4;
	//電池溫度感測器5 溫度值
	int battery_temperature_5;
	//電池溫度感測器6 溫度值
	int battery_temperature_6;
	//電池溫度感測器7 溫度值
	int battery_temperature_7;
	//電池溫度感測器8 溫度值
	int battery_temperature_8;
	//E Lock當前狀態
	ELockStates e_lock_states;
};

// 麥思系統即時資訊
struct DllExport Mivice_Info_st
{
	// 當前助力段數
	unsigned char current_assist_lv;
	// 最小助力段數
	unsigned char min_assist_lv;
	// 最大助力段數
	unsigned char max_assist_lv;
	// 背光亮度等級
	unsigned char brightness_lv;
	// 顯示單位 0:公制 1:英制
	bool display_unit;
	// 系統電源控制狀態
	bool system_power_control;
	// 當前車速
	float bike_speed;
	// 旅行里程
	unsigned int trip_odo;	// Unit:1 km
	// 旅行時間
	unsigned int trip_time_sec;
	// 旅行平均時速
	float trip_avg_speed;	// Unit:0.1 km/hr
	// 當前車輪轉速
	unsigned int wheel_speed_RPM; // Unit:1Km/hr
	// 最高速限
	unsigned int limit_speed;
	// 控制器偵測電壓
	float bus_voltage; 
	// 控制器偵測電流
	float avg_bus_current;
	// 電機溫度
	int motor_temperature;
	// 控制器溫度
	int controller_temperature;
	// 踏板轉速 unit : 1 RPM
	unsigned int pedal_cadence;
	// 踏板扭矩 unit:0.1 Nm
	float pedal_torque;
	// 騎乘循環數 unit: 1 Cycle
	unsigned int ride_cycle_cnt;
	// 系統累積總里程
	unsigned int total_odo;	// Unit:1Km
	// 輪徑
	float wheel_size;
	// 當前前燈輸出狀態
	bool front_light_on;
	// 當前尾燈輸出狀態
	bool rear_light_on;
	// 當前左轉燈輸出狀態
	bool left_light_on;
	// 當前右轉燈輸出狀態
	bool right_light_on;
	// 當前蜂鳴器輸出狀態 單位:百分比
	unsigned char beep_duty;
	// 當前油門把手角度
	unsigned int throttle_angle;
	// 當前剎車把手角度
	unsigned int brake_angle;
	// 自動休眠時間
	unsigned char auto_sleep_time;
	// 系統當前UNIX時間
	unsigned long long sys_unix_time;
	// 控制器當前發送錯誤碼清單
	unsigned int controller_error_list[28];
	// 控制器當前發送錯誤碼清單長度
	unsigned int controller_error_leng;
	// 電池當前電壓值 mV
	unsigned int batt_volt_mv;
	// 電池當前電量
	unsigned char batt_rsoc;
};


// 萊克系統即時資訊
struct DllExport Lexy_Info_st
{
	// 車輛當前狀態
	unsigned char bike_status;
	// 當前助力段數
	unsigned char current_assist_lv;
	// 剩餘里程
	unsigned char rang_KM;
	// 顯示單位 0:公制 1:英制
	bool display_unit;
	// 當前前燈輸出狀態
	bool front_light_on;
	// 當前尾燈輸出狀態
	bool rear_light_on;
	// 當前車速 單位:KPH
	float bike_speed;
	// 旅行里程 單位:KM
	unsigned int trip_odo;
	// 旅行時間 單位:秒
	unsigned int trip_time_sec;
	// 電機輸出功率 單位:W
	unsigned int motor_power_W;
	// 踏板輸入功率 單位:W
	unsigned int pedal_power_W;
	// 電機電流 單位:A
	float motor_current;
	// 油門電壓 單位:V
	float throttle_volt;
	// 踏板轉速 unit : 1 RPM
	unsigned int pedal_cadence;
	// 踏板扭矩 unit:0.1 Nm
	float pedal_torque;
	

	// 主電池電量百分比
	unsigned char main_batt_rsoc;
	// 主電池健康度
	unsigned char main_batt_soh;
	// 主電池溫度
	char main_batt_temp;
	// 主電池設計容量
	unsigned short main_batt_spec_mAH;
	// 主電池循環次數
	unsigned short main_batt_life_cycle;

	// 副電池電量百分比
	unsigned char slave_1_batt_rsoc;
	// 副電池健康度
	unsigned char slave_1_batt_soh;
	// 副電池溫度
	char slave_1_batt_temp;
	// 副電池設計容量
	unsigned short slave_1_batt_spec_mAH;
	// 副電池循環次數
	unsigned short slave_1_batt_life_cycle;

	// 錯誤碼清單
	unsigned int error_list[28];
	// 錯誤碼清單長度
	unsigned int error_list_leng;

	// 警告碼清單
	unsigned int warning_list[28];
	// 警告碼清單長度
	unsigned int warning_list_leng;


	/* 自動檢測狀態 */
	// HMI CAN通訊檢測狀態
	unsigned char auto_test_status_hmi_can_comm;
	// 光感測偵測器檢測狀態
	unsigned char auto_test_status_light_sensor;
	// 主電池CAN通訊檢測狀態
	unsigned char auto_test_status_mbatt_can_comm;
	// 主電池溫度檢測狀態
	unsigned char auto_test_status_mbatt_temp;
	// 主電池電流檢測狀態
	unsigned char auto_test_status_mbatt_current;
	// 主電池電壓檢測狀態
	unsigned char auto_test_status_mbatt_volt;
	// 主電池Cell壓差檢測狀態
	unsigned char auto_test_status_mbatt_cell_diffvolt;
	// 主電池斷線檢測狀態
	unsigned char auto_test_status_mbatt_disconnect;
	// 主電池壽命檢測狀態
	unsigned char auto_test_status_mbatt_life;
	
	// 副電池CAN通訊檢測狀態
	unsigned char auto_test_status_sbatt1_can_comm;
	// 副電池溫度檢測狀態
	unsigned char auto_test_status_sbatt1_temp;
	// 副電池電流檢測狀態
	unsigned char auto_test_status_sbatt1_current;
	// 副電池電壓檢測狀態
	unsigned char auto_test_status_sbatt1_volt;
	// 副電池Cell壓差檢測狀態
	unsigned char auto_test_status_sbatt1_cell_diffvolt;
	// 副電池斷線檢測狀態
	unsigned char auto_test_status_sbatt1_disconnect;
	// 副電池壽命檢測狀態
	unsigned char auto_test_status_sbatt1_life;

	// Controller CAN通訊檢測狀態
	unsigned char auto_test_status_ctrl_can_comm;
	// 主線電壓檢測狀態
	unsigned char auto_test_status_bus_volt;
	// 控制器溫度檢測狀態
	unsigned char auto_test_status_ctrl_temp;
	// 電機溫度檢測狀態
	unsigned char auto_test_status_motor_temp;
	// 電機相線檢測狀態
	unsigned char auto_test_status_motor_phase_line;

	/* 手動檢測 */
	// HMI 顯示檢測狀態
	unsigned char manual_test_status_hmi_display;
	// HMI 背光檢測狀態
	unsigned char manual_test_status_hmi_bglight;
	// 前燈檢測狀態
	unsigned char manual_test_status_front_light;
	// 油門檢測狀態
	unsigned char manual_test_status_throttle;
	// 剎車檢測狀態
	unsigned char manual_test_status_brake;
	// 速度傳感器檢測狀態
	unsigned char manual_test_status_speed_sensor;
	// 踏板頻率檢測狀態
	unsigned char manual_test_status_pedal_cadence;
	// 踏板力矩檢測狀態
	unsigned char manual_test_status_pedal_torque;
	// 助推檢測狀態
	unsigned char manual_test_status_walk_assist;
	// 霍爾/磁編碼檢測狀態
	unsigned char manual_test_status_rotor_sensor;
};


#ifdef __cplusplus
}
#endif

#endif

