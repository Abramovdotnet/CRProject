class SceneBuilder {
    private var name: String = ""
    private var characters: [any Character] = []
    
    func withName(_ name: String) -> SceneBuilder {
        self.name = name
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
        scene.setCharacters(characters)
        return scene
    }
}
