//
//  GroupPresetsView.swift
//  TimeTangle
//
//  Created by Justin Wong on 11/21/23.
//

import SwiftUI
import Firebase

//MARK: - GroupPresetsViewModel
class GroupPresetsViewModel: ObservableObject {
    @Published var groupPresets = [TTGroupPreset]()
    
    init() {
        NotificationCenter.default.addObserver(self, selector: #selector(fetchUpdatedUser), name: .updatedUser, object: nil)
        guard let currentUser = FirebaseManager.shared.currentUser else { return }
        groupPresets = currentUser.groupPresets
    }
    
    @objc private func fetchUpdatedUser(_ notification: Notification) {
        guard let updatedCurrentUser = notification.object as? TTUser else { return }
        groupPresets = updatedCurrentUser.groupPresets
    }
}

//MARK: - GroupPresetsView
struct GroupPresetsView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    @Namespace private var animation
    @StateObject private var groupPresetsVM = GroupPresetsViewModel()
    @State private var selectedGroupPreset: TTGroupPreset? = nil
    @State private var isInEditMode = false
    @State private var isDisclosureGroupExpanded = false
    @State private var isTyping = false
    @State private var isShowingZoomedView = false

    @State private var showCreateNewGroupPresetAlert = false
    @State private var newGroupPresetName = ""
    
