//
//  SignUpViewController.swift
//  Grampus
//
//  Created by MacBook Pro on 5/21/19.
//  Copyright © 2019 Тимур Кошевой. All rights reserved.
//

import UIKit
import ValidationComponents
import Alamofire
import SVProgressHUD

class SignUpViewController: UIViewController, UITextFieldDelegate {
    
    // MARK: - Outlets
    @IBOutlet weak var userNameTextField: UITextField!
    @IBOutlet weak var emailTextField: UITextField!
    @IBOutlet weak var passwordTextField: UITextField!
    @IBOutlet weak var signUpButton: UIButton!
    
    let network = NetworkService()
    let predicate = EmailValidationPredicate()
    //let alert = AlertView()
    
    // MARK: - Functions
    override func viewDidLoad() {
        super.viewDidLoad()
        
        SVProgressHUD.setMinimumDismissTimeInterval(2)
        SVProgressHUD.setDefaultStyle(.dark)
        
        userNameTextField.delegate = self
        emailTextField.delegate = self
        passwordTextField.delegate = self
        
        SetUpOutlets()
        dismissKeyboardOnTap()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        setUpNotifications()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        removeNotifications()
    }
    
    func SetUpOutlets() {
        
        userNameTextField.layer.shadowColor = UIColor.darkGray.cgColor
        userNameTextField.layer.shadowOffset = CGSize(width: 3, height: 3)
        userNameTextField.layer.shadowRadius = 5
        userNameTextField.layer.shadowOpacity = 0.5
        
        passwordTextField.layer.shadowColor = UIColor.darkGray.cgColor
        passwordTextField.layer.shadowOffset = CGSize(width: 3, height: 3)
        passwordTextField.layer.shadowRadius = 5
        passwordTextField.layer.shadowOpacity = 0.5
        
        emailTextField.layer.shadowColor = UIColor.darkGray.cgColor
        emailTextField.layer.shadowOffset = CGSize(width: 3, height: 3)
        emailTextField.layer.shadowRadius = 5
        emailTextField.layer.shadowOpacity = 0.5
        
        signUpButton.layer.shadowColor = UIColor.darkGray.cgColor
        signUpButton.layer.shadowOffset = CGSize(width: 3, height: 3)
        signUpButton.layer.shadowRadius = 5
        signUpButton.layer.shadowOpacity = 0.5
        
        signUpButton.layer.cornerRadius = 5
        
    }
    
    // MARK: - Actions
    
    @IBAction func backButton(_ sender: UIButton) {
        self.dismiss(animated: true, completion: nil)
    }
    
    @IBAction func SignUpButton(_ sender: UIButton) {
        
        dismissKeyboard()
        
        let email = emailTextField.text
        let emailFormatBool = predicate.evaluate(with: email)
        
        // Check lenght of user name
        if let userName = userNameTextField.text {
            if userName.count < 2 {
                SVProgressHUD.showError(withStatus: "Name too short, write your correct name")
            }
        }
        
        // Email isEmpty check.
        if (email!.isEmpty) {
            SVProgressHUD.showError(withStatus: "Incorrect input, enter email!")
            return
        } else {
            // Email validation.
            if (!emailFormatBool) {
                SVProgressHUD.showError(withStatus: "Incorrect input, email format not correct!")
                return
            }
        }
        
        // Check lenght of password
        if let password = passwordTextField.text {
            if password.count < 6 {
                SVProgressHUD.showError(withStatus: "Password too short, password shoud be more than 5 characters!")
            } else if password.count >= 24 {
                SVProgressHUD.showError(withStatus: "Password too long, password shoud be less then 24 symbols")
            }
        }
        
        //Networking
        
        network.signUp(email: emailTextField.text!, password: passwordTextField.text!, fullName: userNameTextField.text!) { (success) in
            if success {
                SVProgressHUD.showSuccess(withStatus: "Great! You are successfully Signed Up!")
                self.network.signIn(username: self.emailTextField.text!, password: self.passwordTextField.text!) { (true) in
                    self.performSegue(withIdentifier: "goToProfile", sender: self)
                }
            } else {
                SVProgressHUD.showError(withStatus: "Error, registration error")
            }
        }
    }
    
    
    // Notifications for moving view when keyboard appears.
    func setUpNotifications() {
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillChange(notification:)), name: UIResponder.keyboardWillChangeFrameNotification, object: nil)
        
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide), name: UIResponder.keyboardWillHideNotification, object: nil)
    }
    
    // Removing notifications.
    func removeNotifications() {
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillChangeFrameNotification, object: nil)
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillHideNotification, object: nil)
    }
    
    @objc func keyboardWillHide() {
        self.view.frame.origin.y = 0
    }
    
    @objc func keyboardWillChange(notification: NSNotification) {
        
        if let keyboardSize = (notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue {
            if userNameTextField.isFirstResponder {
                self.view.frame.origin.y = -keyboardSize.height + 100
            } else if emailTextField.isFirstResponder {
                self.view.frame.origin.y = -keyboardSize.height + 100
            } else if passwordTextField.isFirstResponder {
                self.view.frame.origin.y = -keyboardSize.height + 100
            }
        }
    }
    
    // Hide keyboard on tap.
    func dismissKeyboardOnTap() {
        let tap: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        view.addGestureRecognizer(tap)
    }
    
    // Hide Keyboard.
    @objc func dismissKeyboard() {
        view.endEditing(true)
    }
    
    // Hide the keyboard when the return key pressed.
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
    
}
