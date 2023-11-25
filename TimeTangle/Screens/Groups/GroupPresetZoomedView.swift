//
//  GroupPresetZoomedView.swift
//  TimeTangle
//
//  Created by Justin Wong on 11/24/23.
//

import SwiftUI
import Firebase

//MARK: - GroupPresetZoomedView
struct GroupPresetZoomedView: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var selectedGroupPreset: TTGroupPreset?
    @Binding var isInEditMode: Bool
    @Binding var isDisclosureGroupExpanded: Bool
    @Binding var isTyping: Bool
    
    var animation: Namespace.ID
    
    @State private var friends = [TTUser]()
    @State private var ttError: TTError?
    @State private var isInAddMemberMode = false
    @State private var friendSearchText = ""
    
    private let columns = [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())]
    
    var body: some View {
        VStack {
            Spacer()
            if isInAddMemberMode{
                friendsSearchSection
            }
            Spacer()
            if !isTyping {
                VStack(spacing: 30) {
                    middleSection
                    backButton
                }
            }
            Spacer()
        }
        .padding()
        .fullScreenCover(item: $ttError) { details in
            TTSwiftUIAlertView(alertTitle: "ERROR", message: details.localizedDescription, buttonTitle: "OK")
                .ignoresSafeArea(.all)
        }
     }
    
    private var friendsSearchSection: some View {
        VStack(spacing: 10) {
            TextField("Search for a friend", text: $friendSearchText,onEditingChanged: {
                isTyping = $0
            })
                .padding()
                .tint(.green)
                .bold()
                .roundedRectangleBackgroundStyle(cornerRadius: 10, fillColor: .clear, strokeColor: .green, frameHeight: 40)
                .shadow(color: .green, radius: 5)
            
            if friends.isEmpty {
                Spacer()
                Text("No Friends Available")
                    .foregroundStyle(.secondary).bold()
                    .font(.title3)
                Spacer()
            } else {
                ScrollView {
                    LazyVGrid(columns: columns) {
                        ForEach(friends, id: \.id) { friend in
                            GroupPresetAddFriendView(friend: friend)
                        }
                    }
                    .padding(EdgeInsets(top: 1, leading: 0, bottom: 1, trailing: 0))
                }
            }
        }
        .onAppear {
            if friends.isEmpty {
                fetchFriends()
            }
        }
    }
    
    private var middleSection: some View {
        VStack(spacing: 20) {
            if selectedGroupPreset != nil {
                GroupPresetDisclosureGroup(selectedGroupPresent: Binding.constant(nil), isInEditMode: $isInEditMode, isExpanded: $isDisclosureGroupExpanded, groupPreset: selectedGroupPreset!)
                    .matchedGeometryEffect(id: "\(selectedGroupPreset!.id)", in: animation)
                    .opacity(isInAddMemberMode ? 0.3 : 1)
                    .disabled(isInAddMemberMode ? true : false)
            }

            if !isDisclosureGroupExpanded {
                HStack {
                    addGroupPresetMemberButton
                    
                    if !isInAddMemberMode {
                        deleteGroupPresetMemberButton
                    }
                }
                
                if !isInAddMemberMode {
                    addToMyGroupsButton
                }
            }
        }
    }
    
    private var addGroupPresetMemberButton: some View {
        Button(action: {
            withAnimation(.bouncy) {
                isInAddMemberMode.toggle()
            }
        }) {
            HStack {
                Image(systemName: isInAddMemberMode ? "checkmark": "person.fill.badge.plus")
                    .font(.system(size: 20))
                Text(isInAddMemberMode ? "Finish Adding Members" : "Add Member")
                    .bold()
            }
            .foregroundStyle(.white)
            .roundedRectangleBackgroundStyle(cornerRadius: 10, fillColor: .indigo.opacity(0.7), strokeColor: .indigo, frameHeight: 60)
        }
    }
    
    private var deleteGroupPresetMemberButton: some View {
        Button(action: {
            guard let currentUser = FirebaseManager.shared.currentUser,
                  let selectedGroup = selectedGroupPreset else { return }
        
            FirebaseManager.shared.updateUserData(for: currentUser.id, with: [
                TTConstants.groupPresets: FieldValue.arrayRemove([selectedGroup.dictionary])
            ]) { error in
                if let error = error {
                    ttError = error
                } else {
                    goBackToGroupPresetsView()
                }
            }
        }) {
            HStack {
                Image(systemName: "trash")
                    .font(.system(size: 20))
                Text("Delete Group")
                    .bold()
            }
            .foregroundStyle(.white)
            .roundedRectangleBackgroundStyle(cornerRadius: 10, fillColor: .red.opacity(0.7), strokeColor: .red, frameHeight: 60)
        }
    }
    
    private var addToMyGroupsButton: some View {
        Button(action: {
            guard let selectedGroup = selectedGroupPreset else { return }
            
            FirebaseManager.shared.createGroup(name: selectedGroup.name, users: selectedGroup.userIDs, groupCode: FirebaseManager.shared.generateRandomGroupCode(), startingDate: Date(), endingDate: Date()) { result in
                switch result {
                case .success(_):
                    dismiss()
                case .failure(let error):
                    ttError = error
                }
            }
        }) {
            HStack {
                Image(systemName: "plus")
                    .font(.system(size: 20))
                Text("Add to My Groups")
                    .bold()
            }
            .foregroundStyle(.white)
            .roundedRectangleBackgroundStyle(cornerRadius: 10, fillColor: .blue.opacity(0.5), strokeColor: .blue, frameHeight: 60)
        }
    }
    
    private var backButton: some View {
        Button(action: {
            goBackToGroupPresetsView()
        }) {
            Image(systemName: "chevron.left.circle.fill")
                .font(.system(size: 50))
                .foregroundStyle(.gray.opacity(0.6))
        }
    }
    
    private func fetchFriends() {
        guard let currentUser = FirebaseManager.shared.currentUser,
              let selectedGroupPreset = selectedGroupPreset else { return }
        let usersCache = FirebaseManager.shared.usersCache
        
        let filteredUserIDs = selectedGroupPreset.userIDs.filter{ $0 != currentUser.id && !selectedGroupPreset.userIDs.contains($0) }
        
        //TODO: - Clean Up
        for userID in filteredUserIDs {
            if let ttUser = usersCache.value(forKey: userID) {
                friends.append(ttUser)
            } else {
                FirebaseManager.shared.fetchUserDocumentData(with: userID) { result in
                    switch result {
                    case .success(let ttUser):
                        friends.append(ttUser)
                        usersCache.insert(ttUser, forKey: ttUser.id)
                    case .failure(let error):
                        ttError = error
                    }
                }
            }
        }
    }
    
    private func goBackToGroupPresetsView() {
        withAnimation(.easeInOut) {
            selectedGroupPreset = nil
            isDisclosureGroupExpanded = false
        }
    }
}
//MARK: GroupPresetAddFriendView
struct GroupPresetAddFriendView: View {
    @State private var isSelected = false
    
