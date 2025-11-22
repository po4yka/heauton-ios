import SwiftUI
import UniformTypeIdentifiers

struct DataManagementView: View {
    @Environment(\.dismiss)
    private var dismiss
    @Environment(\.appDependencies)
    private var dependencies

    @State private var storageInfo: StorageInfo?
    @State private var isLoading = false
    @State private var showingExportSheet = false
    @State private var showingError = false
    @State private var errorMessage = ""
    @State private var shareURL: URL?
    @State private var showingShareSheet = false

    var body: some View {
        NavigationStack {
            List {
                storageInfoSection
                exportOptionsSection
                dataManagementSection
                privacySection
            }
            .navigationTitle("Data Management")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    doneButton
                }

                ToolbarItem(placement: .topBarTrailing) {
                    refreshButton
                }
            }
            .task {
                loadStorageInfo()
            }
            .sheet(isPresented: $showingExportSheet) {
                ExportOptionsSheet(onExport: handleExport)
            }
            .sheet(isPresented: $showingShareSheet) {
                if let url = shareURL {
                    ShareSheet(items: [url]) { _ in
                        // Dismiss sheet on completion
                        showingShareSheet = false
                    }
                }
            }
            .alert("Export Error", isPresented: $showingError) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(errorMessage)
            }
            .overlay {
                if isLoading {
                    ProgressView("Loading...")
                        .padding()
                        .background(Color(.systemBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                        .shadow(radius: 10)
                }
            }
        }
    }

    @ViewBuilder private var storageInfoSection: some View {
        if let info = storageInfo {
            Section {
                StorageInfoRow(
                    title: "Journal Entries",
                    count: info.journalEntryCount,
                    icon: "book.closed.fill",
                    color: .appSecondary
                )

                StorageInfoRow(
                    title: "Quotes",
                    count: info.quoteCount,
                    icon: "quote.bubble.fill",
                    color: .appPrimary
                )

                StorageInfoRow(
                    title: "Exercises",
                    count: info.exerciseCount,
                    icon: "figure.mind.and.body",
                    color: .lsGunmetal
                )

                StorageInfoRow(
                    title: "Progress Snapshots",
                    count: info.progressSnapshotCount,
                    icon: "chart.line.uptrend.xyaxis",
                    color: .lsIronGrey
                )

                HStack {
                    Label("Total Items", systemImage: "square.stack.3d.up.fill")
                        .foregroundStyle(.secondary)

                    Spacer()

                    Text("\(info.totalItemCount)")
                        .font(.firaCodeBody(.semiBold))
                        .foregroundStyle(.primary)
                }

                HStack {
                    Label("Estimated Size", systemImage: "externaldrive.fill")
                        .foregroundStyle(.secondary)

                    Spacer()

                    Text(info.formattedSize)
                        .font(.firaCodeBody(.semiBold))
                        .foregroundStyle(.primary)
                }
            } header: {
                Text("Storage Information")
            } footer: {
                Text("Last updated: \(info.lastCalculated.formatted(date: .abbreviated, time: .shortened))")
                    .font(.firaCodeCaption())
            }
        }
    }

    private var exportOptionsSection: some View {
        Section {
            Button {
                showingExportSheet = true
            } label: {
                Label("Export Data", systemImage: "square.and.arrow.up")
                    .font(.firaCodeBody(.regular))
            }

            Button {
                exportCompleteBackup()
            } label: {
                Label("Create Complete Backup", systemImage: "doc.zipper")
                    .font(.firaCodeBody(.regular))
            }
        } header: {
            Text("Export & Backup")
        } footer: {
            Text(
                "Export your data to JSON or CSV format. Complete backup includes all your journals, " +
                    "quotes, exercises, and progress data."
            )
            .font(.firaCodeCaption())
        }
    }

    private var dataManagementSection: some View {
        Section {
            NavigationLink {
                DataRetentionView()
            } label: {
                Label("Data Retention", systemImage: "clock.arrow.circlepath")
                    .font(.firaCodeBody(.regular))
            }
        } header: {
            Text("Data Management")
        } footer: {
            Text("Configure how long your data is kept and manage automatic cleanup.")
                .font(.firaCodeCaption())
        }
    }

    private var privacySection: some View {
        Section {
            VStack(alignment: .leading, spacing: 12) {
                Label("Your Data is Private", systemImage: "lock.shield.fill")
                    .font(.firaCodeSubheadline(.medium))
                    .foregroundStyle(.appPrimary)

                Text(
                    "All exports are saved locally on your device. " +
                        "Journal entries will be decrypted before export if encryption is enabled. " +
                        "You can share the exported files using your preferred method."
                )
                .font(.firaCodeCaption())
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.vertical, 4)
        } header: {
            Text("Privacy")
        }
    }

    private var doneButton: some View {
        Button("Done") {
            dismiss()
        }
    }

    private var refreshButton: some View {
        Button {
            loadStorageInfo()
        } label: {
            Image(systemName: "arrow.clockwise")
        }
        .disabled(isLoading)
    }

    private func loadStorageInfo() {
        isLoading = true

        Task {
            do {
                let info = try await dependencies.dataExportService.getStorageInfo()
                await MainActor.run {
                    storageInfo = info
                    isLoading = false
                }
            } catch {
                await MainActor.run {
                    errorMessage = "Failed to load storage info: \(error.localizedDescription)"
                    showingError = true
                    isLoading = false
                }
            }
        }
    }

    private func exportCompleteBackup() {
        isLoading = true

        Task {
            do {
                let url = try await dependencies.dataExportService.exportCompleteBackup()
                await MainActor.run {
                    shareURL = url
                    showingShareSheet = true
                    isLoading = false
                }
            } catch {
                await MainActor.run {
                    errorMessage = "Failed to create backup: \(error.localizedDescription)"
                    showingError = true
                    isLoading = false
                }
            }
        }
    }

    private func handleExport(type: ExportType) {
        isLoading = true
        showingExportSheet = false

        Task {
            do {
                let url: URL

                switch type {
                case .journalsJSON:
                    let journals = try await dependencies.dataExportService.exportJournals()
                    url = try createJSONFile(journals, filename: "journals")

                case .journalsCSV:
                    url = try await dependencies.dataExportService.exportJournalsAsCSV()

                case .quotesJSON:
                    let quotes = try await dependencies.dataExportService.exportQuotes()
                    url = try createJSONFile(quotes, filename: "quotes")

                case .quotesCSV:
                    url = try await dependencies.dataExportService.exportQuotesAsCSV()

                case .exercisesJSON:
                    let exercises = try await dependencies.dataExportService.exportExercises()
                    url = try createJSONFile(exercises, filename: "exercises")

                case .progressJSON:
                    let progress = try await dependencies.dataExportService.exportProgress()
                    url = try createJSONFile(progress, filename: "progress")

                case .completeBackup:
                    url = try await dependencies.dataExportService.exportCompleteBackup()
                }

                await MainActor.run {
                    shareURL = url
                    showingShareSheet = true
                    isLoading = false
                }
            } catch {
                await MainActor.run {
                    errorMessage = "Export failed: \(error.localizedDescription)"
                    showingError = true
                    isLoading = false
                }
            }
        }
    }

    private func createJSONFile(_ data: some Encodable, filename: String) throws -> URL {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]

        let jsonData = try encoder.encode(data)

        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd_HHmmss"
        let dateString = formatter.string(from: Date.now)

        let tempDir = FileManager.default.temporaryDirectory
        let fileURL = tempDir.appendingPathComponent("heauton_\(filename)_\(dateString).json")

        try jsonData.write(to: fileURL)
        return fileURL
    }
}

