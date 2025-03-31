class SceneBuilder {
    private var name: String = ""
    private var characters: [any Character] = []
    private var isIndoor: Bool = false
    
    
    func withName(_ name: String) -> SceneBuilder {
        self.name = name
        return self
    }
    
    func withIsIndoor(_ isIndoor: Bool) -> SceneBuilder {
        self.isIndoor = isIndoor
        return self
    }
    
    func withCharacter(_ character: any Character) -> SceneBuilder {
        characters.append(character)
        return self
    }
    
    func withCharacters(_ characters: [any Character]) -> SceneBuilder {
        self.characters.append(contentsOf: characters)
        return self
    }
    
    func build() -> Scene {
        let scene = Scene()
        scene.name = name
        scene.isIndoor = isIndoor
        scene.setCharacters(characters)
        return scene
    }
}