    var body: some View {
        NavigationStack {
            ZStack {
                if !FirebaseManager.shared.storeViewModel.isSubscriptionPro {
                    lockedView
                } else if  groupPresetsVM.groupPresets.isEmpty {
                    GroupPresetsEmptyView()
                } else {
                    VStack {
                        List {
                            ForEach(groupPresetsVM.groupPresets.sorted(by: { $0.name < $1.name })) { groupPreset in
                                GroupPresetDisclosureGroup(selectedGroupPreset: $selectedGroupPreset, isInEditMode: $isInEditMode, isExpanded: $isDisclosureGroupExpanded, groupPreset: groupPreset)
                                    .listRowBackground(Color.clear)
                                    .listRowSeparator(.hidden)
                                    .matchedGeometryEffect(id: "\(groupPreset.id)", in: animation)
                            }
                        }
                        .scrollDisabled(selectedGroupPreset != nil  ? true : false)
                        .scrollContentBackground(.hidden)
                        .allowsHitTesting(isShowingZoomedView ? false : true)
                    }
                    .blur(radius: selectedGroupPreset != nil ? 60 : 0)
                    
                    if selectedGroupPreset != nil {
                        GroupPresetZoomedView(selectedGroupPreset: $selectedGroupPreset, isInEditMode: $isInEditMode, isDisclosureGroupExpanded: $isDisclosureGroupExpanded, isTyping: $isTyping, animation: animation)
                            .onAppear {
                                isShowingZoomedView.toggle()
                            }
                            .onDisappear {
                                isShowingZoomedView.toggle()
                            }
                    }
                }
            }
            .navigationTitle("My Group Presets")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button(action: {
                        dismiss()
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .applyCloseButtonStyle()
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
                
                if isDisclosureGroupExpanded, let selectedGroupPreset = selectedGroupPreset,
                   selectedGroupPreset.userIDs.count > 1 {
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
            Button("OK", action: {
                guard let currentUser = FirebaseManager.shared.currentUser else { return }
                
                let newGroupPreset = TTGroupPreset(id: UUID().uuidString, name: newGroupPresetName, userIDs: [currentUser.id])
                
                FirebaseManager.shared.updateUserData(for: currentUser.id, with: [
                    TTConstants.groupPresets: FieldValue.arrayUnion([newGroupPreset.dictionary])
                ]) { error in
                    if let error = error {
                        print("Error: \(error)")
                        //TODO: Show Error
                    }
                }
            })
            Button("Cancel", role: .cancel) {}
        }
        .onChange(of: groupPresetsVM.groupPresets) {
            //If there we have updates to group presets, and a group preset is selected, update the selected group preset 
            if let selectedGroupPreset = selectedGroupPreset,
               let index = groupPresetsVM.groupPresets.firstIndex(where: { $0.id == selectedGroupPreset.id }) {
                self.selectedGroupPreset = groupPresetsVM.groupPresets[index]
            }
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
}

//MARK: - GroupPresetsEmptyView
struct GroupPresetsEmptyView: View {
    @State private var emojiPosition: CGFloat = 0.0
    @State private var isMovingUp = true
    
    var body: some View {
        VStack(spacing: 5) {
            HStack {
                Spacer()
                Text("☝️")
                    .font(.system(size: 50))
                    .offset(x: -10, y: emojiPosition)
            }
            Spacer()
            Text("No Group Presets")
                .font(.title)
            Text("Let's Create One!")
            Spacer()
        }
        .bold()
        .foregroundStyle(.gray)
        .onAppear {
            animateEmoji()
        }
    }
    
    private func animateEmoji() {
        withAnimation(.easeInOut(duration: 1.0).repeatForever()) {
                if self.isMovingUp {
                    self.emojiPosition += 50
                } else {
                    self.emojiPosition -= 50
                }
                self.isMovingUp.toggle()
            }
        }
}

//MARK: - GroupPresetDisclosureGroup
struct GroupPresetDisclosureGroup: View {
    @Binding var selectedGroupPreset: TTGroupPreset?
    @Binding var isInEditMode: Bool
    @Binding var isExpanded: Bool
    
    var groupPreset: TTGroupPreset
    
    @State private var groupPresetUsers = [TTUser]()
    @State private var errorFetchingUsers: TTError?
    @State private var showRemoveMemberConfirmationAlert = false
    
    var showMembersListView: Bool {
        selectedGroupPreset?.id == groupPreset.id && isExpanded
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
        .fullScreenCover(item: $errorFetchingUsers) { details in
            TTSwiftUIAlertView(alertTitle: "ERROR", message: details.rawValue, buttonTitle: "OK")
                .ignoresSafeArea(.all)
        }
    }
    
    private var groupPresetHeaderView: some View {
        Button(action: {
            selectedGroupPreset = groupPreset
            
            withAnimation(.bouncy) {
                isExpanded.toggle()
                if isInEditMode { isInEditMode = false }
            }
        }) {
            HStack {
                VStack(alignment: .leading) {
                    Text(groupPreset.name)
                        .foregroundStyle(.primary)
                        .bold()
                        .font(.title2)
                    Text("^[\(groupPreset.userIDs.count) Member](inflect: true)")
                        .foregroundStyle(.secondary)
                }
                Spacer()
                
                Image(systemName: "chevron.forward")
                    .rotationEffect(showMembersListView ? .degrees(90) : .degrees(0))
                    .fontWeight(.bold)
            }
        }
    }
    
    @ViewBuilder
    private var groupPresetMembersListView: some View {
        if errorFetchingUsers != nil  {
            Text("Could Not Fetch Users: \(errorFetchingUsers!.rawValue)")
            .padding()
            .bold()
            .foregroundStyle(.red)
        } else {
            List {
                ForEach(groupPresetUsers.sorted(by: { $0.firstname < $1.firstname}), id: \.id) { member in
                    HStack {
                        if isInEditMode && member.id != FirebaseManager.shared.currentUser?.id {
                            Button(action: {
                                showRemoveMemberConfirmationAlert.toggle()
                            }) {
                                Image(systemName: "minus.circle.fill")
                                    .font(.system(size: 25))
                                    .foregroundStyle(.red)
                            }
                            .alert("Confirm Remove Member?", isPresented: $showRemoveMemberConfirmationAlert) {
                                Button("Cancel", role: .cancel) {}
                                Button("Remove", role: .destructive) {
                                    deleteMemberFromGroupPreset(for: member)
                                }
                            } message: {
                                Text("Are you sure you want to remove \(member.getFullName()) from this group preset?")
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
            .onAppear {
                groupPresetUsers.removeAll()
                fetchGroupPresetsUsers()
            }
            .onChange(of: selectedGroupPreset) {
                print("Selected Group Preset Changed")
                groupPresetUsers.removeAll()
                fetchGroupPresetsUsers()
            }
        }
    }
    
    private func fetchGroupPresetsUsers() {
        guard let selectedGroupPreset = selectedGroupPreset else { return }
        let usersCache = FirebaseManager.shared.usersCache
        
        //TODO: Abstract this away as part of TTCache<String, TTUser>
        for userID in selectedGroupPreset.userIDs {
            if let fetchedUser = usersCache.value(forKey: userID) {
                groupPresetUsers.append(fetchedUser)
            } else {
                FirebaseManager.shared.fetchUserDocumentData(with: userID) { result in
                    switch result {
                    case .success(let ttUser):
                        groupPresetUsers.append(ttUser)
                        usersCache.insert(ttUser, forKey: ttUser.id)
                    case .failure(let error):
                        errorFetchingUsers = error
                    }
                }
            }
        }
    }
    
    private func deleteMemberFromGroupPreset(for member: TTUser) {
        guard let currentUser = FirebaseManager.shared.currentUser else { return }
        
        var currentUserGroupPresets = currentUser.groupPresets
        if let index = currentUserGroupPresets.firstIndex(where: { $0.id == groupPreset.id }) {
            var userIDSet = Set(currentUserGroupPresets[index].userIDs)
            userIDSet.subtract([member.id])
            currentUserGroupPresets[index].userIDs = Array(userIDSet)
            
            FirebaseManager.shared.updateUserData(for: currentUser.id, with: [
                TTConstants.groupPresets: currentUserGroupPresets.map{ $0.dictionary }
            ]) { error in
                if let error = error {
                    errorFetchingUsers = error
                }
            }
        }
    }
}

//MARK: - GroupPresetMemberView
struct GroupPresetMemberView: View {
    var member: TTUser
    var width: CGFloat? = 250
    @State private var memberUIImage: UIImage?
    
    var body: some View {
        RoundedRectangle(cornerRadius: 10)
            .fill(.indigo.opacity(0.3).gradient)
            .stroke(.indigo, lineWidth: 1)
            .frame(width: width, height: 50)
            .overlay(
                HStack {
                    TTSwiftUIProfileImageView(user: member, image: memberUIImage, size: TTConstants.profileImageViewInCellHeightAndWidth)
                        .frame(width: 50)
                    Text(member.getFullName())
                        .bold()
                    Spacer()
                }
                .padding(5)
            )
            .onAppear {
                member.getProfilePictureUIImage { image in
                    guard let image = image else { return }
                    memberUIImage = image
                }
            }
    }
}

#Preview {
    GroupPresetsView()
}
