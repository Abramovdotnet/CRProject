//
//  IScene.swift
//  CRProject
//
//  Created by Abramov Anatoliy on 31.03.2025.
//

import Foundation

protocol SceneProtocol: Codable, ObservableObject {
    var id: Int { get }
    var name: String { get set }
    var isParent: Bool { get set }
    var parentSceneId: Int { get set }
    var parentSceneName: String { get set }
    var parentSceneType: SceneType { get set }
    var childSceneIds: [Int] { get }
    var hubSceneIds: [Int] { get }
    var isIndoor: Bool { get }
    var sceneType: SceneType { get set }
    
    func getCharacters() -> [any Character]
    func setCharacters(_ characters: [any Character])
    func getCharacter(by id: Int) -> (any Character)?
    func addChildScene(_ childSceneId: Int)
    func removeChildScene(_ childSceneId: Int)
}
