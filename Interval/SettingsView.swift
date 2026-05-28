import SwiftUI

struct SettingsView: View {
    @Bindable var settings: IntervalSettings

    var body: some View {
        Form {
            Section("Timing") {
                Stepper(value: $settings.workMinutes, in: 1...180, step: 1) {
                    LabeledContent("Work interval") {
                        Text("\(Int(settings.workMinutes)) min")
                            .monospacedDigit()
                            .foregroundStyle(.secondary)
                    }
                }

                Stepper(value: $settings.restMinutes, in: 1...60, step: 1) {
                    LabeledContent("Rest duration") {
                        Text("\(Int(settings.restMinutes)) min")
                            .monospacedDigit()
                            .foregroundStyle(.secondary)
                    }
                }

                Stepper(value: $settings.notificationLeadSeconds, in: 0...120, step: 5) {
                    LabeledContent("Notify before rest") {
                        Text("\(Int(settings.notificationLeadSeconds)) s")
                            .monospacedDigit()
                            .foregroundStyle(.secondary)
                    }
                }
            }

            Section {
                Stepper(value: $settings.idleThresholdSeconds, in: 5...600, step: 5) {
                    LabeledContent("Pause after no activity") {
                        Text("\(Int(settings.idleThresholdSeconds)) s")
                            .monospacedDigit()
                            .foregroundStyle(.secondary)
                    }
                }
            } header: {
                Text("Idle detection")
            } footer: {
                Text("Work countdown pauses when you stop moving the mouse or typing, and when the screen is locked. It resumes the moment you interact again.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }

            Section("Rest screen") {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Message")
                        .font(.callout)
                    TextEditor(text: $settings.restMessage)
                        .font(.body)
                        .frame(minHeight: 70)
                        .scrollContentBackground(.hidden)
                        .padding(6)
                        .background(
                            RoundedRectangle(cornerRadius: 6)
                                .fill(Color(nsColor: .textBackgroundColor))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 6)
                                .strokeBorder(Color.secondary.opacity(0.25))
                        )
                }
            }

            Section {
                Text("Changes apply to the next interval.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
        .formStyle(.grouped)
        .frame(width: 480, height: 420)
    }
}

#Preview {
    SettingsView(settings: .shared)
}
