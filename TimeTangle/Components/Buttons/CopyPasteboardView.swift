//
//  CopyPasteboardView.swift
//  TimeTangle
//
//  Created by Justin Wong on 11/25/23.
//

import SwiftUI

struct CopyPasteboardView: View {
    var text: String
    var body: some View {
        Button(action: {
            UIPasteboard.general.string = text
        }) {
            Image(systemName: "clipboard")
                .foregroundStyle(.green)
                .roundedRectangleBackgroundStyle(cornerRadius: 10, fillColor: .green.opacity(0.2), strokeColor: .clear, frameWidth: 35, frameHeight: 35)
        }
    }
}

#Preview {
    CopyPasteboardView(text: "Hello")
}
