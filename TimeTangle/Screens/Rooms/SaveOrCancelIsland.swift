//
//  SaveOrCancelIsland.swift
//  TimeTangle
//
//  Created by Justin Wong on 5/17/23.
//

import UIKit

protocol SaveOrCancelIslandDelegate: AnyObject {
    func didCancelIsland()
    func didSaveIsland()
}

class SaveOrCancelIsland: UIView {
    
    private var confirmRoomChangesContainerView = UIView()
    private var isPresentingRoomChangesView: Bool = false
    private var parentVC: UIViewController!
    
    weak var delegate: SaveOrCancelIslandDelegate?
    
    init(parentVC: UIViewController) {
        super.init(frame: .zero)
        self.parentVC = parentVC
        configure()
    }
    
    override init(frame: CGRect) {
        super.init(frame: .zero)
        configure()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func configure() {
        
        let innerPadding: CGFloat = 10
        let outerPadding: CGFloat = 20
        
        let outerContainerView = UIView()
        let screenSize = UIScreen.main.bounds.size
        outerContainerView.translatesAutoresizingMaskIntoConstraints = false
        
        let roomChangesStackView = UIStackView()
        roomChangesStackView.axis = .horizontal
        roomChangesStackView.distribution = .fillProportionally
        roomChangesStackView.translatesAutoresizingMaskIntoConstraints = false
        
        confirmRoomChangesContainerView.frame = CGRect(x: 0, y: screenSize.height, width: screenSize.width, height: 50 + innerPadding)
        confirmRoomChangesContainerView.addSubview(outerContainerView)
        parentVC.view.addSubview(confirmRoomChangesContainerView)
        outerContainerView.layer.cornerRadius = 10.0
        outerContainerView.layer.masksToBounds = true
        outerContainerView.layer.shadowColor = UIColor.gray.cgColor
        outerContainerView.layer.shadowOffset = CGSize.zero
        outerContainerView.layer.shadowOpacity = 1.0
        outerContainerView.layer.shadowRadius = 7.0
        outerContainerView.addSubview(roomChangesStackView)
        
        let blurEffect: UIBlurEffect!
        if traitCollection.userInterfaceStyle == .light {
            blurEffect = UIBlurEffect(style: .dark)
        } else {
            blurEffect = UIBlurEffect(style: .light)
        }
     
        let blurView = UIVisualEffectView(effect: blurEffect)
        blurView.frame = confirmRoomChangesContainerView.bounds
        blurView.autoresizingMask = .flexibleWidth
        outerContainerView.insertSubview(blurView, at: 0)

        NSLayoutConstraint.activate([
            blurView.topAnchor.constraint(equalTo: outerContainerView.topAnchor),
                blurView.leadingAnchor.constraint(equalTo: outerContainerView.leadingAnchor),
                blurView.trailingAnchor.constraint(equalTo: outerContainerView.trailingAnchor),
                blurView.bottomAnchor.constraint(equalTo: outerContainerView.bottomAnchor)
        ])
   
        let closeButton = TTCloseButton()
        closeButton.tintColor = .systemRed
        closeButton.addTarget(self, action: #selector(cancel), for: .touchUpInside)
        
        let saveButton = UIButton(type: .custom)
        saveButton.setTitle("Save", for: .normal)
        saveButton.titleLabel?.font = UIFont.systemFont(ofSize: 16, weight: .bold)
        saveButton.layer.cornerRadius = 10.0
        saveButton.backgroundColor = .systemGreen
        saveButton.setTitleColor(.white, for: .normal)
        saveButton.addTarget(self, action: #selector(save), for: .touchUpInside)
        
        roomChangesStackView.addArrangedSubview(closeButton)
        roomChangesStackView.addArrangedSubview(saveButton)

        NSLayoutConstraint.activate([
            outerContainerView.leadingAnchor.constraint(equalTo: confirmRoomChangesContainerView.leadingAnchor, constant: outerPadding),
            outerContainerView.trailingAnchor.constraint(equalTo: confirmRoomChangesContainerView.trailingAnchor, constant:  -outerPadding),
            outerContainerView.topAnchor.constraint(equalTo: confirmRoomChangesContainerView.topAnchor),
            outerContainerView.bottomAnchor.constraint(equalTo: confirmRoomChangesContainerView.bottomAnchor),
            
            roomChangesStackView.topAnchor.constraint(equalTo: outerContainerView.topAnchor, constant: innerPadding),
            roomChangesStackView.leadingAnchor.constraint(equalTo: outerContainerView.leadingAnchor, constant: innerPadding),
            roomChangesStackView.trailingAnchor.constraint(equalTo: outerContainerView.trailingAnchor, constant: -innerPadding),
            roomChangesStackView.bottomAnchor.constraint(equalTo: outerContainerView.bottomAnchor, constant: -innerPadding),
        ])
    }
    
    @objc public func save() {
        if let delegate = delegate {
            dismiss()
            delegate.didSaveIsland()
        }
    }
    
    @objc private func cancel() {
        if let delegate = delegate {
            dismiss()
            delegate.didCancelIsland()
        }
    }
    
    public func dismiss() {
        if isPresentingRoomChangesView {
            let screenSize = UIScreen.main.bounds.size
            
            UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 1.0, initialSpringVelocity: 1.0, options: .curveEaseInOut) {
                self.confirmRoomChangesContainerView.frame = CGRect(x: 0, y: screenSize.height, width: screenSize.width, height: 60)
            }
            isPresentingRoomChangesView = false
        }
    }
    
    public func present() {
        if !isPresentingRoomChangesView {
            let screenSize = UIScreen.main.bounds.size
            guard let parentVC = parentViewController, let tabBarController = parentVC.tabBarController else { return }
            let tabBarHeight = tabBarController.tabBar.frame.size.height
            
            UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 1.0, initialSpringVelocity: 1.0, options: .curveEaseInOut) {
                self.confirmRoomChangesContainerView.frame = CGRect(x: 0, y: screenSize.height - tabBarHeight * 2, width: screenSize.width, height: 60)
            }
            isPresentingRoomChangesView = true
        }
    }
    
    public func isPresenting() -> Bool {
        return isPresentingRoomChangesView
    }
}
