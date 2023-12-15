//
//  TTSwiftUIProfileImageView.swift
//  TimeTangle
//
//  Created by Justin Wong on 5/25/23.
//

import SwiftUI

struct TTSwiftUIProfileImageView: View {
    @Environment(\.colorScheme) private var colorScheme
    
    var user: TTUser?
    var name: String?
    @State var image: UIImage?
    var size: CGFloat
    
    var initials: String? {
        guard user != nil || name != nil else { return nil }
        
        if let user = user {
            return "\(String(user.firstname.first!) + String(user.lastname.first!))"
        } else if let name = name {
            let nameComponents = name.components(separatedBy: " ")
            var initialsResult = ""
            nameComponents.forEach{ initialsResult += String($0.first ?? Character(""))}
            return initialsResult
        }
        return nil
    }
    
    var body: some View {
        Group {
            if let profileImage = image {
                Circle()
                    .stroke(.clear)
                    .overlay(
                        Image(uiImage: profileImage)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .clipShape(Circle())
                    )
                    .frame(width: size, height: size)
            } else if let initials = initials {
                Circle()
                    .fill(.radialGradient(colors: backgroundColor, center: .center, startRadius: 1, endRadius: 100))
                    .frame(width: size * 0.78, height: size * 0.78)
                    .overlay(
                        Text(initials)
                            .font(.system(size: size * 0.35))
                            .foregroundStyle(.white)
                            .bold()
                    )
            } else {
                Image(systemName: "person.crop.circle")
                    .font(.system(size: size * 0.75))
            }
        }
        .onAppear {
            if image == nil, let user = user {
                user.getProfilePictureUIImage { image in
                    self.image = image
                }
            }
        }
    }
    
    private var backgroundColor: [Color] {
        return colorScheme == .dark ? [.green, .green.opacity(0.5)] : [.green.opacity(0.5), .green]
    }
}

#Preview(traits: .sizeThatFitsLayout) {
    Group {
        TTSwiftUIProfileImageView(user: TTUser(firstname: "Justin", lastname: "Wong", id: UUID().uuidString, friends: [], friendRequests: [], groupCodes: [], groupPresets: []), image: nil, size: 100)
        TTSwiftUIProfileImageView(user: nil, image: nil, size: 100)
    }
    .padding()
}
