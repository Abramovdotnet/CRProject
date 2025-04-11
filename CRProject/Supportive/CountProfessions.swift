/*import Foundation

let fileURL = URL(fileURLWithPath: "Data/NPCs.json")
let data = try! Data(contentsOf: fileURL)
let npcs = try! JSONSerialization.jsonObject(with: data) as! [[String: Any]]

var professionCounts: [String: Int] = [:]

for npc in npcs {
    let profession = npc["profession"] as! String
    professionCounts[profession, default: 0] += 1
}

print("Profession Distribution:")
for (profession, count) in professionCounts.sorted(by: { $0.key < $1.key }) {
    print("\(profession): \(count)")
} */
