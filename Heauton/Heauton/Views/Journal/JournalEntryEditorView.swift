import SwiftData
import SwiftUI

struct JournalEntryEditorView: View {
    @Environment(\.dismiss)
    private var dismiss
    @Environment(\.appDependencies)
    private var dependencies

    @State private var viewModel: JournalEntryEditorViewModel?

    var entry: JournalEntry?

    var body: some View {
        NavigationStack {
            if let vm = viewModel {
                Form {
                    Section {
                        TextField("Entry Title", text: Binding(
                            get: { vm.title },
                            set: { vm.title = $0 }
                        ))
                        .font(.firaCodeHeadline())
                    }

                    Section("How are you feeling?") {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 12) {
                                ForEach(JournalMood.allCases, id: \.self) { mood in
                                    MoodButton(
                                        mood: mood,
                                        isSelected: vm.selectedMood == mood
                                    ) {
                                        vm.toggleMood(mood)
                                    }
                                }
                            }
                        }
                    }

                    Section("Your thoughts") {
                        TextEditor(text: Binding(
                            get: { vm.content },
                            set: { vm.content = $0 }
                        ))
                        .font(.firaCodeBody(.regular))
                        .frame(minHeight: 200)
                    }

                    Section("Tags") {
                        TagInputView(
                            tags: Binding(
                                get: { vm.tags },
                                set: { vm.tags = $0 }
                            )
                        )
                    }
                }
                .navigationTitle(vm.navigationTitle)
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Cancel") {
                            dismiss()
                        }
                    }

                    ToolbarItem(placement: .confirmationAction) {
                        Button("Save") {
                            Task {
                                if await vm.saveEntry() {
                                    dismiss()
                                }
                            }
                        }
                        .disabled(!vm.canSave)
                    }
                }
            }
        }
        .onAppear {
            if viewModel == nil {
                viewModel = JournalEntryEditorViewModel(
                    entry: entry,
                    journalService: dependencies.journalService
                )
            }
        }
    }
}

// MARK: - Supporting Views

private struct MoodButton: View {
    let mood: JournalMood
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Text(mood.emoji)
                    .font(.title2)
                Text(mood.displayName)
                    .font(.firaCodeCaption2())
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(isSelected ? mood.color.opacity(0.2) : Color.clear)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(
                        isSelected ? mood.color : Color.lsPaleSlate.opacity(0.3),
                        lineWidth: isSelected ? 2 : 1
                    )
            )
        }
        .buttonStyle(.plain)
    }
}

struct TagInputView: View {
    @Binding var tags: [String]
    @State private var newTag = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Current tags
            if !tags.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack {
                        ForEach(tags, id: \.self) { tag in
                            HStack(spacing: 4) {
                                Text(tag)
                                    .font(.firaCodeCaption())
                                Button {
                                    tags.removeAll { $0 == tag }
                                } label: {
                                    Image(systemName: "xmark.circle.fill")
                                        .font(.caption2)
                                }
                            }
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(Color.appPrimary.opacity(0.1))
                            .foregroundStyle(.appPrimary)
                            .clipShape(Capsule())
                        }
                    }
                }
            }

            // Add new tag
            HStack {
                TextField("Add tag", text: $newTag)
                    .font(.firaCodeBody())
                    .textFieldStyle(.roundedBorder)
                    .onSubmit {
                        addTag()
                    }

                Button("Add") {
                    addTag()
                }
                .disabled(newTag.isEmpty)
            }
        }
    }

    private func addTag() {
        let trimmed = newTag.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, !tags.contains(trimmed) else { return }
        tags.append(trimmed)
        newTag = ""
    }
}

#Preview {
    JournalEntryEditorView()
        // swiftlint:disable:next force_try
        .modelContainer(try! SharedModelContainer.create())
        .environment(\.appDependencies, AppDependencyContainer.shared)
}
