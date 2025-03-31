//
//  IScene.swift
//  CRProject
//
//  Created by Abramov Anatoliy on 31.03.2025.
//

import Foundation

protocol SceneProtocol: Codable, ObservableObject {
    var id: UUID { get }
    var name: String { get set }
    var parentSceneId: UUID? { get set }
    var childSceneIds: [UUID] { get }
    
    func getCharacters() -> [any Character]
    func setCharacters(_ characters: [any Character])
    func getCharacter(by id: UUID) -> (any Character)?
    func addChildScene(_ childSceneId: UUID)
    func removeChildScene(_ childSceneId: UUID)
}
