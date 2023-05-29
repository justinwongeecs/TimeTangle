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
    
    func showEmptyStateView(with message: String, in view: UIView, viewsPresentInFront: [UIView]? = nil) {
        let emptyStateView = TTEmptyStateView(message: message)
        emptyStateView.frame = view.bounds
        emptyStateView.tag = TTConstants.emptyStateViewTag
        view.addSubview(emptyStateView)
        view.bringSubviewToFront(emptyStateView)
    
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
    
    //Hide Keyboard
    func hideKeyboardWhenTappedOutside() {
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(hideKeyboard))
        view.addGestureRecognizer(tapGesture)
    }
    @objc private func hideKeyboard() {
        view.endEditing(true)
    }
    
    func configureDismissEditingTapGestureRecognizer() {
        let dismissTapGestureRecognizer = UITapGestureRecognizer(target: view, action: #selector(UIView.endEditing))
        dismissTapGestureRecognizer.cancelsTouchesInView = false
        view.addGestureRecognizer(dismissTapGestureRecognizer)
    }
}

//MARK: - Extension
extension Array {
    func arrayByAppending(_ o: Element) -> [Element] {
        return self + [o]
    }
}
