//
//  SMIDResponse.swift
//  DST
//
//  Created by abe chen on 2022/11/11.
//

import Foundation

struct SmidData: Codable {
    let id: String
    let brandID: Int
    let name: String?
    let image: String?
    let wheelCircumference, tirePressure, speedLimit: Int
    let hmiDmid: String
    let batteryDmid: String
    let controllerDmid: String
    let speedUnit, displayDmid: String?
    let motorDmid, cadenceSensorDmid, torqueSensorDmid: String?
    let chargerDmid, frontLightDmid, rearLightDmid, throttleDmid: String?
    let eBrakeDmid, eLockDmid, eFrontDerailleurDmid, eRearDerailleurDmid: String?
    let iotDmid: String?
    let hmiDisplayDmid: String?
    let batteryHmiDmid: String?
    let batteryControllerDmid: String?
    let batteryControllerHmiDmid: String?
    let note: String?

    enum CodingKeys: String, CodingKey {
        case id
        case brandID = "brand_id"
        case name, image
        case wheelCircumference = "wheel_circumference"
        case tirePressure = "tire_pressure"
        case speedLimit = "speed_limit"
        case speedUnit = "speed_unit"
        case hmiDmid = "hmi_dmid"
        case displayDmid = "display_dmid"
        case controllerDmid = "controller_dmid"
        case batteryDmid = "battery_dmid"
        case motorDmid = "motor_dmid"
        case cadenceSensorDmid = "cadence_sensor_dmid"
        case torqueSensorDmid = "torque_sensor_dmid"
        case chargerDmid = "charger_dmid"
        case frontLightDmid = "front_light_dmid"
        case rearLightDmid = "rear_light_dmid"
        case throttleDmid = "throttle_dmid"
        case eBrakeDmid = "e_brake_dmid"
        case eLockDmid = "e_lock_dmid"
        case eFrontDerailleurDmid = "e_front_derailleur_dmid"
        case eRearDerailleurDmid = "e_rear_derailleur_dmid"
        case iotDmid = "iot_dmid"
        case hmiDisplayDmid = "hmi_display_dmid"
        case batteryHmiDmid = "battery_hmi_dmid"
        case batteryControllerDmid = "battery_controller_dmid"
        case batteryControllerHmiDmid = "battery_controller_hmi_dmid"
        case note
    }
}
