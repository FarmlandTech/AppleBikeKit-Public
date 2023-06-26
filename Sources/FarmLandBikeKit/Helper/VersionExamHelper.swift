//
//  File.swift
//  
//
//  Created by Yves Tsai on 2023/6/20.
//

import Foundation

extension String {
    func getVersion() throws -> Version {
        let element: [Int] = self.components(separatedBy: ".").compactMap({ Int($0) })
        guard element.count == 3 else {
            throw Version.Error.digitOfVersionMismatch
        }
        return Version(major: element[0], minor: element[1], build: element[2])
    }
}

public struct Version {
    public enum Error: Swift.Error {
        case digitOfVersionMismatch
        case hmiFWAppVerIsNil, controllerFWAppVerIsNil, batteryFWAppVerIsNil
        case ridiculous
        case notSupport(Version.Part, String)
    }
    
    public enum Part {
        case hmi, battery, controller
        
        private func getHMIFWAppVersion() throws -> Version {
            if let hmiFWAppVer: String = FarmLandBikeKit.sleipnir.metaParameter.hmiFWAppVer {
                return try hmiFWAppVer.getVersion()
            } else {
                throw Version.Error.hmiFWAppVerIsNil
            }
        }
        
        private func getControllerFWVersion() throws -> Version {
            if let controllerFWAppVer: String = FarmLandBikeKit.sleipnir.metaParameter.controllerFWAppVer {
                return try controllerFWAppVer.getVersion()
            } else {
                throw Version.Error.controllerFWAppVerIsNil
            }
        }
        
        private func getBatteryFWVersion() throws -> Version {
            if let batteryFWAppVer: String = FarmLandBikeKit.sleipnir.metaParameter.batteryFWAppVer {
                return try batteryFWAppVer.getVersion()
            } else {
                throw Version.Error.batteryFWAppVerIsNil
            }
        }
        
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
    
    let major: Int
    let minor: Int
    let build: Int
    
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
        } else if self.major == target.major, self.minor == target.minor, self.build > target.build {
            return .orderedDescending
        } else if self.major == target.major, self.minor == target.minor, self.build < target.build {
            return .orderedAscending
        } else if self.major == target.major, self.minor == target.minor, self.build == target.build {
            return .orderedSame
        } else {
            throw Version.Error.ridiculous
        }
    }
}

extension FarmLandBikeKit {
    func checkVersion(part: Version.Part, version: String) throws {
        guard try version.getVersion().compare(part) != .orderedDescending else {
            throw Version.Error.notSupport(part, version)
        }
    }
}
