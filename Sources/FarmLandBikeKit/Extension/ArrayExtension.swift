//
//  ArrayExtension.swift
//  
//
//  Created by Yves Tsai on 2023/6/26.
//

import Foundation

import CoreSDKService

extension Array where Element == MileageRecord {
    /**
     從電控(電池)讀出來的原始數據為累積里程，此方法可將累積里程映射為單日里程。
     
     - Throws: 若單日里程計算結果為負值，則拋出錯誤。
     */
    fileprivate func tranfer2SingleDayODO() throws -> [MileageRecord] {
        guard let first: MileageRecord = self.first else {
            return self
        }
        var lastMileageRecord: MileageRecord = first  // 第一天是累積里程，所以不放入陣列中。
        var resultMileageRecords: [MileageRecord] = .init()
        for mileageRecord in self[1...] {
            let singleDayODO: Int = mileageRecord.odograph - lastMileageRecord.odograph
            // 判斷數值的合理性，避免出現單日里程為負值的狀態。
            guard singleDayODO >= 0 else {
                throw MileageRecord.Error.accumulatedODOMisSequence(mileageRecord, lastMileageRecord)
            }
            let singleDayMileageRecord: MileageRecord = .init(name: mileageRecord.name,
                                                              date: mileageRecord.date,
                                                              odograph: singleDayODO)
            resultMileageRecords.append(singleDayMileageRecord)
            lastMileageRecord = mileageRecord
        }
        return resultMileageRecords
    }
}

extension Array where Element == ParameterData {
    /**
     將電控(電池)讀出來的數據，映射為 chart 可以使用的數組。
     
     - Throws: 粗略校驗，若數據有明顯不合理的狀況(電控數據不成對；單日里程為負值)，便會拋出例外。
     */
    func transfer2MileageRecords() throws -> [MileageRecord] {
        // 簡略的判斷，從藍牙讀到的參數應該要有62項，但這邊粗暴檢查，能兩兩成對就好了。
        guard self.count.isMultiple(of: 2) else {
            throw MileageRecord.Error.numberOfRawDataShouldBeEven
        }
        // 從藍牙讀到的62項參數，兩兩成對整合成31項里程物件的數組。
        var mileageRecords: [MileageRecord] = .init()
        for index in 0..<(self.count / 2) {
            let date: ParameterData = self[index * 2]
            let odograph: ParameterData = self[index * 2 + 1]
            
            guard let dateName: String = String(describing: date.name).components(separatedBy: "_").last, let odographName: String = String(describing: odograph.name).components(separatedBy: "_").last, dateName == odographName else {
                continue
            }
            
            guard let dateValue: Int = date.value as? Int else {
                continue
            }
            
            let timeInterval: TimeInterval = Double(dateValue)
            
            guard var odographValue: Int = odograph.value as? Int else {
                continue
            }
            
            if let isMetricSystem: Bool = FarmLandBikeKit.sleipnir.metaParameter.hmiDistanceUint, !isMetricSystem {
                odographValue = Int(Double(odographValue).toMile)
            }
            
            let element: MileageRecord = .init(
                name: dateName,
                date: .init(timeIntervalSince1970: timeInterval),
                odograph: odographValue)
            mileageRecords.append(element)
        }
        // 按時間先後升冪排序。
        mileageRecords.sort(by: { $0.date.compare($1.date) == .orderedAscending })
        // 原始的里程為累積里程，這邊要在映射為單日里程。
        let singleDayMileageRecords: [MileageRecord] = try mileageRecords.tranfer2SingleDayODO()
        return singleDayMileageRecords
    }
}
