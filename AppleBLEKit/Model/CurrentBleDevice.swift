//
//  CurrentBleDevice.swift
//  DST
//
//  Created by abe chen on 2022/10/20.
//

import Foundation
import BikeBLEKit
import CoreBluetooth

class CurrentBleDevice: NSObject {
    static var currentPeripheral: BluetoothPeripheral? = nil
    static var writeCharacteristic: CBCharacteristic? = nil
    static var writeWithoutResponseCharacteristic: CBCharacteristic? = nil
    static var notifyCharacteristic: CBCharacteristic? = nil
}

// 斷線時摳這個
func resetCurrentDevice() {
    CurrentBleDevice.currentPeripheral = nil
    CurrentBleDevice.writeCharacteristic = nil
    CurrentBleDevice.writeWithoutResponseCharacteristic = nil
    CurrentBleDevice.notifyCharacteristic = nil
}
