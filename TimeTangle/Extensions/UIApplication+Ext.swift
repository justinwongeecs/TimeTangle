//
//  UIApplication+Ext.swift
//  TimeTangle
//
//  Created by Justin Wong on 5/27/23.
//

import UIKit

extension UIApplication {
    func topMostController() -> UIViewController? {
        guard
            let window = UIApplication.shared.connectedScenes
                .filter({$0.activationState == .foregroundActive})
                .map({$0 as? UIWindowScene})
                .compactMap({$0})
                .first?.windows
                .filter({$0.isKeyWindow}).first,
            let rootViewController = window.rootViewController else {
                return nil
        }
        
        var topController = rootViewController
        
        while let newTopController = topController.presentedViewController {
            topController = newTopController
        }
        
        return topController
    }
    
    func dismiss() {
        UIApplication.shared.topMostController()!.dismiss(animated: true, completion: nil)
    }
}
