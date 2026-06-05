#pragma once
#pragma warning(disable:4996)
#pragma warning(disable:26812)
//
#ifndef _FL_CORE_SDK_DELEGATE_FUNC_H
#define _FL_CORE_SDK_DELEGATE_FUNC_H

#include <CoreSDKSourceCode/CoreSDK_Common.h>

#ifdef __cplusplus
extern "C" {
#endif

	//無除了狀態以外的參數Callback調用函數類型定義
	typedef void(__stdcall* fpCallback_NoParamReturn)(int return_state);

/********************************************/
/*
*		可委派相關程式定義
*/
/********************************************/
//ReadParameter Callback調用函數類型定義
typedef void(__stdcall* fpCallback_ReadParameters)(int return_state, SDKDeviceType_e target_device, unsigned char* read_buff, unsigned short addr, unsigned short leng, unsigned char bank_index);
//WriteParameters Callback調用函數類型定義
typedef void(__stdcall* fpCallback_WriteParameters)(int return_state, SDKDeviceType_e target_device, unsigned short addr, unsigned short leng, unsigned char bank_index);
//ResetParameters Callback調用函數類型定義
typedef void(__stdcall* fpCallback_ResetParameters)(int return_state, SDKDeviceType_e target_device, unsigned char bank_index);
//GetCanIdBypassList Callback調用函數類型定義
typedef void(__stdcall* fpCallback_GetCanIdBypassList)(int return_state, unsigned char mode, unsigned char id_count, unsigned char* id_list);
//ReadDeviceLogs Callback調用函數類型定義
typedef void(__stdcall* fpCallback_ReadDeviceLogs)(int return_state, SDKDeviceType_e target_device, int start_index, int count, DeviceLogs_T* logs_list);
//GetELock_DEV Callback調用函數類型定義
typedef void(__stdcall* fpCallback_GetELock_DEV)(int return_state, ELockStates now_states);
//UpgradeStateMsg Callback調用函數類型定義,當更新(DFU)進度刷新時自動呼叫
typedef void (__stdcall *UpgradeStateMsg_p)(const char* out_msg, int progress_value);
//CheckScreenAccessCtrl Callback調用函數類型定義
typedef void(__stdcall* fpCallback_SetScreenAccessCtrl)(int return_state, SDKDeviceType_e target_device, int action, int pwd);
//ResetScreenAccessCtrl
typedef void(__stdcall* fpCallback_ResetScreenAccessCtrl)(int return_state, SDKDeviceType_e target_device);

// 可委派程式清單定義
typedef struct DllExport FL_DelegateFuncDefine_st
{
	// 讀取裝置參數數值程式指針
	int (__stdcall *ReadParameters)(RouterType router, SDKDeviceType_e target_device, unsigned short addr, unsigned short leng, unsigned char bank_index, fpCallback_ReadParameters callback);
	// 寫入裝置參數數值程式指針
	int (__stdcall *WriteParameters)(RouterType router, SDKDeviceType_e target_device,	unsigned short addr, unsigned short leng, unsigned char bank_index, unsigned char* data, fpCallback_WriteParameters callback);
	// 重置裝置參數數值程式指針
	int(__stdcall* ResetParameters)(RouterType router, SDKDeviceType_e target_device, unsigned char bank_index, fpCallback_ResetParameters callback);
	// 更新裝置韌體程式指針
	int(__stdcall* UpgradeFirmware)(RouterType router, SDKDeviceType_e target_device, unsigned char* device_MID, unsigned char* data, unsigned int data_size, UpgradeStateMsg_p upgrade_msg_callback, fpCallback_NoParamReturn callback);
	// 設定裝置Debug Mode程式指針
	int(__stdcall* SetDebugMode)(RouterType router, SDKDeviceType_e target_device, unsigned char mode, unsigned char repet_cnt, unsigned short interval_time, fpCallback_NoParamReturn callback);
	// 設定裝置Test Mode程式指針
	int(__stdcall* SetTestMode)(RouterType router, SDKDeviceType_e target_device, unsigned char mode, unsigned int value, fpCallback_NoParamReturn callback);
	// 取得CAN byapss ID 清單程式指針
	int(__stdcall* GetCanIdBypassList)(RouterType router, fpCallback_GetCanIdBypassList callback);
	// 設定CAN bypass 白名單程式指針
	int(__stdcall* SetCanIdBypassAllowList)(RouterType router, unsigned char function_code, unsigned char id_list_count, unsigned char* id_list_data, fpCallback_NoParamReturn callback);
	// 設定CAN bypass 黑名單程式指針
	int(__stdcall* SetCanIdBypassBlockList)(RouterType router, unsigned char function_code, unsigned char id_list_count, unsigned char* id_list_data, fpCallback_NoParamReturn callback);
	// 發送重新啟動裝置指令程式指針
	int(__stdcall* RestartDevice)(RouterType router, SDKDeviceType_e target_device, fpCallback_NoParamReturn callback);
	// 讀取裝置內所儲存的歷史紀錄程式指針
	int(__stdcall* ReadDeviceLogs)(RouterType router, SDKDeviceType_e target_device, int start_index, int count, fpCallback_ReadDeviceLogs callback);
	// 清除裝置內所儲存的歷史紀錄程式指針
	int(__stdcall* ClearDeviceLogs)(RouterType router, SDKDeviceType_e target_device, fpCallback_NoParamReturn callback);
	// 設定系統時間Unix time程式指針 (時區請使用+0)
	int(__stdcall* ConfigSysTime)(RouterType router, SDKDeviceType_e target_device, uint64_t unix_time, fpCallback_NoParamReturn callback);
	// 電子鎖操作指令(Dev版本 非正式版)
	// release = 釋放防誤觸定位閂鎖, 釋放後才能
	// unlocked = 當電子鎖已上鎖時, 使用此指令解鎖
	int(__stdcall* SetELock_DEV)(RouterType router,  bool release, bool unlocked, fpCallback_NoParamReturn callback);
	// 電子鎖當前狀態查詢程式指針
	int(__stdcall* GetELock_DEV)(RouterType router, fpCallback_GetELock_DEV callback);
	// 車燈控制程式指針
	int(__stdcall* LightControl)(RouterType router, light_control_parts  parts, bool on_off, fpCallback_NoParamReturn callback);
	// 清除旅程相關資訊程式指針
	int(__stdcall* ClearTripInfo)(RouterType router, fpCallback_NoParamReturn callback);
	// 設定當前助力等級
	int(__stdcall* SetAssistLV)(RouterType router, unsigned char set_level, fpCallback_NoParamReturn callback);
	// HMI螢幕鎖解/上鎖 action = 1 Lock , action = 2 Unlock
	int(__stdcall* SetScreenAccessCtrl)(RouterType router, SDKDeviceType_e target_device, int action, unsigned char* pwd, fpCallback_SetScreenAccessCtrl callback);
	// 重置HMI螢幕
	int(__stdcall* ResetScreenAccessCtrl)(RouterType router, SDKDeviceType_e target_device, fpCallback_ResetScreenAccessCtrl callback);
} Apple_DelegateFuncDefine_T;

int FL_DelegateMethod_Init(Apple_DelegateFuncDefine_T* Init);

/********************************************/
/*
*		可委派相關程式定義
*/
/********************************************/


//取得區塊資訊內容:
// 總里程(KM)
// 顯示單位(0:公制 1:英制)
// 背光亮度等級(0~2), 自動休眠時間(min 0~255:不休眠)
// 輪徑
// 限速
// 助力檔位取值分布(原廠說明文字)
typedef void(__stdcall* fpCallback_GetBikeInfos)(int return_state, unsigned int odo_km, bool display_unit, cherry_wheel_type wheel_type, unsigned char limit_speed, unsigned char assist_type);

//取得控制器相關版本資訊內容
typedef void(__stdcall* fpCallback_CTRLVersionInfos)(int return_state, CHERRY_BOOT_INFO_T bike_info);

//取得輪徑資訊內容
typedef void(__stdcall* fpCallback_GetWheelSize)(int return_state, unsigned int wheel_inch_0d1, unsigned char magnets);

//取得速限資訊內容
typedef void(__stdcall* fpCallback_SpeedLimitInfos)(int return_state, CHERRY_SPEED_LIMIT_T speed_limit_info);

//各檔位總累積里程
typedef void(__stdcall* fpCallback_TotalODOInfos)(int return_state, CHERRY_ASSIST_LV_ODO_INFO_T odo_info);

//各檔位助力強度
typedef void(__stdcall* fpCallback_AssistPowerInfos)(int return_state, CHERRY_ASSIST_LV_POWER_INFO_T assist_power_info);

//歷史錯誤紀錄清單
typedef void(__stdcall* fpCallback_ErrorHistoryList)(int return_state, CHERRY_ERROR_HSITORY_INFO_T error_hsitory);

//校驗韌體是否可用結果
typedef void(__stdcall* fpCallback_FirmwareCheck)(int return_state, unsigned char target_device, unsigned char check_type, unsigned char check_result);

//傳動參數
typedef void(__stdcall* fpCallback_TransParamsInfos)(int return_state, CHERRY_TRANSMISSION_PARAMETERS_INFO_T trans_params_info);


typedef struct DllExport Cherry_DelegateFuncDefine_st
{
	// 啟用藍芽通訊指令
	int(__stdcall*BTEnable)(fpCallback_NoParamReturn callback);
	// 關機指令
	int(__stdcall*Shutdown)(RouterType router, fpCallback_NoParamReturn callback);
	// 頭燈控制指令
	int(__stdcall*Headlamps)(RouterType router, bool set_on, fpCallback_NoParamReturn callback);
	// 里程設置
	int(__stdcall*SetODO)(RouterType router, unsigned int odo,fpCallback_NoParamReturn callback);
	// 顯示單位設置
	// 0:公制 KPH 1:英制 MPH
	int(__stdcall*SetDisplayUnit)(RouterType router, bool unit_type, fpCallback_NoParamReturn callback);
	// 背光亮度設置
	// 0~2等級
	int(__stdcall*SetBacklightLevel)(RouterType router, unsigned char level, fpCallback_NoParamReturn callback);
	// 清除開機密碼
	int(__stdcall*DisablePassword)(RouterType router, fpCallback_NoParamReturn callback);
	// 助力檔位參照表設置
	int(__stdcall*SetAssistProfile)(RouterType router, CHERRY_ASSIST_PROFILE_TYPE_E profile_type, fpCallback_NoParamReturn callback);
	// 限流設置
	// 單位: 0.5A
	int(__stdcall*SetLimitCurrent)(RouterType router, unsigned char current_current_0d5A, fpCallback_NoParamReturn callback);
	// 系統電壓定義值設置
	// 0:24V 1:36V 2:48V
	int(__stdcall*SetSystemVoltage)(RouterType router, unsigned char voltage_type, fpCallback_NoParamReturn callback);
	// 欠壓保護設置
	// 單位: 0.5V
	int(__stdcall*SetUnderVoltage)(RouterType router, unsigned int voltage, fpCallback_NoParamReturn callback);
	// 設定系統時間Unix time程式指針 (時區請使用+0)
	int(__stdcall*ConfigSysTime)(RouterType router, uint64_t unix_time, fpCallback_NoParamReturn callback);
	// 取得區塊資訊內容: 總里程, 顯示單位, 背光亮度等級, 自動休眠時間, 輪徑, 限速, 助力檔位參照表
	int(__stdcall*BTGetBikeInfos)(fpCallback_GetBikeInfos callback);
	// 檢查裝置韌體是否為可用狀態
	int(__stdcall* FirmwareVaildCheck)(RouterType router, unsigned char target_device, uint8_t check_type, fpCallback_FirmwareCheck callback);
	// 更新裝置韌體, 參數表, 車架號碼都是使用此程序
	int(__stdcall*UpgradeFirmware)(RouterType router, SDKDeviceType_e target_device, unsigned char* file_name, unsigned int file_name_size, 
		unsigned char* data, unsigned int data_size, UpgradeStateMsg_p upgrade_msg_callback, fpCallback_NoParamReturn callback);
	// 讀取控制器相關版本資訊
	int(__stdcall* ReadControllerVersion)(unsigned char target_device, fpCallback_CTRLVersionInfos callback);
	// 自動排程讀取CAN-Bus狀態值:騎乘循環數, 總里程, 騎乘時間, 運行時間
	// 0 = 停止, 單位 = 1ms
	int(__stdcall* AutoReadCANBusRidingRecord)(unsigned int cycle_time);
	// 自動排程讀取CAN-Bus狀態值:Cadence踏板頻率
	// 0 = 停止, 單位 = 1ms
	int(__stdcall* AutoReadCANBusPedalCadence)(unsigned int cycle_time);
	// 自動排程讀取CAN-Bus狀態值:Torque踏板扭矩
	// 0 = 停止, 單位 = 1ms
	int(__stdcall* AutoReadCANBusPedalTorque)(unsigned int cycle_time);
	// 自動排程讀取CAN-Bus狀態值:車速
	// 0 = 停止, 單位 = 1ms
	int(__stdcall* AutoReadCANBusBikeSpeed)(unsigned int cycle_time);
	// 自動排程讀取CAN-Bus狀態值:煞把位置
	// 0 = 停止, 單位 = 1ms
	int(__stdcall* AutoReadCANBusBrake)(unsigned int cycle_time);
	// 自動排程讀取CAN-Bus狀態值:轉把位置
	// 0 = 停止, 單位 = 1ms
	int(__stdcall* AutoReadCANBusThrottle)(unsigned int cycle_time);
	// 自動排程讀取CAN-Bus狀態值:前燈狀態
	// 0 = 停止, 單位 = 1ms
	int(__stdcall* AutoReadCANBusFrontLight)(unsigned int cycle_time);
	// 自動排程讀取CAN-Bus狀態值:後燈狀態
	// 0 = 停止, 單位 = 1ms
	int(__stdcall* AutoReadCANBusRearLight)(unsigned int cycle_time);
	// 自動排程讀取CAN-Bus狀態值:左燈狀態
	// 0 = 停止, 單位 = 1ms
	int(__stdcall* AutoReadCANBusTurnLeftLight)(unsigned int cycle_time);
	// 自動排程讀取CAN-Bus狀態值:右燈狀態
	// 0 = 停止, 單位 = 1ms
	int(__stdcall* AutoReadCANBusTurnRightLight)(unsigned int cycle_time);
	// 自動排程讀取CAN-Bus狀態值:蜂鳴器
	// 0 = 停止, 單位 = 1ms
	int(__stdcall* AutoReadCANBusBee)(unsigned int cycle_time);
	// 自動排程讀取CAN-Bus狀態值:主線電壓
	// 0 = 停止, 單位 = 1ms
	int(__stdcall* AutoReadCANBusBusVoltage)(unsigned int cycle_time);
	// 自動排程讀取CAN-Bus狀態值:電機溫度
	// 0 = 停止, 單位 = 1ms
	int(__stdcall* AutoReadCANBusMotorTemp)(unsigned int cycle_time);
	// 自動排程讀取CAN-Bus狀態值:控制器溫度
	// 0 = 停止, 單位 = 1ms
	int(__stdcall* AutoReadCANBusControllerTemp)(unsigned int cycle_time);
	// 自動排程讀取CAN-Bus狀態值:控制器錯誤碼
	int(__stdcall* AutoReadCANBusControllerError)(unsigned int cycle_time);
	// 自動排程讀取CAN-Bus狀態值:電池電量
	int(__stdcall* AutoReadCANBusBattRSOC)(unsigned int cycle_time);
	// 設定馬達轉至指定轉速
	int(__stdcall* TestModeMotorRun)(RouterType router, unsigned short motor_RPM, fpCallback_NoParamReturn callback);
	// 讀取各檔位累積里程數
	int(__stdcall* GetTotalODO)(RouterType router, fpCallback_TotalODOInfos callback);
	// 寫入輪徑資訊, SDK不進行單位轉換 輪徑如為 10.25 Inch, 此帶入值為 1025
	int(__stdcall* SetWheelSize)(RouterType router, unsigned short wheel_inch_0d01, fpCallback_NoParamReturn callback);
	// 讀取輪徑資訊
	int(__stdcall* GetWheelSize)(RouterType router, fpCallback_GetWheelSize callback);	
	// 寫入單位, 開機時大燈是否啟動
	// 0: KPH, 1: MPH
	int(__stdcall* SetLimitSpeed)(RouterType router, bool unit, bool startup_light_on, fpCallback_NoParamReturn callback);
	// 讀取速限, 單位, 開機自動啟動大燈資訊
	int(__stdcall* GetLimitSpeed)(RouterType router, fpCallback_SpeedLimitInfos callback);
	// 寫入各檔位這立強度
	int(__stdcall* SetAssistPower)(RouterType router, CHERRY_ASSIST_LV_POWER_INFO_T power, fpCallback_NoParamReturn callback);
	// 讀取各檔位這立強度
	int(__stdcall* GetAssistPower)(RouterType router, fpCallback_AssistPowerInfos callback);
	// 讀取歷史錯誤紀錄
	int(__stdcall* GetErrorHistoryList)(RouterType router, SDKDeviceType_e target_device, fpCallback_ErrorHistoryList callback);
	// 讀取傳動參數
	int(__stdcall* GetTransParams)(RouterType router, fpCallback_TransParamsInfos callback);
} Cherry_DelegateFuncDefine_T;


/********************************************/
/*
*		可委派相關程式定義
*/
/********************************************/

typedef struct DllExport Orange_DelegateFuncDefine_st
{
	// 讀取裝置參數數值
	int(__stdcall* ReadParameters)(RouterType router, SDKDeviceType_e target_device, unsigned short addr, unsigned short leng, unsigned char bank_index, fpCallback_ReadParameters callback);
	// 寫入裝置參數數值
	int(__stdcall* WriteParameters)(RouterType router, SDKDeviceType_e target_device, unsigned short addr, unsigned short leng, unsigned char bank_index, unsigned char* data, fpCallback_WriteParameters callback);
	// 重置參數表
	int(__stdcall* ResetDeviceParam)(RouterType router, fpCallback_NoParamReturn callback);
	// 設定車輛狀態
	int(__stdcall* SetBikeStatus)(RouterType router, ORANGE_BIKE_STATUS_E set_status, fpCallback_NoParamReturn callback);
	// 設定手動測試
	int(__stdcall* SetManualTest)(RouterType router, ORANGE_MANUAL_TEST_TYPE_E command, fpCallback_NoParamReturn callback);
	// 讀取電池資訊
	int(__stdcall* ReadBatteryInfo)(RouterType router, fpCallback_NoParamReturn callback);
	// 重置車輛相關設定
	// 0 = 騎乘紀錄
	// 1 = 車輛設置
	// 2 = 保養里程
	int(__stdcall* ResetBikeSettings)(RouterType router, unsigned char reset_type, fpCallback_NoParamReturn callback);
	// 同步時間戳資訊
	int(__stdcall* ConfigSysTime)(RouterType router, uint64_t unix_time, fpCallback_NoParamReturn callback);
	// 設定當前助力等級
	int(__stdcall* ConfigAssistLv)(RouterType router, unsigned char set_lv, fpCallback_NoParamReturn callback);
	// 更新裝置韌體程式指針
	int(__stdcall* UpgradeFirmware)(RouterType router, SDKDeviceType_e target_device, unsigned char* device_MID, unsigned char* data, unsigned int data_size, UpgradeStateMsg_p upgrade_msg_callback, fpCallback_NoParamReturn callback);
} Orange_DelegateFuncDefine_T;



// 非DLL公開程式宣告內容

// 啟用自動讀取狀態處理執行緒
void __stdcall Cherry_AutoReadEnable(void);
// 禁用自動讀取狀態處理執行緒
void __stdcall Cherry_AutoReadDisable(void);
// 重置自動讀取指令狀態
void Cherry_AutoReadStatusReset(void);
// 自動讀取狀態處理執行緒
int __stdcall  Cherry_AutoReadHandler(void);
// 初始化委派相關程序指標
int Cherry_DelegateMethod_Init(Cherry_DelegateFuncDefine_T* Init);


// 初始化委派相關程序指標
int Orange_DelegateMethod_Init(Orange_DelegateFuncDefine_T* Init);
#ifdef __cplusplus
}
#endif

#endif

