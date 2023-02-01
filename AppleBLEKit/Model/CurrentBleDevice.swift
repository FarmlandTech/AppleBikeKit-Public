//
//  CurrentBleDevice.swift
//  DST
//
//  Created by abe chen on 2022/10/20.
//

import Foundation
import BikeBLEKit
import CoreBluetooth

public class CurrentBleDevice: NSObject {
    static public var currentPeripheral: BluetoothPeripheral? = nil
    static public var writeCharacteristic: CBCharacteristic? = nil
    static public var writeWithoutResponseCharacteristic: CBCharacteristic? = nil
    static public var notifyCharacteristic: CBCharacteristic? = nil
}

// 斷線時摳這個
public func resetCurrentDevice() {
    CurrentBleDevice.currentPeripheral = nil
    CurrentBleDevice.writeCharacteristic = nil
    CurrentBleDevice.writeWithoutResponseCharacteristic = nil
    CurrentBleDevice.notifyCharacteristic = nil
}
