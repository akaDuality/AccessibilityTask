//
//  ViewController.swift
//  AccessibilityTask
//
//  Created by Mikhail Rubanov on 03.02.2021.
//

import UIKit
import Accessibility

typealias Email = String
extension Email {
    var isValid: Bool {
        // It’s soooooooo naive, I khow :-)
        let correctSuffix = hasSuffix(".com") || hasSuffix(".ru")
        let hasAddressSign = contains("@")
        return hasAddressSign && correctSuffix
    }
}

extension UIView {
    func roundCorners(radius: CGFloat = 24) {
        layer.cornerRadius = 24
        layer.cornerCurve = .continuous
        clipsToBounds = true
    }
}

extension UIViewController {
    func enableShakeGesture() {
        becomeFirstResponder()
    }
}

class ShakeViewController: UIViewController {
    
    typealias Action = () -> Void
    var onShake: Action?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        enableShakeGesture()
    }
    
    override func motionEnded(_ motion: UIEvent.EventSubtype, with event: UIEvent?) {
        
        if motion == .motionShake {
            onShake?()
        }
    }
}

class ViewController: ShakeViewController, UITextFieldDelegate {

    @IBOutlet weak var successModalView: UIView!
    @IBOutlet private weak var dummyFriendAddressLabel: UILabel!
    
    
    @IBOutlet private weak var postcardLabelsStackContainer: UIStackView!
    @IBOutlet private weak var successTitleLabel: UILabel!
    @IBOutlet private weak var successTextLabel: UILabel!
    
    private lazy var indicator = UIActivityIndicatorView(style: UIActivityIndicatorView.Style.large)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        successModalView.center = view.center
        successModalView.roundCorners()
        successModalView.isHidden = true
        
        priceContainer.roundCorners()
        priceContainer.isHidden = true
        
        onShake = fillMockData
        emailErrorLabel.isHidden = true
        
        emailTextField.delegate = self
        
        let tapRecognizer = UITapGestureRecognizer(target: self, action: #selector(resignKeyboard))
        view.addGestureRecognizer(tapRecognizer)
        
        setupAccessibility()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        setupAccessibilityFrames()
    }
    
    private func setupAccessibility() {
        emailTextField.accessibilityLabel = "Адрес друга"
        
        countStepper.accessibilityTraits.formUnion(.adjustable)
        countStepper.isAccessibilityElement = true
        countStepper.accessibilityValue = "\(piecesCountUniversal(count: Int(countStepper.value))). Итого: \(roublesCountUniversal(count: price))"
        countStepper.accessibilityLabel = "Количество кусочков"
        
        addPostcardSwitch.isAccessibilityElement = true
        addPostcardSwitch.accessibilityLabel = "Добавить открытку за 25 рублей"
        
        totalLabel.accessibilityLabel = "Итого"
        totalLabel.accessibilityValue = roublesCountUniversal(count: price)
        
        if paymentButton.isEnabled {
            paymentButton.accessibilityTraits.remove(.notEnabled)
        } else {
            paymentButton.accessibilityTraits.formUnion(.notEnabled)
        }
        paymentButton.total = price
        paymentButton.piecesCount = Int(countStepper.value)
        
        indicator.accessibilityLabel = "Идет отправка счастья"
        successTitleLabel.accessibilityLabel = [successTitleLabel.text!, successTextLabel.text!].joined(separator: ", ")
        successTextLabel.isAccessibilityElement = false
    }
    
    private func setupAccessibilityFrames() {
        dummyFriendAddressLabel.isAccessibilityElement = false
        
        let stepperA11yFrame = countStepper.accessibilityFrame.union(numberOfPiecesLabel.accessibilityFrame)
        countStepper.accessibilityFrame = screenCoordinate(stepperA11yFrame, in: view)
        numberOfPiecesLabel.isAccessibilityElement = false

        // Стэк-вью ломался :(
//        let postcardSwitchA11yFrame = addPostcardSwitch.accessibilityFrame.union(postcardLabelsStackContainer.accessibilityFrame)
//        addPostcardSwitch.accessibilityFrame = screenCoordinate(postcardSwitchA11yFrame, in: view)
    }
    
    private func piecesCountUniversal(count: Int) -> String {
        let formatString : String = NSLocalizedString(
            "pieces",
            comment: ""
        )
        let resultString = String(format: formatString, count)
        return resultString;
    }
    
    private func screenCoordinate(_ value: CGRect, in view: UIView) -> CGRect {
        UIAccessibility.convertToScreenCoordinates(value, in: view)
    }
    
    @objc private func resignKeyboard() {
        view.endEditing(true)
    }
    
    private func fillMockData() {
        emailTextField.text = "test@test.ru"
        emailDidChanged(emailTextField)
    }

