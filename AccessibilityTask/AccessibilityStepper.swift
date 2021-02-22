//
//  AccessibilityStepper.swift
//  AccessibilityTask
//
//  Created by Иван Ерасов on 19.02.2021.
//

import Foundation
import UIKit

class AccessibilityStepper: UIStepper {
    
    override func accessibilityIncrement() {
        value += stepValue
        sendActions(for: .valueChanged)
    }
    
    override func accessibilityDecrement() {
        value -= stepValue
        sendActions(for: .valueChanged)
    }
}
