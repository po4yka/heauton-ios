import SwiftUI

struct ExerciseCompletionView: View {
    @Environment(\.dismiss)
    private var dismiss
    @Environment(\.appDependencies)
    private var dependencies

    let session: ExerciseSession
    let exercise: Exercise

    @State private var moodAfter: JournalMood?
    @State private var notes: String = ""

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 30) {
                    // Celebration
                    VStack(spacing: 16) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 80))
                            .foregroundStyle(.green)

                        Text("Exercise Complete!")
                            .font(.firaCodeTitle())

                        Text(exercise.title)
                            .font(.firaCodeHeadline())
                            .foregroundStyle(.secondary)

                        Text(session.formattedDuration)
                            .font(.firaCodeTitle3())
                            .foregroundStyle(.blue)
                    }
                    .padding(.top, 40)

                    Divider()
                        .padding(.horizontal)

                    // Mood after
                    VStack(alignment: .leading, spacing: 16) {
                        Text("How do you feel now?")
                            .font(.firaCodeHeadline())

                        LazyVGrid(
                            columns: [
                                GridItem(.flexible()),
                                GridItem(.flexible()),
                                GridItem(.flexible()),
                            ],
                            spacing: 12
                        ) {
                            ForEach(JournalMood.allCases, id: \.self) { mood in
                                MoodButton(
                                    mood: mood,
                                    isSelected: moodAfter == mood
                                ) {
                                    moodAfter = mood
                                }
                            }
                        }
                    }
                    .padding(.horizontal)

                    // Optional notes
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Notes (Optional)")
                            .font(.firaCodeHeadline())

                        TextEditor(text: $notes)
                            .font(.firaCodeBody())
                            .frame(height: 100)
                            .padding(8)
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Color.gray.opacity(0.3))
                            )
                    }
                    .padding(.horizontal)

                    Spacer()
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        saveAndDismiss()
                    }
                }
            }
        }
    }

    private func saveAndDismiss() {
        Task {
            try? await dependencies.exerciseService.completeSession(
                session,
                actualDuration: session.actualDuration,
                moodAfter: moodAfter,
                notes: notes.isEmpty ? nil : notes
            )

            await MainActor.run {
                dismiss()
            }
        }
    }
}

private struct MoodButton: View {
    let mood: JournalMood
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Text(mood.emoji)
                    .font(.title)

                Text(mood.displayName)
                    .font(.firaCodeCaption())
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? Color.blue.opacity(0.2) : Color.gray.opacity(0.1))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Color.blue : Color.clear, lineWidth: 2)
            )
        }
    }
}

#Preview {
    ExerciseCompletionView(
        session: ExerciseSession(
            linkedExerciseId: UUID(),
            actualDuration: 256
        ),
        exercise: Exercise(
            title: "Box Breathing",
            exerciseDescription: "A stress-relief technique.",
            type: .breathing,
            duration: 256,
            difficulty: .beginner,
            instructions: ["Breathe"],
            category: "Stress Relief"
        )
    )
    .environment(\.appDependencies, AppDependencyContainer.shared)
}
