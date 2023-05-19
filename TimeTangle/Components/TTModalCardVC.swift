//
//  TTModalCardVC.swift
//  TimeTangle
//
//  Created by Justin Wong on 12/28/22.
//

import UIKit

class TTModalCardVC: UIViewController {
    
    let outsideMainView = UIView()
    let containerView = UIView()
    
    weak var delegate: CloseButtonDelegate?

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor(red: 0, green: 0, blue: 0, alpha: 0.75)
        configureDismissViewController()
        configureOutsideMainView()
        configureContainerView()
    }
    
    func configureDismissViewController() {
        let tap = UITapGestureRecognizer(target: self, action: #selector(dismissVC))
        outsideMainView.addGestureRecognizer(tap)
    }
    
    //When user clicks the outside bounds of the container view
    private func configureOutsideMainView() {
        view.addSubview(outsideMainView)
        outsideMainView.translatesAutoresizingMaskIntoConstraints = false
        outsideMainView.isUserInteractionEnabled = true
        
        NSLayoutConstraint.activate([
            outsideMainView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            outsideMainView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            outsideMainView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            outsideMainView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor)
        ])
    }
    
    private func configureContainerView() {
        view.addSubview(containerView)
        
        containerView.backgroundColor = .systemBackground
        containerView.layer.cornerRadius = 16
        containerView.layer.borderWidth = 2
        containerView.layer.borderColor = UIColor.white.cgColor
        containerView.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            containerView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 100),
            containerView.centerXAnchor.constraint(equalTo: view.safeAreaLayoutGuide.centerXAnchor),
            containerView.widthAnchor.constraint(equalToConstant: 350),
            containerView.heightAnchor.constraint(equalToConstant: 350)
        ])
        
    }
    
    @objc internal func dismissVC() {
        if let delegate = delegate {
            delegate.didDismissPresentedView()
        }
    }
}
