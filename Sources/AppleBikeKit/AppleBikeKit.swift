//
//  File.swift
//  
//
//  Created by Yves Tsai on 2023/3/28.
//

import Foundation
import Combine
import CoreBluetooth

import CoreBLEService

public final class AppleBikeKit {
    
    private var subscriptions: Set<AnyCancellable> = .init()
    
    public private(set) lazy var connectedPeripheral: ConnectedPeripheral = {
        .init()
    }()
    
    public static let shared: AppleBikeKit = .init()
    
    private init() {
        self.characteristicsPublisher.sink(receiveValue: { peripheral in
            self.connectedPeripheral.currentPeripheral.value?.device.services?.forEach({ [weak self] service in
                guard let self: AppleBikeKit else { return }
                guard let characteristics: [CBCharacteristic] = service.characteristics else { return }
                if let characteristic: CBCharacteristic = characteristics.first(where: { $0.uuid.uuidString == "46610010-726D-6C61-6E64-546563685457" }) {
                    self.connectedPeripheral.writeCharacteristic.value = BluetoothCharacteristic(characteristic: characteristic)
                }
                if let characteristic: CBCharacteristic = characteristics.first(where: { $0.uuid.uuidString == "46610011-726D-6C61-6E64-546563685457" }) {
                    self.connectedPeripheral.notifyCharacteristic.value = BluetoothCharacteristic(characteristic: characteristic)
                }
                if let characteristic: CBCharacteristic = characteristics.first(where: { $0.uuid.uuidString == "46610020-726D-6C61-6E64-546563685457" }) {
                    self.connectedPeripheral.writeWithoutResponseCharacteristic.value = BluetoothCharacteristic(characteristic: characteristic)
                }
            })
            
        }).store(in: &self.subscriptions)
    }
    
    private let coreBluetoothService: CoreBluetoothService = .init()
    
    public private(set) lazy var statePublisher: AnyPublisher<CBManagerState, Never> = {
        self.coreBluetoothService.stateSubject.eraseToAnyPublisher()
    }()
    
    public private(set) lazy var scanningPublisher: AnyPublisher<Bool, Never> = {
        self.coreBluetoothService.scanningSubject.eraseToAnyPublisher()
    }()
    
    public private(set) lazy var foundDevicesPublisher: AnyPublisher<Array<BluetoothPeripheral>, Never> = {
        self.coreBluetoothService.foundDevicesSubject
            .map({ peripherals in
                peripherals.filter({
                    $0.deviceName != nil && ($0.deviceName!.hasPrefix("FL") || $0.deviceName!.hasPrefix("Farmland"))
                })
            })
            .eraseToAnyPublisher()
    }()
    
    public private(set) lazy var peripheralPublisher: AnyPublisher<(CoreBluetoothService.PeripheralStatus, BluetoothPeripheral?), Never> = {
        self.coreBluetoothService.peripheralSubject.eraseToAnyPublisher()
    }()
    
    public private(set) lazy var characteristicsPublisher: AnyPublisher<CBPeripheral?, Never> = {
        self.coreBluetoothService.characteristicsSubject
            .filter({ $0?.identifier == self.connectedPeripheral.currentPeripheral.value?.device.identifier })
            .eraseToAnyPublisher()
    }()
    
    public private(set) lazy var rssiPublisher: AnyPublisher<NSNumber?, Never> = {
        self.coreBluetoothService.rssiSubject.eraseToAnyPublisher()
    }()
}

extension AppleBikeKit {
    
    public func startScan() {
        do {
            try self.coreBluetoothService.startScanning()
        } catch {
            print("👻👻👻 \(error)")
        }
    }
    
    public func stopScan() {
        self.coreBluetoothService.stopScanning()
    }
    
    public func connect(_ bluetoothPeripheral: BluetoothPeripheral) {
        self.connectedPeripheral.currentPeripheral.value = bluetoothPeripheral
        self.coreBluetoothService.connect(peripheral: bluetoothPeripheral)
    }
    
    public func disconnect(_ bluetoothPeripheral: BluetoothPeripheral) {
        self.connectedPeripheral.reset()
        self.coreBluetoothService.disconnect(peripheral: bluetoothPeripheral)
    }
    
    public func readRSSI() {
        self.connectedPeripheral.currentPeripheral.value?.device.readRSSI()
    }
}
