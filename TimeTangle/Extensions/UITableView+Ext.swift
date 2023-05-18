//
//  UITableView+Ext.swift
//  TimeTangle
//
//  Created by Justin Wong on 5/17/23.
//

import UIKit

extension UITableView {
    func reloadData(with animation: UITableView.RowAnimation) {
        reloadSections(IndexSet(integersIn: 0..<numberOfSections), with: animation)
    }
}
