//
//  GroupSettingsView.swift
//  TimeTangle
//
//  Created by Justin Wong on 5/26/23.
//

import SwiftUI
import Setting
import FirebaseFirestore

struct GroupSettingsView: View {
    @Environment(\.dismiss) var dismiss
    var config: Configuration 
    @State var group: TTGroup!
    private(set) var updateClosure: (TTGroup) -> Void
    private var popUIViewController: () -> Void
    
    @State private var ttError: TTError? = nil
    @State private var showErrorAlert = false
    @State private var showChangeGroupNameAlert = false
    @State private var showDeleteGroupConfirmation = false
    @State private var showLeaveGroupConfirmation = false
    
    @State private var newGroupNameText = ""
    @State private var minimumNumberOfUsersIndex = 0
    @State private var maximumNumberOfUsersIndex = 0
    @State private var boundedStartDate = Date()
    @State private var boundedEndDate = Date()
    @State private var lockGroupChanges = false
    @State private var allowGroupJoin = true
    
    init(group: TTGroup, config: Configuration, updateClosure: @escaping (TTGroup) -> Void, popUIViewController: @escaping() -> Void) {
        _group = State(initialValue: group)
        self.config = config 
        self.updateClosure = updateClosure
        self.popUIViewController = popUIViewController
        _newGroupNameText = State(initialValue: group.name)
        _minimumNumberOfUsersIndex = State(initialValue: group.setting.minimumNumOfUsers - 2)
        _maximumNumberOfUsersIndex = State(initialValue: group.setting.maximumNumOfUsers - 2)
        _boundedStartDate = State(initialValue: group.setting.boundedStartDate)
        _boundedEndDate = State(initialValue: group.setting.boundedEndDate)
        _lockGroupChanges = State(initialValue: group.setting.lockGroupChanges)
        _allowGroupJoin = State(initialValue: group.setting.allowGroupJoin)
    }
    
