//
//  FriendsGroupPresetsView.swift
//  TimeTangle
//
//  Created by Justin Wong on 11/21/23.
//

import SwiftUI

struct TTGroupPreset: Identifiable {
    let id = UUID().uuidString
    var name: String
    var users: [TTUser]
}

struct FriendsGroupPresetsView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    @Namespace private var animation
    @State private var groupPresets = [TTGroupPreset]()
    @State private var selectedGroupPreset: TTGroupPreset? = nil
    @State private var isInEditMode = false
    @State private var isDisclosureGroupExpanded = false
    @State private var isTyping = false
    @State private var isShowingZoomedView = false
    
    @State private var showCreateNewGroupPresetAlert = false
    @State private var newGroupPresetName = ""
    
    init(groupPresets: [TTGroupPreset]) {
        _groupPresets = State(initialValue: groupPresets)
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
//                if !FirebaseManager.shared.storeViewModel.isSubscriptionPro {
//                    lockedView
//                } /*else if groupPresets.isEmpty {*/
//                    emptyView
//                else {
                    VStack {
                        List {
                            ForEach(groupPresets) { groupPreset in
                                GroupPresetDisclosureGroup(selectedGroupPresent: $selectedGroupPreset, isInEditMode: $isInEditMode, isExpanded: $isDisclosureGroupExpanded, groupPreset: groupPreset)
                                    .listRowBackground(Color.clear)
                                    .listRowSeparator(.hidden)
                                    .matchedGeometryEffect(id: "\(groupPreset.id)", in: animation)
                            }
                        }
                        .scrollDisabled(selectedGroupPreset != nil  ? true : false)
                        .scrollContentBackground(.hidden)
                        .allowsHitTesting(isShowingZoomedView ? false : true)
                    }
                    .blur(radius: selectedGroupPreset != nil ? 10 : 0)
                    
                    if selectedGroupPreset != nil {
                        GroupPresetZoomedView(selectedGroupPreset: $selectedGroupPreset, isInEditMode: $isInEditMode, isDisclosureGroupExpanded: $isDisclosureGroupExpanded, isTyping: $isTyping, animation: animation)
                            .onAppear {
                                isShowingZoomedView.toggle()
                            }
                            .onDisappear {
                                isShowingZoomedView.toggle()
                            }
                    }
//                }
            }
            .navigationTitle("My Group Presets")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button(action: {
                        dismiss()
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 25))
                            .foregroundStyle(.gray)
                    }
                }
                
                if FirebaseManager.shared.storeViewModel.isSubscriptionPro && selectedGroupPreset == nil {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button(action: {
                            showCreateNewGroupPresetAlert.toggle()
                        }) {
                            Image(systemName: "plus")
                                .foregroundStyle(.green)
                        }
                    }
                }
                
                if isDisclosureGroupExpanded {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button(action: {
                            withAnimation {
                                isInEditMode.toggle()
                            }
                        }) {
                            Text(isInEditMode ? "Done" : "Edit")
                                .foregroundStyle(.green)
                        }
                    }
                }
            }
        }
        .interactiveDismissDisabled()
        .alert("Enter New Group Preset Name", isPresented: $showCreateNewGroupPresetAlert) {
            TextField("", text: $newGroupPresetName)
                .textInputAutocapitalization(.never)
            Button("OK", action: {})
            Button("Cancel", role: .cancel) { }
        }
    }
    
    private var lockedView: some View {
        VStack(spacing: 10) {
            Image(systemName: "lock.fill")
                .font(.system(size: 60))
            VStack {
                Text("Group Presets require")
                HStack {
                    SubscriptionPlanBadgeView(isPro: true)
                    Text("subscription")
                }
            }
            .font(.title3).bold()
        }
        .foregroundStyle(.gray)
    }
    
    private var emptyView: some View {
        VStack(spacing: 5) {
            Spacer()
            Text("No Group Presets")
                .font(.title)
            Text("Let's Create One!")
            Text("👇")
                .font(.system(size: 50))
            Spacer()
        }
        .bold()
        .foregroundStyle(.gray)
    }
}
//MARK: - GroupPresetZoomedView
struct GroupPresetZoomedView: View {
    @Binding var selectedGroupPreset: TTGroupPreset?
    @Binding var isInEditMode: Bool
    @Binding var isDisclosureGroupExpanded: Bool
    @Binding var isTyping: Bool
    
    var animation: Namespace.ID
    
    @State private var isInAddMemberMode = false
    @State private var friendSearchText = ""
    
