#pragma once
#pragma warning(disable:4996)
#pragma warning(disable:26812)
//
#ifndef _FL_CORE_SDK_H // include guard
#define _FL_CORE_SDK_H

  

#include <CoreSDKSourceCode/lib_event_scheduler.h>
#include <CoreSDKSourceCode/FL_CANInfoStruct.h>
#include <CoreSDKSourceCode/CoreSDK_Common.h>
#include <CoreSDKSourceCode/CAN_ISO_TP.h>
#include <CoreSDKSourceCode/FL_Logs.h>

#include <CoreSDKSourceCode/CoreSDK_DeviceInfo.h>
#include <CoreSDKSourceCode/CoreSDK_DelegateFunc.h>
#include <CoreSDKSourceCode/LogPrinter.h>
#define LOG_PRINT_ENABLE 1


#ifdef __cplusplus
extern "C" {
#endif







//系統零件即時狀態定義
typedef DllExport struct DeviceInfoDefine
{
	struct Apple_Info_st Apple;
	struct Cherry_Info_st Cherry;
	struct Orange_Info_st Orange;
}DeviceInformation_T;



typedef struct DllExport DelegateFuncDefine_st
{
	Apple_DelegateFuncDefine_T Apple;
	Cherry_DelegateFuncDefine_T Cherry;
	Orange_DelegateFuncDefine_T Orange;
} DelegateFuncDefine_T;

//SDK接收及發送外部封包指令集

struct DllExport Apple_DataBusDefine_st
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
};

typedef void (*fpParameterChangeNotify)(SDKDeviceType_e target_device, unsigned char bank_index, unsigned short addr, unsigned short leng);

struct DllExport Cherry_DataBusDefine_st
{
	// CAN Bus封包輸入	
	int(__stdcall* CANBus_Packet_IN)(unsigned int can_id, bool is_extender_id, unsigned char* raw_data, unsigned int leng);
	// CAN Bus封包輸出
	int(__stdcall *CANBus_Packet_OUT)(unsigned int* can_id, bool* is_extender_id, unsigned char* data, unsigned int* leng);
	// BLE 封包專用指令輸入
	// 0xFD02 BT UUID : 7658FD02-878A-4350-A93E-DA553E719ED0
	int(__stdcall* BLE_CommandPacket_IN)(unsigned char* data, unsigned int leng);
	// BLE 封包專用指令輸出
	// 0xFD01 UUID : 7658FD01-878A-4350-A93E-DA553E719ED0
	int(__stdcall* BLE_CommandPacket_OUT)(unsigned char* data, unsigned int* leng);
	// BLE 透傳指令輸入
	// 0xFD03 UUID : 7658FD03-878A-4350-A93E-DA553E719ED0
	int(__stdcall* BLE_PassThrough_IN)(unsigned char* data, unsigned int leng);
	// BLE 透傳指令輸出
	// 0xFD05 UUID : 7658FD05-878A-4350-A93E-DA553E719ED0
	int(__stdcall* BLE_PassThrough_OUT)(unsigned char* data, unsigned int* leng);
	// BLE HMI實時數據輸入
	// 0xFD04 UUID : 7658FD04-878A-4350-A93E-DA553E719ED0
	int(__stdcall* BLE_HMIData_IN)(unsigned char* data, unsigned int leng);
};


typedef struct DllExport DataBusDefine_st
{
	struct Apple_DataBusDefine_st Apple;
	struct Cherry_DataBusDefine_st Cherry;
} DataBusDefine_T;

typedef void(__stdcall* fpLogCallback)(char* output_buff, unsigned int output_leng);

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
	void(__stdcall *InfoUpdateEvent)(ProtocolType Protocol, DeviceInformation_T DeviceInfo);
	//參數變更通知
	void(__stdcall* ParameterChangeNotify)(SDKDeviceType_e target_device, unsigned char bank_index, unsigned short addr, unsigned short leng);
	//SDK接收及發送數據接口
	DataBusDefine_T DataBus;
	//委派SDK執行功能
	DelegateFuncDefine_T DelegateMethod;
	//SDK Thread迴圈休眠設定值: us = 0.001 ms = 0.000001 Sec
	int ThreadSleepInterval_us;
	//使用核可檢查
	int(__stdcall* Authentication)(unsigned long long unix_time, char* P_key, unsigned char key_leng);
	//Log Output Callback
	void(__stdcall* BindingLogOutput)(fpLogCallback callback);
	//Log 輸出層級設置
	LogLevel_E LogLevel;
} CoreSDKInst_T;

//初始化SDK功能
DllExport int FarmLandCoreSDK_Init(CoreSDKInst_T* SDK_Inst);
int __stdcall FL_CANBusPacket_IN(unsigned int can_id, bool is_extender_id, unsigned char* raw_data, unsigned int leng);

#ifdef __cplusplus
}
#endif

#endif

