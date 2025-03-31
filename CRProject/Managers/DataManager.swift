//
//  DataManager.swift
//  CRProject
//
//  Created by Abramov Anatoliy on 31.03.2025.
//

import Foundation

final class DataManager {
    static let shared = DataManager()
    
    private let fileManager = FileManager.default
    private let baseDirectory: URL
    
    private init() {
        // iOS documents directory
        let documentsDirectory = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
        baseDirectory = documentsDirectory.appendingPathComponent("CrimsonRequiemData")
        
        // Create directory structure
        createDirectoryIfNeeded()
    }
    
    private func createDirectoryIfNeeded() {
        let directories = [
            baseDirectory.appendingPathComponent("Scenes"),
            baseDirectory.appendingPathComponent("NPCs"),
            baseDirectory.appendingPathComponent("Characters")
        ]
        
        for directory in directories {
            if !fileManager.fileExists(atPath: directory.path) {
                try? fileManager.createDirectory(at: directory, withIntermediateDirectories: true)
            }
        }
    }
    
    // MARK: - Generic Save/Load Methods
    
    private func save<T: Codable>(_ object: T, to directory: URL, fileName: String) throws {
        let fileURL = directory.appendingPathComponent(fileName).appendingPathExtension("plist")
        let data = try PropertyListEncoder().encode(object)
        try data.write(to: fileURL, options: .atomic)
    }
    
    private func load<T: Codable>(from directory: URL, fileName: String) throws -> T {
        let fileURL = directory.appendingPathComponent(fileName).appendingPathExtension("plist")
        let data = try Data(contentsOf: fileURL)
        return try PropertyListDecoder().decode(T.self, from: data)
    }
    
    private func loadAll<T: Codable>(from directory: URL) throws -> [T] {
        let files = try fileManager.contentsOfDirectory(at: directory, includingPropertiesForKeys: nil)
            .filter { $0.pathExtension == "plist" }
        
        return try files.map { fileURL in
            let data = try Data(contentsOf: fileURL)
            return try PropertyListDecoder().decode(T.self, from: data)
        }
    }
    
    // MARK: - Scene Operations
    
    func saveScene(_ scene: any SceneProtocol) throws {
        let scenesDirectory = baseDirectory.appendingPathComponent("Scenes")
        try save(scene, to: scenesDirectory, fileName: scene.id.uuidString)
    }
    
    func loadScene(id: UUID) throws -> Scene {
        let scenesDirectory = baseDirectory.appendingPathComponent("Scenes")
        return try load(from: scenesDirectory, fileName: id.uuidString)
    }
    
    func loadAllScenes() throws -> [Scene] {
        let scenesDirectory = baseDirectory.appendingPathComponent("Scenes")
        return try loadAll(from: scenesDirectory)
    }
    
    // MARK: - NPC Operations
    
    func saveNPC(_ npc: NPC) throws {
        let npcsDirectory = baseDirectory.appendingPathComponent("NPCs")
        try save(npc, to: npcsDirectory, fileName: npc.id.uuidString)
    }
    
    func loadNPC(id: UUID) throws -> NPC {
        let npcsDirectory = baseDirectory.appendingPathComponent("NPCs")
        return try load(from: npcsDirectory, fileName: id.uuidString)
    }
    
    func loadAllNPCs() throws -> [NPC] {
        let npcsDirectory = baseDirectory.appendingPathComponent("NPCs")
        return try loadAll(from: npcsDirectory)
    }
    
    // MARK: - Cleanup
    
    func clearAllData() throws {
        try fileManager.removeItem(at: baseDirectory)
        createDirectoryIfNeeded()
    }
}
