//
//  UIViewController+Ext.swift
//  TimeTangle
//
//  Created by Justin Wong on 12/24/22.
//

import UIKit

fileprivate var containerView: UIView!

extension UIViewController {
    func presentTTAlert(title: String, message: String, buttonTitle: String) {
        DispatchQueue.main.async {
            let alertVC = TTAlertVC(alertTitle: title, message: message, buttonTitle: buttonTitle)
            alertVC.modalPresentationStyle = .overFullScreen
            alertVC.modalTransitionStyle = .crossDissolve
            self.present(alertVC, animated: true)
        }
    }
    
    func showLoadingView() {
        containerView = UIView(frame: view.bounds)
        view.addSubview(containerView)
        containerView.backgroundColor = .systemBackground
        containerView.alpha = 0
        
        UIView.animate(withDuration: 0.25) { containerView.alpha = 0.8 }
        
        let activityIndicator = UIActivityIndicatorView(style: .large)
        containerView.addSubview(activityIndicator)
        
        activityIndicator.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            activityIndicator.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            activityIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor)
        ])
        
        activityIndicator.startAnimating()
    }
    
    func dismissLoadingView() {
        DispatchQueue.main.async {
            containerView.removeFromSuperview()
            containerView = nil
        }
    }
    
    func showEmptyStateView(with message: String, in view: UIView, viewsPresentInFront: [UIView]? = nil) {
        let emptyStateView = TTEmptyStateView(message: message)
        emptyStateView.frame = view.bounds
        emptyStateView.tag = TTConstants.emptyStateViewTag
        view.addSubview(emptyStateView)
        view.bringSubviewToFront(emptyStateView)
        
//        view.subviews.filter{ !(viewsPresentInFront?.contains($0) ?? true) }.forEach{ $0.isHidden.toggle() }
        viewsPresentInFront?.forEach{ view.bringSubviewToFront($0) }
    }
    
    func removeEmptyStateView(in view: UIView) {
        if let viewWithTag = view.viewWithTag(TTConstants.emptyStateViewTag) {
            viewWithTag.removeFromSuperview()
        }
    }
    
    func add(childVC: UIViewController, to containerView: UIView) {
        addChild(childVC)
        containerView.addSubview(childVC.view)
        childVC.view.frame = containerView.bounds
        childVC.didMove(toParent: self)
    }
    
    func createDismissKeyboardTapGesture() {
        let tap = UITapGestureRecognizer(target: self.view, action: #selector(UIView.endEditing))
        view.addGestureRecognizer(tap)
    }
    
    func previousViewController() -> UIViewController? {
        if let navController = self.navigationController, navController.viewControllers.count >= 2 {
             let viewController = navController.viewControllers[navController.viewControllers.count - 2]
             return viewController
        }
        return nil 
    }
}

//MARK: - Extension
extension Array {
    func arrayByAppending(_ o: Element) -> [Element] {
        return self + [o]
    }
}

