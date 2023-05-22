//
//  StringExtension.swift
//  
//
//  Created by Jeff Chiu on 2023/5/21.
//

import Foundation

extension String {
    
    /// 對於 AdvertisementData 存取的鍵值的枚舉。
    public enum AdvertisementDataRetrievalKey {
        /// 廣播名稱。
        case localName
        /// 製造商相關的數據。
        case manufacturerData
        /// 裝置的服務的 UUID 。
        case serviceUUIDsKey
        /// 裝置是否可被連接。
        case isConnectable
    }
    
    /// 從 CBCentralManagerDelegate 掃描到的裝置，存取廣播參數的鍵值。
    internal var advertisementDataRetrievalKey: AdvertisementDataRetrievalKey? {
        switch self {
        case "kCBAdvDataIsConnectable":
            return .isConnectable
        case "kCBAdvDataLocalName":
            return .localName
        case "kCBAdvDataManufacturerData":
            return .manufacturerData
        case "kCBAdvDataServiceUUIDs":
            return .serviceUUIDsKey
        default:
            return nil
        }
    }
}
