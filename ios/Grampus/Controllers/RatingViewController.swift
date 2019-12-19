//
//  RatingViewController.swift
//  Grampus
//
//  Created by Тимур Кошевой on 5/21/19.
//  Copyright © 2019 Тимур Кошевой. All rights reserved.
//

import UIKit
import Alamofire
import SwiftyJSON
import SVProgressHUD
import SDWebImage

class RatingViewController: RootViewController, ModalViewControllerDelegate, UISearchBarDelegate, SWRevealViewControllerDelegate, UITableViewDelegate, UITableViewDataSource, UITableViewDataSourcePrefetching {
    
    // MARK: - Outlets
    @IBOutlet weak var menuBarButton: UIBarButtonItem!
    @IBOutlet weak var searchBar: UISearchBar!
    @IBOutlet weak var tableView: UITableView!
    
    
    // MARK: - Properties
    let network = NetworkService()
    let storage = StorageService()
    let imageService = ImageService()
    var filteredJson = [JSON]()
    var UrlsToPrefetch = [URL]()
    var page = 1
    var isFetch = false
    var limit = 0
    var ratingType = ""
    
    // MARK: - Functions
    override func loadView() {
        super.loadView()
        fetchAllUsers(page: 0, ratingType: "")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
                
        SVProgressHUD.show()
        
        SVProgressHUD.setMinimumDismissTimeInterval(2)
        SVProgressHUD.setDefaultStyle(.dark)
        
        tableView.delegate = self
        tableView.dataSource = self
        tableView.refreshControl = myRefreshControl
        searchBar.delegate = self
        tableView.prefetchDataSource = self
        
        NotificationCenter.default.addObserver(self, selector: #selector(loadList), name: NSNotification.Name(rawValue: "load"), object: nil)

        
        if revealViewController() != nil {
            menuBarButton.target = self.revealViewController()
            menuBarButton.action = #selector(SWRevealViewController().revealToggle(_:))
            self.view.addGestureRecognizer(revealViewController().panGestureRecognizer())
            self.revealViewController()?.delegate = self
        }
    }
    
    
    func revealController(_ revealController: SWRevealViewController!, willMoveTo position: FrontViewPosition) {
        dismissKeyboard()
    }
    

    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        searchBar.searchTextField.resignFirstResponder()
    }
    
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        
        filteredJson = [JSON]()
        tableView.reloadData()

