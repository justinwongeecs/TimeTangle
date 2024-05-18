//
//  GroupUserCalendarConfirmationView.swift
//  TimeTangle
//
//  Created by Justin Wong on 12/17/23.
//

import SwiftUI
import EventKit

struct GroupUserCalendarConfirmationView: View {
    @Environment(\.dismiss) private var dismiss
    var events: [EKEvent]
    var completionHandler: ([EKEvent]) -> Void
    @State var omittedEvents = [EKEvent]()
    
    var body: some View {
        NavigationStack {
            confirmedEventsCountView
            List {
                tapToOmmitView
                    .listRowBackground(Color.clear)
                ForEach(events, id: \.self) { event in
                    GroupUserConfirmationEventView(event: event, omittedEvents: $omittedEvents)
                }
            }
            .scrollContentBackground(.hidden)
            .navigationTitle("Confirm Events To Be Added")
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
                
                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: {
                        let ekEventsSet = Set(events)
                        let omittedEkEventsSet = Set(omittedEvents)
                        let confirmedEkEventsSet = ekEventsSet.symmetricDifference(omittedEkEventsSet)
                        completionHandler(Array(confirmedEkEventsSet))
                    }) {
                        Text("Add")
                            .foregroundStyle(.green)
                    }
                }
            }
        }
    }
    
    private var confirmedEventsCountView: some View {
        Text("^[\(events.count - omittedEvents.count) Event](inflect: true) Confirmed")
            .foregroundStyle(.green)
            .bold()
            .padding(EdgeInsets(top: 8, leading: 10, bottom: 8, trailing: 10))
            .background(.green.opacity(0.2))
            .clipShape(RoundedRectangle(cornerRadius: 20))
    }
    
    private var tapToOmmitView: some View {
        HStack {
            Image(systemName: "hand.tap.fill")
            Text("Tap To Omit")
                .multilineTextAlignment(.center)
        }
        .foregroundStyle(.red)
        .centered()
    }
}

//MARK: - GroupUserConfirmationEventView
struct GroupUserConfirmationEventView: View {
    var event: EKEvent
    @Binding var omittedEvents: [EKEvent]
    var isSelected: Bool {
        omittedEvents.contains(event)
    }
    
    private var color: Color {
        Color(cgColor: event.calendar.cgColor)
    }
    
    var body: some View {
        Button(action: {
            if let index = omittedEvents.firstIndex(of: event) {
                omittedEvents.remove(at: index)
            } else {
                omittedEvents.append(event)
            }
        }) {
            RoundedRectangle(cornerRadius: 10)
                .fill(Color.clear)
                .stroke(color, lineWidth: 2)
                .frame(height: 130)
                .overlay(
                    HStack {
                        calendarColorIndicator
                        VStack(alignment: .leading) {
                            headerView
                            Spacer()
                            datesSection
                            Spacer()
                        }
                        .padding(EdgeInsets(top: 5, leading: 5, bottom: 10, trailing: 5))
                        Spacer()
                    }
                    .background(color.opacity(0.2))
                    .blur(radius: isSelected ? 10 : 0)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                    .overlay(
                        isSelected ?
                        omittedOverlayView : nil
                    )
                )
        }
        .tint(.primary)
        .listRowBackground(Color.clear)
        .listRowSeparator(.hidden)
    }
    
    private var omittedOverlayView: some View {
        VStack(spacing: 10) {
            Image(systemName: "xmark")
                .font(.title2)
            Text("Omitted")
                .bold()
        }
        .foregroundStyle(color)
    }
    
    private var headerView: some View {
        VStack(alignment: .leading) {
            Text(event.title)
                .font(.title3)
                .bold()
            Spacer()
            Text(event.calendar.title)
                .font(.caption).bold()
                .foregroundStyle(Color.white)
                .padding(5)
                .background(color)
                .clipShape(RoundedRectangle(cornerRadius: 10))
        }
        .padding(EdgeInsets(top: 5, leading: 0, bottom: 0, trailing: 0))
    }
    
    private var datesSection: some View {
        HStack {
            GroupUserConfirmationEventDateView(date: event.startDate, color: color)
            Image(systemName: "arrow.right")
            GroupUserConfirmationEventDateView(date: event.endDate, color: color)
        }
        .foregroundStyle(.secondary)
        .centered()
    }
    
    private var calendarColorIndicator: some View {
        RoundedRectangle(cornerRadius: 10)
            .fill(Color(cgColor: event.calendar.cgColor))
            .frame(width: 6)
            .padding(EdgeInsets(top: 8, leading: 8, bottom: 8, trailing: 0))
    }
}

//MARK: - GroupUserConfirmationEventDateView
struct GroupUserConfirmationEventDateView: View {
    var date: Date
    var color: Color
    
    var body: some View {
        VStack {
            Text("\(date.formatted(with: "MM/dd/YYYY"))")
                .bold()
                .foregroundStyle(color)
                .font(.headline)
            Text("\(date.formatted(date: .omitted, time: .shortened))")
        }
        .font(.subheadline)
    }
}

//MARK: - Preview
struct GroupUserCalendarConfirmationViewPreview: PreviewProvider {
    static let eventStore = EKEventStore()
    static var sampleEvents = createEKEvents()
    static var calendarNames = [
        "Epic Adventures", "School", "Personal", "Work"
    ]
    static var colors = [UIColor.systemRed.cgColor, UIColor.systemBlue.cgColor, UIColor.systemGreen.cgColor, UIColor.systemPurple.cgColor, UIColor.systemCyan.cgColor, UIColor.systemYellow.cgColor, UIColor.systemPink.cgColor, UIColor.systemMint.cgColor]
    static var previews: some View {
        GroupUserCalendarConfirmationView(events: sampleEvents) { _ in }
    }
    
    static private func createEKEvents() -> [EKEvent] {
        var newEvents = [EKEvent]()
        for i in 0..<6 {
            let newEKEvent = EKEvent(eventStore: eventStore)
            newEKEvent.title = "New Event \(i)"
            newEKEvent.startDate = Date()
            newEKEvent.endDate = Date()
            newEKEvent.calendar = EKCalendar(for: .event, eventStore: eventStore)
            newEKEvent.calendar.title = calendarNames[Int.random(in: 0..<calendarNames.count)]
            newEKEvent.calendar.cgColor = colors[Int.random(in: 0..<colors.count)]
            newEvents.append(newEKEvent)
        }
        return newEvents
    }
}
