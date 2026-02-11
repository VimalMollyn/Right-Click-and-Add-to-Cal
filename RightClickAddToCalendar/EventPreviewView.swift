import SwiftUI

struct EventPreviewView: View {
    @State var title: String
    @State var startDate: Date
    @State var endDate: Date
    @State var location: String
    @State var notes: String
    @State var isAllDay: Bool

    let onAdd: (CalendarEvent) -> Void
    let onCancel: () -> Void

    init(event: CalendarEvent, onAdd: @escaping (CalendarEvent) -> Void, onCancel: @escaping () -> Void) {
        _title = State(initialValue: event.title)
        _startDate = State(initialValue: event.startDate)
        _endDate = State(initialValue: event.endDate)
        _location = State(initialValue: event.location ?? "")
        _notes = State(initialValue: event.notes ?? "")
        _isAllDay = State(initialValue: event.isAllDay)
        self.onAdd = onAdd
        self.onCancel = onCancel
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Add to Calendar")
                .font(.headline)
                .padding(.bottom, 4)

            LabeledField("Title") {
                TextField("Event title", text: $title)
                    .textFieldStyle(.roundedBorder)
            }

            Toggle("All Day", isOn: $isAllDay)

            if isAllDay {
                LabeledField("Date") {
                    DatePicker("", selection: $startDate, displayedComponents: .date)
                        .labelsHidden()
                }
            } else {
                LabeledField("Start") {
                    DatePicker("", selection: $startDate, displayedComponents: [.date, .hourAndMinute])
                        .labelsHidden()
                }

                LabeledField("End") {
                    DatePicker("", selection: $endDate, displayedComponents: [.date, .hourAndMinute])
                        .labelsHidden()
                }
            }

            LabeledField("Location") {
                TextField("Location (optional)", text: $location)
                    .textFieldStyle(.roundedBorder)
            }

            LabeledField("Notes") {
                TextField("Notes (optional)", text: $notes)
                    .textFieldStyle(.roundedBorder)
            }

            HStack {
                Spacer()
                Button("Cancel") {
                    onCancel()
                }
                .keyboardShortcut(.cancelAction)

                Button("Add to Calendar") {
                    let event = CalendarEvent(
                        title: title,
                        startDate: startDate,
                        endDate: isAllDay ? startDate : endDate,
                        location: location.isEmpty ? nil : location,
                        notes: notes.isEmpty ? nil : notes,
                        isAllDay: isAllDay
                    )
                    onAdd(event)
                }
                .keyboardShortcut(.defaultAction)
                .buttonStyle(.borderedProminent)
            }
            .padding(.top, 8)
        }
        .padding(20)
        .frame(width: 400)
    }
}

struct LabeledField<Content: View>: View {
    let label: String
    let content: Content

    init(_ label: String, @ViewBuilder content: () -> Content) {
        self.label = label
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
            content
        }
    }
}

struct LoadingView: View {
    var body: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.5)
            Text("Parsing event details...")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .padding(40)
        .frame(width: 300)
    }
}

struct ErrorView: View {
    let message: String
    let onDismiss: () -> Void

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 36))
                .foregroundColor(.orange)
            Text("Error")
                .font(.headline)
            Text(message)
                .font(.body)
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
            Button("OK") { onDismiss() }
                .keyboardShortcut(.defaultAction)
        }
        .padding(24)
        .frame(width: 350)
    }
}
