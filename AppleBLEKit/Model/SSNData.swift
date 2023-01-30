//
//  SSNData.swift
//  DST
//
//  Created by abe chen on 2022/11/21.
//

import Foundation

struct SsnData: Codable {
    let id: String
    let systemModelID: String
    let frameNumber: String
    let proSaleDate: Date?
    let wheelCircumference: Int?
    let tirePressure: Int?
    let speedLimit: Int?
    let speedUnit: String?
    let hmiDSN: String
    let displayDSN: String?
    let controllerDSN: String?
    let batteryDSN: String?
    let cadenceSensorDSN: String?
    let motorDSN: String?
    let torqueSensorDSN: String?
    let chargerDSN: String?
    let frontLightDSN, rearLightDSN, throttleDSN, eBrakeDSN: String?
    let eLockDSN, eFrontDerailleurDSN, eRearDerailleurDSN, iotDSN: String?
    let hmiDisplayDSN, batteryHmiDSN, batteryControllerDSN, batteryControllerHmiDSN: String?
    let lastChangeTime, appUserID: String?

    enum CodingKeys: String, CodingKey {
        case id
        case systemModelID = "system_model_id"
        case frameNumber = "frame_number"
        case proSaleDate = "pro_sale_date"
        case wheelCircumference = "wheel_circumference"
        case tirePressure = "tire_pressure"
        case speedLimit = "speed_limit"
        case speedUnit = "speed_unit"
        case hmiDSN = "hmi_dsn"
        case displayDSN = "display_dsn"
        case controllerDSN = "controller_dsn"
        case batteryDSN = "battery_dsn"
        case motorDSN = "motor_dsn"
        case cadenceSensorDSN = "cadence_sensor_dsn"
        case torqueSensorDSN = "torque_sensor_dsn"
        case chargerDSN = "charger_dsn"
        case frontLightDSN = "front_light_dsn"
        case rearLightDSN = "rear_light_dsn"
        case throttleDSN = "throttle_dsn"
        case eBrakeDSN = "e_brake_dsn"
        case eLockDSN = "e_lock_dsn"
        case eFrontDerailleurDSN = "e_front_derailleur_dsn"
        case eRearDerailleurDSN = "e_rear_derailleur_dsn"
        case iotDSN = "iot_dsn"
        case hmiDisplayDSN = "hmi_display_dsn"
        case batteryHmiDSN = "battery_hmi_dsn"
        case batteryControllerDSN = "battery_controller_dsn"
        case batteryControllerHmiDSN = "battery_controller_hmi_dsn"
        case lastChangeTime = "last_change_time"
        case appUserID = "app_user_id"
    }
}
