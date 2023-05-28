//
//  TTSwiftUIAlertView.swift
//  TimeTangle
//
//  Created by Justin Wong on 5/27/23.
//

import SwiftUI

struct TTSwiftUIAlertView: UIViewControllerRepresentable {
    typealias UIViewType = TTAlertVC
    
    private var alertTitle: String!
    private var message: String!
    private var buttonTitle: String!

    init(alertTitle: String, message: String, buttonTitle: String) {
        self.alertTitle = alertTitle
        self.message = message
        self.buttonTitle = buttonTitle
    }
    
    func makeUIViewController(context: Context) -> TTAlertVC {
        let ttAlertVC = TTAlertVC(alertTitle: alertTitle, message: message, buttonTitle: buttonTitle)
        ttAlertVC.modalPresentationStyle = .overFullScreen
        ttAlertVC.modalTransitionStyle = .crossDissolve
        return ttAlertVC
    }
    
    func updateUIViewController(_ uiViewController: TTAlertVC, context: Context) {}
}