// MARK: - Supporting Views

struct StorageInfoRow: View {
    let title: String
    let count: Int
    let icon: String
    let color: Color

    var body: some View {
        HStack {
            Label {
                Text(title)
                    .font(.firaCodeBody(.regular))
            } icon: {
                Image(systemName: icon)
                    .foregroundStyle(color)
            }

            Spacer()

            Text("\(count)")
                .font(.firaCodeBody(.semiBold))
                .foregroundStyle(.secondary)
        }
    }
}

struct ExportOptionsSheet: View {
    @Environment(\.dismiss)
    private var dismiss
    let onExport: (ExportType) -> Void

    var body: some View {
        NavigationStack {
            List {
                Section {
                    ExportOptionRow(
                        title: "Journals (JSON)",
                        description: "Export all journal entries with metadata",
                        icon: "book.closed.fill",
                        color: .appSecondary
                    ) {
                        onExport(.journalsJSON)
                        dismiss()
                    }

                    ExportOptionRow(
                        title: "Journals (CSV)",
                        description: "Export journal entries as spreadsheet",
                        icon: "tablecells.fill",
                        color: .appSecondary
                    ) {
                        onExport(.journalsCSV)
                        dismiss()
                    }
                } header: {
                    Text("Journals")
                }

                Section {
                    ExportOptionRow(
                        title: "Quotes (JSON)",
                        description: "Export all quotes with metadata",
                        icon: "quote.bubble.fill",
                        color: .appPrimary
                    ) {
                        onExport(.quotesJSON)
                        dismiss()
                    }

                    ExportOptionRow(
                        title: "Quotes (CSV)",
                        description: "Export quotes as spreadsheet",
                        icon: "tablecells.fill",
                        color: .appPrimary
                    ) {
                        onExport(.quotesCSV)
                        dismiss()
                    }
                } header: {
                    Text("Quotes")
                }

                Section {
                    ExportOptionRow(
                        title: "Exercises (JSON)",
                        description: "Export all exercises and sessions",
                        icon: "figure.mind.and.body",
                        color: .lsGunmetal
                    ) {
                        onExport(.exercisesJSON)
                        dismiss()
                    }

                    ExportOptionRow(
                        title: "Progress (JSON)",
                        description: "Export progress snapshots and stats",
                        icon: "chart.line.uptrend.xyaxis",
                        color: .lsIronGrey
                    ) {
                        onExport(.progressJSON)
                        dismiss()
                    }
                } header: {
                    Text("Other Data")
                }

                Section {
                    ExportOptionRow(
                        title: "Complete Backup",
                        description: "Export everything in one file",
                        icon: "doc.zipper",
                        color: .lsShadowGrey
                    ) {
                        onExport(.completeBackup)
                        dismiss()
                    }
                } header: {
                    Text("Full Backup")
                }
            }
            .navigationTitle("Export Data")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
}

struct ExportOptionRow: View {
    let title: String
    let description: String
    let icon: String
    let color: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundStyle(color)
                    .frame(width: 32)

                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.firaCodeBody(.semiBold))
                        .foregroundStyle(.primary)

                    Text(description)
                        .font(.firaCodeCaption())
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Image(systemName: "arrow.down.circle")
                    .foregroundStyle(.secondary)
            }
            .padding(.vertical, 4)
        }
    }
}

