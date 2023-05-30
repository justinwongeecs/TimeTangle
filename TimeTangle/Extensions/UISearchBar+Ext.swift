//
//  UISearchBar+Ext.swift
//  TimeTangle
//
//  Created by Justin Wong on 5/30/23.
//

import UIKit

extension UISearchBar {
    func disableSearchBar() {
        if #available(iOS 16.4, *) {
            self.isEnabled = false
        } else {
            // Fallback on earlier versions
            self.isUserInteractionEnabled = false
            self.layer.opacity = 0.35
        }
    }
    
    func enableSearchBar() {
        if #available(iOS 16.4, *) {
            self.isEnabled = true
        } else {
            // Fallback on earlier versions
            self.isUserInteractionEnabled = true
            self.layer.opacity = 1
        }
    }
}

