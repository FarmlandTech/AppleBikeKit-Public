//
//  DiagnoseErrorCode.swift
//  
//
//  Created by Yves Tsai on 2023/6/14.
//

import Foundation

public struct ErrorCode: Identifiable {
    public let id = UUID()
    public let code: Int
    public let hint: String
    
    public init(code: Int, hint: String) {
        self.code = code
        self.hint = hint
    }
}

extension ErrorCode {
    public init(_ code: Int) {
        self.code = code
        switch code {
        case 1:
            self.hint = "HMI Communication Fault"
        case 21:
            self.hint = "Battery Communication Fault"
        case 22:
            self.hint = "Battery Capacity too Low"
        case 23:
            self.hint = "Battery Empty Capacity"
        case 24:
            self.hint = "Cell Overvoltage (HW)"
        case 25:
            self.hint = "Cell Undervoltage (HW)"
        case 26:
            self.hint = "Discharge Overcurrent_1st (HW)"
        case 27:
            self.hint = "Discharge Overcurrent_2nd (HW)"
        case 28:
            self.hint = "Discharge Short Circuit (HW)"
        case 29:
            self.hint = "Charge Overcurrent  (HW)"
        case 30:
            self.hint = "Cell Overvoltage (SW)"
        case 31:
            self.hint = "Cell Undervoltage (SW)"
        case 32:
            self.hint = "Discharge Overcurrent (SW)"
        case 33:
            self.hint = "Charge Overcurrent (SW)"
        case 34:
            self.hint = "Discharge Overtemperature (SW)"
        case 35:
            self.hint = "Discharge Undertemperature (SW)"
        case 36:
            self.hint = "Charge Overtemperature (SW)"
        case 37:
            self.hint = "Charge Undertemperature (SW)"
        case 41:
            self.hint = "Controller Communication Fault"
        case 42:
            self.hint = "Controller Overvoltage"
        case 43:
            self.hint = "Controller Undervoltage"
        case 44:
            self.hint = "Controller bus Overcurrent"
        case 45:
            self.hint = "Controller Over temperature"
        case 46:
            self.hint = "Motor Locked when Walk Assist"
        case 47:
            self.hint = "Motor Locked when Pedal Assist"
        case 48:
            self.hint = "Motor Locked when Throttle Assist"
        case 49:
            self.hint = "Controller U Phase Overcurrent"
        case 50:
            self.hint = "Controller V Phase Overcurrent"
        case 51:
            self.hint = "Controller W Phase Overcurrent"
        case 52:
            self.hint = "Controller bus Overcurrent(SW)"
        case 61:
            self.hint = "Hall all High"
        case 62:
            self.hint = "Hall all Low"
        case 63:
            self.hint = "Hall A Fault"
        case 64:
            self.hint = "Hall B Fault"
        case 65:
            self.hint = "Hall C Fault"
        case 66:
            self.hint = "Speed Sensor Fault"
        case 81:
            self.hint = "Torque Overvoltage"
        case 82:
            self.hint = "Torque Undervoltage"
        case 83:
            self.hint = "Cadence Sensor Fault"
        case 91:
            self.hint = "Throttle Overvoltage"
        case 92:
            self.hint = "Throttle Undervoltage"
        case 101:
            self.hint = "Light Overcurrent"
        case 102:
            self.hint = "Light Overcurrent(SW)"
        case 131:
            self.hint = "Without Chain"
        case 151:
            self.hint = "Front TPMS Communication Fault"
        case 152:
            self.hint = "Rear TPMS Communication Fault"
        case 153:
            self.hint = "Front Tire Pressure too High"
        case 154:
            self.hint = "Rear Tire Pressure too High"
        case 155:
            self.hint = "Front Tire Pressure too Low"
        case 156:
            self.hint = "Rear Tire Pressure too Low"
        case 157:
            self.hint = "Front Tire Tmperature too High"
        case 158:
            self.hint = "Rear Tire Tmperature too High"
        default:
            self.hint = "unknown"
        }
    }
}