    var body: some View {
        NavigationStack {
            SettingStack(isSearchable: false, embedInNavigationStack: true) {
                SettingPage(title: "\(group.name) Settings", navigationTitleDisplayMode: .inline) {
                    SettingGroup(id: "Change Group Name Button", header: "Group Name") {
                        SettingText(title: "\(newGroupNameText)")
                        SettingCustomView(id: "Change Group Name Button") {
                            Button(action: {
                                showChangeGroupNameAlert.toggle()
                            }) {
                                HStack {
                                    Text("Change Group Name")
                                    Image(systemName: "square.and.pencil")
                                }
                                .foregroundColor(.green)
                                .leftAligned()
                                .frame(maxWidth: .infinity)
                            }
                            .padding(15)
                            .alert("Change Group Name", isPresented: $showChangeGroupNameAlert) {
                                TextField("Group Name", text: $newGroupNameText)
                                Button("OK", action: {
                                    newGroupNameText = newGroupNameText.trimmingCharacters(in: .whitespacesAndNewlines)
                                })
                                Button("Cancel", role: .cancel) {
                                    showChangeGroupNameAlert.toggle()
                                }
                            }
                        }
                    }
                    
                    SettingGroup(id: "Set Min And Max User Pickers", header: "Number Of Users") {
                        minimumNumberOfUsersPicker
                        maximumNumberOfUsersPicker
                    }
                    
                    SettingGroup(id: "Set Min and Max Dates", header: "Date Bounds") {
                        SettingCustomView(id: "Bounded Start Date Picker") {
                            DatePicker("Bounded Start Date", selection: $boundedStartDate, displayedComponents: [.date])
                                .datePickerStyle(.compact)
                                .tint(.green)
                                .padding(15)
                        }
                        SettingCustomView(id: "Bounded End Date Picker") {
                            DatePicker("Bounded End Date", selection: $boundedEndDate, displayedComponents: [.date])
                                .datePickerStyle(.compact)
                                .tint(.green)
                                .padding(15)
                        }
                    }
                    
                    SettingGroup(id: "Group Settings", header: "Group Settings") {
                        lockGroupChangesButton
                        enableGroupJoinToggle
                    }
                    
                    SettingGroup(id: "Delete Group Button") {
                        deleteGroupButton
                    }
                    
                    SettingGroup(id: "Leave Group Button") {
                        leaveGroupButton
                    }
                }
            }
            .toolbar {
                //Close Button
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: {
                        dismiss()
                    }) {
                        Text("Cancel")
                    }
                    .tint(.green)
                }
                //Save Button
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        saveToFirestore()
                    }) {
                        Text("Save")
                            .frame(width: 60)
                            .foregroundColor(.white)
                            .bold()
                            .padding(8)
                            .background(.green.opacity(0.7))
                            .cornerRadius(10)
                            
                    }
                    .tint(.green)
                }
            }
            .onChange(of: minimumNumberOfUsersIndex) { [minimumNumberOfUsersIndex] newValue in
                if newValue + 2 > maximumNumberOfUsersIndex + 2 {
                    showError(for: TTError.invalidMinimumNumOfUsersIndex)
                    self.minimumNumberOfUsersIndex = minimumNumberOfUsersIndex
                } else {
                    nilError()
                }
            }
            .onChange(of: maximumNumberOfUsersIndex) { [maximumNumberOfUsersIndex] newValue in
                if newValue + 2 < minimumNumberOfUsersIndex + 2 {
                    showError(for: TTError.invalidMaximumNumOfUsersIndex)
                    self.maximumNumberOfUsersIndex = maximumNumberOfUsersIndex
                } else {
                    nilError()
                }
            }
            .onChange(of: boundedStartDate) { [boundedStartDate] newValue in
                if newValue > boundedEndDate {
                    showError(for: TTError.invalidBoundedStartDate)
                    self.boundedStartDate = boundedStartDate
                } else {
                    nilError()
                }
            }
            .onChange(of: boundedEndDate) { [boundedEndDate] newValue in
                if newValue < boundedStartDate {
                    showError(for: TTError.invalidBoundedEndDate)
                    self.boundedEndDate = boundedEndDate
                } else {
                    nilError()
                }
            }
            .onChange(of: showErrorAlert) { _ in
                config.hostingController?.presentTTAlert(title: "Setting Error", message: ttError?.rawValue ?? "No Message", buttonTitle: "OK")
            }
        }
    }
    
    //MARK: - MinimumNumberofUsersPicker
    @SettingBuilder private var minimumNumberOfUsersPicker: some Setting {
        SettingPicker(title: "Minimum Users", choices: [
        "2", "3", "4", "5", "6", "7", "8", "9", "10"
        ], selectedIndex: $minimumNumberOfUsersIndex, choicesConfiguration: .init(pickerDisplayMode: .menu))
    }
    
    //MARK: - MaximumNumberOfUsersPicker
    @SettingBuilder private var maximumNumberOfUsersPicker: some Setting {
        SettingPicker(title: "Maximum Users", choices: [
        "2", "3", "4", "5", "6", "7", "8", "9", "10"
        ], selectedIndex: $maximumNumberOfUsersIndex, choicesConfiguration: .init(pickerDisplayMode: .menu))
    }
    
    //MARK: - LockGroupChangesButton
    @SettingBuilder private var lockGroupChangesButton: some Setting {
        SettingCustomView(id: "Lock Unlock Group Changes Button") {
            VStack {
                HStack {
                    Text("Lock Group Changes: ")
                    Spacer()
                    Button(action: {
                        withAnimation {
                            lockGroupChanges.toggle()
                        }
                    }) {
                        HStack {
                            if lockGroupChanges {
                                Text("Locked")
                                Image(systemName: "lock.fill")
                            } else {
                                Text("Unlocked")
                            }
                        }
                        .bold()
                        .foregroundColor(.white)
                        .padding(8)
                        .background(lockGroupChanges ? .red : .green)
                        .cornerRadius(10)
                    }
                }
                
                Text("When locked, group can ONLY be edited by users with Admin access level")
                    .font(.system(size: 13))
                    .foregroundColor(.secondary)
            }
            .padding(15)
        }
    }
    
    //MARK: - EnableGroupJoinToggle
    @SettingBuilder private var enableGroupJoinToggle: some Setting {
        SettingToggle(title: "Allow Group Join", isOn: $allowGroupJoin)
    }
    
    //MARK: - DeleteGroupButton
    @SettingBuilder private var deleteGroupButton: some Setting {
        SettingCustomView {
            Button(action: {
                showDeleteGroupConfirmation.toggle()
            }) {
                Text("Delete Group")
                    .foregroundColor(.red)
                    .leftAligned()
                    .frame(maxWidth: .infinity)
            }
            .padding(15)
            .alert(isPresented: $showDeleteGroupConfirmation) {
                Alert(title: Text("Confirm Delete Group"),
                      message: Text("Are you sure you want to delete \(group.name)?"),
                      primaryButton: .cancel(),
                      secondaryButton: .default(Text("OK")) { deleteGroup() })
            }
        }
    }
    
    //MARK: - LeaveGroupButton
    @SettingBuilder private var leaveGroupButton: some Setting {
        SettingCustomView {
            Button(action: {
                showLeaveGroupConfirmation.toggle()
            }) {
                Text("Leave Group")
                    .foregroundColor(.red)
                    .leftAligned()
                    .frame(maxWidth: .infinity)
            }
            .padding(15)
            .alert(isPresented: $showLeaveGroupConfirmation) {
                Alert(title: Text("Confirm Leaving Group"),
                      message: Text("Are you sure you want to leave \(group.name)?"),
                      primaryButton: .cancel(),
                      secondaryButton: .default(Text("OK")) { leaveGroup() })
            }
        }
    }
    
    //MARK: - Save
    private func saveToFirestore() {
        FirebaseManager.shared.updateGroup(for: group.code, with: [
            TTConstants.groupName: newGroupNameText,
            TTConstants.groupSettingMinimumNumOfUsers: minimumNumberOfUsersIndex + 2,
            TTConstants.groupSettingMaximumNumOfUsers: maximumNumberOfUsersIndex + 2,
            TTConstants.groupSettingBoundedStartDate: boundedStartDate,
            TTConstants.groupSettingBoundedEndDate: boundedEndDate,
            TTConstants.groupSettingLockGroupChanges: lockGroupChanges,
            TTConstants.groupSettingAllowGroupJoin: allowGroupJoin,
            TTConstants.groupStartingDate: boundedStartDate > group.startingDate ? boundedStartDate : group.startingDate,
            TTConstants.groupEndingDate: group.endingDate > boundedEndDate ? boundedEndDate : group.endingDate
        ]) { error in
            guard let error = error else {
                let newGroupSettings = TTGroupSetting(minimumNumOfUsers: minimumNumberOfUsersIndex + 2,
                                                    maximumNumOfUsers: maximumNumberOfUsersIndex + 2,
                                                    boundedStartDate: boundedStartDate,
                                                    boundedEndDate: boundedEndDate,
                                                    lockGroupChanges: lockGroupChanges,
                                                    allowGroupJoin: allowGroupJoin)
                let newGroup = TTGroup(name: newGroupNameText,
                                     users: group.users,
                                     code: group.code,
                                     startingDate: boundedStartDate > group.startingDate ? boundedStartDate : group.startingDate,
                                     endingDate: group.endingDate > boundedEndDate ? boundedEndDate : group.endingDate,
                                     histories: group.histories,
                                     events: group.events,
                                     admins: group.admins,
                                     setting: newGroupSettings)
                updateClosure(newGroup)
                dismiss()
                return
            }
            ttError = error
            showErrorAlert = true
        }
    }
    
    //MARK: - Helper Methods
    private func showError(for error: TTError) {
        ttError = error
        showErrorAlert.toggle()
    }
    
    private func nilError() {
        ttError = nil
        showErrorAlert = false
    }
    
    private func deleteGroup() {
        FirebaseManager.shared.deleteGroup(for: group.code) { error in
            if let err = error {
                showError(for: err)
            } else {
                for username in group.users {
                    FirebaseManager.shared.updateUserData(for: username, with: [
                        TTConstants.groupCodes: FieldValue.arrayRemove([group.code])
                    ]) { error in
                        if let err = error {
                            ttError = err
                            showErrorAlert = true
                        } else {
                            dismiss()
                            popUIViewController()
                        }
                    }
                }
            }
        }
    }
    
    private func leaveGroup() {
        guard let currentUser = FirebaseManager.shared.currentUser else { return }
        
        FirebaseManager.shared.updateGroup(for: group.code, with: [
            TTConstants.groupUsers: FieldValue.arrayRemove([currentUser.username])
        ]) { error in
            if let err = error {
                showError(for: err)
            } else {
                FirebaseManager.shared.updateUserData(for: currentUser.username, with: [
                    TTConstants.groupCodes: FieldValue.arrayRemove([group.code])
                ]) { error in
                    if let err = error {
                        ttError = err
                        showErrorAlert = true
                    } else {
                        dismiss()
                        popUIViewController()
                    }
                }
            }
        }
    }
}

struct GroupSettingsView_Previews: PreviewProvider {
    static let configuration = Configuration()
    static let group = TTGroup(name: "Meeting 1", users: [], code: "ABCDE", startingDate: Date(), endingDate: Date(), histories: [], events: [], admins: [], setting: TTGroupSetting(minimumNumOfUsers: 2, maximumNumOfUsers: 10, boundedStartDate: Date(), boundedEndDate: Date(), lockGroupChanges: false, allowGroupJoin: true))
    static var previews: some View {
        GroupSettingsView(group: group, config: configuration, updateClosure: {_ in }, popUIViewController: {})
    }
}