        if searchText == "" {
            fetchAllUsers(page: 0, ratingType: "")
        } else {
            network.fetchAllUsers(page: 0, name: searchText.lowercased(), ratingType: "") { (json) in
                if let json = json {
                    if json.isEmpty {
                        self.tableView.reloadData()
                    }
                    for i in 0..<json.count {
                        self.filteredJson.append(json[i])
                        self.tableView.reloadData()
                    }
                }
            }
        }
        
    }
    
    func fetchAllUsers(page: Int, ratingType: String) {
        network.fetchAllUsers(page: page, name: "", ratingType: ratingType) { (json) in
            if let json = json {
                SVProgressHUD.dismiss()
                print(json)
//                self.json = json
                self.filteredJson = [JSON]()
                for i in 0..<json.count {
                    self.filteredJson.append(json[i])
                }
                self.tableView.reloadData()
            } else {
                print("Error")
            }
        }
    }
    
    
    @objc func loadList(notification: NSNotification){
        DispatchQueue.main.async {
            self.fetchAllUsers(page: 0, ratingType: self.ratingType)
            self.page = 1
            self.limit = 0
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                SVProgressHUD.showSuccess(withStatus: "Sucess!")
            }
        }
    }
    
    @objc override func pullToRefresh(sender: UIRefreshControl) {
        SDImageCache.shared.clearDisk()
        fetchAllUsers(page: 0, ratingType: ratingType)
        page = 1
        limit = 0
        sender.endRefreshing()
    }
    
    // Actions
    @IBAction func likeButtonAction(_ sender: Any) {
        storage.chooseLikeOrDislike(bool: true)
        
        self.performSegue(withIdentifier: "ShowModalView", sender: self)
        self.definesPresentationContext = true
        self.providesPresentationContextTransitionStyle = true
        
        self.overlayBlurredBackgroundView()
    }
    
    @IBAction func dislikeButtonAction(_ sender: Any) {
        
        storage.chooseLikeOrDislike(bool: false)
        
        self.performSegue(withIdentifier: "ShowModalView", sender: self)
        self.definesPresentationContext = true
        self.providesPresentationContextTransitionStyle = true
        
        self.overlayBlurredBackgroundView()
    }
    
    func overlayBlurredBackgroundView() {
        
        let blurredBackgroundView = UIVisualEffectView()
        
        blurredBackgroundView.frame = view.frame
        blurredBackgroundView.effect = UIBlurEffect(style: .dark)
        
        view.addSubview(blurredBackgroundView)
        
    }
    
    func removeBlurredBackgroundView() {
        
        for subview in view.subviews {
            if subview.isKind(of: UIVisualEffectView.self) {
                subview.removeFromSuperview()
            }
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let identifier = segue.identifier {
            if identifier == "ShowModalView" {
                if let viewController = segue.destination as? ModalViewController {
                    viewController.delegate = self
                    viewController.modalPresentationStyle = .overFullScreen
                }
            }
        }
    }
    
    
    @objc func buttonClicked(sender:UIButton) {
        let buttonRow = sender.tag
        if let id = self.filteredJson[buttonRow]["id"].int {
            storage.saveSelectedUserId(selectedUserId: String(describing: id))
        }
    }
    
    @IBAction func sortButtonPressed(_ sender: UIBarButtonItem) {
        let alert = UIAlertController(title: "Sort rating", message: "You can sort rating by likes, dislikes or rating types", preferredStyle: .actionSheet)
        
        let action1 = UIAlertAction(title: "Likes", style: .default) { (action) in
            self.fetchAllUsers(page: 0, ratingType: "")
            self.ratingType = ""
        }
        
        let action2 = UIAlertAction(title: "Dislikes", style: .default) { (action) in
            self.fetchAllUsers(page: 0, ratingType: "DISLIKE")
            self.ratingType = "DISLIKE"
        }
        
        let action3 = UIAlertAction(title: "Rating types", style: .default) { (action) in
            let ratingTypesSortAlert = UIAlertController(title: "Sort by rating types", message: nil, preferredStyle: .actionSheet)
            let bestlooker = UIAlertAction(title: "Bestlooker", style: .default, handler: { (action) in
                self.fetchAllUsers(page: 0, ratingType: "BEST_LOOKER")
                self.ratingType = "DISLIKE"
            })
            let deadliner = UIAlertAction(title: "Deadliner", style: .default, handler: { (action) in
                self.fetchAllUsers(page: 0, ratingType: "DEADLINER")
                self.ratingType = "BEST_LOOKER"
            })
            let smartMind = UIAlertAction(title: "Smart mind", style: .default, handler: { (action) in
                self.fetchAllUsers(page: 0, ratingType: "SMART_MIND")
                self.ratingType = "SMART_MIND"
            })
            let superWorker = UIAlertAction(title: "Super worker", style: .default, handler: { (action) in
                self.fetchAllUsers(page: 0, ratingType: "SUPER_WORKER")
                self.ratingType = "SUPER_WORKER"
            })
            let motivator = UIAlertAction(title: "Motivator", style: .default, handler: { (action) in
                self.fetchAllUsers(page: 0, ratingType: "MOTIVATOR")
                self.ratingType = "MOTIVATOR"
            })
            let TOP1 = UIAlertAction(title: "TOP1", style: .default, handler: { (action) in
                self.fetchAllUsers(page: 0, ratingType: "TOP1")
                self.ratingType = "TOP1"
            })
            let mentor = UIAlertAction(title: "Mentor", style: .default, handler: { (action) in
                self.fetchAllUsers(page: 0, ratingType: "MENTOR")
                self.ratingType = "MENTOR"
            })
            
            
            ratingTypesSortAlert.addAction(bestlooker)
            ratingTypesSortAlert.addAction(deadliner)
            ratingTypesSortAlert.addAction(smartMind)
            ratingTypesSortAlert.addAction(superWorker)
            ratingTypesSortAlert.addAction(motivator)
            ratingTypesSortAlert.addAction(TOP1)
            ratingTypesSortAlert.addAction(mentor)
            self.present(ratingTypesSortAlert, animated: true) {
                self.tapRecognizer(alert: ratingTypesSortAlert)
            }
        }
        alert.addAction(action1)
        alert.addAction(action2)
        alert.addAction(action3)
        present(alert, animated: true) {
            self.page = 1
            self.limit = 0
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
    
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 100
        
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return filteredJson.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "ratingCell", for: indexPath) as! RatingTableViewCell

        var userNameToDisplay = ""
        var jobTitleToDisplay = ""
        var likeDislikeButtonState: Bool?
        var isFollowerState: Bool?
        var profilePictureString = ""
        var totalLikes: Int?
        var totalDislikes: Int?
        
        DispatchQueue.main.async {
            userNameToDisplay = self.filteredJson[indexPath.row]["fullName"].string ?? ""
            jobTitleToDisplay = self.filteredJson[indexPath.row]["jobTitle"].string ?? ""
            profilePictureString = self.filteredJson[indexPath.row]["profilePicture"].string ?? ""
            likeDislikeButtonState = self.filteredJson[indexPath.row]["isAbleToLike"].bool ?? false
            isFollowerState = self.filteredJson[indexPath.row]["isFollowing"].bool ?? false
            totalLikes = self.filteredJson[indexPath.row]["totalLikes"].int ?? 0
            totalDislikes = self.filteredJson[indexPath.row]["totalDisLikes"].int ?? 0
            cell.nameLabelCell.text = userNameToDisplay
            cell.professionLabelCell.text = jobTitleToDisplay
            cell.likeCount.text = String(describing: totalLikes!)
            cell.dislikeCount.text = String(describing: totalDislikes!)

            if let url = URL(string: profilePictureString) {
                self.UrlsToPrefetch.append(url)
                cell.imageViewCell.sd_setImage(with: url, placeholderImage: UIImage(named: "red cross"))
            } else {
                cell.imageViewCell.image = UIImage(named: "red cross")!
            }


            if !isFollowerState! {
                cell.isFollowerImageView.isHidden = true
            } else {
                cell.isFollowerImageView.isHidden = false
            }

                if likeDislikeButtonState! {
                    cell.likeButton.isEnabled = true
                    cell.dislikeButton.isEnabled = true
                } else {
                    cell.likeButton.isEnabled = false
                    cell.likeButton.tintColor = UIColor.gray
                    cell.dislikeButton.isEnabled = false
                    cell.dislikeButton.tintColor = UIColor.gray
                }

                cell.likeButton.tag = indexPath.row
                cell.dislikeButton.tag = indexPath.row
                cell.likeButton.addTarget(self, action: #selector(self.buttonClicked), for: UIControl.Event.touchUpInside)
                cell.dislikeButton.addTarget(self, action: #selector(self.buttonClicked), for: UIControl.Event.touchUpInside)
        }
        return cell

    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        if let id = self.filteredJson[indexPath.row]["id"].int {
            print(id)
            storage.saveSelectedUserId(selectedUserId: String(describing: id))
            storage.saveProfileState(state: false)
            self.performSegue(withIdentifier: SegueIdentifier.rating_to_selected_profile.rawValue, sender: self)
        } else {
        }
    }
    
    
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        if indexPath.row == filteredJson.count - 1 {
            isFetch = true
        } else {
            isFetch = false
        }
    }
    
    func tableView(_ tableView: UITableView, prefetchRowsAt indexPaths: [IndexPath]) {

        limit = filteredJson.count
        if isFetch {
            network.fetchAllUsers(page: page, name: "", ratingType: "") { (json) in
                if let json = json {
                    for i in 0..<json.count {
                        if !self.filteredJson.contains(json[i]) {
                            self.filteredJson.append(json[i])
                            SDWebImagePrefetcher.shared.prefetchURLs(self.UrlsToPrefetch)
                        }
                    }
                    if self.limit < self.filteredJson.count {
                        self.page += 1
                        self.tableView.reloadData()
                    }
                } else {
                    print("Error")
                }
            }
        }
    }
}
