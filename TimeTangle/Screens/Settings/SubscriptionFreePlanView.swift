//
//  SubscriptionFreePlanView.swift
//  TimeTangle
//
//  Created by Justin Wong on 5/25/23.
//

import SwiftUI

struct SubscriptionFreePlanView: View {
    private let roomsCount = FirebaseManager.shared.currentUser?.roomCodes.count
    
    var body: some View {
        VStack {
            Text("Free Plan")
                .font(.title.bold())
                .foregroundColor(.gray)
            
            Spacer()
            
            if roomsCount != nil {
                Text("Room Limit:")
                    .font(.title.bold())
                    .foregroundColor(.gray)
                HStack {
                    Text("\(roomsCount!)")
                        .font(.system(size: 40).bold())
                        .foregroundColor(.red)
                    Text("/5 Rooms")
                        .font(.system(size: 20).bold())
                        .foregroundColor(.gray)
                }
            } else {
                Text("Fetch User Error")
                    .foregroundColor(.red)
                    .bold()
            }
            
            Spacer()
        }
        .padding(10)
    }
}

struct SubscriptionFreePlanView_Previews: PreviewProvider {
    static var previews: some View {
        SubscriptionFreePlanView()
    }
}
