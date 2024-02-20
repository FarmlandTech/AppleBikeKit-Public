#pragma once
#pragma warning(disable:4996)
#pragma warning(disable:26812)
//
#ifndef _FL_CORE_SDK_H // include guard
#define _FL_CORE_SDK_H

  
#import <CoreSDKSourceCode/lib_event_scheduler.h>
#import <CoreSDKSourceCode/FL_CANInfoStruct.h>
#import <CoreSDKSourceCode/Common.h>
#import <CoreSDKSourceCode/CAN_ISO_TP.h>
#import <CoreSDKSourceCode/FL_Logs.h>


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

#define SDK_PARAM_VERIFY_NULL(_param_) if(_param_==NULL){ return SDK_RETURN_NULL;}


	// E Lock狀態類型定義
	typedef DllExport enum ELockStates_enum
	{
		// 未上鎖
		ELOCK_STATES_UNLOCKED = 0U,
		// 環形鎖上鎖
		ELOCK_STATES_RING_LOCK,
		// 插銷鎖上鎖
		ELOCK_STATES_LATCH_LOCK,
		// 全上鎖
		ELOCK_STATES_ALL_LOCK,
		// 未知狀態或無法讀取到狀態
		ELOCK_STATES_UNKNOW
	} ELockStates;

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
		SDK_ROUTER_BLE = 0U,
		//CANBUS路由
		SDK_ROUTER_CANBUS,
		//MST板 USB路由
		SDK_ROUTER_MST_USB,
	} RouterType;

	typedef DllExport enum light_control_enum
	{
		//前燈
		LIGHT_CONTROL_FRONT = 0,
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

	typedef DllExport struct DeviceLogs_st
	{
		unsigned int index;
		unsigned char dateTime_year;
		unsigned char dateTime_month;
		unsigned char dateTime_days;
		unsigned char dateTime_hour;
		unsigned char dateTime_minute;
		unsigned char dateTime_senond;
		unsigned int odo;

		bool charge_fet_on;
		bool charging;
		bool fully_charged;
		bool charge_detected;
		bool discharge_fet;
		bool discharging;
		bool nearly_discharged;
		bool fully_discharged;

		unsigned char error_code[8];
		unsigned char cell_count;
		unsigned int cell_volt[16];
		unsigned char temp_sensor_count;
		char temp_sensor[3];
		unsigned short bike_speed;
		unsigned short motor_speed;
		unsigned char RSOC;
		unsigned char assist_lv;
		unsigned char controller_avg_output;

	} DeviceLogs_T;

	//系統零件即時狀態定義
	typedef DllExport struct DeviceInfoDefine
	{
		//農田電控系統
		struct FL_Info_st FL;

	}DeviceInformation_T;

	//ReadParameter Callback調用函數類型定義
	typedef void(__stdcall* fpCallback_ReadParameters)(int return_state, SDKDeviceType_e target_device, unsigned char* read_buff, unsigned short addr, unsigned short leng, unsigned char bank_index);
	//WriteParameters Callback調用函數類型定義
	typedef void(__stdcall* fpCallback_WriteParameters)(int return_state, SDKDeviceType_e target_device, unsigned short addr, unsigned short leng, unsigned char bank_index);
	//ResetParameters Callback調用函數類型定義
	typedef void(__stdcall* fpCallback_ResetParameters)(int return_state, SDKDeviceType_e target_device, unsigned char bank_index);
	//UpgradeFirmware Callback調用函數類型定義
	typedef void(__stdcall* fpCallback_UpgradeFirmware)(int return_state);
	//SetDebugMode Callback調用函數類型定義
	typedef void(__stdcall* fpCallback_SetDebugMode)(int return_state);
	//SetTestMode Callback調用函數類型定義
	typedef void(__stdcall* fpCallback_SetTestMode)(int return_state);
	//GetCanIdBypassList Callback調用函數類型定義
	typedef void(__stdcall* fpCallback_GetCanIdBypassList)(int return_state, unsigned char mode, unsigned char id_count, unsigned char* id_list);
	//SetCanIdBypassAllowList Callback調用函數類型定義
	typedef void(__stdcall* fpCallback_SetCanIdBypassAllowList)(int return_state);
	//SetCanIdBypassBlockList Callback調用函數類型定義
	typedef void(__stdcall* fpCallback_SetCanIdBypassBlockList)(int return_state);
	//RestartDevice Callback調用函數類型定義
	typedef void(__stdcall* fpCallback_RestartDevice)(int return_state);
	//ReadDeviceLogs Callback調用函數類型定義
	typedef void(__stdcall* fpCallback_ReadDeviceLogs)(int return_state, SDKDeviceType_e target_device, DeviceLogs_T* logs_list, int logs_leng);
	//ClearDeviceLogs Callback調用函數類型定義
	typedef void(__stdcall* fpCallback_ClearDeviceLogs)(int return_state);
	//ConfigSysTime Callback調用函數類型定義
	typedef void(__stdcall* fpCallback_ConfigSysTime)(int return_state);
	//SetELock_DEV Callback調用函數類型定義
	typedef void(__stdcall* fpCallback_SetELock_DEV)(int return_state);
	//GetELock_DEV Callback調用函數類型定義
	typedef void(__stdcall* fpCallback_GetELock_DEV)(int return_state, ELockStates now_states);
	//UpgradeStateMsg Callback調用函數類型定義,當更新(DFU)進度刷新時自動呼叫
	typedef void (__stdcall *UpgradeStateMsg_p)(const char* out_msg, int progress_value);
	//Light control Callback調用函數類型定義
	typedef void(__stdcall* fpCallback_LightControl)(int return_state);
	//Trip info clear Callback調用函數類型定義
	typedef void(__stdcall* fpCallback_ClearTripInfo)(int return_state); 
	 
	 
	typedef struct DllExport DelegateFuncDefine_st
	{
		// 讀取裝置參數數值
		int (__stdcall *ReadParameters)(RouterType router, SDKDeviceType_e target_device, unsigned short addr, unsigned short leng, unsigned char bank_index, fpCallback_ReadParameters callback);
		// 寫入裝置參數數值
		int (__stdcall *WriteParameters)(RouterType router, SDKDeviceType_e target_device,	unsigned short addr, unsigned short leng, unsigned char bank_index, unsigned char* data, fpCallback_WriteParameters callback);
		// 重置裝置參數數值
		int(__stdcall* ResetParameters)(RouterType router, SDKDeviceType_e target_device, unsigned char bank_index, fpCallback_ResetParameters callback);
		// 更新裝置韌體		
		int(__stdcall* UpgradeFirmware)(RouterType router, SDKDeviceType_e target_device, unsigned char* device_MID, unsigned char* data, unsigned int data_size, UpgradeStateMsg_p upgrade_msg_callback, fpCallback_UpgradeFirmware callback);
		// 設定裝置Debug Mode
		int(__stdcall* SetDebugMode)(RouterType router, SDKDeviceType_e target_device, unsigned char mode, unsigned char repet_cnt, unsigned short interval_time, fpCallback_SetDebugMode callback);
		// 設定裝置Test Mode
		int(__stdcall* SetTestMode)(RouterType router, SDKDeviceType_e target_device, unsigned char mode, unsigned int value, fpCallback_SetTestMode callback);
		// 取得CAN byapss ID 清單
		int(__stdcall* GetCanIdBypassList)(RouterType router, fpCallback_GetCanIdBypassList callback);
		// 設定CAN bypass 白名單
		int(__stdcall* SetCanIdBypassAllowList)(RouterType router, unsigned char function_code, unsigned char id_list_count, unsigned char* id_list_data, fpCallback_SetCanIdBypassAllowList callback);
		// 設定CAN bypass 黑名單
		int(__stdcall* SetCanIdBypassBlockList)(RouterType router, unsigned char function_code, unsigned char id_list_count, unsigned char* id_list_data, fpCallback_SetCanIdBypassBlockList callback);
		// 發送重新啟動裝置指令
		int(__stdcall* RestartDevice)(RouterType router, SDKDeviceType_e target_device, fpCallback_RestartDevice callback);
		// 讀取裝置內所儲存的歷史紀錄
		int(__stdcall* ReadDeviceLogs)(RouterType router, SDKDeviceType_e target_device, fpCallback_ReadDeviceLogs callback);
		// 清除裝置內所儲存的歷史紀錄
		int(__stdcall* ClearDeviceLogs)(RouterType router, SDKDeviceType_e target_device, fpCallback_ClearDeviceLogs callback);
		// Unix time 時區請使用+0
		int(__stdcall* ConfigSysTime)(RouterType router, SDKDeviceType_e target_device, uint64_t unix_time, fpCallback_ConfigSysTime callback);
		// 電子鎖操作指令(Dev版本 非正式版)
		// release = 釋放防誤觸定位閂鎖, 釋放後才能
		// unlocked = 當電子鎖已上鎖時, 使用此指令解鎖
		int(__stdcall* SetELock_DEV)(RouterType router,  bool release, bool unlocked, fpCallback_SetELock_DEV callback);
		// 電子鎖當前狀態查詢
		int(__stdcall* GetELock_DEV)(RouterType router, fpCallback_GetELock_DEV callback);
		// 車燈控制
		int(__stdcall* LightControl)(RouterType router, light_control_parts  parts, bool on_off, fpCallback_LightControl callback);
		// 清除TRIP Info
		int(__stdcall* ClearTripInfo)(RouterType router, fpCallback_ClearTripInfo  callback);


	} DelegateFuncDefine_T;

	//SDK接收及發送外部封包指令集
	typedef struct DllExport MethodDefine_st
	{
		//CAN Bus封包輸入
		int(__stdcall* CANBusPacket_IN)(unsigned int can_id, bool is_extender_id, unsigned char* raw_data, unsigned int leng);
		//CAN Bus封包輸出
		int(__stdcall *CANBusPacket_OUT)(unsigned int* can_id, bool* is_extender_id, unsigned char* data, unsigned int* leng);
		//藍芽指令 Bus封包輸入
		int(__stdcall* BLECommandPacket_IN)(unsigned char* data, unsigned int leng);
		//藍芽指令 Bus封包輸出
		int(__stdcall* BLECommandPacket_OUT)(unsigned char* data, unsigned int* leng);
		//藍芽資料 Bus封包輸入
		int(__stdcall* BLEDataPacket_IN)(unsigned char* data, unsigned int leng);
		//藍芽資料 Bus封包輸出
		int(__stdcall* BLEDataPacket_OUT)(unsigned char* data, unsigned int* leng);
	} MethodDefine_T;

	//MST Sdk 選項
	typedef struct DllExport MstSdkConfig_st
	{
		//啟用MST 初始化
		bool initEnable;
		//DFU 開啟功能
		bool dfuEnable;
		//Parameter 開啟功能
		bool paraEnable;
	}MstSdkConfig_T;

	typedef DllExport struct FLCoreSDK_st
	{
		//電控系統當前狀態資訊
		DeviceInformation_T DeviceInfo;
		//暫存的參數記憶體位址, 外部請勿直接調用
		unsigned char ParametersArray[PARAMETER_ARR_SIZE];
		//SDK版本資訊, String類型
		unsigned char Version[20];
		//啟用SDK Thread
		int (__stdcall *Enable)(void);
		//禁用SDK Thread
		int (__stdcall *Disable)(void);
		//當前資訊更新通知
		void(__stdcall *InfoUpdateEvent)(DeviceInformation_T DeviceInfo);
		//SDK接收及發送外部封包指令集
		MethodDefine_T Method;
		//委派SDK執行功能
		DelegateFuncDefine_T DelegateMethod;
		//SDK Thread迴圈休眠設定值: us = 0.001 ms = 0.000001 Sec
		int ThreadSleepInterval_us;
		MstSdkConfig_T MstSdkConfig;
	} CoreSDKInst_T;

	//初始化SDK功能
	DllExport int FarmLandCoreSDK_Init(CoreSDKInst_T* SDK_Inst);
	int __stdcall CANBusPacket_IN(unsigned int can_id, bool is_extender_id, unsigned char* raw_data, unsigned int leng);


#ifdef __cplusplus
}
#endif

#endif

