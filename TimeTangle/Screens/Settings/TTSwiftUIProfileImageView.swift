//
//  TTSwiftUIProfileImageView.swift
//  TimeTangle
//
//  Created by Justin Wong on 5/25/23.
//

import SwiftUI

struct TTSwiftUIProfileImageView: View {
    @Environment(\.colorScheme) private var colorScheme
    
    var image: UIImage?
    var size: CGFloat
    
    var body: some View {
        Group {
            if let profileImage = image {
                Image(uiImage: profileImage)
                    .resizable()
                    .frame(width: size, height: size)
                    .aspectRatio(contentMode: .fit)
                    .clipShape(Circle())
                    .shadow(color: colorScheme == .dark ? .white : .black, radius: 7)
            } else {
                Image(systemName: "person.crop.circle")
            }
        }
        .foregroundColor(.gray)
        .font(.system(size: size))
    }
}
