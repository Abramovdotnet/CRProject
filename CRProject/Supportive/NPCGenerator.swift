import Foundation


class NPCGenerator {
    private static let maleFirstNames = [
        // English/American male names
        "John", "Michael", "William", "James", "Alexander", "Benjamin", "Daniel", "Henry", "Joseph", "Samuel",
        "David", "Matthew", "Andrew", "Christopher", "Jack", "Thomas", "Oliver", "Lucas", "Noah", "Ethan",
        // European male names
        "Liam", "Marcus", "Adrian", "Felix", "Gustav", "Henrik", "Klaus", "Franz", "Paolo", "Marco",
        "Carlo", "Pietro", "Giovanni", "Antonio", "Lorenzo", "Friedrich", "Wolfgang", "Rudolf", "Maximilian", "Ludwig",
        "Giuseppe", "Enzo", "Luca", "Matteo", "Dante", "Henri", "Pierre", "Louis", "François", "Jean",
        "Marcel", "André", "Philippe", "Claude", "René", "Hans", "Otto", "Werner", "Dieter", "Günther",
        "Vittorio", "Stefano", "Roberto", "Massimo", "Alberto", "Jean-Pierre", "Alain", "Michel", "Jacques", "Yves",
        "Karl", "Wilhelm", "Hermann", "Walter", "Heinrich", "Sergio", "Gianni", "Bruno", "Mario", "Franco",
        // Nordic male names
        "Erik", "Magnus", "Bjorn", "Lars", "Sven", "Thor", "Leif", "Axel", "Oscar", "Gustav",
        "Anders", "Olaf", "Harald", "Nils", "Johan", "Rune", "Arne", "Einar", "Gunnar", "Ivar",
        "Ragnar", "Eskil", "Torsten", "Viggo", "Birger", "Valdemar", "Haakon", "Olav", "Eirik", "Knut",
        "Bjarne", "Finn", "Halfdan", "Trygve", "Sigurd", "Roar", "Geir", "Steinar", "Odd", "Per",
        "Torbjorn", "Erling", "Sverre", "Dag", "Ole", "Hakon", "Egil", "Sten", "Amund", "Tore",
        // Slavic male names
        "Ivan", "Dmitri", "Vladimir", "Boris", "Sergei", "Mikhail", "Nikolai", "Pavel", "Alexei", "Yuri"
    ]
    
    private static let femaleFirstNames = [
        // English/American female names
        "Emma", "Sophia", "Olivia", "Ava", "Isabella", "Mia", "Charlotte", "Amelia", "Harper", "Evelyn",
        "Abigail", "Emily", "Elizabeth", "Sofia", "Victoria", "Grace", "Chloe", "Lily", "Zoe", "Hannah",
        // European female names
        "Anna", "Elena", "Clara", "Lucia", "Ingrid", "Astrid", "Heidi", "Greta", "Chiara", "Bianca",
        "Valentina", "Sofia", "Francesca", "Isabella", "Maria", "Mathilde", "Johanna", "Elise", "Sophie", "Katharina",
        "Alessandra", "Beatrice", "Claudia", "Vittoria", "Adriana", "Camille", "Margot", "Amélie", "Céline", "Delphine",
        "Juliette", "Madeleine", "Élise", "Pauline", "Simone", "Gertrude", "Hildegard", "Ursula", "Sabine", "Helga",
        "Elisabetta", "Caterina", "Gabriella", "Silvia", "Lucia", "Isabelle", "Sophie", "Marie-Claire", "Brigitte", "Monique",
        "Ingeborg", "Marlene", "Renate", "Erika", "Monika", "Paola", "Rosa", "Teresa", "Angela", "Giovanna",
        // Nordic female names
        "Astrid", "Freya", "Ingrid", "Helga", "Sigrid", "Hedda", "Linnea", "Britta", "Ebba", "Saga",
        "Kristin", "Dagmar", "Elin", "Karin", "Astrid", "Solveig", "Liv", "Hilda", "Greta", "Frida",
        "Ylva", "Tyra", "Maja", "Alma", "Asta", "Sigrid", "Ragnhild", "Gudrun", "Turid", "Bergljot",
        "Hildur", "Ingeborg", "Signe", "Astri", "Bodil", "Toril", "Randi", "Berit", "Marit", "Kirsten",
        "Eldrid", "Runa", "Aslaug", "Inger", "Vigdis", "Torunn", "Alfhild", "Borgny", "Gjertrud", "Magnhild",
        // Slavic female names
        "Natasha", "Olga", "Tatiana", "Svetlana", "Anastasia", "Ekaterina", "Marina", "Irina", "Yelena", "Polina"
    ]
    
