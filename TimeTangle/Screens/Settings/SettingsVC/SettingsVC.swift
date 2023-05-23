//
//  SettingsVC.swift
//  TimeTangle
//
//  Created by Justin Wong on 12/24/22.
//

import UIKit

typealias SettingActionType = Setting.SettingType

struct SettingIcon {
    var backgroundColor: UIColor
    var foregroundColor: UIColor
    var iconName: String
}

struct SettingSection {
    var title: String?
    var settings: [Setting]
}

struct Setting {
    enum SettingType {
        case toggle
        case disclosure
        case none
        case button 
    }
    
    var icon: SettingIcon?
    var title: String?
    var titleColor: UIColor? 
    var actionType: SettingType
    var viewController: UIViewController?
    var actionClosure: (() -> Void)?
}

class SettingsVC: UIViewController {

    private var settingsTableView = UITableView(frame: .zero, style: .insetGrouped)
    
    private var settingSections = [
        SettingSection(settings: [
            Setting(actionType: .disclosure, viewController: SettingsProfileEditVC()),
        ]),
        
        SettingSection(settings: [
            Setting(icon: SettingIcon(backgroundColor: .gray, foregroundColor: .white, iconName: "gear"),
                    title: "General",
                    actionType: .disclosure, viewController: UIViewController()),
            Setting(icon: SettingIcon(backgroundColor: .black, foregroundColor: .yellow, iconName: "sun.max.fill"),
                    title: "Appearance",
                    actionType: .disclosure, viewController: UIViewController()),
            Setting(icon: SettingIcon(backgroundColor: .lightGray, foregroundColor: .white, iconName: "lock.fill"),
                    title: "Privacy",
                    actionType: .disclosure, viewController: UIViewController()),
            Setting(icon: SettingIcon(backgroundColor: .purple, foregroundColor: .white, iconName: "bubbles.and.sparkles.fill"),
                    title: "Subscription",
                    actionType: .disclosure, viewController: UIViewController()),
            Setting(icon: SettingIcon(backgroundColor: .blue, foregroundColor: .white, iconName: "questionmark.circle.fill"),
                    title: "Help",
                    actionType: .disclosure, viewController: UIViewController()),
            Setting(icon: SettingIcon(backgroundColor: .green, foregroundColor: .white, iconName: "info.circle.fill"),
                    title: "About",
                    actionType: .disclosure, viewController: UIViewController())
        ])
    ]
    
    override func viewDidLoad() {
        super.viewDidLoad()
 
        NotificationCenter.default.addObserver(self, selector: #selector(fetchUpdatedUser(_:)), name: .updatedUser, object: nil)
        
        title = "Settings"
        configureSettingsTableView()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.navigationBar.prefersLargeTitles = true
    }
    
    private func configureSettingsTableView() {
        settingsTableView.translatesAutoresizingMaskIntoConstraints = false
        settingsTableView.dataSource = self
        settingsTableView.delegate = self
        settingsTableView.register(SettingsProfileHeaderCell.self, forCellReuseIdentifier: SettingsProfileHeaderCell.reuseID)
        settingsTableView.register(SettingsCell.self, forCellReuseIdentifier: SettingsCell.reuseID)
        view.addSubview(settingsTableView)
        
        NSLayoutConstraint.activate([
            settingsTableView.topAnchor.constraint(equalTo: view.topAnchor),
            settingsTableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            settingsTableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            settingsTableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }
    
    @objc private func fetchUpdatedUser(_ notification: Notification) {
//        guard let updatedUser = notification.object as? TTUser else { return }
        DispatchQueue.main.async {
            self.settingsTableView.reloadRows(at: [IndexPath(row: 0, section: 0)], with: .automatic)
        }
    }
}

//MARK: - SettingsVC Extensions
extension SettingsVC: UITableViewDelegate, UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return settingSections.count
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let section = settingSections[section]
        return section.settings.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.section == 0 {
            let profileHeaderCell = settingsTableView.dequeueReusableCell(withIdentifier: SettingsProfileHeaderCell.reuseID) as! SettingsProfileHeaderCell
            return profileHeaderCell
        } else {
            let section = settingSections[indexPath.section]
            let setting = section.settings[indexPath.row]
            let cell = settingsTableView.dequeueReusableCell(withIdentifier: SettingsCell.reuseID) as! SettingsCell
          
            cell.setCell(for: setting)
            return cell
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let setting = settingSections[indexPath.section].settings[indexPath.row]
        if let vc = setting.viewController {
            navigationController?.pushViewController(vc, animated: true)
        }
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 20.0
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if indexPath.section == 0 {
            return 100.0
        }
        return 50.0
    }
}
