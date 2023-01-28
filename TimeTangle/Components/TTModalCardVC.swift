//
//  TTModalCardVC.swift
//  TimeTangle
//
//  Created by Justin Wong on 12/28/22.
//

import UIKit

class TTModalCardVC: UIViewController {
    
    let containerViewHeader = UIStackView()
    let outsideMainView = UIView()
    let containerView = UIView()
    var headerLabel = TTTitleLabel(textAlignment: .center, fontSize: 18)
    
    weak var delegate: CloseButtonDelegate!

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor(red: 0, green: 0, blue: 0, alpha: 0.75)
        // Do any additional setup after loading the view.
        configureDismissViewController()
        configureOutsideMainView()
        configureContainerView()
        configureContainerViewHeader()
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
//        view.bringSubviewToFront(containerView)
        
        containerView.backgroundColor = .systemBackground
        containerView.layer.cornerRadius = 16
        containerView.layer.borderWidth = 2
        containerView.layer.borderColor = UIColor.white.cgColor
        containerView.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            //            containerView.centerYAnchor.constraint(equalTo: view.safeAreaLayoutGuide.centerYAnchor),
            containerView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 100),
            containerView.centerXAnchor.constraint(equalTo: view.safeAreaLayoutGuide.centerXAnchor),
            containerView.widthAnchor.constraint(equalToConstant: 350),
            containerView.heightAnchor.constraint(equalToConstant: 350)
        ])
        
    }
    
    private func configureContainerViewHeader() {
        containerView.addSubview(containerViewHeader)
        containerViewHeader.translatesAutoresizingMaskIntoConstraints = false
        containerViewHeader.layer.cornerRadius = 16
        containerViewHeader.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        containerViewHeader.backgroundColor = .systemBackground
        containerViewHeader.axis = .horizontal
    
        headerLabel.font = UIFont.boldSystemFont(ofSize: 20)
        
        let closeButton = TTCloseButton()
        closeButton.addTarget(self, action: #selector(dismissVC), for: .touchUpInside)
        
        containerViewHeader.addArrangedSubview(headerLabel)
        containerViewHeader.addArrangedSubview(closeButton)
        
        NSLayoutConstraint.activate([
            containerViewHeader.topAnchor.constraint(equalTo: containerView.topAnchor),
            containerViewHeader.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 10),
            containerViewHeader.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -8),
            containerViewHeader.heightAnchor.constraint(equalToConstant: 50)
        ])
    }
    
    @objc private func dismissVC() {
        delegate.didDismissPresentedView()
    }
}
