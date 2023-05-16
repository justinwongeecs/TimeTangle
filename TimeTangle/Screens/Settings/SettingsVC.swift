//
//  SettingsVC.swift
//  TimeTangle
//
//  Created by Justin Wong on 12/24/22.
//

import UIKit

typealias SettingActionType = Setting.SettingType

struct Setting {
    enum SettingType {
        case customView
        case toggle
        case disclosure
    }
    
    var name: String
    var actionType: SettingType
}

class SettingsVC: UIViewController {
    
    private var settingsTableView: UITableView!
    
    private var settings = [
        Setting(name: "Hello World", actionType: .toggle),
        Setting(name: "Hello Justin", actionType: .toggle)
    ]
    
    var currentUser: TTUser?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        currentUser = FirebaseManager.shared.currentUser
//        configureProfileView()
//        configureProfileTapGesture()
        configureSettingsTableView()
        NotificationCenter.default.addObserver(self, selector: #selector(fetchUpdatedUser(_:)), name: .updatedUser, object: nil)
        
        title = "Settings"
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.navigationBar.prefersLargeTitles = true
    }
    
//    private func configureProfileView() {
//        guard let currentUser = currentUser else { return }
//        profileImageView.image =  UIImage(systemName: "person.crop.circle", withConfiguration: UIImage.SymbolConfiguration(pointSize: 80, weight: .regular))?.withTintColor(.lightGray, renderingMode: .alwaysOriginal)
//        firstAndLastNameLabel.text = "\(currentUser.firstname) \(currentUser.lastname)"
//        usernameLabel.text = "\(currentUser.username)"
//        firstAndLastNameLabel.sizeToFit()
//        usernameLabel.sizeToFit()
//    }
    
    private func configureSettingsTableView() {
        settingsTableView = UITableView(frame: .zero, style: .insetGrouped)
        settingsTableView.backgroundColor = .secondarySystemBackground
        settingsTableView.translatesAutoresizingMaskIntoConstraints = false
        settingsTableView.dataSource = self
        settingsTableView.delegate = self
        settingsTableView.register(SettingsCell.self, forCellReuseIdentifier: SettingsCell.reuseID)
        view.addSubview(settingsTableView)
        
        NSLayoutConstraint.activate([
            settingsTableView.topAnchor.constraint(equalTo: view.topAnchor),
            settingsTableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            settingsTableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            settingsTableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }
    
//    private func configureProfileTapGesture() {
//        let tapProfileViewGesture = UITapGestureRecognizer(target: self, action: #selector(showProfileEditSheet))
//        profileView.isUserInteractionEnabled = true
//        profileView.addGestureRecognizer(tapProfileViewGesture)
//    }
    
//    @objc private func showProfileEditSheet() {
//        print("tapped")
//        let editProfileVC = SettingsEditProfileVC(nibName: "SettingsEditProfileVCNib", bundle: nil)
//        editProfileVC.closeButtonDelegate = self 
//        let navController = UINavigationController(rootViewController: editProfileVC)
//        present(navController, animated: true)
//    }
//    
//    @IBAction func clickedSignOutButton(_ sender: UIButton) {
//        FirebaseManager.shared.signOutUser { result in
//            switch result {
//            case .success():
//                //go to login screen though it should be automatic?
//                (UIApplication.shared.connectedScenes.first?.delegate as? SceneDelegate)?.changeRootViewController(LoginVC())
//            case .failure(let error):
//                self.presentTTAlert(title: "Error", message: error.rawValue, buttonTitle: "Ok")
//            }
//        }
//    }
    
    @objc private func fetchUpdatedUser(_ notification: Notification) {
        guard let updatedUser = notification.object as? TTUser else { return }
        currentUser = updatedUser
//        configureProfileView()
    }
}

//MARK: - SettingsVC Extensions
extension SettingsVC: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        settings.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = settingsTableView.dequeueReusableCell(withIdentifier: SettingsCell.reuseID) as! SettingsCell
        let setting = settings[indexPath.row]
        cell.setCell(name: setting.name, actionType: setting.actionType)
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        40.0
    }
}

extension SettingsVC: CloseButtonDelegate {
    func didDismissPresentedView() {
        dismiss(animated: true)
    }
}

//MARK: - SettingsCell
class SettingsCell: UITableViewCell {
    static let reuseID = "SettingsCell"
    
    private var name: String!
    private var actionType: SettingActionType!
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public func setCell(name: String, actionType: SettingActionType) {
        self.name = name
        self.actionType = actionType
        configureCell()
    }
    
    private func configureCell() {
        selectionStyle = .none
        
        let nameLabel = UILabel()
        nameLabel.text = name
        nameLabel.font = UIFont.systemFont(ofSize: 15, weight: .regular)
        nameLabel.textColor = .secondaryLabel
        nameLabel.translatesAutoresizingMaskIntoConstraints = false
        addSubview(nameLabel)
        
        var actionControl = UIControl()
       
        switch actionType {
        case .toggle:
            actionControl = UISwitch()
            actionControl.translatesAutoresizingMaskIntoConstraints = false
            contentView.addSubview(actionControl)
            break
        case .customView:
            break
        case .disclosure:
            break
        default:
            break
        }
        
        let padding: CGFloat = 10.0
        
        NSLayoutConstraint.activate([
            nameLabel.centerYAnchor.constraint(equalTo: centerYAnchor),
            nameLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: padding),
            nameLabel.heightAnchor.constraint(equalToConstant: 20),
            
            actionControl.centerYAnchor.constraint(equalTo: centerYAnchor),
            actionControl.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -padding)
        ])
    }
}

