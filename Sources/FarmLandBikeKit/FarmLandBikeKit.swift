//
//  FarmLandBikeKit.swift
//  
//
//  Created by Jeff Chiu on 2023/5/21.
//

import Foundation
import Combine
import CoreBLEService

import AppleBikeKit

final public class FarmLandBikeKit: AppleBikeKit {
    
    public static let sleipnir: FarmLandBikeKit = .init()
    
    private var subscriptions: Set<AnyCancellable> = .init()
    
    public private(set) lazy var selectedPeripheralSubject: CurrentValueSubject<BluetoothPeripheral?, Never> = {
        .init(nil)
    }()
    
    public private(set) lazy var batteryRSOCSubject: CurrentValueSubject<UInt32?, Never> = {
        .init(nil)
    }()
    
    public func connect(bikeName: String) throws {
        // 監聽連線狀態。
        self.peripheralPublisher.sink(receiveValue: { [weak self] (status, peripheral) in
            guard let self: FarmLandBikeKit else { return }
            if case .didDisconnect = status {
                self.subscriptions.forEach { $0.cancel() }
                self.subscriptions = .init()
            }
        }).store(in: &self.subscriptions)
        // 監聽裝置資訊？
        self.deviceInfoPublisher.sink(receiveValue: { deviceInfo in
            self.batteryRSOCSubject.send(deviceInfo?.battery_rsoc)
        }).store(in: &self.subscriptions)
        // 開始掃描。
        try self.startScan()
        // 監聽掃描。
        self.foundDevicesPublisher.sink(receiveValue: { [weak self] foundDevices in
            guard let self: FarmLandBikeKit else { return }
            // 篩選。
            guard let selectedPeripheral: BluetoothPeripheral = foundDevices.first(where: { $0.deviceName == bikeName }) else { return }
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
        self.selectedPeripheralSubject.send(nil)
        self.batteryRSOCSubject.send(nil)
    }
}
