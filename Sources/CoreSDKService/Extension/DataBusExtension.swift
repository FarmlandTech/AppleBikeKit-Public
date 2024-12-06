//
//  File.swift
//  
//
//  Created by Yves Tsai on 2024/2/26.
//

import Foundation

import CoreSDKSourceCode

protocol DataBus {
    func bleCommandPacketIn(data: UnsafeMutablePointer<UInt8>?, length: UInt32) -> Int32
    
    func bleCommandPacketOut(data: UnsafeMutablePointer<UInt8>?, length: UnsafeMutablePointer<UInt32>?) -> Int32
    
    func bleDataPacketOut(data: UnsafeMutablePointer<UInt8>?, length: UnsafeMutablePointer<UInt32>?) throws -> Int32
}

extension Apple_DataBusDefine_st: DataBus {
    func bleCommandPacketIn(data: UnsafeMutablePointer<UInt8>?, length: UInt32) -> Int32 {
        return self.BLECommandPacket_IN(data, length)
    }
    
    func bleCommandPacketOut(data: UnsafeMutablePointer<UInt8>?, length: UnsafeMutablePointer<UInt32>?) -> Int32 {
        return self.BLECommandPacket_OUT(data, length)
    }
    
    func bleDataPacketOut(data: UnsafeMutablePointer<UInt8>?, length: UnsafeMutablePointer<UInt32>?) throws -> Int32 {
        return self.BLEDataPacket_OUT(data, length)
    }
}

extension Cherry_DataBusDefine_st: DataBus {
    func bleCommandPacketIn(data: UnsafeMutablePointer<UInt8>?, length: UInt32) -> Int32 {
        return self.BLE_CommandPacket_IN(data, length)
    }
    
    func bleCommandPacketOut(data: UnsafeMutablePointer<UInt8>?, length: UnsafeMutablePointer<UInt32>?) -> Int32 {
        return self.BLE_CommandPacket_OUT(data, length)
    }
    
    func bleDataPacketOut(data: UnsafeMutablePointer<UInt8>?, length: UnsafeMutablePointer<UInt32>?) throws -> Int32 {
        throw Tenant.Error.dataBusNotExist(#function)
    }
}
