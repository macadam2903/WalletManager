import UIKit

enum Haptics {
    // Gomb megnyomásakor - könnyű tap
    static func buttonTap() {
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.prepare()
        generator.impactOccurred()
    }
    
    // Mentéskor - puha visszajelzés
    static func saveImpact() {
        let generator = UIImpactFeedbackGenerator(style: .soft)
        generator.prepare()
        generator.impactOccurred()
    }
    
    // Sikeres tranzakció hozzáadásakor - bugyborékoló dupla rezgés
    static func transactionSuccess() {
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.prepare()
        generator.impactOccurred()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            generator.impactOccurred(intensity: 0.6)
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.18) {
            generator.impactOccurred(intensity: 0.3)
        }
    }
    
    // Hiba esetén - éles kettős ütés
    static func error() {
        let generator = UINotificationFeedbackGenerator()
        generator.prepare()
        generator.notificationOccurred(.error)
    }
}
