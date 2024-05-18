//
//  AddGroupUsersView.swift
//  TimeTangle
//
//  Created by Justin Wong on 12/15/23.
//

import SwiftUI
import FirebaseFirestore

struct AddGroupUsersView: View {
    @Environment(\.dismiss) private var dismiss
    
    var group: TTGroup
    var completionHandler: ([TTUser]) -> Void
    
    @State private var friends = [TTUser]()
    @State private var filteredFriends = [TTUser]()
    @State private var searchFriendText = ""
    @State private var selectedFriendsToAdd = [TTUser]()
    @State private var ttError: TTError?
    
    var body: some View {
        NavigationStack {
            VStack {
                HStack {
                    searchResultsCountView
                    if !selectedFriendsToAdd.isEmpty {
                        Spacer()
                        ScrollView(.horizontal) {
                            HStack(spacing: 5) {
                                ForEach(selectedFriendsToAdd, id: \.id) { selectedFriend in
                                    TTSwiftUIProfileImageView(user: selectedFriend, size: 40)
                                }
                            }
                        }
                        .scrollIndicators(.hidden)
                    }
                }
                .padding(EdgeInsets(top: 0, leading: 10, bottom: 0, trailing: 10))
                
                if friends.isEmpty {
                   Text("No Results")
                        .applyNoResultsStyle()
                } else if filteredFriends.isEmpty {
                    Text("No Matching Results")
                        .applyNoResultsStyle()
                } else {
                    friendResultsList
                }
            }
            .fullScreenCover(item: $ttError) { details in
                TTSwiftUIAlertView(alertTitle: "ERROR", message: details.rawValue, buttonTitle: "OK")
                    .ignoresSafeArea(.all)
            }
            .navigationTitle("Add Friends To Group")
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
                
                if !selectedFriendsToAdd.isEmpty {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button(action: {
                            addSelectedFriendsToGroup()
                        }) {
                            Text("Add")
                                .foregroundStyle(.green)
                        }
                    }
                }
            }
        }
        .searchable(text: $searchFriendText, placement: .navigationBarDrawer(displayMode: .always), prompt: "Search for a friend")
        .onChange(of: searchFriendText) {
            withAnimation {
                if searchFriendText.isEmpty {
                    filteredFriends = friends
                } else {
                    filteredFriends = filteredFriends.filter { $0.getFullName().lowercased().contains(searchFriendText.lowercased())}
                }
            }
        }
        .onAppear {
            guard let currentUser = FirebaseManager.shared.currentUser else { return }
            FirebaseManager.shared.fetchMultipleUsersDocumentData(with: currentUser.friends) { result in
                switch result {
                case .success(let friends):
                    var friendsUIDSSet = Set(friends.map{ $0.id})
                    let groupUIDS = Set(group.users)
                    friendsUIDSSet.subtract(groupUIDS)
                    let friendsNotInGroup = friends.filter{ Array(friendsUIDSSet).contains($0.id) }
                    
                    self.friends.append(contentsOf: friendsNotInGroup)
                    filteredFriends.append(contentsOf: friendsNotInGroup)
                case .failure(let error):
                    ttError = error
                }
            }
        }
        .tint(.green)
    }
    
    private var friendResultsList: some View {
        List {
            ForEach(filteredFriends.sorted(by: {$0.firstname < $1.firstname}), id: \.id) { filteredFriend in
                    FriendSearchResultRowView(filteredFriend: filteredFriend, selectedFriendsToAdd: $selectedFriendsToAdd)
            }
        }
        .listRowSpacing(-15)
        .offset(x: 0, y: -30)
        .scrollContentBackground(.hidden)
    }
    
    @ViewBuilder
    private var searchResultsCountView: some View {
        if !friends.isEmpty {
            RoundedRectangle(cornerRadius: 20)
                .fill(.ultraThickMaterial)
                .frame(width: 100, height: 30)
                .overlay(
                    Text("^[\(filteredFriends.count) Result](inflect: true)")
                        .bold()
                        .foregroundStyle(.gray)
                )
        }
    }
    
    private func addSelectedFriendsToGroup() {
        FirebaseManager.shared.updateGroup(for: group.code, with: [
            TTConstants.groupUsers: FieldValue.arrayUnion(selectedFriendsToAdd.getIDs())
        ]) { error in
            if let error = error {
                ttError = error
            } else {
                addGroupCodeToSelectedFriends()
            }
        }
    }
    
    private func addGroupCodeToSelectedFriends() {
        //update added user groupcodes field
        for selectedFriend in selectedFriendsToAdd {
            FirebaseManager.shared.updateUserData(for: selectedFriend.id, with: [
                TTConstants.groupCodes: FieldValue.arrayUnion([self.group.code])
            ]) { error in
                if let error = error {
                    ttError = error
                } else {
                    completionHandler(selectedFriendsToAdd)
                    dismiss()
                }
            }
        }
    }
}

//MARK: - FriendSearchResultRowView
struct FriendSearchResultRowView: View {
    var filteredFriend: TTUser
    @Binding var selectedFriendsToAdd: [TTUser]
    
    var isTapped: Bool {
        selectedFriendsToAdd.contains(filteredFriend)
    }
    
    var body: some View {
        GroupPresetMemberView(member: filteredFriend, width: nil)
     
            .onTapGesture {
                withAnimation {
                    if !isTapped {
                        selectedFriendsToAdd.append(filteredFriend)
                    } else {
                        if let index = selectedFriendsToAdd.firstIndex(of: filteredFriend) {
                            selectedFriendsToAdd.remove(at: index)
                        }
                    }
                }
            }
            .padding(10)
            .background(isTapped ? .green.opacity(0.35): .clear)
            .clipShape(isTapped ? RoundedRectangle(cornerRadius: 10) : .init(cornerRadius: 10))
    }
}

#Preview {
    AddGroupUsersView(group: TTGroup(name: "Hello", users: [], code: UUID().uuidString, startingDate: Date(), endingDate: Date(), histories: [], events: [], admins: [], setting: TTGroupSetting(minimumNumOfUsers: 1, maximumNumOfUsers: 1, boundedStartDate: Date(), boundedEndDate: Date(), lockGroupChanges: false, allowGroupJoin: true)), completionHandler: { _ in })
}
