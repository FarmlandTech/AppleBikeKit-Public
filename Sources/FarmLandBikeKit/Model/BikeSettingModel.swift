//
//  BikeSettingModel.swift
//  AppleBikeKit
//
//  Created by Yves Tsai on 2025/2/24.
//

import MapKit

public extension FarmLandBikeKit {
    
    /**
     自行車設定模型，包含保養、里程、單位、亮度等設定。
     
     - Note: 此結構體用於管理自行車的設定值，並提供相關計算屬性以便快速獲取有用的資訊。
     */
    public struct BikeSettingModel {
        /// 上次保養里程。
        let recMaintDist: Int?
        /// 保養間隔里程。
        let meterMaintDist: Int?
        /// 自動關機時間。
        public let meterSleepTime: Int?
        /// 距離單位的設定值，0 表示公制 (公里)，1 表示英制 (英里)。
        let dispUnitSw: Int?
        /// 保養提醒開關，0 表示關閉，1 表示開啟。
        public let dispMaintMarkSw: Int?
        /// 背光亮度。
        public let dispBrightness: Int?
        /// 總里程。
        let infoOdo: Int?
        
        /// 轉換 `dispUnitSw` 為 `MKDistanceFormatter.Units`。
        ///
        /// - Returns: 若 `dispUnitSw` 為 `0` 則返回 `.metric` (公里)；若為 `1` 則返回 `.imperial` (英里)；否則返回 `nil`。
        public var units: MKDistanceFormatter.Units? {
            guard let dispUnitSw: Int else { return nil }
            if dispUnitSw == 0 {
                return .metric
            } else if dispUnitSw == 1 {
                return .imperial
            } else {
                return nil
            }
        }
        
        /// 計算下一次保養所需的剩餘里程。
        ///
        /// - Returns: 若 `recMaintDist`、`meterMaintDist` 和 `infoOdo` 均不為 `nil`，則返回距離下次保養的里程數；否則返回 `nil`。
        public var nextOdoToMaintain: Int? {
            guard let recMaintDist: Int else { return nil }
            guard let meterMaintDist: Int else { return nil }
            guard let infoOdo: Int else { return nil }
            return meterMaintDist - (infoOdo - recMaintDist)
        }
        
        init(recMaintDist: Int? = nil, meterMaintDist: Int? = nil, meterSleepTime: Int? = nil, dispUnitSw: Int? = nil, dispMaintMarkSw: Int? = nil, dispBrightness: Int? = nil, infoOdo: Int? = nil) {
            self.recMaintDist = recMaintDist
            self.meterMaintDist = meterMaintDist
            self.meterSleepTime = meterSleepTime
            self.dispUnitSw = dispUnitSw
            self.dispMaintMarkSw = dispMaintMarkSw
            self.dispBrightness = dispBrightness
            self.infoOdo = infoOdo
        }
        
        public init(meterSleepTime: Int? = nil, dispUnitSw: MKDistanceFormatter.Units? = nil, dispMaintMarkSw: Bool? = nil, dispBrightness: Int? = nil) {
            self.recMaintDist = nil
            self.meterMaintDist = nil
            self.meterSleepTime = meterSleepTime
            if let dispUnitSw: MKDistanceFormatter.Units = dispUnitSw, case .metric = dispUnitSw {
                self.dispUnitSw = 0
            } else if let dispUnitSw: MKDistanceFormatter.Units = dispUnitSw, case .imperial = dispUnitSw {
                self.dispUnitSw = 1
            } else {
                self.dispUnitSw = nil
            }
            if let dispMaintMarkSw: Bool = dispMaintMarkSw, !dispMaintMarkSw {
                self.dispMaintMarkSw = 0
            } else if let dispMaintMarkSw: Bool = dispMaintMarkSw, dispMaintMarkSw {
                self.dispMaintMarkSw = 1
            } else {
                self.dispMaintMarkSw = nil
            }
            if let dispBrightness: Int = dispBrightness {
                self.dispBrightness = dispBrightness - 1
            } else {
                self.dispBrightness = nil
            }
            self.infoOdo = nil
        }
    }
}
