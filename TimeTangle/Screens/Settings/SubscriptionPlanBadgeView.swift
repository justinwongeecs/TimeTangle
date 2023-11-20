//
//  SubscriptionPlanBadgeView.swift
//  TimeTangle
//
//  Created by Justin Wong on 11/7/23.
//

import SwiftUI

struct SubscriptionPlanBadgeView: View {
    var isPro: Bool
    
    private let hPadding: CGFloat = 1
    private let vPadding: CGFloat = 3
    
    var body: some View {
        Text(isPro ? "Pro" : "Free")
            .frame(width: 45, height: 20)
            .bold()
            .foregroundColor(.white)
            .padding(EdgeInsets(top: vPadding, leading: hPadding, bottom: vPadding, trailing: hPadding))
            .background(isPro ? .purple.opacity(0.7) : .gray.opacity(0.7))
            .clipShape(RoundedRectangle(cornerRadius: 6))
    }
}

#Preview(traits: .sizeThatFitsLayout) {
    Group {
        SubscriptionPlanBadgeView(isPro: true)
        SubscriptionPlanBadgeView(isPro: false)
    }
}

