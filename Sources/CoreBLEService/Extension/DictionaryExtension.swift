//
//  DictionaryExtension.swift
//  
//
//  Created by Jeff Chiu on 2023/5/21.
//

import Foundation
import CoreBluetooth

extension Dictionary where Key == String, Value == Any {
    
    /// 從 CBCentralManagerDelegate 掃描到的裝置廣播，轉換為可以直接使用的型態。
    internal var used: [String.AdvertisementDataRetrievalKey: Any] {
        var results: [String.AdvertisementDataRetrievalKey: Any] = .init()
        
        for (key, value) in self {
            switch key.advertisementDataRetrievalKey {
            case .none:
                break
            case .some(let advertisementDataRetrievalKey):
                switch advertisementDataRetrievalKey {
                case .serviceUUIDsKey:
                    guard let serviceUUIDs: [CBUUID] = value as? [CBUUID] else { continue }
                    let identifiers: [String] = serviceUUIDs.map { $0.uuidString }
                    results.updateValue(identifiers, forKey: advertisementDataRetrievalKey)
                case .manufacturerData:
                    guard let data: Data = value as? Data else { continue }
                    results.updateValue(data, forKey: advertisementDataRetrievalKey)
                default:
                    results.updateValue(value, forKey: advertisementDataRetrievalKey)
                }
            }
        }
        
        return results
    }
}

extension Dictionary where Key == String.AdvertisementDataRetrievalKey, Value == Any {
    
    /// 掃描到的藍牙裝置，取得其廣播名稱。
    internal var localName: String? {
        self[.localName] as? String
    }
    
    /// 掃描到的藍牙裝置，取得其服務的 UUID 的值。
    internal var uuids: [String]? {
        self[.serviceUUIDsKey] as? [String]
    }
}