struct DataRetentionView: View {
    @Environment(\.dismiss)
    private var dismiss
    @AppStorage("dataRetentionDays")
    private var retentionDays = 0

    var body: some View {
        Form {
            Section {
                Picker("Keep Data For", selection: $retentionDays) {
                    Text("Forever").tag(0)
                    Text("1 Year").tag(365)
                    Text("6 Months").tag(180)
                    Text("3 Months").tag(90)
                    Text("1 Month").tag(30)
                }
            } header: {
                Text("Data Retention")
            } footer: {
                if retentionDays == 0 {
                    Text("Your data will never be automatically deleted.")
                } else {
                    Text("Data older than \(retentionDays) days will be automatically deleted. This helps manage storage space.")
                }
            }

            Section {
                VStack(alignment: .leading, spacing: 12) {
                    Label("Automatic Cleanup", systemImage: "sparkles")
                        .font(.firaCodeSubheadline(.medium))

                    Text(
                        "When enabled, old data will be permanently deleted according to " +
                            "the retention policy. This action cannot be undone. " +
                            "Consider exporting your data regularly if you choose a short retention period."
                    )
                    .font(.firaCodeCaption())
                    .foregroundStyle(.secondary)
                }
                .padding(.vertical, 4)
            } header: {
                Text("Information")
            }
        }
        .navigationTitle("Data Retention")
        .navigationBarTitleDisplayMode(.inline)
    }
}

enum ExportType {
    case journalsJSON
    case journalsCSV
    case quotesJSON
    case quotesCSV
    case exercisesJSON
    case progressJSON
    case completeBackup
}

#Preview {
    DataManagementView()
        .environment(\.appDependencies, AppDependencyContainer.shared)
}