    private static let lastNames = [
        // English/American surnames
        "Smith", "Johnson", "Williams", "Brown", "Jones", "Garcia", "Miller", "Davis", "Rodriguez", "Martinez",
        "Hernandez", "Lopez", "Gonzalez", "Wilson", "Anderson", "Thomas", "Taylor", "Moore", "Jackson", "Martin",
        "Lee", "Thompson", "White", "Harris", "Clark", "Lewis", "Robinson", "Walker", "Young", "Allen",
        "King", "Wright", "Scott", "Green", "Baker", "Adams", "Nelson", "Carter", "Mitchell", "Roberts",
        // European surnames
        "Mueller", "Schmidt", "Fischer", "Weber", "Meyer", "Wagner", "Becker", "Hoffmann", "Rossi", "Ferrari",
        "Russo", "Romano", "Colombo", "Ricci", "Marino", "Costa", "Fontana", "Conti", "Bernard", "Dubois",
        "Lefebvre", "Moreau", "Laurent", "Simon", "Michel", "Leroy", "Roux", "David", "Bertrand", "Morel",
        // Additional European surnames
        "Schneider", "Zimmermann", "Schulz", "Hoffmann", "Schäfer", "Bauer", "Klein", "Richter", "Wolf", "Schroder",
        "Esposito", "Bianchi", "Rizzo", "Greco", "Lombardi", "De Luca", "Santoro", "Marini", "Ferrara", "Gallo",
        "Dupont", "Martin", "Durand", "Dubois", "Moreau", "Lambert", "Bonnet", "Girard", "Fournier", "Mercier",
        "Schmitt", "Krause", "Schwarz", "Lang", "Schuster", "Neumann", "Braun", "Zimmerman", "Kruger", "Hoffman",
        "Conti", "De Angelis", "Mancini", "Pellegrini", "Bernardi", "Vitale", "Benedetti", "Cattaneo", "Palmieri", "Serra",
        "Rousseau", "Blanc", "Guerin", "Faure", "Legrand", "Garnier", "Chevalier", "Gauthier", "Perrin", "Morin",
        "Huber", "Berger", "Gruber", "Baumgartner", "Maier", "Hofer", "Pichler", "Steiner", "Moser", "Mayer",
        "Fabbri", "Leone", "Marchetti", "Valentini", "Ferri", "Mariani", "Rizzi", "Rossetti", "Gentile", "Villa",
        "Lefevre", "Lemaire", "Mathieu", "Gautier", "Leclerc", "Masson", "Germain", "Picard", "Fontaine", "Weber",
        // Nordic surnames
        "Andersson", "Johansson", "Karlsson", "Nilsson", "Eriksson", "Larsson", "Olsson", "Persson", "Svensson", "Gustafsson",
        "Nielsen", "Jensen", "Hansen", "Pedersen", "Andersen", "Christensen", "Larsen", "Sorensen", "Rasmussen", "Petersen",
        // Additional Nordic surnames
        "Lindberg", "Strom", "Bergman", "Lundgren", "Hedlund", "Norberg", "Sandberg", "Blomqvist", "Lindstrom", "Magnusson",
        "Kristiansen", "Olsen", "Johnsen", "Pettersen", "Halvorsen", "Berg", "Haugen", "Johannessen", "Andreassen", "Jacobsen",
        "Holm", "Nystrom", "Lundqvist", "Bjorklund", "Bergstrom", "Ekman", "Holmberg", "Sundberg", "Wallin", "Engstrom",
        "Thomsen", "Knudsen", "Madsen", "Mortensen", "Moller", "Christiansen", "Dahl", "Eriksen", "Vestergaard", "Jorgensen",
        "Lindholm", "Forsberg", "Wikstrom", "Axelsson", "Nordstrom", "Soderstrom", "Ahlstrom", "Henriksson", "Lindqvist", "Knutsson",
        "Jakobsen", "Gundersen", "Fredriksen", "Paulsen", "Bakken", "Eide", "Moen", "Strand", "Solberg", "Iversen",
        "Ostlund", "Berglund", "Hellstrom", "Sjoberg", "Oberg", "Hedberg", "Lindgren", "Eklund", "Fransson", "Gunnarsson",
        "Mikkelsen", "Kristoffersen", "Antonsen", "Nilsen", "Jenssen", "Aas", "Hovland", "Karlsen", "Gulbrandsen", "Ruud"
    ]
    
    static func createPlayer() -> Player {
          return Player(name: "Victor", sex: .male, age: 300, profession: .noProfession, id: 0)
      }
    
    // MARK: - District NPC Distributions
    
    private static let residentialDistrictNPCs: [(profession: Profession, count: Int)] = [
        (.noProfession, 90), // No profession
        (.cityGuard, 11), // City guards
        (.carpenter, 10), // Carpenters
        (.tailor, 10), // Tailors
        (.gardener, 10), // Gardeners
        (.maintenanceWorker, 10), // Maintenance workers
        (.cleaner, 10), // Cleaners
        (.apprentice, 10), // Apprentices
        (.lordLady, 10), // Lords/Ladies
        (.administrator, 10), // Administrators
        (.stableHand, 10), // Stable hands
        (.kitchenStaff, 10)  // Kitchen staff
    ]
    
