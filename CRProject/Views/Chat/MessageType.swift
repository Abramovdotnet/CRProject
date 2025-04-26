//
//  MessageType.swift
//  CRProject
//
//  Created by Abramov Anatoliy on 26.04.2025.
//


import Combine
import SwiftUI
import SwiftUICore
import Foundation

enum MessageType: String, CaseIterable {
    case common
    case warning
    case system
    case dialogue
    case event
    case danger
}