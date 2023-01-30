//
//  SearchDevicesViewModel.swift
//  DST
//
//  Created by abe chen on 2022/11/8.
//

import Foundation
import BikeBLEKit


struct DeviceCell: Identifiable {
    let id: String
    let name: String
    let rssi: String
    let devicePeripheral: BluetoothPeripheral
}

class SearchDevicesViewModel: ObservableObject {
    @Published var searchedDevices: [DeviceCell] = []
    @Published var isSearching: Bool = false
    
    func onAppear() {
        BluetoothService.sharedInstance.detectedDeviceDelegates.append(self)
    }
    
    func onDisappear() {
        BluetoothService.sharedInstance.removeDetectedDeviceDelegate(delegate: self)
    }
    
    func scan() throws {
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
    
    func stopScanning() {
        BluetoothService.sharedInstance.stopScanning()
        isSearching = false
    }
}

extension SearchDevicesViewModel: BluetoothServiceDetectedDeviceDelegate {
    func discoveredDevice(devices: [BluetoothPeripheral]) {
        searchedDevices = devices.map { device -> DeviceCell in
            var deviceName = ""
            if let name = device.deviceName {
                deviceName = name
            }
            
            return DeviceCell(id: device.address , name: deviceName, rssi: String(describing: device.rssi!), devicePeripheral: device)
        }
    }
}
