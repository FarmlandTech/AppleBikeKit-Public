//
//  File.swift
//  
//
//  Created by Yves Tsai on 2023/6/20.
//

import Foundation

extension String {
    /**
     將字串映射為 Version 物件。
     
     - Returns: Version 物件。
     - Throws: 字串內容不符合版本格式(三碼數字)。
     */
    fileprivate func getVersion() throws -> Version {
        let element: [Int] = self.components(separatedBy: ".").compactMap({ Int($0) })
        guard element.count == 3 else {
            throw Version.Error.digitOfVersionMismatch
        }
        return Version(major: element[0], minor: element[1], patch: element[2])
    }
}

/// 處理 Firmware 版本比對的物件。
public struct Version {
    /// 處理 Firmware 版本比對流程中，可能會遭遇到的錯誤。
    public enum Error: Swift.Error {
        /// 字串內容不符合版本格式(三碼數字)。
        case digitOfVersionMismatch
        /// 無法取得部件的 Firmware 版本。
        case hmiFWAppVerIsNil, controllerFWAppVerIsNil, batteryFWAppVerIsNil
        /// 無法比對版本新舊。(邏輯上不可能發生，但排列組合上存在這種狀態)
        case ridiculous
        /// 當前部件的 Firmware 版本過舊，功能不支援。
        case notSupport(Version.Part, String)
    }
    
    /// 進行版本比對的目標部件。
    public enum Part {
        /// 部件名稱。
        case hmi, battery, controller
        
        /**
         取得 HMI 的 Version 物件實例。
         
         - Throws: 字串格式不符，或無法取得部件版本，便會拋出錯誤。
         */
        private func getHMIFWAppVersion() throws -> Version {
            if let hmiFWAppVer: String = FarmLandBikeKit.sleipnir.metaParameter.hmiFWAppVer {
                return try hmiFWAppVer.getVersion()
            } else {
                throw Version.Error.hmiFWAppVerIsNil
            }
        }
        
        /**
         取得 Controller 的 Version 物件實例。
         
         - Throws: 字串格式不符，或無法取得部件版本，便會拋出錯誤。
         */
        private func getControllerFWVersion() throws -> Version {
            if let controllerFWAppVer: String = FarmLandBikeKit.sleipnir.metaParameter.controllerFWAppVer {
                return try controllerFWAppVer.getVersion()
            } else {
                throw Version.Error.controllerFWAppVerIsNil
            }
        }
        
        /**
         取得 Battery 的 Version 物件實例。
         
         - Throws: 字串格式不符，或無法取得部件版本，便會拋出錯誤。
         */
        private func getBatteryFWVersion() throws -> Version {
            if let batteryFWAppVer: String = FarmLandBikeKit.sleipnir.metaParameter.batteryFWAppVer {
                return try batteryFWAppVer.getVersion()
            } else {
                throw Version.Error.batteryFWAppVerIsNil
            }
        }
        
        /**
         取得 Version 物件實例。
         
         - Throws: 字串格式不符，或無法取得部件版本，便會拋出錯誤。
         */
        func getVersion() throws -> Version {
            switch self {
            case .hmi:
                return try self.getHMIFWAppVersion()
            case .battery:
                return try self.getBatteryFWVersion()
            case .controller:
                return try self.getControllerFWVersion()
            }
        }
    }
    
    /// 主版本。
    let major: Int
    /// 次版本。
    let minor: Int
    /// 修訂版本。
    let patch: Int
    
    /// 比對本版。
    func compare(_ part: Part) throws -> ComparisonResult {
        let target: Version = try part.getVersion()
        if self.major > target.major {
            return .orderedDescending
        } else if self.major < target.major {
            return .orderedAscending
        } else if self.major == target.major, self.minor > target.minor {
            return .orderedDescending
        } else if self.major == target.major, self.minor < target.minor {
            return .orderedAscending
        } else if self.major == target.major, self.minor == target.minor, self.patch > target.patch {
            return .orderedDescending
        } else if self.major == target.major, self.minor == target.minor, self.patch < target.patch {
            return .orderedAscending
        } else if self.major == target.major, self.minor == target.minor, self.patch == target.patch {
            return .orderedSame
        } else {
            throw Version.Error.ridiculous
        }
    }
}

extension FarmLandBikeKit {
    /**
     比對 Firmware 本版，判斷功能是否支援。
     
     - Throws: 字串格式不符，或無法取得部件版本，便會拋出錯誤。
     */
    public func checkVersion(part: Version.Part, version: String) throws {
        guard try version.getVersion().compare(part) != .orderedDescending else {
            throw Version.Error.notSupport(part, version)
        }
    }
}
