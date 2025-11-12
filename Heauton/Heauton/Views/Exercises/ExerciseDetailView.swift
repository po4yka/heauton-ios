import SwiftUI

struct ExerciseDetailView: View {
    @Environment(\.appDependencies)
    private var dependencies
    let exercise: Exercise

    @State private var showingBreathingExercise = false
    @State private var showingGenericExercise = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Header
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: exercise.type.icon)
                            .font(.title)
                            .foregroundStyle(.blue)

                        Spacer()

                        // Difficulty badge
                        Text(exercise.difficulty.displayName)
                            .font(.firaCodeCaption())
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(
                                Color(exercise.difficulty.color)
                                    .opacity(0.2)
                            )
                            .foregroundStyle(Color(exercise.difficulty.color))
                            .clipShape(Capsule())
                    }

                    Text(exercise.title)
                        .font(.firaCodeTitle())

                    HStack {
                        Label(
                            exercise.formattedDuration,
                            systemImage: "clock"
                        )
                        .font(.firaCodeSubheadline())
                        .foregroundStyle(.secondary)

                        Text("•")
                            .foregroundStyle(.secondary)

                        Text(exercise.category)
                            .font(.firaCodeSubheadline())
                            .foregroundStyle(.secondary)
                    }
                }
                .padding()

                Divider()

                // Description
                VStack(alignment: .leading, spacing: 12) {
                    Text("About")
                        .font(.firaCodeHeadline())

                    Text(exercise.exerciseDescription)
                        .font(.firaCodeBody())
                        .foregroundStyle(.secondary)
                }
                .padding(.horizontal)

                // Instructions
                VStack(alignment: .leading, spacing: 12) {
                    Text("Instructions")
                        .font(.firaCodeHeadline())

                    ForEach(
                        Array(exercise.instructions.enumerated()),
                        id: \.offset
                    ) { index, instruction in
                        HStack(alignment: .top, spacing: 12) {
                            Text("\(index + 1)")
                                .font(.firaCodeCaption(.semiBold))
                                .foregroundStyle(.white)
                                .frame(width: 24, height: 24)
                                .background(Circle().fill(.blue))

                            Text(instruction)
                                .font(.firaCodeBody())
                        }
                    }
                }
                .padding(.horizontal)

                Spacer(minLength: 100)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .safeAreaInset(edge: .bottom) {
            // Start Exercise Button
            Button {
                startExercise()
            } label: {
                HStack {
                    Image(systemName: "play.fill")
                    Text("Start Exercise")
                        .font(.firaCodeHeadline())
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(.blue)
                .foregroundStyle(.white)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .padding()
            .background(.ultraThinMaterial)
        }
        .fullScreenCover(isPresented: $showingBreathingExercise) {
            if exercise.type == .breathing {
                BreathingExerciseView(exercise: exercise)
            }
        }
        .fullScreenCover(isPresented: $showingGenericExercise) {
            GenericExerciseView(exercise: exercise)
        }
    }

    private func startExercise() {
        switch exercise.type {
        case .breathing:
            showingBreathingExercise = true
        case .meditation, .bodyScan, .visualization:
            showingGenericExercise = true
        }
    }
}

// MARK: - Generic Exercise View

/// Temporary view for exercise types that don't have specialized implementations
private struct GenericExerciseView: View {
    @Environment(\.dismiss)
    private var dismiss
    @Environment(\.appDependencies)
    private var dependencies
    let exercise: Exercise

    @State private var timeRemaining: Int
    @State private var isRunning = false
    @State private var timer: Timer?

    init(exercise: Exercise) {
        self.exercise = exercise
        _timeRemaining = State(initialValue: exercise.duration)
    }

    var body: some View {
        ZStack {
            Color.black
                .ignoresSafeArea()

            VStack(spacing: 40) {
                // Close button
                HStack {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title)
                            .foregroundStyle(.white.opacity(0.7))
                    }
                    Spacer()
                }
                .padding()

                Spacer()

                // Exercise icon
                Image(systemName: exercise.type.icon)
                    .font(.system(size: 80))
                    .foregroundStyle(.blue)

                // Exercise title
                Text(exercise.title)
                    .font(.firaCodeTitle())
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.center)

                // Timer
                Text(formattedTime)
                    .font(.system(size: 72, weight: .thin, design: .rounded))
                    .foregroundStyle(.white)
                    .monospacedDigit()

                // Instructions
                if !isRunning {
                    VStack(alignment: .leading, spacing: 12) {
                        ForEach(
                            Array(exercise.instructions.prefix(3).enumerated()),
                            id: \.offset
                        ) { _, instruction in
                            Text("• \(instruction)")
                                .font(.firaCodeBody())
                                .foregroundStyle(.white.opacity(0.8))
                        }
                    }
                    .padding(.horizontal, 40)
                }

                Spacer()

                // Control button
                Button {
                    if isRunning {
                        stopExercise()
                    } else {
                        startExercise()
                    }
                } label: {
                    HStack {
                        Image(systemName: isRunning ? "pause.fill" : "play.fill")
                        Text(isRunning ? "Pause" : "Start")
                            .font(.firaCodeHeadline())
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(isRunning ? .orange : .blue)
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .padding(.horizontal, 40)
                .padding(.bottom, 40)
            }
        }
        .onDisappear {
            timer?.invalidate()
        }
    }

    private var formattedTime: String {
        let minutes = timeRemaining / 60
        let seconds = timeRemaining % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }

    private func startExercise() {
        isRunning = true
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            if timeRemaining > 0 {
                timeRemaining -= 1
            } else {
                completeExercise()
            }
        }
    }

    private func stopExercise() {
        isRunning = false
        timer?.invalidate()
        timer = nil
    }

    private func completeExercise() {
        timer?.invalidate()
        timer = nil
        isRunning = false
        dismiss()
    }
}

#Preview {
    NavigationStack {
        ExerciseDetailView(
            exercise: Exercise(
                title: "Box Breathing",
                exerciseDescription: """
                A powerful stress-relief technique used by Navy SEALs. \
                Breathe in a balanced 4-4-4-4 pattern.
                """,
                type: .breathing,
                duration: 256,
                difficulty: .beginner,
                instructions: [
                    "Sit comfortably with your back straight",
                    "Breathe in for 4 seconds",
                    "Hold for 4 seconds",
                    "Breathe out for 4 seconds",
                    "Hold for 4 seconds",
                    "Repeat for 8 cycles",
                ],
                category: "Stress Relief"
            )
        )
        .environment(\.appDependencies, AppDependencyContainer.shared)
    }
}
