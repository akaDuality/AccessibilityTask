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
    
    @IBOutlet weak var emailMistakeLabel: UILabel!
    @IBAction func emailEditiingDidEnd(_ sender: UITextField) {
        let email: Email = sender.text!
        emailMistakeLabel.isHidden = email.isValid
    }
    
    
    // MARK: - Price
    @IBOutlet weak var priceContainer: UIView!
    @IBOutlet weak var countStepper: UIStepper!
    @IBOutlet weak var numberOfPiecesLabel: UILabel!
    @IBAction func numberOfPiecesDidChange(_ sender: UIStepper) {
        numberOfPiecesLabel.text = "\(Int(sender.value)) кусочек"
        updateTotal()
    }
    
    @IBOutlet weak var addPostcardSwitch: UISwitch!
    @IBAction func addPostcardDidChange(_ sender: Any) {
        updateTotal()
    }
    
    @IBOutlet weak var totalLabel: UILabel!
    private func updateTotal() {
        var price = countStepper.value * 50
        
        if addPostcardSwitch.isOn {
            price += 25
        }
        totalLabel.text = "\(Int(price)) ₽"
    }
    
    
    // MARK: - Payment
    @IBOutlet weak var paymentButton: UIButton!
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
        
        let indicator = UIActivityIndicatorView(style: UIActivityIndicatorView.Style.large)
        indicator.startAnimating()
        overlay.addSubview(indicator)
        indicator.center = overlay.center
    }
    
    func finishPayment() {
        view.addSubview(successModalView)
        successModalView.isHidden = false
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
    }
}

