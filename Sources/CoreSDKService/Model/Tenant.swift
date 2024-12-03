//
//  File.swift
//  
//
//  Created by Yves Tsai on 2024/2/24.
//

import Foundation

/// 代表App可能的租戶配置，用於識別不同的運行環境或客戶端。
enum Tenant: String {
    /// 未知配置，默認值。
    case unknown = "unknown"
    /// 面向Farmland的配置。
    case farmland = "farmland"
    /// 面向Lexy的配置。
    case lexy = "lexy"
    /// 面向Mivice的配置。
    case mivice = "mivice"
    /// 面向Merida的配置。
    case merida = "merida"
    
    /// 定義處理租戶配置錯誤的枚舉。
    enum Error: Swift.Error {
        /// 當嘗試使用未知的 Tenant 配置時拋出。
        case unknownTenant
        /// 當嘗試使用未知的 DataBus 配置時拋出，攜帶一個字串參數，為方法名稱。
        case dataBusNotExist(String)
        /// 當嘗試使用未知的 DelegateFunction 配置時拋出，攜帶一個字串參數，為方法名稱。
        case delegateFunctionNotExist(String)
        /// 調用方法時，參數不匹配(缺失)。
        case delegateFunctionArgMissing([String])
        /// 協定方法不可被調用。
        case protocolMethodNotValid(String)
    }
    
    /// 根據提供的字符串值初始化枚舉實例。
    /// 如果字符串不匹配任何已知配置，則默認為`.unknown`。
    ///
    /// - parameter target: 目標配置的字符串表示。
    /// - Returns: 對應的`Tenant`枚舉實例。
    static func from(_ target: String) -> Tenant {
        return .init(rawValue: target) ?? .unknown
    }
}
