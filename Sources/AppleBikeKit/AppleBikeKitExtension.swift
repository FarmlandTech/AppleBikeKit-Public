//
//  AppleBikeKitExtension.swift
//  
//
//  Created by Yves Tsai on 2023/5/18.
//

import Foundation
import Combine
import CoreBLEService

public protocol DataLakeBikeKitDelegate {
    
    func dataLakeKikeKitConnection(_ peripheral: BluetoothPeripheral, status: CoreBluetoothService.PeripheralStatus)
    
    func dataLakeBikeKitFoundPeripheripherals(_ peripherals: [BluetoothPeripheral])
    
    func dataLakeBikeKitSelectedPeripheral(_ peripheral: BluetoothPeripheral)
    
    func dataLakeBikeKitReadBatteryRSOC(_ rsoc: UInt32?)
}

public class DataLakeBikeKit: AppleBikeKit {
    
    public var delegate: DataLakeBikeKitDelegate?
    
    private var subscriptions: Set<AnyCancellable> = .init()
    
    public static var instance: DataLakeBikeKit {
        self.shared as! DataLakeBikeKit
    }
    
    public private(set) lazy var selectedPeripheralSubject: CurrentValueSubject<BluetoothPeripheral?, Never> = {
        .init(nil)
    }()
    
    public private(set) lazy var batteryRSOCSubject: CurrentValueSubject<UInt32?, Never> = {
        .init(nil)
    }()
    
    public func connect(bikeName: String) throws {
        // 監聽連線狀態。
        self.peripheralPublisher.sink(receiveValue: { [weak self] (status, peripheral) in
            guard let self: DataLakeBikeKit else { return }
            guard let peripheral: BluetoothPeripheral else { return }
            self.delegate?.dataLakeKikeKitConnection(peripheral, status: status)
        }).store(in: &self.subscriptions)
        // 開始掃描。
        try self.startScan()
        // 監聽掃描。
        self.foundDevicesPublisher.sink(receiveValue: { [weak self] foundDevices in
            guard let self: DataLakeBikeKit else { return }
            self.delegate?.dataLakeBikeKitFoundPeripheripherals(foundDevices)
            // 篩選。
            guard let selectedPeripheral: BluetoothPeripheral = foundDevices.first(where: { $0.deviceName == bikeName }) else { return }
            self.delegate?.dataLakeBikeKitSelectedPeripheral(selectedPeripheral)
            self.selectedPeripheralSubject.send(selectedPeripheral)
            // 停止掃描。
            self.stopScan()
            // 連線。
            self.connect(selectedPeripheral)
            // 監聽電池電量。
        }).store(in: &self.subscriptions)
    }
    
    public func disconnectCurrentBike() {
        guard let peripheral: BluetoothPeripheral = self.selectedPeripheralSubject.value else { return }
        self.disconnect(peripheral)
        self.subscriptions.forEach { $0.cancel() }
    }
    
//    self.deviceInfo?.battery_rsoc
    public func listenBatteryRSOC() {
        // 監聽裝置資訊？
        self.deviceInfoPublisher.sink(receiveValue: { deviceInfo in
            self.delegate?.dataLakeBikeKitReadBatteryRSOC(deviceInfo?.battery_rsoc)
            self.batteryRSOCSubject.send(deviceInfo?.battery_rsoc)
        }).store(in: &self.subscriptions)
    }
}
