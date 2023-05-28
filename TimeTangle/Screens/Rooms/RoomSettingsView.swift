//
//  RoomSettingsView.swift
//  TimeTangle
//
//  Created by Justin Wong on 5/26/23.
//

import SwiftUI
import Setting
import FirebaseFirestore

struct RoomSettingsView: View {
    @Environment(\.dismiss) var dismiss
    @State var room: TTRoom!
    private(set) var updateClosure: (TTRoom) -> Void
    private var popUIViewController: () -> Void
    
    @State private var ttError: TTError? = nil
    @State private var showErrorAlert = false
    @State private var showChangeRoomNameAlert = false
    @State private var showDeleteRoomConfirmation = false
    @State private var showLeaveRoomConfirmation = false
    
    @State private var newRoomNameText = ""
    @State private var minimumNumberOfUsersIndex = 0
    @State private var maximumNumberOfUsersIndex = 0
    @State private var boundedStartDate = Date()
    @State private var boundedEndDate = Date()
    @State private var lockRoomChanges = false
    @State private var allowRoomJoin = true
    
    init(room: TTRoom, updateClosure: @escaping (TTRoom) -> Void, popUIViewController: @escaping() -> Void) {
        _room = State(initialValue: room)
        self.updateClosure = updateClosure
        self.popUIViewController = popUIViewController
        _newRoomNameText = State(initialValue: room.name)
        _minimumNumberOfUsersIndex = State(initialValue: room.setting.minimumNumOfUsers - 2)
        _maximumNumberOfUsersIndex = State(initialValue: room.setting.maximumNumOfUsers - 2)
        _boundedStartDate = State(initialValue: room.setting.boundedStartDate)
        _boundedEndDate = State(initialValue: room.setting.boundedEndDate)
        _lockRoomChanges = State(initialValue: room.setting.lockRoomChanges)
        _allowRoomJoin = State(initialValue: room.setting.allowRoomJoin)
    }
    