    private static let noblesCrestNPCs: [(profession: Profession, count: Int)] = [
        (.militaryOfficer, 25), // Military officers
        (.servant, 12), // Servants
        (.cityGuard, 5), // City guards
        (.administrator, 5), // Administrators
        (.lordLady, 2)   // Lords/Ladies
    ]
    
    private static let hallowedGroundsNPCs: [(profession: Profession, count: Int)] = [
        (.monk, 15), // Monks
        (.religiousScholar, 13), // Religious scholars
        (.priest, 3),  // Priests
        (.cityGuard, 2), // City guards
        (.cleaner, 2)   // Cleaners
    ]
    
    private static let commercialDistrictNPCs: [(profession: Profession, count: Int)] = [
        (.generalLaborer, 70), // General laborers
        (.bookseller, 15),  // Booksellers
        (.cityGuard, 8), // City guards
        (.blacksmith, 2), // Blacksmiths
        (.alchemist, 2), // Alchemists
        (.herbalist, 2) // Herbalists
    ]
    
    private static let entertainmentDistrictNPCs: [(profession: Profession, count: Int)] = [
        (.barmaid, 17), // Barmaids
        (.entertainer, 17), // Entertainers
        (.cleaner, 9), // Cleaners
        (.cityGuard, 5), // City guards
        (.tavernKeeper, 1), // Tavern keepers
        (.courtesan, 3) // Courtesans
    ]
    
    private static let docksNPCs: [(profession: Profession, count: Int)] = [
        (.generalLaborer, 4), // General laborers
        (.dockWorker, 2), // Dock workers
        (.sailor, 2), // Sailors
        (.cityGuard, 2), // City guards
        (.shipCaptain, 0)  // Ship captains
    ]
    
    private static let temporaryPopulationNPCs: [(profession: Profession, count: Int)] = [
        (.adventurer, 30), // Adventurers
        (.pilgrim, 18),    // Pilgrims
        (.noProfession, 15),    // No profession
        (.merchant, 11)    // Merchants
    ]
    
    static func generateNPCs() -> [[String: Any]] {
        var npcs: [[String: Any]] = []
        var currentId = 1
        
        // Generate NPCs for each district based on predefined distributions
        let allDistrictNPCs = [
            residentialDistrictNPCs,
            noblesCrestNPCs,
            hallowedGroundsNPCs,
            commercialDistrictNPCs,
            entertainmentDistrictNPCs,
            docksNPCs,
            temporaryPopulationNPCs
        ]
        
        for districtNPCs in allDistrictNPCs {
            for (profession, count) in districtNPCs {
                for _ in 0..<count {
                    let sex = Bool.random() ? "male" : "female"
                    let firstName = sex == "male" ? maleFirstNames.randomElement()! : femaleFirstNames.randomElement()!
                    let lastName = lastNames.randomElement()!
                    
                    let npc: [String: Any] = [
                        "id": currentId,
                        "name": "\(firstName) \(lastName)",
                        "sex": sex,
                        "age": Int.random(in: 18...80),
                        "profession": profession.rawValue,
                        "homeLocationId": 0, // Will be set later
                        "isVampire": false
                    ]
                    
                    npcs.append(npc)
                    currentId += 1
                }
            }
        }
        
        return npcs
    }
    
    static func saveToFile() {
        let npcs = generateNPCs()
        let jsonData = try! JSONSerialization.data(withJSONObject: npcs, options: .prettyPrinted)
        
        // Create Data directory if it doesn't exist
        let fileManager = FileManager.default
        let dataDirectory = "Data"
        if !fileManager.fileExists(atPath: dataDirectory) {
            try! fileManager.createDirectory(atPath: dataDirectory, withIntermediateDirectories: true)
        }
        
        let fileURL = URL(fileURLWithPath: "Data/NPCs.json")
        try! jsonData.write(to: fileURL)
        DebugLogService.shared.log("Generated \(npcs.count) NPCs and saved to NPCs.json", category: "NPC")
    }
}

// Call saveToFile when the script is run
//NPCGenerator.saveToFile()

#if DEBUG
// Only run this in debug builds
func generateNPCs() {
    let npcs = NPCGenerator.generateNPCs()
    let jsonData = try! JSONSerialization.data(withJSONObject: npcs, options: .prettyPrinted)
    
    // Create Data directory if it doesn't exist
    let fileManager = FileManager.default
    let dataDirectory = "CRProject/Data"
    if !fileManager.fileExists(atPath: dataDirectory) {
        try! fileManager.createDirectory(atPath: dataDirectory, withIntermediateDirectories: true)
    }
    
    let fileURL = URL(fileURLWithPath: "CRProject/Data/NPCs.json")
    try! jsonData.write(to: fileURL)
    DebugLogService.shared.log("Generated \(npcs.count) NPCs and saved to NPCs.json", category: "NPC")
}

// Uncomment to generate NPCs
// generateNPCs()
#endif
