import SwiftData
import SwiftUI

struct HistoryView: View {
    @Environment(\.modelContext)
    private var modelContext
    @Query(sort: \UserEvent.createdAt, order: .reverse)
    private var events: [UserEvent]

    // Group events by date
    private var groupedEvents: [(String, [UserEvent])] {
        let calendar = Calendar.current
        let grouped = Dictionary(grouping: events) { event in
            calendar.startOfDay(for: event.createdAt)
        }

        return grouped.map { date, events in
            let formatter = DateFormatter()
            formatter.dateStyle = .full
            return (formatter.string(from: date), events.sorted { $0.createdAt > $1.createdAt })
        }
        .sorted { $0.1.first?.createdAt ?? Date() > $1.1.first?.createdAt ?? Date() }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Title
                    Text("history.")
                        .font(.system(size: 48, weight: .bold, design: .default))
                        .padding(.horizontal)
                        .padding(.top, 10)

                    // Insights Card
                    InsightsCard()
                        .padding(.horizontal)

                    // Events grouped by date
                    if events.isEmpty {
                        ContentUnavailableView(
                            "No History",
                            systemImage: "book",
                            description: Text("Your life events will appear here")
                        )
                        .frame(maxWidth: .infinity)
                        .padding(.top, 40)
                    } else {
                        ForEach(groupedEvents, id: \.0) { dateString, eventsForDate in
                            VStack(alignment: .leading, spacing: 12) {
                                // Date header with chevron
                                HStack {
                                    Text(dateString)
                                        .font(.system(size: 24, weight: .bold))
                                    Spacer()
                                    Image(systemName: "chevron.right")
                                        .foregroundStyle(.secondary)
                                }
                                .padding(.horizontal)

                                // Events for this date
                                ForEach(eventsForDate) { event in
                                    NavigationLink(value: event) {
                                        HistoryEventCard(event: event)
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                            .padding(.bottom, 8)
                        }
                    }
                }
                .padding(.bottom, 20)
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Menu(content: {
                        Button(action: {}, label: {
                            Label("Days", systemImage: "calendar")
                        })
                        Button(action: {}, label: {
                            Label("Weeks", systemImage: "calendar")
                        })
                        Button(action: {}, label: {
                            Label("Months", systemImage: "calendar")
                        })
                    }, label: {
                        HStack(spacing: 4) {
                            Text("Days")
                            Image(systemName: "chevron.down")
                        }
                        .font(.system(size: 15, weight: .medium))
                        .foregroundStyle(.primary)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(Color(.systemBackground))
                        .clipShape(Capsule())
                        .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
                    })
                }

                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: {}, label: {
                        Image(systemName: "line.3.horizontal")
                            .font(.system(size: 18))
                    })
                }

                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: {}, label: {
                        Image(systemName: "magnifyingglass")
                            .font(.system(size: 18))
                    })
                }
            }
            .navigationDestination(for: UserEvent.self) { event in
                UserEventDetailView(event: event)
            }
        }
    }
}

// MARK: - Insights Card

struct InsightsCard: View {
    var body: some View {
        ZStack(alignment: .topLeading) {
            // Background
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(.systemGray6))
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(
                            LinearGradient(
                                colors: [Color.black.opacity(0.8), Color.black.opacity(0.6)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                )

            VStack(alignment: .leading) {
                HStack {
                    Text("Insights")
                        .font(.system(size: 32, weight: .bold))
                        .foregroundStyle(.white)

                    Spacer()

                    Button(action: {}, label: {
                        HStack(spacing: 4) {
                            Text("See All")
                                .font(.system(size: 14))
                            Image(systemName: "chevron.right")
                                .font(.system(size: 12))
                        }
                        .foregroundStyle(.white.opacity(0.8))
                    })
                }
                .padding()

                Spacer()

                // Mouse/magnifying glass illustration
                HStack {
                    Spacer()
                    Image(systemName: "magnifyingglass.circle.fill")
                        .font(.system(size: 80))
                        .foregroundStyle(.white.opacity(0.2))
                        .padding(.trailing, 20)
                        .padding(.bottom, 20)
                }
            }
        }
        .frame(height: 200)
    }
}

// MARK: - History Event Card

struct HistoryEventCard: View {
    let event: UserEvent

    var body: some View {
        HStack(spacing: 16) {
            // Icon
            Image(systemName: event.type.iconName)
                .font(.system(size: 24))
                .foregroundStyle(.primary)
                .frame(width: 40, height: 40)

            VStack(alignment: .leading, spacing: 4) {
                Text(event.type.displayName)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(.secondary)
                    .tracking(0.5)

                Text(event.title)
                    .font(.system(size: 16, weight: .medium))
                    .lineLimit(2)
                    .foregroundStyle(.primary)

                // Show duration or description if available
                if let duration = event.duration {
                    Text("\(duration) minutes")
                        .font(.system(size: 13))
                        .foregroundStyle(.secondary)
                } else if let description = event.eventDescription {
                    Text(description)
                        .font(.system(size: 13))
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }

            Spacer()

            // Time
            Text(formattedTime(event.createdAt))
                .font(.system(size: 14))
                .foregroundStyle(.secondary)
        }
        .padding()
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
        .padding(.horizontal)
    }

    private func formattedTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

// MARK: - User Event Detail View

struct UserEventDetailView: View {
    let event: UserEvent

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Event type badge
                HStack {
                    Image(systemName: event.type.iconName)
                        .font(.system(size: 20))
                    Text(event.type.displayName)
                        .font(.system(size: 13, weight: .semibold))
                        .tracking(0.5)
                }
                .foregroundStyle(.secondary)
                .padding(.top)

                // Title
                Text(event.title)
                    .font(.system(size: 28, weight: .bold))

                // Metadata
                VStack(alignment: .leading, spacing: 12) {
                    if let duration = event.duration {
                        HStack {
                            Image(systemName: "clock")
                                .foregroundStyle(.secondary)
                            Text("Duration: \(duration) minutes")
                                .font(.system(size: 16))
                        }
                    }

                    HStack {
                        Image(systemName: "calendar")
                            .foregroundStyle(.secondary)
                        Text(formattedDate(event.createdAt))
                            .font(.system(size: 16))
                    }

                    if let value = event.value {
                        HStack {
                            Image(systemName: "chart.bar")
                                .foregroundStyle(.secondary)
                            Text("Value: \(String(format: "%.1f", value))")
                                .font(.system(size: 16))
                        }
                    }
                }
                .padding(.vertical, 8)

                // Description
                if let description = event.eventDescription {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Details")
                            .font(.system(size: 18, weight: .semibold))
                        Text(description)
                            .font(.system(size: 16))
                            .foregroundStyle(.secondary)
                    }
                    .padding(.top, 8)
                }

                Spacer()
            }
            .padding()
        }
        .navigationBarTitleDisplayMode(.inline)
    }

    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}