    var body: some View {
        NavigationView {
            SettingStack(isSearchable: false, embedInNavigationStack: true) {
                SettingPage(title: "\(room.name) Settings", navigationTitleDisplayMode: .inline) {
                    SettingGroup(id: "Change Room Name Button", header: "Room Name") {
                        SettingText(title: "\(newRoomNameText)")
                        SettingCustomView(id: "Change Room Name Button") {
                            Button(action: {
                                showChangeRoomNameAlert.toggle()
                            }) {
                                HStack {
                                    Text("Change Room Name")
                                    Image(systemName: "square.and.pencil")
                                }
                                .foregroundColor(.green)
                                .leftAligned()
                                .frame(maxWidth: .infinity)
                            }
                            .padding(15)
                            .alert("Change Room Name", isPresented: $showChangeRoomNameAlert) {
                                TextField("Room Name", text: $newRoomNameText)
                                Button("OK", action: {
                                    newRoomNameText = newRoomNameText.trimmingCharacters(in: .whitespacesAndNewlines)
                                })
                                Button("Cancel", role: .cancel) {
                                    showChangeRoomNameAlert.toggle()
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
                    
                    SettingGroup(id: "Room Settings", header: "Room Settings") {
                        lockRoomChangesButton
                        enableRoomJoinToggle
                    }
                    
                    SettingGroup(id: "Delete Room Button") {
                        deleteRoomButton
                    }
                    
                    SettingGroup(id: "Leave Room Button") {
                        leaveRoomButton
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
                }
                //Save Button
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        saveToFirestore()
                    }) {
                        Text("Save")
                            .frame(width: 100)
                            .foregroundColor(.white)
                            .bold()
                            .padding(8)
                            .background(.green.opacity(0.7))
                            .cornerRadius(10)
                            
                    }
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
            .presentScreen(isPresented: $showErrorAlert, modalPresentationStyle: .overFullScreen) {
                TTSwiftUIAlertView(alertTitle: "Error", message: ttError?.rawValue ?? "No Message", buttonTitle: "OK")
                    .ignoresSafeArea(.all)
            }
        }
    }
    
    //MARK: - ChangeRoomNameButton
//    @SettingBuilder private var changeRoomNameButton: some Setting  {
//
//    }
    
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
    
    //MARK: - LockRoomChangesButton
    @SettingBuilder private var lockRoomChangesButton: some Setting {
        SettingCustomView(id: "Lock Unlock Room Changes Button") {
            VStack {
                HStack {
                    Text("Lock Room Changes: ")
                    Spacer()
                    Button(action: {
                        withAnimation {
                            lockRoomChanges.toggle()
                        }
                    }) {
                        HStack {
                            if lockRoomChanges {
                                Text("Locked")
                                Image(systemName: "lock.fill")
                            } else {
                                Text("Unlocked")
                            }
                        }
                        .bold()
                        .foregroundColor(.white)
                        .padding(8)
                        .background(lockRoomChanges ? .red : .green)
                        .cornerRadius(10)
                    }
                }
                
                Text("When locked, room can ONLY be edited by users with Admin access level")
                    .font(.system(size: 13))
                    .foregroundColor(.secondary)
            }
            .padding(15)
        }
    }
    
    //MARK: - EnableRoomJoinToggle
    @SettingBuilder private var enableRoomJoinToggle: some Setting {
        SettingToggle(title: "Allow Room Join", isOn: $allowRoomJoin)
    }
    
    //MARK: - DeleteRoomButton
    @SettingBuilder private var deleteRoomButton: some Setting {
        SettingCustomView {
            Button(action: {
                showDeleteRoomConfirmation.toggle()
            }) {
                Text("Delete Room")
                    .foregroundColor(.red)
                    .leftAligned()
                    .frame(maxWidth: .infinity)
            }
            .padding(15)
            .alert(isPresented: $showDeleteRoomConfirmation) {
                Alert(title: Text("Confirm Delete Room"),
                      message: Text("Are you sure you want to delete \(room.name)?"),
                      primaryButton: .cancel(),
                      secondaryButton: .default(Text("OK")) { deleteRoom() })
            }
            .presentScreen(isPresented: $showErrorAlert, modalPresentationStyle: .overFullScreen) {
                TTSwiftUIAlertView(alertTitle: "Delete Room Error", message: ttError?.rawValue ?? "No Message", buttonTitle: "OK")
            }
        }
    }
    
    //MARK: - LeaveRoomButton
    @SettingBuilder private var leaveRoomButton: some Setting {
        SettingCustomView {
            Button(action: {
                showLeaveRoomConfirmation.toggle()
            }) {
                Text("Leave Room")
                    .foregroundColor(.red)
                    .leftAligned()
                    .frame(maxWidth: .infinity)
            }
            .padding(15)
            .alert(isPresented: $showLeaveRoomConfirmation) {
                Alert(title: Text("Confirm Leaving Room"),
                      message: Text("Are you sure you want to leave \(room.name)?"),
                      primaryButton: .cancel(),
                      secondaryButton: .default(Text("OK")) { leaveRoom() })
            }
            .presentScreen(isPresented: $showErrorAlert, modalPresentationStyle: .overFullScreen) {
                TTSwiftUIAlertView(alertTitle: "Leave Room Error", message: ttError?.rawValue ?? "No Message", buttonTitle: "OK")
            }
        }
    }
    
    //MARK: - Save
    private func saveToFirestore() {
        FirebaseManager.shared.updateRoom(for: room.code, with: [
            TTConstants.roomName: newRoomNameText,
            TTConstants.roomSettingMinimumNumOfUsers: minimumNumberOfUsersIndex + 2,
            TTConstants.roomSettingMaximumNumOfUsers: maximumNumberOfUsersIndex + 2,
            TTConstants.roomSettingBoundedStartDate: boundedStartDate,
            TTConstants.roomSettingBoundedEndDate: boundedEndDate,
            TTConstants.roomSettingLockRoomChanges: lockRoomChanges,
            TTConstants.roomSettingAllowRoomJoin: allowRoomJoin,
            TTConstants.roomStartingDate: boundedStartDate > room.startingDate ? boundedStartDate : room.startingDate,
            TTConstants.roomEndingDate: room.endingDate > boundedEndDate ? boundedEndDate : room.endingDate
        ]) { error in
            guard let error = error else {
                let newRoomSettings = TTRoomSetting(minimumNumOfUsers: minimumNumberOfUsersIndex + 2,
                                                    maximumNumOfUsers: maximumNumberOfUsersIndex + 2,
                                                    boundedStartDate: boundedStartDate,
                                                    boundedEndDate: boundedEndDate,
                                                    lockRoomChanges: lockRoomChanges,
                                                    allowRoomJoin: allowRoomJoin)
                let newRoom = TTRoom(name: newRoomNameText,
                                     users: room.users,
                                     code: room.code,
                                     startingDate: boundedStartDate > room.startingDate ? boundedStartDate : room.startingDate,
                                     endingDate: room.endingDate > boundedEndDate ? boundedEndDate : room.endingDate,
                                     histories: room.histories,
                                     events: room.events,
                                     admins: room.admins,
                                     setting: newRoomSettings)
                updateClosure(newRoom)
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
    
    private func deleteRoom() {
        FirebaseManager.shared.deleteRoom(for: room.code) { error in
            if let err = error {
                showError(for: err)
            } else {
                for username in room.users {
                    FirebaseManager.shared.updateUserData(for: username, with: [
                        TTConstants.roomCodes: FieldValue.arrayRemove([room.code])
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
    
    private func leaveRoom() {
        guard let currentUser = FirebaseManager.shared.currentUser else { return }
        
        FirebaseManager.shared.updateRoom(for: room.code, with: [
            TTConstants.roomUsers: FieldValue.arrayRemove([currentUser.username])
        ]) { error in
            if let err = error {
                showError(for: err)
            } else {
                FirebaseManager.shared.updateUserData(for: currentUser.username, with: [
                    TTConstants.roomCodes: FieldValue.arrayRemove([room.code])
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

struct RoomSettingsView_Previews: PreviewProvider {
    static let room = TTRoom(name: "Meeting 1", users: [], code: "ABCDE", startingDate: Date(), endingDate: Date(), histories: [], events: [], admins: [], setting: TTRoomSetting(minimumNumOfUsers: 2, maximumNumOfUsers: 10, boundedStartDate: Date(), boundedEndDate: Date(), lockRoomChanges: false, allowRoomJoin: true))
    static var previews: some View {
        RoomSettingsView(room: room, updateClosure: {_ in }, popUIViewController: {})
    }
}
