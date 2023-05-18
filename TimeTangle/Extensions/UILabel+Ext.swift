//
//  UILabel+Ext.swift
//  TimeTangle
//
//  Created by Justin Wong on 5/16/23.
//

import UIKit

extension UILabel {
    func withSearchCountStyle() -> UILabel {
        textAlignment = .center
        textColor = .secondaryLabel
        translatesAutoresizingMaskIntoConstraints = false
        isHidden = true
        font = UIFont.boldSystemFont(ofSize: 15)
        return self
    }
}
