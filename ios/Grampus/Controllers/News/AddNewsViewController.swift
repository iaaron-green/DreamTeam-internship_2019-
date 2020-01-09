//
//  AddNewsViewController.swift
//  Grampus
//
//  Created by student on 12/5/19.
//  Copyright © 2019 Тимур Кошевой. All rights reserved.
//

import UIKit
import SVProgressHUD


class AddNewsViewController: RootViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate, UITextViewDelegate {
    
    @IBOutlet weak var newsImageView: UIImageView!
    @IBOutlet weak var titleTextField: UITextField!
    @IBOutlet weak var bodyTextView: UITextView!
    @IBOutlet weak var addImage: UIButton!
    @IBOutlet weak var deleteImage: UIButton!
    @IBOutlet weak var okButton: UIButton!
    @IBOutlet weak var cancelButton: UIButton!
    
    var newsImage: UIImage?
    let network = NetworkService()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        configureView()
        
        SVProgressHUD.setMinimumDismissTimeInterval(2)
        SVProgressHUD.setDefaultStyle(.dark)
        
        bodyTextView.delegate = self
        titleTextField.delegate = self
        dismissKeyboardOnTap()
    }
    
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
          return .lightContent
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        setUpNotifications()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        removeNotifications()
    }
    
    override func textFieldShouldReturn(_ textField: UITextField) -> Bool {
            if textField == titleTextField {
               textField.resignFirstResponder()
               bodyTextView.becomeFirstResponder()
            }
          return true
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
        UIView.animate(withDuration: 0.5, animations: {
            self.view.layoutIfNeeded()
        })
       }
       
       @objc func keyboardWillChange(notification: NSNotification) {
           
           if let keyboardSize = (notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue {
            if titleTextField.isFirstResponder || bodyTextView.isFirstResponder {
                   self.view.frame.origin.y = -keyboardSize.height + 110
                UIView.animate(withDuration: 0.5, animations: {
                    self.view.layoutIfNeeded()
                })
               }
           }
       }
    
    
    @IBAction func addImagePressed(_ sender: UIButton) {
        let alert = UIAlertController(title: "Choose image source", message: nil, preferredStyle: .actionSheet)
               alert.addAction(UIAlertAction(title: "Gallery", style: .default, handler: { _ in
                   self.openGallery()
               }))

               alert.addAction(UIAlertAction(title: "Camera", style: .default, handler: { _ in
                   self.openCamera()
               }))

        self.present(alert, animated: true) {
            self.tapRecognizer(alert: alert)
        }
    }
    
    func tapRecognizer(alert: UIAlertController) {
        alert.view.superview?.subviews.first?.isUserInteractionEnabled = true
        alert.view.superview?.subviews.first?.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(self.actionSheetBackgroundTapped)))
    }
    
    @objc func actionSheetBackgroundTapped() {
        self.dismiss(animated: true, completion: nil)
    }
    
    func openCamera()
    {
        if UIImagePickerController.isSourceTypeAvailable(UIImagePickerController.SourceType.camera) {
            let imagePicker = UIImagePickerController()
            imagePicker.delegate = self
            imagePicker.sourceType = UIImagePickerController.SourceType.camera
            imagePicker.allowsEditing = true
            self.present(imagePicker, animated: true, completion: nil)
        }
        else
        {
            SVProgressHUD.showError(withStatus: "You don't have permission to access camera")
        }
    }

     func openGallery()
    {
        if UIImagePickerController.isSourceTypeAvailable(UIImagePickerController.SourceType.photoLibrary){
            let imagePicker = UIImagePickerController()
            imagePicker.delegate = self
            imagePicker.allowsEditing = true
            imagePicker.sourceType = UIImagePickerController.SourceType.photoLibrary
            self.present(imagePicker, animated: true, completion: nil)
        }
        else
        {
            SVProgressHUD.showError(withStatus: "You don't have permission to access gallery")

        }
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        if let editedImage = info[.editedImage] as? UIImage {
      newsImage = editedImage
        } else if let originalImage = info[.originalImage] as? UIImage {
      newsImage = originalImage
      }
        
        newsImageView.image = newsImage
        newsImageView.layer.cornerRadius = 10
        
        self.dismiss(animated: true, completion: nil)
    }
    
    @IBAction func deleteImagePressed(_ sender: UIButton) {
        newsImageView.image = UIImage(named: "no-image")
        newsImage = nil
    }
    
    @IBAction func cancelButtonPressed(_ sender: UIButton) {
        dismiss(animated: true, completion: nil)

    }
    
    @IBAction func okButtonPressed(_ sender: UIButton) {
        
        if newsTitleValidation(title: titleTextField) {
            network.uploadNews(selectedImage: newsImage, topic: titleTextField.text!, body: bodyTextView.text) { (success) in
                if success {
                    NotificationCenter.default.post(name: NSNotification.Name(rawValue: "loadNews"), object: nil)
                    self.dismiss(animated: true, completion: nil)
                } else {
                    SVProgressHUD.showError(withStatus: "Error!")
                }
            }
        }
    }
    
    func configureView() {
        
        bodyTextView.layer.cornerRadius = 8
        okButton.layer.cornerRadius = 5
        cancelButton.layer.cornerRadius = 5
        addImage.layer.cornerRadius = 5
        deleteImage.layer.cornerRadius = 5

    }
    


}
