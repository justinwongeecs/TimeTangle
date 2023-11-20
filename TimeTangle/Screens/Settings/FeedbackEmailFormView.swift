//
//  FeedbackEmailFormView.swift
//  TimeTangle
//
//  Created by Justin Wong on 11/17/23.
//

import SwiftUI
import MessageUI

enum TTFeedbackFormType {
    case bugReport
    case featureRequest
}

struct FeedbackEmailFormView: UIViewControllerRepresentable {
    class Coordinator: NSObject, MFMailComposeViewControllerDelegate {
        var parent: FeedbackEmailFormView
        
        init(_ parent: FeedbackEmailFormView) {
            self.parent = parent
        }
        
        func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
            controller.dismiss(animated: true)
        }
    }
    
    var formType: TTFeedbackFormType
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    func makeUIViewController(context: Context) -> MFMailComposeViewController  {
        let composeVC = MFMailComposeViewController()
        composeVC.setToRecipients(["jwonghelloworld@berkeley.edu"])
        composeVC.mailComposeDelegate = context.coordinator
        
        switch formType {
        case .bugReport:
            composeVC.setSubject("[BUG REPORT] {ENTER BUG TITLE}")
            composeVC.setMessageBody("[BUG]: {Please describe what occurred, and steps to reproduce such an bug}", isHTML: false)
        case .featureRequest:
            composeVC.setSubject("[FEATURE REQUEST] {ENTER FEATURE REQUEST NAME}")
            composeVC.setMessageBody("[FEATURE REQUEST]: {Please describe what your feature request is.}", isHTML: false)
        }
        return composeVC
    }
    
    func updateUIViewController(_ uiViewController: MFMailComposeViewController, context: Context) {}
}
