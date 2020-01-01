import Foundation
import UIKit

extension UIFont {
    convenience init? (familyName: String, size: CGFloat = UIFont.systemFontSize, variantName: String? = nil)
    {
        guard let name = UIFont.familyNames
            .filter({ $0.contains(familyName) })
            .flatMap({ UIFont.fontNames(forFamilyName: $0) })
            .filter({variantName != nil ? $0.contains(variantName!) : true})
            .first else {return nil}
        
        self.init(name: name, size: size)
    }
}

struct Theme {
    static func apply() {
        guard let hearderFont = UIFont(familyName: "Lobster", size: UIFont.systemFontSize * 2) else {
            NSLog("Failed to load header font")
            return
        }
        
        guard let primaryFont = UIFont(familyName: "Quicksand") else {
            NSLog("Failed to load application font")
            return
        }
        
        let tintColor = #colorLiteral(red: 0.56, green: 0.35, blue: 0.97, alpha: 1)
        
        UIApplication.shared.delegate?.window??.tintColor = tintColor
        
        let navBar = UINavigationBar.appearance()
        navBar.titleTextAttributes = [.font: hearderFont]
        
        let navBarLabel = UILabel.appearance(whenContainedInInstancesOf: [UINavigationBar.self])
        navBarLabel.font = primaryFont
        
        let label = UILabel.appearance()
        label.font = primaryFont
        
        let barButton = UIBarButtonItem.appearance()
        barButton.setTitleTextAttributes([.font: primaryFont], for: .normal)
        barButton.setTitleTextAttributes([.font: primaryFont], for: .highlighted)
        
        let buttonLabel = UILabel.appearance(whenContainedInInstancesOf: [UIButton.self])
        buttonLabel.font = primaryFont
    }
}
