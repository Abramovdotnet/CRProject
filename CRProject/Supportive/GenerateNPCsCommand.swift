/*import Foundation

@main
struct GenerateNPCsCommand {
    static func main() {
        // Create Data directory if it doesn't exist
        let fileManager = FileManager.default
        let dataDirectory = "Data"
        if !fileManager.fileExists(atPath: dataDirectory) {
            try! fileManager.createDirectory(atPath: dataDirectory, withIntermediateDirectories: true)
        }

        // Generate NPCs
        let npcs = NPCGenerator.generateNPCs()
        let jsonData = try! JSONSerialization.data(withJSONObject: npcs, options: .prettyPrinted)

        // Save to file
        let fileURL = URL(fileURLWithPath: "Data/NPCs.json")
        try! jsonData.write(to: fileURL)
        print("Generated \(npcs.count) NPCs and saved to NPCs.json")
    }
} */
