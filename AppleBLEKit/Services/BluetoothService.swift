//
//  BluetoothService.swift
//  DST
//
//  Created by abe chen on 2022/10/19.
//

import Foundation
import BikeBLEKit
import CoreBluetooth
import UIKit

// 掃描附近裝置的 delegate
public protocol BluetoothServiceDetectedDeviceDelegate: AnyObject {
    func discoveredDevice(devices: [BluetoothPeripheral])
}

// 裝置連線後的 delegate
public protocol BluetoothServiceConnectedDeviceDelegate: AnyObject {
    func connectedDevice(device: BluetoothPeripheral)
    func discoveredService()
    func updateRemoteRssi(rssi: Float)
}

public class BluetoothService: NSObject {
    public static let sharedInstance = BluetoothService()
    
    private let bleManager = BikeBLEManager(context: UIView(), serviceUUID: nil)
    private var devices: [BluetoothPeripheral] = []
    public var connectedBluetoothPeripheral: BluetoothPeripheral? = nil
    public var detectedDeviceDelegates: [BluetoothServiceDetectedDeviceDelegate] = []
    public var connectedDeviceDelegates: [(UUID, BluetoothServiceConnectedDeviceDelegate)] = []
    
    deinit {
        print("Ble Service Dead")
    }
    
    private override init() {
        super.init()
        bleManager.delegates.add(self)
        print("BluetoothService init")
    }
    
    // 掃描裝置
    public func scan() throws {
        if devices.count != 0 {
            devices.removeAll()
        }
        
        try bleManager.scan()
    }
    
    // 停止掃描
    public func stopScanning() {
        print("STOP SCANNING")
        bleManager.stopScanning()
    }
    
    // 連線
    func connect(bluetoothPeripheral: BluetoothPeripheral) {
        bleManager.connect(bluetoothPeripheral: bluetoothPeripheral, autoConnect: false)
    }
    
    // 斷線
    func disconnect(bluetoothPeripheral: BluetoothPeripheral) {
        bleManager.disconnect(bluetoothPeripheral: bluetoothPeripheral)
        resetCurrentDevice()
    }
    
    // 讀取藍芽訊號強度
    func readRemoteRssi(bluetoothPeripheral: BluetoothPeripheral) {
        bleManager.readRemoteRssi(bluetoothPeripheral: bluetoothPeripheral)
    }
    
    // 傳遞資料到裝置
    func writeCharacteristic(bluetoothCharacteristic: BluetoothCharacteristic, value: [UInt8]) {
        guard let connectedBluetoothPeripheral = connectedBluetoothPeripheral else { return }
                
        bleManager.writeCharacteristic(
            bluetoothPeripheral: connectedBluetoothPeripheral,
            bluetoothCharacteristic: bluetoothCharacteristic,
            value: convertToKotlinByteArray(value: value)
        )
    }
    
    //MARK: 轉換 swift byteArray to kotlinByteArray
    private func convertToKotlinByteArray(value: [UInt8]) -> KotlinByteArray {
        let swiftByteArray : [UInt8] = value
        let intArray : [Int8] = swiftByteArray.map { Int8(bitPattern: $0) }
        let kotlinByteArray: KotlinByteArray = KotlinByteArray.init(size: Int32(swiftByteArray.count))
        for (index, element) in intArray.enumerated() {
            kotlinByteArray.set(index: Int32(index), value: element)
        }
        return kotlinByteArray
    }
    
    // 開啟裝置的通知
    func setNotifyCharacteristic(bluetoothPeripheral: BluetoothPeripheral, bluetoothCharacteristic: CBCharacteristic, notify: Bool) {
        bleManager.notifyCharacteristic(
            bluetoothPeripheral: bluetoothPeripheral,
            bluetoothCharacteristic: BluetoothCharacteristic(characteristic: bluetoothCharacteristic),
            notify: notify
        )
    }
    
    // 移除掃描裝置的 delegate
    public func removeDetectedDeviceDelegate(delegate: BluetoothServiceDetectedDeviceDelegate) {
        for (index, storedDelegate) in detectedDeviceDelegates.enumerated() {
            if delegate === storedDelegate {
                detectedDeviceDelegates.remove(at: index)
            }
        }
    }
    
    // 移除連線裝置的 delegate
    func removeConnectedDeviceDelegate(delegate: BluetoothServiceConnectedDeviceDelegate) {
        for (index, storedDelegate) in connectedDeviceDelegates.enumerated() {
            if delegate === storedDelegate.1 {
                connectedDeviceDelegates.remove(at: index)
            }
        }
    }
}

