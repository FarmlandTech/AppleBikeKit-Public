//
//  BaseParameterDataRepository.swift
//
//
//  Created by Yves Tsai on 2023/4/20.
//

import Foundation

import CoreSDKSourceCode

/// 部件參數模型的倉庫，包括定義與緩存，以及小部分的邏輯。
public class BaseParameterDataRepository {
    
    /// 自定義的錯誤枚舉。
    public enum Error: Swift.Error {
        /// 透過名稱枚舉查詢部件參數時，搜尋失敗。
        case parameterDataNotFoundByName(String)
        /// 透過相關資訊查詢部件參數時，搜尋失敗。
        case parameterDataNotFoundByArguments(DeviceType_enum, UInt8, UInt16, UInt16)
        /// 來自系統定義的例外，非自定義的錯誤。
        case exception(Swift.Error)
        /// 轉型錯誤
        case wrongType(BaseParameterDataRepository.Type)
    }
    
    internal init() {
        
    }
}
