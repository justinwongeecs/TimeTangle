//
//  SaveOrCancelIsland.swift
//  TimeTangle
//
//  Created by Justin Wong on 5/17/23.
//

import UIKit

protocol SaveOrCancelIslandDelegate: AnyObject {
    func didCancelIsland()
}

class SaveOrCancelIsland: UIView {
    
    private let outerContainerView = UIView()
    private var blurView: UIVisualEffectView!
    private var confirmGroupChangesContainerView = UIView()
    private var isPresentingGroupChangesView: Bool = false
    private var parentVC: UIViewController!
    
    private var saveCompletionHandler: (() -> Void)?
    weak var delegate: SaveOrCancelIslandDelegate?
    
    init(parentVC: UIViewController, saveCompletionHandler: (() -> Void)?) {
        super.init(frame: .zero)
        self.parentVC = parentVC
        self.saveCompletionHandler = saveCompletionHandler
        configure()
    }
    
    override init(frame: CGRect) {
        super.init(frame: .zero)
        configure()
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        updateBlurBackground()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func configure() {
        let innerPadding: CGFloat = 10
        let outerPadding: CGFloat = 20
        let screenSize = UIScreen.main.bounds.size
        outerContainerView.translatesAutoresizingMaskIntoConstraints = false
        
        updateBlurBackground()
        
        let groupChangesStackView = UIStackView()
        groupChangesStackView.axis = .horizontal
        groupChangesStackView.distribution = .fillProportionally
        groupChangesStackView.translatesAutoresizingMaskIntoConstraints = false
        
        confirmGroupChangesContainerView.frame = CGRect(x: 0, y: screenSize.height, width: screenSize.width, height: 50 + innerPadding)
        confirmGroupChangesContainerView.addSubview(outerContainerView)
        parentVC.view.addSubview(confirmGroupChangesContainerView)
        outerContainerView.layer.cornerRadius = 10.0
        outerContainerView.layer.masksToBounds = true
        outerContainerView.layer.shadowColor = UIColor.gray.cgColor
        outerContainerView.layer.shadowOffset = CGSize.zero
        outerContainerView.layer.shadowOpacity = 1.0
        outerContainerView.layer.shadowRadius = 7.0
        outerContainerView.layer.borderWidth = 1
        outerContainerView.addSubview(groupChangesStackView)
        
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
        
        groupChangesStackView.addArrangedSubview(closeButton)
        groupChangesStackView.addArrangedSubview(saveButton)
        
        let swipeDownGestureReognizer = UISwipeGestureRecognizer(target: self, action: #selector(cancel))
        swipeDownGestureReognizer.direction = .down
        outerContainerView.addGestureRecognizer(swipeDownGestureReognizer)

        NSLayoutConstraint.activate([
            outerContainerView.leadingAnchor.constraint(equalTo: confirmGroupChangesContainerView.leadingAnchor, constant: outerPadding),
            outerContainerView.trailingAnchor.constraint(equalTo: confirmGroupChangesContainerView.trailingAnchor, constant:  -outerPadding),
            outerContainerView.topAnchor.constraint(equalTo: confirmGroupChangesContainerView.topAnchor),
            outerContainerView.bottomAnchor.constraint(equalTo: confirmGroupChangesContainerView.bottomAnchor),
            
            groupChangesStackView.topAnchor.constraint(equalTo: outerContainerView.topAnchor, constant: innerPadding),
            groupChangesStackView.leadingAnchor.constraint(equalTo: outerContainerView.leadingAnchor, constant: innerPadding),
            groupChangesStackView.trailingAnchor.constraint(equalTo: outerContainerView.trailingAnchor, constant: -innerPadding),
            groupChangesStackView.bottomAnchor.constraint(equalTo: outerContainerView.bottomAnchor, constant: -innerPadding),
        ])
    }
    
    private func updateBlurBackground() {
        let blurEffect: UIBlurEffect!
        
        if traitCollection.userInterfaceStyle == .light {
            blurEffect = UIBlurEffect(style: .dark)
            outerContainerView.layer.borderColor = UIColor.black.cgColor
        } else {
            blurEffect = UIBlurEffect(style: .light)
            outerContainerView.layer.borderColor = UIColor.white.cgColor
        }
        
        blurView?.removeFromSuperview()
        blurView = UIVisualEffectView(effect: blurEffect)
        blurView.translatesAutoresizingMaskIntoConstraints = false
        blurView.autoresizingMask = .flexibleWidth
        outerContainerView.insertSubview(blurView, at: 0)

        NSLayoutConstraint.activate([
            blurView.topAnchor.constraint(equalTo: outerContainerView.topAnchor),
            blurView.leadingAnchor.constraint(equalTo: outerContainerView.leadingAnchor),
            blurView.trailingAnchor.constraint(equalTo: outerContainerView.trailingAnchor),
            blurView.bottomAnchor.constraint(equalTo: outerContainerView.bottomAnchor)
        ])
    }
    
    @objc public func save() {
        if let saveCompletionHandler = saveCompletionHandler {
            saveCompletionHandler()
        }
        dismiss()
    }
    
    @objc private func cancel() {
        dismiss()
        delegate?.didCancelIsland()
    }
    
    public func dismiss() {
        if isPresentingGroupChangesView {
            let screenSize = UIScreen.main.bounds.size
            
            UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 1.0, initialSpringVelocity: 1.0, options: .curveEaseInOut) {
                self.confirmGroupChangesContainerView.frame = CGRect(x: 0, y: screenSize.height, width: screenSize.width, height: 60)
            }
            isPresentingGroupChangesView = false
        }
    }
    
    public func present() {
        if !isPresentingGroupChangesView {
            let screenSize = UIScreen.main.bounds.size
            guard let parentVC = parentViewController, let tabBarController = parentVC.tabBarController else { return }
            let tabBarHeight = tabBarController.tabBar.frame.size.height
            
            UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 1.0, initialSpringVelocity: 1.0, options: .curveEaseInOut) {
                self.confirmGroupChangesContainerView.frame = CGRect(x: 0, y: screenSize.height - tabBarHeight * 2, width: screenSize.width, height: 60)
            }
            isPresentingGroupChangesView = true
        }
    }
    
    public func isPresenting() -> Bool {
        return isPresentingGroupChangesView
    }
}