extension BluetoothService: BLEManagerDelegate {
    // filter 出連線裝置的 delegate
    private func bluetoothServiceConnectedDeviceDelegates(bluetoothPeripheralId: UUID) -> [BluetoothServiceConnectedDeviceDelegate] {
        return connectedDeviceDelegates.compactMap { connectedDeviceDelegateTuple -> BluetoothServiceConnectedDeviceDelegate? in
            connectedDeviceDelegateTuple.0 == bluetoothPeripheralId ? connectedDeviceDelegateTuple.1 : nil
        }
    }
    
    // didDiscoverDevice callback
    public func didDiscoverDevice(bluetoothPeripheral: BluetoothPeripheral, advertisementData: [AdvertisementDataRetrievalKeys : Any]) {
        // 篩選出所有 Farmland 的設備
        if bluetoothPeripheral.deviceName != nil && bluetoothPeripheral.deviceName!.matches("FL") {
            if devices.first(where: { $0.address == bluetoothPeripheral.address }) != nil {
                for index in stride(from: 0, through: devices.count - 1, by: 1) {
                    if devices[index].address == bluetoothPeripheral.address {
                        devices[index] = bluetoothPeripheral
                    }
                }
            } else {
                devices.append(bluetoothPeripheral)
            }

            detectedDeviceDelegates.forEach { delegate in
                delegate.discoveredDevice(devices: devices)
            }
        }
    }
    
    public func didConnect(bluetoothPeripheral: BluetoothPeripheral) {
        stopScanning()
        connectedBluetoothPeripheral = bluetoothPeripheral
        print("Connect device: \(bluetoothPeripheral.bluetoothDevice)")
        print("connectedBluetoothPeripheral: \(String(describing: connectedBluetoothPeripheral))")
        bluetoothServiceConnectedDeviceDelegates(bluetoothPeripheralId: bluetoothPeripheral.bluetoothDevice.identifier).forEach { delegate in
            delegate.connectedDevice(device: bluetoothPeripheral)
        }
    }
    
    public func didDisconnect(bluetoothPeripheral: BluetoothPeripheral) {
        connectedBluetoothPeripheral = nil
        print("Disconnect device: \(bluetoothPeripheral.bluetoothDevice)")
    }
    
    // 吐封包資料的 callback，這裡會將回傳的 data 傳遞給 CoreSDK 做解析
    public func didCharacteristicsValueChanged(bluetoothPeripheral: BluetoothPeripheral, bluetoothCharacteristic: BluetoothCharacteristic) {
        let dataPacket: [UInt8]?
        if (bluetoothCharacteristic.characteristic.value != nil) {
            dataPacket = Array(bluetoothCharacteristic.characteristic.value!)
            CoreSdkService.sharedInstance.commandPacketIn(dataPacket: dataPacket!)
        }
    }
    
    // 找到裝置的所有 characteristics service 的 callback
    public func didDiscoverCharacteristics(bluetoothPeripheral: BluetoothPeripheral) {
        bluetoothServiceConnectedDeviceDelegates(bluetoothPeripheralId: bluetoothPeripheral.bluetoothDevice.identifier)
            .forEach { bluetoothServiceConnectedDeviceDelegate in
                bluetoothServiceConnectedDeviceDelegate.discoveredService()
            }
    }
    
    public func didDiscoverServices(bluetoothPeripheral: BluetoothPeripheral) {}
    
    // 藍芽訊號 callback
    public func didRssiUpdate(bluetoothPeripheral: BluetoothPeripheral) {
        print("bbrssi \(String(describing: bluetoothPeripheral.rssi))")
//        connectedDeviceDelegates.forEach { (uuid, bluetoothServiceConnectedDeviceDelegate) in
//            bluetoothServiceConnectedDeviceDelegate.updateRemoteRssi(rssi: bluetoothPeripheral.rssi as! Float )
//        }
    }
    
    public func didUpdateMTU(bluetoothPeripheral: BluetoothPeripheral) {
        
    }
    
    public func didWriteCharacteristic(bluetoothPeripheral: BluetoothPeripheral, bluetoothCharacteristic: BluetoothCharacteristic, success: Bool) {
        print("bluetoothPeripheral: \(bluetoothPeripheral)")
        print("bluetoothCharacteristic: \(bluetoothCharacteristic)")
        print("success: \(success)")
    }
    
    public func didReadDescriptor(bluetoothPeripheral: BluetoothPeripheral, bluetoothCharacteristicDescriptor: CBDescriptor) {}

    public func didWriteDescriptor(bluetoothPeripheral: BluetoothPeripheral, bluetoothCharacteristicDescriptor: CBDescriptor) {}
}
