//
//  MileageRecordModel.swift
//  
//
//  Created by Yves Tsai on 2023/6/26.
//

import Foundation

/// 單日里程(chart)的數據模型。
public struct MileageRecord: Identifiable {
    
    /// 里程圖表數據相關的自定義錯誤。
    public enum Error: Swift.Error {
        /// 從藍牙讀到的參數應有62項(包含31項日期與31項里程)，但簡單驗證至少要為偶數，才能兩兩成對將數據整合。
        case numberOfRawDataShouldBeEven
        /// 累積里程應為遞增(至少持平)，否則會得到單日裡成為負數的不合理情境。
        case accumulatedODOMisSequence(MileageRecord, MileageRecord)
    }
    
    /// 給 SwiftUI 的 List 用於識別的參數。
    public let id = UUID()
    /// 顯示名稱。
    public let name: String
    /// 日期。
    public let date: Date
    /// 里程。
    public let odograph: Int
    
    /// 格式化日期。
    public var dateContent: String {
        let formatter: DateFormatter = .init()
        formatter.timeZone = TimeZone(abbreviation: "GMT+0")
        formatter.dateFormat = "MMM dd"
        return formatter.string(from: self.date)
    }
}
