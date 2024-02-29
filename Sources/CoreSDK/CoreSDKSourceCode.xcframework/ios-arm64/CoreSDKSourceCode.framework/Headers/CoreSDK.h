#pragma once
#pragma warning(disable:4996)
#pragma warning(disable:26812)
//
#ifndef _FL_CORE_SDK_H // include guard
#define _FL_CORE_SDK_H

  

#import <CoreSDKSourceCode/lib_event_scheduler.h>
#import <CoreSDKSourceCode/FL_CANInfoStruct.h>
#import <CoreSDKSourceCode/CoreSDK_Common.h>
#import <CoreSDKSourceCode/CAN_ISO_TP.h>
#import <CoreSDKSourceCode/FL_Logs.h>

#import <CoreSDKSourceCode/CoreSDK_DeviceInfo.h>
#import <CoreSDKSourceCode/CoreSDK_DelegateFunc.h>



#define LOG_PRINT_ENABLE 1


#ifdef __cplusplus
extern "C" {
#endif







//系統零件即時狀態定義
typedef DllExport struct DeviceInfoDefine
{
	//農田電控系統
	struct FL_Info_st FL;
	//麥思電控系統
	struct Mivice_Info_st Mivice;
	//萊克電控系統
	struct Lexy_Info_st Lexy;
}DeviceInformation_T;



typedef struct DllExport DelegateFuncDefine_st
{
	// 農田可委派相關程式
	FL_DelegateFuncDefine_T FL;
	// 麥思可委派相關程式
	Mivice_DelegateFuncDefine_T Mivice;
	// 萊克可委派相關程式
	Lexy_DelegateFuncDefine_T Lexy;
} DelegateFuncDefine_T;

//SDK接收及發送外部封包指令集

struct DllExport FL_DataBusDefine_st
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

struct DllExport Mivice_DataBusDefine_st
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
	// 農田數據接口
	struct FL_DataBusDefine_st FL;
	// 麥思數據接口
	struct Mivice_DataBusDefine_st Mivice;
} DataBusDefine_T;



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
	//SDK接收及發送數據接口
	DataBusDefine_T DataBus;
	//委派SDK執行功能
	DelegateFuncDefine_T DelegateMethod;
	//SDK Thread迴圈休眠設定值: us = 0.001 ms = 0.000001 Sec
	int ThreadSleepInterval_us;
	//使用核可檢查
	int(__stdcall* Authentication)(unsigned long long unix_time, char* P_key, unsigned char key_leng);
} CoreSDKInst_T;

//初始化SDK功能
DllExport int FarmLandCoreSDK_Init(CoreSDKInst_T* SDK_Inst);
int __stdcall FL_CANBusPacket_IN(unsigned int can_id, bool is_extender_id, unsigned char* raw_data, unsigned int leng);

#ifdef __cplusplus
}
#endif

#endif

