import Foundation

import Foundation
import Combine

class BloodManagementService: GameService {
    
    func feed(vampire: any Character, prey: any Character, amount: Float) throws {
        guard vampire.isVampire else {
            throw BloodError.invalidRecipient("Blood recipient must be a vampire")
        }
        
        guard !prey.isVampire else {
            throw BloodError.invalidPrey("Cannot feed on another vampire")
        }
        
        guard prey.bloodMeter.hasEnoughBlood(amount) else {
            throw BloodError.insufficientBlood("Prey doesn't have enough blood")
        }
        
        // Fixed method calls with proper parameter labels
        prey.bloodMeter.useBlood(amount)
        vampire.bloodMeter.addBlood(amount)
        
        // Notify observers of changes
        (vampire.objectWillChange as? ObservableObjectPublisher)?.send()
        (prey.objectWillChange as? ObservableObjectPublisher)?.send()
    }
    
    func canFeed(vampire: any Character, prey: any Character, amount: Float) -> Bool {
        guard vampire.isVampire, !prey.isVampire else {
            return false
        }
        
        return prey.bloodMeter.hasEnoughBlood(amount)
    }
    
    func getBloodLevel(of character: any Character) -> Float {
        return character.bloodMeter.currentBlood
    }
    
    func getBloodPercentage(of character: any Character) -> Float {
        return character.bloodMeter.bloodPercentage
    }
}

enum BloodError: Error {
    case invalidRecipient(String)
    case invalidPrey(String)
    case insufficientBlood(String)
}
