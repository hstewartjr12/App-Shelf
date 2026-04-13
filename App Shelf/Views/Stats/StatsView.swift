import SwiftUI
import SwiftData

struct StatsView: View {
    @Query private var allItems: [MediaItem]
    @Query(sort: \MoodTag.label) private var allTags: [MoodTag]

    @State private var selectedYear = Calendar.current.component(.year, from: .now)

    private var calendar: Calendar { .current }

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
                let current = calendar.component(.year, from: .now)
                if selectedYear < current {
                    selectedYear += 1
                }
            } label: {
                Image(systemName: "chevron.right")
            }
            .buttonStyle(.plain)
            .disabled(selectedYear >= calendar.component(.year, from: .now))
        }
        .padding(.vertical, 4)
    }

    // MARK: - Overview

    private var overviewGrid: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
            StatCardView(
                title: "Finished",
                value: "\(finishedCount(in: selectedYear))",
                icon: "checkmark.seal.fill",
                subtitle: "this year"
            )

            StatCardView(
                title: "This Month",
                value: "\(finishedCount(inCurrentMonth: true))",
                icon: "calendar",
                subtitle: finishedThisMonthLabel
            )

            StatCardView(
                title: "Avg. Shelf Time",
                value: avgShelfTime(year: selectedYear),
                icon: "clock.fill",
                subtitle: "to finish"
            )

            StatCardView(
                title: "Started",
                value: "\(startedCount(in: selectedYear))",
                icon: "play.fill",
                subtitle: "this year"
            )
        }
    }

    // MARK: - Mood Tags

    @ViewBuilder
    private var moodTagSection: some View {
        let tagCounts = tagCountsSorted(year: selectedYear)
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
                                width: barWidth(count: entry.count, max: tagCounts.first?.count ?? 1),
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
        let typeCounts = typeCounts(year: selectedYear)
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

    // MARK: - Calculations

    private func itemsFinished(year: Int) -> [MediaItem] {
        allItems.filter { item in
            guard let date = item.finishedDate else { return false }
            return calendar.component(.year, from: date) == year
        }
    }

    private func finishedCount(in year: Int) -> Int {
        itemsFinished(year: year).count
    }

    private func finishedCount(inCurrentMonth: Bool) -> Int {
        guard inCurrentMonth else { return 0 }
        let now = Date.now
        return allItems.filter { item in
            guard let date = item.finishedDate else { return false }
            return calendar.isDate(date, equalTo: now, toGranularity: .month)
        }.count
    }

    private var finishedThisMonthLabel: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM"
        return "in \(formatter.string(from: .now))"
    }

    private func startedCount(in year: Int) -> Int {
        allItems.filter { item in
            guard let date = item.startedDate else { return false }
            return calendar.component(.year, from: date) == year
        }.count
    }

    private func avgShelfTime(year: Int) -> String {
        let finished = itemsFinished(year: year).filter { $0.startedDate != nil }
        guard !finished.isEmpty else { return "—" }
        let durations = finished.compactMap { item -> Double? in
            guard let start = item.startedDate, let end = item.finishedDate else { return nil }
            return end.timeIntervalSince(start)
        }
        guard !durations.isEmpty else { return "—" }
        let avgSeconds = durations.reduce(0, +) / Double(durations.count)
        let days = Int(avgSeconds / 86400)
        if days < 1 { return "< 1 day" }
        if days == 1 { return "1 day" }
        if days < 30 { return "\(days) days" }
        let months = days / 30
        return "\(months) mo"
    }

    private struct TagCount {
        let tag: MoodTag
        let count: Int
    }

    private func tagCountsSorted(year: Int) -> [TagCount] {
        let finished = itemsFinished(year: year)
        return allTags.compactMap { tag in
            let count = finished.filter { item in
                item.moodTags.contains(where: {
                    $0.persistentModelID == tag.persistentModelID
                })
            }.count
            return count > 0 ? TagCount(tag: tag, count: count) : nil
        }
        .sorted { $0.count > $1.count }
    }

    private struct TypeCount {
        let type: MediaType
        let count: Int
    }

    private func typeCounts(year: Int) -> [TypeCount] {
        let finished = itemsFinished(year: year)
        return MediaType.allCases.compactMap { type in
            let count = finished.filter { $0.mediaType == type }.count
            return count > 0 ? TypeCount(type: type, count: count) : nil
        }
        .sorted { $0.count > $1.count }
    }

    private func barWidth(count: Int, max: Int) -> CGFloat {
        guard max > 0 else { return 0 }
        return CGFloat(count) / CGFloat(max) * 80
    }
}
