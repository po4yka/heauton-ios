import SwiftUI

struct BreathingExerciseView: View {
    @Environment(\.dismiss)
    private var dismiss
    @Environment(\.appDependencies)
    private var dependencies

    let exercise: Exercise

    @State private var viewModel: BreathingExerciseViewModel?

    var body: some View {
        ZStack {
            // Background gradient
            if let vm = viewModel {
                content(for: vm)
            }
        }
        .onAppear {
            if viewModel == nil {
                viewModel = BreathingExerciseViewModel(
                    exercise: exercise,
                    exerciseService: dependencies.exerciseService
                )
            }
            Task {
                await viewModel?.startExercise()
            }
        }
        .onChange(of: viewModel?.timerService.currentPhase) { _, newPhase in
            if let phase = newPhase {
                animateForPhase(phase)
            }
        }
        .onChange(of: viewModel?.timerService.isRunning) { _, _ in
            Task {
                await viewModel?.checkCompletion()
            }
        }
        .sheet(isPresented: Binding(
            get: { viewModel?.showingCompletion ?? false },
            set: { viewModel?.showingCompletion = $0 }
        )) {
            if let vm = viewModel, let session = vm.session {
                ExerciseCompletionView(
                    session: session,
                    exercise: exercise
                )
            }
        }
    }

    private func content(for vm: BreathingExerciseViewModel) -> some View {
        ZStack {
            LinearGradient(
                colors: vm.gradientColors,
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 40) {
                // Close button
                HStack {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.title3)
                            .foregroundStyle(.white)
                            .frame(width: 44, height: 44)
                            .background(
                                Circle()
                                    .fill(.ultraThinMaterial)
                            )
                    }
                    Spacer()
                }
                .padding()

                Spacer()

                // Breathing circle
                ZStack {
                    // Outer glow
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [
                                    .white.opacity(0.3),
                                    .white.opacity(0.1),
                                    .clear,
                                ],
                                center: .center,
                                startRadius: 100,
                                endRadius: 180
                            )
                        )
                        .scaleEffect(vm.circleScale)

                    // Main circle
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [
                                    .white.opacity(0.9),
                                    .white.opacity(0.6),
                                ],
                                center: .center,
                                startRadius: 0,
                                endRadius: 100
                            )
                        )
                        .frame(width: 200, height: 200)
                        .scaleEffect(vm.circleScale)

                    // Phase text
                    VStack(spacing: 8) {
                        Text(vm.timerService.currentPhase.displayName)
                            .font(.firaCodeTitle())
                            .fontWeight(.bold)

                        Text("\(vm.timerService.timeRemaining)")
                            .font(.system(size: 48, weight: .light, design: .rounded))
                    }
                    .foregroundStyle(.black.opacity(0.8))
                }
                .frame(height: 400)

                // Phase instruction
                Text(vm.timerService.currentPhase.instruction)
                    .font(.firaCodeTitle3())
                    .foregroundStyle(.white.opacity(0.9))
                    .multilineTextAlignment(.center)

                // Cycle progress
                Text("Cycle \(vm.timerService.currentCycle) of \(vm.timerService.totalCycles)")
                    .font(.firaCodeSubheadline())
                    .foregroundStyle(.white.opacity(0.7))

                Spacer()

                // Controls
                HStack(spacing: 30) {
                    if vm.showResumeButton {
                        // Resume button
                        Button {
                            vm.resumeExercise()
                            animateForPhase(vm.timerService.currentPhase)
                        } label: {
                            Image(systemName: "play.fill")
                                .font(.title2)
                                .foregroundStyle(.white)
                                .frame(width: 60, height: 60)
                                .background(Circle().fill(Color.lsGunmetal))
                        }
                    } else if vm.showPauseButton {
                        // Pause button
                        Button {
                            vm.pauseExercise()
                        } label: {
                            Image(systemName: "pause.fill")
                                .font(.title2)
                                .foregroundStyle(.white)
                                .frame(width: 60, height: 60)
                                .background(Circle().fill(Color.lsIronGrey))
                        }
                    }

                    // Stop button
                    Button {
                        Task {
                            await vm.stopExercise()
                        }
                    } label: {
                        Image(systemName: "stop.fill")
                            .font(.title2)
                            .foregroundStyle(.white)
                            .frame(width: 60, height: 60)
                            .background(Circle().fill(Color.lsShadowGrey))
                    }
                }
                .padding(.bottom, 40)
            }
        }
    }

    // MARK: - Animation Helper

    private func animateForPhase(_ phase: BreathingPhase) {
        guard let vm = viewModel else { return }

        let (duration, scale) = vm.animationParameters(for: phase)

        withAnimation(.easeInOut(duration: duration)) {
            vm.updateCircleScale(scale)
        }

        // Haptic feedback
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()
    }
}

#Preview {
    BreathingExerciseView(
        exercise: Exercise(
            title: "Box Breathing",
            exerciseDescription: "A powerful stress-relief technique.",
            type: .breathing,
            duration: 256,
            difficulty: .beginner,
            instructions: ["Breathe in", "Hold", "Breathe out", "Hold"],
            category: "Stress Relief"
        )
    )
    .environment(\.appDependencies, AppDependencyContainer.shared)
}
