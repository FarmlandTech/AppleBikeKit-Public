//
//  SearchDevicesViewModel.swift
//  DST
//
//  Created by abe chen on 2022/11/8.
//

import Foundation
import BikeBLEKit


public struct DeviceCell: Identifiable {
    public let id: String
    let name: String
    let rssi: String
    let devicePeripheral: BluetoothPeripheral
}

public class SearchDevicesViewModel: ObservableObject {
    @Published public var searchedDevices: [DeviceCell] = []
    @Published public var isSearching: Bool = false
    
    public init() {
        BluetoothService.sharedInstance.detectedDeviceDelegates.append(self)
    }
    
    deinit {
        BluetoothService.sharedInstance.removeDetectedDeviceDelegate(delegate: self)
    }
    
    public func scan() throws {
        if searchedDevices.count != 0 {
            searchedDevices.removeAll()
        }
        
        // 這裡要做 try catch 以防沒有開啟藍芽
        do {
            try BluetoothService.sharedInstance.scan()
            isSearching = true
        } catch {
            let error = error as NSError
            print("\(error.userInfo)")
        }
    }
    
    public func stopScanning() {
        BluetoothService.sharedInstance.stopScanning()
        isSearching = false
    }
}

extension SearchDevicesViewModel: BluetoothServiceDetectedDeviceDelegate {
    public func discoveredDevice(devices: [BluetoothPeripheral]) {
        searchedDevices = devices.map { device -> DeviceCell in
            var deviceName = ""
            if let name = device.deviceName {
                deviceName = name
            }
            
            return DeviceCell(id: device.address , name: deviceName, rssi: String(describing: device.rssi!), devicePeripheral: device)
        }
    }
}
