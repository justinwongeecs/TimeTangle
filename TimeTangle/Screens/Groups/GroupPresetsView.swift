//
//  GroupPresetsView.swift
//  TimeTangle
//
//  Created by Justin Wong on 11/21/23.
//

import SwiftUI
import Firebase

//MARK: - TTGroupPreset
struct TTGroupPreset: Codable, Identifiable {
    var id: String 
    var name: String
    var userIDs: [String]
    private var users: [TTUser]?
    
    var dictionary: [String: Any] {
        return [
            "id": id,
            "name": name,
            "userIDs": userIDs
        ]
    }
    
    init(id: String, name: String, userIDs: [String]) {
        self.id = id
        self.name = name
        self.userIDs = userIDs
    }
    
    func getUsers() -> [TTUser]? {
        return users
    }
}

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
//                if !FirebaseManager.shared.storeViewModel.isSubscriptionPro {
//                    lockedView
                if groupPresetsVM.groupPresets.isEmpty {
                    GroupPresetsEmptyView()
                } else {
                    VStack {
                        List {
                            ForEach(groupPresetsVM.groupPresets) { groupPreset in
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
    
    func animateEmoji() {
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
    @Binding var selectedGroupPresent: TTGroupPreset?
    @Binding var isInEditMode: Bool
    @Binding var isExpanded: Bool
    
    var groupPreset: TTGroupPreset
    
    @State private var groupPresetUsers = [TTUser]()
    @State private var errorFetchingUsers = ""
    
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
        if !errorFetchingUsers.isEmpty {
            Text("Could Not Fetch Users: \(errorFetchingUsers)")
            .padding()
            .bold()
            .foregroundStyle(.red)
        } else {
            List {
                ForEach(groupPresetUsers.sorted(by: { $0.firstname < $1.firstname}), id: \.id) { member in
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
            .onAppear {
                //Fetch groupPreset's TTUsers from userIDs
                if groupPresetUsers.isEmpty {
                    fetchGroupPresetsUsers()
                }
            }
        }
    }
    
    private func fetchGroupPresetsUsers() {
        let usersCache = FirebaseManager.shared.usersCache
        
        //TODO: Abstract this away as part of TTCache<String, TTUser>
        for userID in groupPreset.userIDs {
            if let fetchedUser = usersCache.value(forKey: userID) {
                groupPresetUsers.append(fetchedUser)
            } else {
                FirebaseManager.shared.fetchUserDocumentData(with: userID) { result in
                    switch result {
                    case .success(let ttUser):
                        groupPresetUsers.append(ttUser)
                        usersCache.insert(ttUser, forKey: ttUser.id)
                    case .failure(let error):
                        errorFetchingUsers = error.rawValue
                    }
                }
            }
        }
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
    GroupPresetsView()
}