    var friend: TTUser
    private let usersCache = FirebaseManager.shared.usersCache
    
    var body: some View {
        VStack {
            Button(action: {
                withAnimation(.easeIn(duration: 0.5)) {
                    isSelected.toggle()
                }
            }) {
                ZStack {
                    VStack {
                        TTSwiftUIProfileImageView(image: friend.getProfilePictureUIImage(), size: 80)
                        Text(friend.getFullName())
                            .foregroundStyle(.green)
                            .lineLimit(1)
                            .multilineTextAlignment(.center)
                            .font(.caption).bold()
                    }
                    if isSelected {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(.red)
                            .font(.system(size: 25))
                            .offset(x: -45, y: 30)
                    }
                }
            }
        }
    }
}


#Preview {
    struct PreviewWrapper: View {
        @Namespace private var animation
        @State private var isInEditMode = false
        @State private var isTyping = false
        @State private var isDisclosureGroupExpanded = false
        
        @State private var groupPreset = TTGroupPreset(id: UUID().uuidString, name: "Best Buddies", userIDs: ["JTZ3X73E4gbi7IFrMe4FLHfGUAB3"])
        
        var body: some View {
            GroupPresetZoomedView(selectedGroupPreset: .constant(groupPreset), isInEditMode: $isInEditMode, isDisclosureGroupExpanded: $isDisclosureGroupExpanded, isTyping: $isTyping, animation: animation)
        }
    }
    return PreviewWrapper()
}