    private let columns = [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())]
    
    private let friends = ["Johnny Appleseed", "Justin Wong", "Jess Luu", "Johnny Appleseed1", "Justin Wong1", "Jess Luu1", "Johnny Appleseed2", "Justin Wong2", "Jess Luu2"]
    
    var body: some View {
        VStack {
            Spacer()
            if isInAddMemberMode{
                friendsSearchSection
            }
            Spacer()
            if !isTyping {
                VStack {
                    middleSection
                    backButton
                }
            }
            Spacer()
        }
        .padding()
    }
    
    private var friendsSearchSection: some View {
        VStack(spacing: 10) {
            TextField("Search for a friend", text: $friendSearchText,onEditingChanged: {
                isTyping = $0
            })
                .padding()
                .tint(.green)
                .bold()
                .roundedRectangleBackgroundStyle(cornerRadius: 10, fillColor: .green.opacity(0.3), strokeColor: .green, frameHeight: 40)
                .shadow(color: .green, radius: 5)
            
            ScrollView {
                LazyVGrid(columns: columns) {
                    ForEach(friends, id: \.self) { friendID in
                        GroupPresetAddFriendView(friendID: friendID)
                    }
                }
                .padding(EdgeInsets(top: 1, leading: 0, bottom: 1, trailing: 0))
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
        Button(action: {}) {
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
    
    private var backButton: some View {
        Button(action: {
            withAnimation(.easeInOut) {
                selectedGroupPreset = nil
                isDisclosureGroupExpanded = false
            }
        }) {
            Image(systemName: "chevron.left.circle.fill")
                .font(.system(size: 50))
                .foregroundStyle(.gray.opacity(0.6))
        }
    }
}
//MARK: GroupPresetAddFriendView
struct GroupPresetAddFriendView: View {
    @State private var isSelected = false
    @State private var image: UIImage?
    
    var friendID: String
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
                        TTSwiftUIProfileImageView(image: image, size: 80)
                            .roundedRectangleBackgroundStyle(cornerRadius: 10, fillColor: .gray.opacity(0.6), strokeColor: .gray, frameWidth: 90, frameHeight: 90)
                        Text(friendID)
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
        .onAppear {
            if let user = usersCache.value(forKey: friendID) {
                image = user.getProfilePictureUIImage()
            } else {
                FirebaseManager.shared.fetchUserDocumentData(with: friendID) { result in
                    switch result {
                    case .success(let ttUser):
                        image = ttUser.getProfilePictureUIImage()
                    case .failure(let error):
                        print("Error: \(error)")
                    }
                }
            }
        }
    }
}

//MARK: - GroupPresetDisclosureGroup
struct GroupPresetDisclosureGroup: View {
    @Binding var selectedGroupPresent: TTGroupPreset?
    @Binding var isInEditMode: Bool
    @Binding var isExpanded: Bool
    
    var groupPreset: TTGroupPreset
    
    var showMembersListView: Bool {
        selectedGroupPresent?.id != groupPreset.id && isExpanded
    }
    
    var body: some View {
        VStack {
            RoundedRectangle(cornerRadius: 10)
                .fill(.green.gradient)
                .stroke(.green, lineWidth: 1)
                .frame(height: 80)
                .overlay(
                    VStack {
                       groupPresetHeaderView
                    }
                    .padding()
                    .tint(.white)
                )
                .shadow(color: .green, radius: 5)
        
            if showMembersListView {
                groupPresetMembersListView
            }
        }
    }
    
    private var groupPresetHeaderView: some View {
        Button(action: {
            selectedGroupPresent = groupPreset
            
            withAnimation(.bouncy) {
                isExpanded.toggle()
            }
        }) {
            HStack {
                VStack(alignment: .leading) {
                    Text(groupPreset.name)
                        .foregroundStyle(.primary)
                        .bold()
                        .font(.title2)
                    Text("^[\(groupPreset.users.count) Member](inflect: true)")
                        .foregroundStyle(.secondary)
                }
                Spacer()
                
                Image(systemName: "chevron.forward")
                    .rotationEffect(showMembersListView ? .degrees(90) : .degrees(0))
                    .fontWeight(.bold)
            }
        }
    }
    
    private var groupPresetMembersListView: some View {
        List {
            ForEach(groupPreset.users.sorted(by: { $0.firstname < $1.firstname}), id: \.id) { member in
                HStack {
                    if isInEditMode {
                        Button(action: {
                            //TODO: Delete Member From Group
                        }) {
                            Image(systemName: "minus.circle.fill")
                                .font(.system(size: 25))
                                .foregroundStyle(.red)
                        }
                    }
                    Spacer()
                    GroupPresetMemberView(member: member)
                }
                .listRowInsets(EdgeInsets(top: 4, leading: 2, bottom: 4, trailing: 2))
                .listRowSeparator(.hidden)
                .listRowBackground(Color.clear)
            }
        }
        .scrollContentBackground(.hidden)
        .scrollIndicators(.hidden)
        .padding(EdgeInsets(top: -10, leading: isInEditMode ? 0 : 20, bottom: 0, trailing: 0))
    }
}

//MARK: - GroupPresetMemberView
struct GroupPresetMemberView: View {
    var member: TTUser
    
    var body: some View {
        RoundedRectangle(cornerRadius: 10)
            .fill(.indigo.opacity(0.3).gradient)
            .stroke(.indigo, lineWidth: 1)
            .frame(width: 250, height: 50)
            .overlay(
                HStack {
                    TTSwiftUIProfileImageView(image: member.getProfilePictureUIImage(), size: TTConstants.profileImageViewInCellHeightAndWidth)
                    Text(member.getFullName())
                        .bold()
                    Spacer()
                }
                .padding(5)
            )
    }
}

#Preview {
    FriendsGroupPresetsView(groupPresets: [
        TTGroupPreset(name: "Group 1", users: [
            TTUser(firstname: "Johnny", lastname: "Appleseed", id: UUID().uuidString, friends: [], friendRequests: [], groupCodes: [], groupPresets: []),
            TTUser(firstname: "Johnny", lastname: "Appleseed", id: UUID().uuidString, friends: [], friendRequests: [], groupCodes: [], groupPresets: []),
            TTUser(firstname: "Johnny", lastname: "Appleseed", id: UUID().uuidString, friends: [], friendRequests: [], groupCodes: [], groupPresets: []),
            TTUser(firstname: "Johnny", lastname: "Appleseed", id: UUID().uuidString, friends: [], friendRequests: [], groupCodes: [], groupPresets: []), TTUser(firstname: "Johnny", lastname: "Appleseed", id: UUID().uuidString, friends: [], friendRequests: [], groupCodes: [], groupPresets: []),
            TTUser(firstname: "Johnny", lastname: "Appleseed", id: UUID().uuidString, friends: [], friendRequests: [], groupCodes: [], groupPresets: []),
            TTUser(firstname: "Johnny", lastname: "Appleseed", id: UUID().uuidString, friends: [], friendRequests: [], groupCodes: [], groupPresets: []),
            TTUser(firstname: "Johnny", lastname: "Appleseed", id: UUID().uuidString, friends: [], friendRequests: [], groupCodes: [], groupPresets: []),
            TTUser(firstname: "Johnny", lastname: "Appleseed", id: UUID().uuidString, friends: [], friendRequests: [], groupCodes: [], groupPresets: []),
            TTUser(firstname: "Johnny", lastname: "Appleseed", id: UUID().uuidString, friends: [], friendRequests: [], groupCodes: [], groupPresets: []),
            TTUser(firstname: "Johnny", lastname: "Appleseed", id: UUID().uuidString, friends: [], friendRequests: [], groupCodes: [], groupPresets: []),
        ]),
        TTGroupPreset(name: "Group 2", users: [
            TTUser(firstname: "Johnny", lastname: "Appleseed", id: UUID().uuidString, friends: [], friendRequests: [], groupCodes: [], groupPresets: []),
            TTUser(firstname: "Johnny", lastname: "Appleseed", id: UUID().uuidString, friends: [], friendRequests: [], groupCodes: [], groupPresets: []),
            TTUser(firstname: "Johnny", lastname: "Appleseed", id: UUID().uuidString, friends: [], friendRequests: [], groupCodes: [], groupPresets: []),
            TTUser(firstname: "Johnny", lastname: "Appleseed", id: UUID().uuidString, friends: [], friendRequests: [], groupCodes: [], groupPresets: []),
        ]),
        TTGroupPreset(name: "Group 2", users: [
            TTUser(firstname: "Johnny", lastname: "Appleseed", id: UUID().uuidString, friends: [], friendRequests: [], groupCodes: [], groupPresets: []),
            TTUser(firstname: "Johnny", lastname: "Appleseed", id: UUID().uuidString, friends: [], friendRequests: [], groupCodes: [], groupPresets: []),
            TTUser(firstname: "Johnny", lastname: "Appleseed", id: UUID().uuidString, friends: [], friendRequests: [], groupCodes: [], groupPresets: []),
            TTUser(firstname: "Johnny", lastname: "Appleseed", id: UUID().uuidString, friends: [], friendRequests: [], groupCodes: [], groupPresets: []),
        ]),
        TTGroupPreset(name: "Group 2", users: [
            TTUser(firstname: "Johnny", lastname: "Appleseed", id: UUID().uuidString, friends: [], friendRequests: [], groupCodes: [], groupPresets: []),
            TTUser(firstname: "Johnny", lastname: "Appleseed", id: UUID().uuidString, friends: [], friendRequests: [], groupCodes: [], groupPresets: []),
            TTUser(firstname: "Johnny", lastname: "Appleseed", id: UUID().uuidString, friends: [], friendRequests: [], groupCodes: [], groupPresets: []),
            TTUser(firstname: "Johnny", lastname: "Appleseed", id: UUID().uuidString, friends: [], friendRequests: [], groupCodes: [], groupPresets: []),
        ])
    ])
}
