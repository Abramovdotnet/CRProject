//
//  DeathStatus.swift
//  CRProject
//
//  Created by Abramov Anatoliy on 14.04.2025.
//

enum DeathStatus : String, Codable, CaseIterable {
    case none = "none"
    case unknown = "unknown"
    case investigated = "investigated"
    case confirmed = "confirmed"
}
