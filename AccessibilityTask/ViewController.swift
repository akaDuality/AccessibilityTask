//
//  ViewController.swift
//  AccessibilityTask
//
//  Created by Mikhail Rubanov on 03.02.2021.
//

import UIKit

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

class ViewController: ShakeViewController {

    @IBOutlet weak var successTitleLabel: UILabel!
    @IBOutlet weak var successCountLabel: UILabel!
    @IBOutlet weak var successAnotherTryButton: UIButton!
    @IBOutlet weak var successModalView: UIView!
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        
        successModalView.center = view.center
        successModalView.roundCorners()
        successModalView.isHidden = true
        
        priceContainer.roundCorners()
        priceContainer.isHidden = true
        
        onShake = fillMockData
        emailErrorLabel.isHidden = true
        
        addToolbar(for: emailTextField)
        
        setupAccessibility()
        refreshAccessibilityProperties()
    }
    
    override func viewDidLayoutSubviews() {
        DispatchQueue.main.async { [weak self] in
            self?.refreshAccessibilityFrames()
        }
    }
    
    private func fillMockData() {
        emailTextField.text = "test@test.ru"
        emailDidChanged(emailTextField)
    }
    
    // MARK: - Introduction
    
    @IBOutlet weak var sloganLabel: UILabel!
    @IBOutlet weak var descriptionLabel: UILabel!

    // MARK: - Email
    
    @IBOutlet weak var emailStackView: UIStackView!
    @IBOutlet weak var emailTextField: UITextField!
    @IBOutlet weak var emailErrorLabel: UILabel!
    
    @IBAction func emailDidChanged(_ sender: UITextField) {
        
        let email: Email = sender.text!
        
        priceContainer.isHidden = !email.isValid || email.isEmpty
        paymentButton.isEnabled = email.isValid
        
        if email.isValid {
            sender.resignFirstResponder() // Hide keyboard
        }
    }
    
    @IBOutlet weak var emailMistakeLabel: UILabel!
    @IBAction func emailEditiingDidEnd(_ sender: UITextField) {
        
        let email: Email = sender.text!
        emailMistakeLabel.isHidden = email.isValid || email.isEmpty
        
        updateTotal()
        refreshAccessibilityProperties()
        
        let argument = email.isValid ? countStepper : emailTextField
        UIAccessibility.post(notification: .layoutChanged, argument: argument)
    }
    
    
    // MARK: - Price
    
    var piecePrice: UInt = 50
    var postcardPrice: UInt = 25
    var currentTotal: UInt = 0
    
    @IBOutlet weak var countContainer: UIStackView!
    @IBOutlet weak var postcardContainer: UIStackView!
    @IBOutlet weak var totalContainer: UIView!
    @IBOutlet weak var priceContainer: UIView!
    @IBOutlet weak var countStepper: UIStepper!
    @IBOutlet weak var numberOfPiecesLabel: UILabel!
    
    @IBAction func numberOfPiecesDidChange(_ sender: UIStepper) {
        numberOfPiecesLabel.text = String(Int(sender.value)) + " " + getPieceWordForCount(count: UInt(sender.value))
        updateTotal()
        refreshAccessibilityProperties()
    }
    
    @IBOutlet weak var addPostcardSwitch: UISwitch!
    
    @IBAction func addPostcardDidChange(_ sender: Any) {
        updateTotal()
        refreshAccessibilityProperties()
    }
    
    @IBOutlet weak var totalLabel: UILabel!
    
    private func updateTotal() {
        
        currentTotal = UInt(countStepper.value) * piecePrice
        
        if addPostcardSwitch.isOn {
            currentTotal += postcardPrice
        }
        
        totalLabel.text = "\(currentTotal) ₽"
    }
    
    // MARK: - Payment
    
    @IBOutlet weak var paymentButton: UIButton!
    private var overlay: UIView!
    private var indicator: UIActivityIndicatorView!
    
    func startPayment() {
        
        func addOverlay() {
            
            overlay = UIView()
            overlay.backgroundColor = .black
            overlay.alpha = 0.5
            overlay.frame = view.frame
            
            view.addSubview(overlay)
        }
        
        addOverlay()
        
        indicator = UIActivityIndicatorView(style: UIActivityIndicatorView.Style.large)
        indicator.startAnimating()
        overlay.addSubview(indicator)
        
        indicator.center = overlay.center
        
        indicator.accessibilityLabel = "Оплачиваем"
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
        
        DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(1)) {
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
        
        UIAccessibility.post(notification: .screenChanged, argument: sloganLabel)
    }
    
    #warning("Add pseudo timer")
    
    // MARK: - Helpers
    
    func addToolbar(for textField: UITextField) {
        
        let toolbar = UIToolbar(frame: CGRect(x: 0, y: 0, width: 320, height: 44))
        toolbar.items = [UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil), UIBarButtonItem(title: "Закрыть", style: .done, target: textField, action: #selector(resignFirstResponder))]
        
        toolbar.isAccessibilityElement = false
        toolbar.accessibilityLabel = "Действия с клавиатурой"
        
        textField.inputAccessoryView = toolbar
    }
    
    fileprivate func getNounForCount(count: UInt, multiple: String, few: String, single: String) -> String {
         
         let hundredRemnant = count % 100
         let tenRemnant = count % 10
         
         if hundredRemnant > 10 && hundredRemnant < 21 {
             return multiple
         }
         else if tenRemnant == 1 {
             return single
         }
         else if tenRemnant > 1 && tenRemnant < 5 {
             return few
         }
         
         return multiple
     }
    
    fileprivate func getPieceWordForCount(count: UInt) -> String {
        return getNounForCount(count: count, multiple: "кусочков", few: "кусочка", single: "кусочек")
    }
    
    fileprivate func getRubleForCount(count: UInt) -> String {
        return getNounForCount(count: count, multiple: "рублей", few: "рубля", single: "рубль")
    }
    
    fileprivate func screenFrame(for view: UIView, outsetBy margin: CGFloat = 10) -> CGRect? {
        
        guard let superview = view.superview else { return nil }
            
        var frame = UIAccessibility.convertToScreenCoordinates(view.frame, in: superview)
        frame = frame.inset(by: UIEdgeInsets(top: -margin, left: -margin, bottom: -margin, right: -margin))
        
        return frame
    }
    
    fileprivate func screenCenter(for view: UIView) -> CGPoint? {
        
        guard let superview = view.superview else { return nil }
        guard let window = superview.window else { return nil }
        
        return window.convert(superview.convert(view.center, to: nil), to: nil)
    }
    
    // MARK: - Accessibility
    
    func setupAccessibility() {
        
        sloganLabel.isAccessibilityElement = true
        sloganLabel.accessibilityLabel = "Поделись кусочком счастья"
        sloganLabel.accessibilityValue = "Подари кусочек пиццы своему другу. Напиши адрес и оплати, а мы пришлем ему письмо где получить."
        sloganLabel.accessibilityTraits = .header
        
        emailTextField.isAccessibilityElement = true
        emailTextField.accessibilityLabel = "Адрес друга"
        emailTextField.accessibilityTraits.insert(.header)
        
        countStepper.isAccessibilityElement = true
        countStepper.accessibilityLabel = "Количество кусочков"
        countStepper.accessibilityTraits = .adjustable

        addPostcardSwitch.isAccessibilityElement = true
        addPostcardSwitch.accessibilityLabel = "Добавить открытку за \(postcardPrice) \(getRubleForCount(count: postcardPrice))"
        
        paymentButton.isAccessibilityElement = true
        paymentButton.accessibilityLabel = "Оплатить"
        
        successTitleLabel.isAccessibilityElement = true
        successTitleLabel.accessibilityLabel = successTitleLabel.text! + " " + successCountLabel.text!
        
        successAnotherTryButton.isAccessibilityElement = true
    }
    
    func refreshAccessibilityFrames() {
        
        sloganLabel.accessibilityFrame = sloganLabel.frame.union(descriptionLabel.frame)
        
        if let countContainerFrame = screenFrame(for: countContainer) {
            countStepper.accessibilityFrame = countContainerFrame
        }
        
        if let postcardFrame = screenFrame(for: postcardContainer),
           let switchCenter = screenCenter(for: addPostcardSwitch) {
            addPostcardSwitch.accessibilityFrame = postcardFrame
            addPostcardSwitch.accessibilityActivationPoint = switchCenter
        }
        
        let successFrame = successTitleLabel.frame.union(successCountLabel.frame)
        successTitleLabel.accessibilityFrame = UIAccessibility.convertToScreenCoordinates(successFrame, in: successModalView)
    }

    func refreshAccessibilityProperties() {
        
        let totalString = "Итого \(currentTotal) \(getRubleForCount(count: currentTotal))"
        
        if emailMistakeLabel.isHidden {
            emailTextField.accessibilityValue = nil
        }
        else {
            let emailText = emailTextField.text ?? ""
            emailTextField.accessibilityValue = emailMistakeLabel.text! + ", " + emailText
        }
        
        countStepper.accessibilityValue = numberOfPiecesLabel.text! + ", " + totalString
        
        if paymentButton.isEnabled {
            
            var paymentButtonValue = numberOfPiecesLabel.text!
            
            if addPostcardSwitch.isOn {
                paymentButtonValue += " и открытка"
            }
            
            paymentButtonValue += ", " + totalString
            
            paymentButton.accessibilityValue = paymentButtonValue
        }
        else {
            paymentButton.accessibilityValue = nil
        }
        
        if paymentButton.isEnabled {
            paymentButton.accessibilityHint = "Можно выполнить из любого места через Magic Tap. Коснитесь двумя пальцами дважды."
        }
        else if emailMistakeLabel.isHidden {
            paymentButton.accessibilityHint = "Введите адрес друга"
        }
        else {
            paymentButton.accessibilityHint = emailMistakeLabel.text
        }
    }
    
    override func accessibilityPerformEscape() -> Bool {
        
        guard !successModalView.isHidden else { return false }
        
        closeModalView(successAnotherTryButton as Any)
        return true
    }
    
    override func accessibilityPerformMagicTap() -> Bool {
        
        guard successModalView.isHidden else { return false }
        guard paymentButton.isEnabled else {
            UIAccessibility.post(notification: .announcement, argument: paymentButton.accessibilityHint)
            return false
        }
        
        pay(paymentButton as Any)
        return true
    }
}

