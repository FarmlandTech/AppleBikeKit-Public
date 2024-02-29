#pragma once
#pragma warning(disable:4996)
#pragma warning(disable:26812)
//
#ifndef _FL_CORE_SDK_DELEGATE_FUNC_H
#define _FL_CORE_SDK_DELEGATE_FUNC_H



#import <CoreSDKSourceCode/Common.h>
#import <CoreSDKSourceCode/CoreSDK_Common.h>



#ifdef __cplusplus
extern "C" {
#endif

	//無除了狀態以外的參數Callback調用函數類型定義
	typedef void(__stdcall* fpCallback_NoParamReturn)(int return_state);

/********************************************/
/*
*		農田可委派相關程式定義
*/
/********************************************/
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
typedef void(__stdcall* fpCallback_ReadDeviceLogs)(int return_state, SDKDeviceType_e target_device, int start_index, int count, DeviceLogs_T* logs_list);
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

// 農田可委派程式清單定義
typedef struct DllExport FL_DelegateFuncDefine_st
{
	// 讀取裝置參數數值程式指針
	int (__stdcall *ReadParameters)(RouterType router, SDKDeviceType_e target_device, unsigned short addr, unsigned short leng, unsigned char bank_index, fpCallback_ReadParameters callback);
	// 寫入裝置參數數值程式指針
	int (__stdcall *WriteParameters)(RouterType router, SDKDeviceType_e target_device,	unsigned short addr, unsigned short leng, unsigned char bank_index, unsigned char* data, fpCallback_WriteParameters callback);
	// 重置裝置參數數值程式指針
	int(__stdcall* ResetParameters)(RouterType router, SDKDeviceType_e target_device, unsigned char bank_index, fpCallback_ResetParameters callback);
	// 更新裝置韌體程式指針
	int(__stdcall* UpgradeFirmware)(RouterType router, SDKDeviceType_e target_device, unsigned char* device_MID, unsigned char* data, unsigned int data_size, UpgradeStateMsg_p upgrade_msg_callback, fpCallback_UpgradeFirmware callback);
	// 設定裝置Debug Mode程式指針
	int(__stdcall* SetDebugMode)(RouterType router, SDKDeviceType_e target_device, unsigned char mode, unsigned char repet_cnt, unsigned short interval_time, fpCallback_SetDebugMode callback);
	// 設定裝置Test Mode程式指針
	int(__stdcall* SetTestMode)(RouterType router, SDKDeviceType_e target_device, unsigned char mode, unsigned int value, fpCallback_SetTestMode callback);
	// 取得CAN byapss ID 清單程式指針
	int(__stdcall* GetCanIdBypassList)(RouterType router, fpCallback_GetCanIdBypassList callback);
	// 設定CAN bypass 白名單程式指針
	int(__stdcall* SetCanIdBypassAllowList)(RouterType router, unsigned char function_code, unsigned char id_list_count, unsigned char* id_list_data, fpCallback_SetCanIdBypassAllowList callback);
	// 設定CAN bypass 黑名單程式指針
	int(__stdcall* SetCanIdBypassBlockList)(RouterType router, unsigned char function_code, unsigned char id_list_count, unsigned char* id_list_data, fpCallback_SetCanIdBypassBlockList callback);
	// 發送重新啟動裝置指令程式指針
	int(__stdcall* RestartDevice)(RouterType router, SDKDeviceType_e target_device, fpCallback_RestartDevice callback);
	// 讀取裝置內所儲存的歷史紀錄程式指針
	int(__stdcall* ReadDeviceLogs)(RouterType router, SDKDeviceType_e target_device, int start_index, int count, fpCallback_ReadDeviceLogs callback);
	// 清除裝置內所儲存的歷史紀錄程式指針
	int(__stdcall* ClearDeviceLogs)(RouterType router, SDKDeviceType_e target_device, fpCallback_ClearDeviceLogs callback);
	// 設定系統時間Unix time程式指針 (時區請使用+0)
	int(__stdcall* ConfigSysTime)(RouterType router, SDKDeviceType_e target_device, uint64_t unix_time, fpCallback_ConfigSysTime callback);
	// 電子鎖操作指令(Dev版本 非正式版)
	// release = 釋放防誤觸定位閂鎖, 釋放後才能
	// unlocked = 當電子鎖已上鎖時, 使用此指令解鎖
	int(__stdcall* SetELock_DEV)(RouterType router,  bool release, bool unlocked, fpCallback_SetELock_DEV callback);
	// 電子鎖當前狀態查詢程式指針
	int(__stdcall* GetELock_DEV)(RouterType router, fpCallback_GetELock_DEV callback);
	// 車燈控制程式指針
	int(__stdcall* LightControl)(RouterType router, light_control_parts  parts, bool on_off, fpCallback_LightControl callback);
	// 清除旅程相關資訊程式指針
	int(__stdcall* ClearTripInfo)(RouterType router, fpCallback_ClearTripInfo  callback);
	// 設定當前助力等級
	int(__stdcall* SetAssistLV)(RouterType router, unsigned char set_level, fpCallback_NoParamReturn callback);
} FL_DelegateFuncDefine_T;

int FL_DelegateMethod_Init(FL_DelegateFuncDefine_T* Init);

/********************************************/
/*
*		麥思可委派相關程式定義
*/
/********************************************/


//取得區塊資訊內容:
// 總里程(KM)
// 顯示單位(0:公制 1:英制)
// 背光亮度等級(0~2), 自動休眠時間(min 0~255:不休眠)
// 輪徑
// 限速
// 助力檔位取值分布(原廠說明文字)
typedef void(__stdcall* fpCallback_GetBikeInfos)(int return_state, unsigned int odo_km, bool display_unit, mivice_wheel_type wheel_type, unsigned char limit_speed, unsigned char assist_type);

//取得控制器相關版本資訊內容
typedef void(__stdcall* fpCallback_CTRLVersionInfos)(int return_state);



typedef struct DllExport Mivice_DelegateFuncDefine_st
{
	// 以下指令當前提供的藍芽協議(麥思 Display BT Protocol V2)中才有明確定義具備
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
	// 輪徑設置
	int(__stdcall*SetWheelSizeType)(RouterType router, mivice_wheel_type type, fpCallback_NoParamReturn callback);
	// 限速設置
	int(__stdcall*SetLimitSpeed)(RouterType router, unsigned char speed_km, fpCallback_NoParamReturn callback);
	// 助力檔位參照表設置
	int(__stdcall*SetAssistProfile)(RouterType router, MIVICE_ASSIST_PROFILE_TYPE_E profile_type, fpCallback_NoParamReturn callback);
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
	// 讀取裝置參數數值
	// 目前版本未實作功能
	int (__stdcall*ReadParameters)(RouterType router, SDKDeviceType_e target_device, unsigned short addr, unsigned short leng, unsigned char bank_index, fpCallback_ReadParameters callback);
	// 寫入裝置參數數值
	// 目前版本未實作功能
	int (__stdcall*WriteParameters)(RouterType router, SDKDeviceType_e target_device,	unsigned short addr, unsigned short leng, unsigned char bank_index, unsigned char* data, fpCallback_WriteParameters callback);
	// 重置裝置參數數值
	// 目前版本未實作功能
	int(__stdcall*ResetParameters)(RouterType router, SDKDeviceType_e target_device, unsigned char bank_index, fpCallback_ResetParameters callback);
	// 更新裝置韌體
	int(__stdcall*UpgradeFirmware)(RouterType router, SDKDeviceType_e target_device, unsigned char* device_MID, unsigned char* data, unsigned int data_size, UpgradeStateMsg_p upgrade_msg_callback, fpCallback_UpgradeFirmware callback);
	// 讀取控制器相關版本資訊
	int(__stdcall* ReadControllerVersion)(fpCallback_CTRLVersionInfos callback);
	// 自動排程讀取CAN-Bus狀態值:騎乘循環數
	// 0 = 停止, 單位 = 1ms
	int(__stdcall* AutoReadCANBusRideCycle)(unsigned int cycle_time);
	// 自動排程讀取CAN-Bus狀態值:總里程
	// 0 = 停止, 單位 = 1ms
	int(__stdcall* AutoReadCANBusTotalODO)(unsigned int cycle_time);
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
	// 設定馬達轉至指定轉速
	int(__stdcall* TestModeMotorRun)(RouterType router, unsigned short motor_RPM, fpCallback_NoParamReturn callback);
} Mivice_DelegateFuncDefine_T;


/********************************************/
/*
*		萊克可委派相關程式定義
*/
/********************************************/

typedef struct DllExport Lexy_DelegateFuncDefine_st
{
	// 設定車輛狀態
	int(__stdcall* SetBikeStatus)(RouterType router, LEXY_BIKE_STATUS_E set_status, fpCallback_NoParamReturn callback);
	// 設定手動測試
	int(__stdcall* SetManualTest)(RouterType router, LEXY_MANUAL_TEST_TYPE_E command, fpCallback_NoParamReturn callback);
	// 讀取電池資訊
	int(__stdcall* ReadBatteryInfo)(RouterType router, fpCallback_NoParamReturn callback);
} Lexy_DelegateFuncDefine_T;



// 非DLL公開程式宣告內容

// 啟用自動讀取狀態處理執行緒
void __stdcall Mivice_AutoReadEnable(void);
// 禁用自動讀取狀態處理執行緒
void __stdcall Mivice_AutoReadDisable(void);
// 重置自動讀取指令狀態
void Mivice_AutoReadStatusReset(void);
// 自動讀取狀態處理執行緒
int __stdcall  Mivice_AutoReadHandler(void);
// 初始化麥思委派相關程序指標
int Mivice_DelegateMethod_Init(Mivice_DelegateFuncDefine_T* Init);


// 初始化萊克委派相關程序指標
int Lexy_DelegateMethod_Init(Lexy_DelegateFuncDefine_T* Init);
#ifdef __cplusplus
}
#endif

#endif

