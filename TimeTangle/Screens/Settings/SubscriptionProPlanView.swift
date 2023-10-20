//
//  SubscriptionProPlanView.swift
//  TimeTangle
//
//  Created by Justin Wong on 5/25/23.
//

import SwiftUI

struct SubscriptionProPlanView: View {
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        VStack {
            Text("Unlock the Potential!")
                .font(.title.bold())
                .foregroundColor(.white)
            
            Text("Pro Plan")
                .font(.title.bold())
                .foregroundColor(.purple)
            
            Text("$3.99/month")
                .foregroundColor(.purple.opacity(0.8))
                .font(.system(size: 20).bold())
            
            Group {
                SubscriptionBulletPoint(text: "Unlimited groups")
                SubscriptionBulletPoint(text: "Create custom preset friend groups")
                SubscriptionBulletPoint(text: "Manage group admin users")
                SubscriptionBulletPoint(text: "Lock & unlock groups")
                SubscriptionBulletPoint(text: "Additional personalized settings")
                SubscriptionBulletPoint(text: "View detailed user profiles")
                SubscriptionBulletPoint(text: "Enhanced visibility & privacy features")
                SubscriptionBulletPoint(text: "Filtered & customizable notifications")
            }
            .foregroundColor(.purple)
            .padding(5)
            
            Spacer()
            Button("Let's Go! 🚀")  {
                //Go to StoreKit page whatever
            }
            .foregroundColor(.white)
            .bold()
            .padding(10)
            .background(.green.opacity(0.8))
            .cornerRadius(10)
            .shadow(color: .white, radius: 5)
            .wiggling()
            
            Spacer()
        }
        .padding(10)
    }
}

struct SubscriptionBulletPoint: View {
    var text: String
    
    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: "checkmark.circle.fill")
                .background(.purple.opacity(0.3))
                .clipShape(Circle())
            Text(text)
            Spacer()
        }
    }
}

struct SubscriptionPlanView_Previews: PreviewProvider {
    static var previews: some View {
        SubscriptionProPlanView()
    }
}
