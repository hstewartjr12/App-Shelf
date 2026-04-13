import SwiftUI
import SwiftData

struct StatsView: View {
    @Query private var allItems: [MediaItem]
    @Query(sort: \MoodTag.label) private var allTags: [MoodTag]

    @State private var selectedYear = Calendar.current.component(.year, from: .now)

    private var calculator: StatsCalculator {
        StatsCalculator(items: allItems, tags: allTags)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(spacing: 20) {
                    yearPicker
                    overviewGrid
                    moodTagSection
                    mediaTypeSection
                }
                .padding()
            }
            .navigationTitle("Year in Review")
        }
    }

    // MARK: - Year Picker

    private var yearPicker: some View {
        HStack {
            Button {
                selectedYear -= 1
            } label: {
                Image(systemName: "chevron.left")
            }
            .buttonStyle(.plain)

            Spacer()
            Text(String(selectedYear))
                .font(.title3)
                .fontWeight(.semibold)
                .monospacedDigit()
            Spacer()

            Button {
                let current = Calendar.current.component(.year, from: .now)
                if selectedYear < current {
                    selectedYear += 1
                }
            } label: {
                Image(systemName: "chevron.right")
            }
            .buttonStyle(.plain)
            .disabled(selectedYear >= Calendar.current.component(.year, from: .now))
        }
        .padding(.vertical, 4)
    }

    // MARK: - Overview

    private var overviewGrid: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
            StatCardView(
                title: "Finished",
                value: "\(calculator.finishedCount(in: selectedYear))",
                icon: "checkmark.seal.fill",
                subtitle: "this year"
            )

            StatCardView(
                title: "This Month",
                value: "\(calculator.finishedCount(inMonth: .now))",
                icon: "calendar",
                subtitle: finishedThisMonthLabel
            )

            StatCardView(
                title: "Avg. Shelf Time",
                value: calculator.avgShelfTime(year: selectedYear),
                icon: "clock.fill",
                subtitle: "to finish"
            )

            StatCardView(
                title: "Started",
                value: "\(calculator.startedCount(in: selectedYear))",
                icon: "play.fill",
                subtitle: "this year"
            )
        }
    }

    // MARK: - Mood Tags

    @ViewBuilder
    private var moodTagSection: some View {
        let tagCounts = calculator.tagCountsSorted(year: selectedYear)
        if tagCounts.isEmpty {
            EmptyStateView(
                systemImage: "tag",
                title: "No vibes yet",
                subtitle: "Tag items in their detail view"
            )
        } else {
            VStack(alignment: .leading, spacing: 12) {
                Text("Top Vibes")
                    .font(.headline)

                ForEach(tagCounts.prefix(5), id: \.tag.persistentModelID) { entry in
                    HStack {
                        Text(entry.tag.label)
                            .font(.body)
                        Spacer()
                        Text("\(entry.count)")
                            .foregroundStyle(.secondary)
                            .monospacedDigit()

                        RoundedRectangle(cornerRadius: 3)
                            .fill(Color.accentColor)
                            .frame(
                                width: calculator.barWidth(count: entry.count, max: tagCounts.first?.count ?? 1),
                                height: 8
                            )
                            .frame(width: 80, alignment: .trailing)
                    }
                }
            }
            .padding()
            .background(.secondary.opacity(0.07))
            .clipShape(RoundedRectangle(cornerRadius: 14))
        }
    }

    // MARK: - Media Type

    @ViewBuilder
    private var mediaTypeSection: some View {
        let typeCounts = calculator.typeCounts(year: selectedYear)
        if typeCounts.isEmpty {
            EmptyStateView(
                systemImage: "square.grid.2x2",
                title: "No items yet",
                subtitle: "Add something to your shelf"
            )
        } else {
            VStack(alignment: .leading, spacing: 12) {
                Text("By Type")
                    .font(.headline)

                ForEach(typeCounts, id: \.type) { entry in
                    HStack(spacing: 10) {
                        Image(systemName: entry.type.systemImage)
                            .frame(width: 20)
                            .foregroundStyle(Color.accentColor)
                        Text(entry.type.displayName)
                        Spacer()
                        Text("\(entry.count)")
                            .foregroundStyle(.secondary)
                            .monospacedDigit()
                    }
                }
            }
            .padding()
            .background(.secondary.opacity(0.07))
            .clipShape(RoundedRectangle(cornerRadius: 14))
        }
    }

    // MARK: - Helpers

    private var finishedThisMonthLabel: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM"
        return "in \(formatter.string(from: .now))"
    }
}
