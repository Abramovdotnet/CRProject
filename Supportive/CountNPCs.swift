import Foundation

// Read the JSON file
let fileURL = URL(fileURLWithPath: "CRProject/Data/NPCs.json")
let data = try! Data(contentsOf: fileURL)
let npcs = try! JSONSerialization.jsonObject(with: data) as! [[String: Any]]

// Count NPCs by profession
var professionCounts: [String: Int] = [:]
for npc in npcs {
    let profession = npc["profession"] as! String
    professionCounts[profession, default: 0] += 1
}

// Print results
print("\nNPC Count by Profession:")
for (profession, count) in professionCounts.sorted(by: { $0.key < $1.key }) {
    print("\(profession): \(count)")
}
print("\nTotal NPCs: \(npcs.count)") 