    // MARK: - Email
    @IBOutlet weak var emailTextField: UITextField!
    @IBOutlet weak var emailErrorLabel: UILabel!
    
    @IBAction func emailDidChanged(_ sender: UITextField) {
        let email: Email = sender.text!
        
        priceContainer.isHidden = !email.isValid
        paymentButton.isEnabled = email.isValid
        
        if email.isValid {
            sender.resignFirstResponder() // Hide keyboard
        }
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
    
    @IBOutlet weak var emailMistakeLabel: UILabel!
    @IBAction func emailEditiingDidEnd(_ sender: UITextField) {
        let email: Email = sender.text!
        emailMistakeLabel.isHidden = email.isValid
        if email.isValid {
            UIAccessibility.post(notification: .layoutChanged, argument: countStepper)
        } else {
            UIAccessibility.post(notification: .layoutChanged, argument: emailMistakeLabel)
        }
    }
    
    
    // MARK: - Price
    @IBOutlet weak var priceContainer: UIView!
    @IBOutlet weak var countStepper: AccessibleStepper!
    @IBOutlet weak var numberOfPiecesLabel: UILabel!
    @IBAction func numberOfPiecesDidChange(_ sender: UIStepper) {
        numberOfPiecesLabel.text = piecesCountUniversal(count: Int(sender.value))
        updateTotal()
        setupAccessibility()
    }
    
    @IBOutlet weak var addPostcardSwitch: UISwitch!
    @IBAction func addPostcardDidChange(_ sender: Any) {
        updateTotal()
        paymentButton.postcardAdded = addPostcardSwitch.isOn
    }
    
    @IBOutlet weak var totalLabel: UILabel!
    var price: Int {
        var value = countStepper.value * 50
        if addPostcardSwitch.isOn {
            value += 25
        }
        return Int(value)
    }
    
    private func updateTotal() {
        totalLabel.text = "\(price) ₽"
        setupAccessibility()
    }
    
    
    // MARK: - Payment
    @IBOutlet weak var paymentButton: PaymentButton!
    private var overlay: UIView!
    
    func startPayment() {
        func addOverlay() {
            overlay = UIView()
            overlay.backgroundColor = .black
            overlay.alpha = 0.5
            overlay.frame = view.frame
            view.addSubview(overlay)
        }
        
        addOverlay()
        
        indicator.startAnimating()
        indicator.hidesWhenStopped = true
        overlay.addSubview(indicator)
        indicator.center = overlay.center
        UIAccessibility.post(notification: .screenChanged, argument: indicator)
    }
    
    func finishPayment() {
        indicator.stopAnimating()
        view.addSubview(successModalView)
        successModalView.isHidden = false
        UIAccessibility.post(notification: .screenChanged, argument: successTitleLabel)
    }
    
    @IBAction func pay(_ sender: Any) {
        startPayment()
        
        DispatchQueue.main.asyncAfter(
            deadline: .now() + .seconds(1))
        {
            self.finishPayment()
        }
    }
    
    // MARK: - Modal view
    @IBAction func closeModalView(_ sender: Any) {
        overlay.removeFromSuperview()
        overlay = nil
        successModalView.isHidden = true
        
        func clearInput() {
            emailTextField.text = ""
            emailDidChanged(emailTextField)
        }
        
        clearInput()
        UIAccessibility.post(notification: .screenChanged, argument: emailTextField)
    }
}

final class PaymentButton: UIButton {
    var piecesCount: Int = 0
    var postcardAdded: Bool = false
    var total: Int = 0
}

extension PaymentButton: AXCustomContentProvider {

    var accessibilityCustomContent: [AXCustomContent]! {
        get {
            guard isEnabled else {
                return []
            }
            let pieces = AXCustomContent(label: "Кусочков", value: String(describing: piecesCount))
            var postcard: AXCustomContent?
            if postcardAdded {
                postcard = AXCustomContent(label: "С открыткой", value: "")
            }
            let total = AXCustomContent(label: "Итого", value: roublesCountUniversal(count: total))
            total.importance = .high
            return [pieces, postcard, total].compactMap { $0 }
        }
        set(accessibilityCustomContent) { }
    }
}

final class AccessibleStepper: UIStepper {

    override func accessibilityIncrement() {
        value += stepValue
        sendActions(for: .valueChanged)
    }

    override func accessibilityDecrement() {
        value -= stepValue
        sendActions(for: .valueChanged)
    }
}


private func roublesCountUniversal(count: Int) -> String {
    let formatString : String = NSLocalizedString(
        "roubles",
        comment: ""
    )
    let resultString = String(format: formatString, count)
    return resultString;
}
