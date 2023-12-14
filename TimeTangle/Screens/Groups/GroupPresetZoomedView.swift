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
    @State private var filteredFriends = [TTUser]()
    @State private var selectedFriendsToAdd = [TTUser]()
    @State private var ttError: TTError?
    @State private var isInAddMemberMode = false
    @State private var friendSearchText = ""
    @State private var showDeleteGroupAlert = false
    @State private var newGroupPresetName = ""
    @State private var showRenameGroupAlert = false
    
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
            TTSwiftUIAlertView(alertTitle: "ERROR", message: details.rawValue, buttonTitle: "OK")
                .ignoresSafeArea(.all)
        }
     }
    
    //MARK: - FriendsSearchSection
    private var friendsSearchSection: some View {
        VStack(spacing: 10) {
            HStack {
                TextField("Search for a friend", text: $friendSearchText, onEditingChanged: {
                    isTyping = $0
                })
                    .padding()
                    .tint(.green)
                    .bold()
                    .roundedRectangleBackgroundStyle(cornerRadius: 10, fillColor: .clear, strokeColor: .green, frameHeight: 40)
                    .shadow(color: .green, radius: 5)
                    .onSubmit {
                        friendSearchText.removeAll()
                    }
                
                //Cancel Button
                if isTyping {
                    Button(action: {
                        withAnimation(.bouncy) {
                            isTyping = false
                            UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                        }
                    }) {
                        Text("Cancel")
                            .foregroundStyle(.green)
                    }
                }
            }
        
            searchFriendsResultsView
        }
        .onAppear {
            fetchFriends()
        }
        .onChange(of: friendSearchText) {
           updateFilteredFriends()
        }
        .onChange(of: selectedGroupPreset) {
            fetchFriends()
        }
    }
    
    //MARK: - SearchFriendsResultsView
    @ViewBuilder
    private var searchFriendsResultsView: some View {
        if friends.isEmpty {
            Spacer()
            Text("No Friends Available")
                .foregroundStyle(.secondary).bold()
                .font(.title3)
            Spacer()
        } else {
            if isTyping && filteredFriends.isEmpty {
                VStack {
                    Spacer()
                    Text("No Matching Results")
                        .foregroundStyle(.secondary).bold()
                        .font(.title3)
                    Spacer()
                }
            } else {
                ScrollView {
                    LazyVGrid(columns: columns) {
                        ForEach(filteredFriends, id: \.id) { friend in
                            GroupPresetAddFriendView(selectedFriendsToAdd: $selectedFriendsToAdd, friend: friend)
                        }
                    }
                    .padding(EdgeInsets(top: 1, leading: 0, bottom: 1, trailing: 0))
                }
            }
        }
    }
    
    //MARK: - Middle Section
    private var middleSection: some View {
        VStack(spacing: 20) {
            if selectedGroupPreset != nil && !isTyping {
                GroupPresetDisclosureGroup(selectedGroupPreset: $selectedGroupPreset, isInEditMode: $isInEditMode, isExpanded: $isDisclosureGroupExpanded, groupPreset: selectedGroupPreset!)
                    .matchedGeometryEffect(id: "\(selectedGroupPreset!.id)", in: animation)
                    .opacity(isInAddMemberMode ? 0.3 : 1)
                    .disabled(isInAddMemberMode ? true : false)
            }

            if !isDisclosureGroupExpanded {
                HStack {
                    if !isInAddMemberMode {
                        renameGroupPresetButton
                        deleteGroupPresetMemberButton
                    }
                }
                
                addGroupPresetMemberButton
                
                if !isInAddMemberMode {
                    addToMyGroupsButton
                }
            }
        }
    }
    
    //MARK: - Buttons
    private var addGroupPresetMemberButton: some View {
        Button(action: {
            withAnimation(.bouncy) {
                addSelectedFriendsToGroupPresets()
                isInAddMemberMode.toggle()
            }
        }) {
            Group {
                if selectedFriendsToAdd.isEmpty {
                    HStack {
                        Image(systemName: isInAddMemberMode ? "checkmark": "person.fill.badge.plus")
                            .font(.system(size: 20))
                        Text(isInAddMemberMode ? "Finish Adding Members" : "Add Member")
                    }
                } else {
                    HStack {
                        Image(systemName: "plus")
                            .font(.system(size: 20))
                        Text("Add ^[\(selectedFriendsToAdd.count) Friend](inflect: true) To Group Preset")
                    }
                }
            }
            .bold()
            .foregroundStyle(.white)
            .roundedRectangleBackgroundStyle(cornerRadius: 10, fillColor: .indigo.opacity(0.7), strokeColor: .indigo, frameHeight: 60)
        }
    }
    
    private var renameGroupPresetButton: some View {
        Button(action: {
            showRenameGroupAlert.toggle()
        }) {
            HStack {
                Image(systemName: "square.and.pencil")
                    .font(.system(size: 20))
                Text("Rename Group")
                    .bold()
            }
            .foregroundStyle(.white)
            .roundedRectangleBackgroundStyle(cornerRadius: 10, fillColor: .orange.opacity(0.7), strokeColor: .orange, frameHeight: 60)
        }
        .alert("Rename Group", isPresented: $showRenameGroupAlert) {
            TextField("New Group Preset Name", text: $newGroupPresetName)
            Button("Cancel", role: .cancel) {}
            Button("Rename", role: .none) {
                renameGroupPreset()
            }
        } message: {}
    }
    
    private var deleteGroupPresetMemberButton: some View {
        Button(action: {
            showDeleteGroupAlert.toggle()
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
        .alert("Delete Group Preset?", isPresented: $showDeleteGroupAlert) {
            Button("Cancel", role: .cancel) {}
            Button("Delete", role: .destructive) {
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
            }
        } message: {
            Text("Are you sure you want to delete this group preset?")
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
        
        friends.removeAll()
        filteredFriends.removeAll()
        
        let filteredUserIDs = currentUser.friends.filter{ $0 != currentUser.id && !selectedGroupPreset.userIDs.contains($0) }
        
        //TODO: - Clean Up
        for userID in filteredUserIDs {
            if let ttUser = usersCache.value(forKey: userID) {
                friends.append(ttUser)
                filteredFriends.append(ttUser)
            } else {
                FirebaseManager.shared.fetchUserDocumentData(with: userID) { result in
                    switch result {
                    case .success(let ttUser):
                        friends.append(ttUser)
                        filteredFriends.append(ttUser)
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
    
    private func updateFilteredFriends() {
        if friendSearchText.isEmpty {
            filteredFriends = friends
        } else {
            filteredFriends = friends.filter{ $0.getFullName().lowercased().contains(friendSearchText.lowercased())
            }
        }
    }
    
    private func renameGroupPreset() {
        guard let currentUser = FirebaseManager.shared.currentUser,
        let selectedGroupPreset = selectedGroupPreset else { return }
        
        guard !newGroupPresetName.isEmpty else {
            showRenameGroupAlert.toggle()
            ttError = .textFieldsCannotBeEmpty
            return
        }
        
        var currentUserGroupPresets = currentUser.groupPresets
        if let index = currentUserGroupPresets.firstIndex(where: { $0.id == selectedGroupPreset.id }) {
            currentUserGroupPresets[index].name = newGroupPresetName
        }
        
        FirebaseManager.shared.updateUserData(for: currentUser.id, with: [
            TTConstants.groupPresets: currentUserGroupPresets.map{ $0.dictionary }
        ]) { error in
            if let error = error {
                 ttError = error
            }
        }
    }
    
    private func addSelectedFriendsToGroupPresets() {
        guard let currentUser = FirebaseManager.shared.currentUser,
        let selectedGroupPreset = selectedGroupPreset else { return }
        var currentUserGroupPresets = currentUser.groupPresets
        
        if let index = currentUserGroupPresets.firstIndex(where: { $0.id == selectedGroupPreset.id }) {
            selectedFriendsToAdd.forEach {
                currentUserGroupPresets[index].userIDs.append($0.id)
            }
            
            FirebaseManager.shared.updateUserData(for: currentUser.id, with: [
                TTConstants.groupPresets: currentUserGroupPresets.map{ $0.dictionary }
            ]) { error in
                if let error = error {
                    ttError = error
                } else {
                    selectedFriendsToAdd.removeAll()
                }
            }
        }
    }
}
//MARK: GroupPresetAddFriendView
struct GroupPresetAddFriendView: View {
    @State private var isSelected = false
    @State private var friendUIImage: UIImage?
    @Binding var selectedFriendsToAdd: [TTUser]
    
    var friend: TTUser
    private let usersCache = FirebaseManager.shared.usersCache
    
    var body: some View {
        VStack {
            Button(action: {
                withAnimation(.easeIn(duration: 0.3)) {
                    isSelected.toggle()
                    
                    if let index = selectedFriendsToAdd.firstIndex(of: friend) {
                        selectedFriendsToAdd.remove(at: index)
                    } else {
                        selectedFriendsToAdd.append(friend)
                    }
                }
            }) {
                RoundedRectangle(cornerRadius: 10)
                    .stroke(isSelected ? Color.red : Color.clear, lineWidth: 1.0)
                    .fill(isSelected ? Color.red.opacity(0.1) : Color.clear)
                    .frame(width: 100, height: 100)
                    .overlay(
                        VStack(spacing: 10) {
                            TTSwiftUIProfileImageView(user: friend, image: friendUIImage, size: 80)
                            Text(friend.getFullName())
                                .foregroundStyle(.green)
                                .lineLimit(1)
                                .multilineTextAlignment(.center)
                                .font(.caption).bold()
                        }
                        .padding(10)
                    )
            }
        }
        .onAppear {
            friend.getProfilePictureUIImage { image in
                if image != nil {
                    friendUIImage = image 
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
        
        @State private var groupPreset = TTGroupPreset(id: UUID().uuidString, name: "Best Buddies", userIDs: ["y31WjbojjfSGoLwJPfJiLJFOfzc2"])
        
        var body: some View {
            GroupPresetZoomedView(selectedGroupPreset: .constant(groupPreset), isInEditMode: $isInEditMode, isDisclosureGroupExpanded: $isDisclosureGroupExpanded, isTyping: $isTyping, animation: animation)
        }
    }
    return PreviewWrapper()
}
