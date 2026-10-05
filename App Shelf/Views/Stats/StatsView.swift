import SwiftUI
import SwiftData
import Charts

struct StatsView: View {
    @Query private var allItems: [MediaItem]
    @Query(sort: \MoodTag.label) private var allTags: [MoodTag]
    @State private var selectedYear = Calendar.current.component(.year, from: .now)
    @AppStorage("review.annualGoal") private var annualGoal = 12

    private var calculator: StatsCalculator { StatsCalculator(items: allItems, tags: allTags) }
    private var calendar: Calendar { calculator.calendar }
    private var currentYear: Int { calendar.component(.year, from: .now) }
    private var finished: [MediaItem] { calculator.itemsFinished(in: selectedYear) }
    private var rated: [MediaItem] { finished.filter { $0.rating != nil }.sorted { ($0.rating ?? 0) > ($1.rating ?? 0) } }
    private var averageRating: String {
        guard !rated.isEmpty else { return "—" }
        let average = Double(rated.reduce(0) { $0 + ($1.rating ?? 0) }) / Double(rated.count)
        return average.formatted(.number.precision(.fractionLength(1)))
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 24) {
                    reviewHeader
                    if selectedYear == currentYear { goalCard }
                    overviewGrid
                    activityChart
                    if !rated.isEmpty { favoritesSection }
                    if !finished.isEmpty { mediaTypeSection; moodTagSection }
                    else {
                        ContentUnavailableView("Your story is still unfolding", systemImage: "sparkles",
                                               description: Text("Mark a title finished to see your favorites, media mix, and top vibes here."))
                            .frame(maxWidth: .infinity)
                    }
                }
                .padding(20)
                .frame(maxWidth: 1000, alignment: .leading)
                .frame(maxWidth: .infinity)
            }
            .background(ShelfStyle.canvas)
            .navigationTitle("Year in Review")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Menu {
                        ForEach((earliestYear...currentYear).reversed(), id: \.self) { year in
                            Button(String(year)) { selectedYear = year }
                        }
                    } label: { Label(String(selectedYear), systemImage: "calendar") }
                }
            }
        }
        .tint(ShelfStyle.sageForeground)
    }

    private var earliestYear: Int {
        let years = allItems.flatMap { [$0.createdAt, $0.startedDate, $0.finishedDate].compactMap { $0 } }
            .map { calendar.component(.year, from: $0) }
        return max(1900, min(currentYear - 2, years.min() ?? currentYear))
    }

    private var reviewHeader: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("THE STORIES THAT STAYED WITH YOU")
                .font(.system(size: 10, weight: .bold, design: .rounded)).tracking(2).foregroundStyle(ShelfStyle.sageForeground)
            Text("Your year, one story at a time.")
                .font(.system(size: 28, weight: .medium, design: .serif))
            Text("A little perspective on everything you made time for in \(String(selectedYear)).")
                .font(.subheadline).foregroundStyle(.secondary)
        }
    }

    private var goalCard: some View {
        HStack(spacing: 22) {
            ZStack {
                Circle().stroke(ShelfStyle.sage.opacity(0.13), lineWidth: 7)
                Circle().trim(from: 0, to: min(1, Double(finished.count) / Double(max(1, annualGoal))))
                    .stroke(ShelfStyle.sage, style: StrokeStyle(lineWidth: 7, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                VStack(spacing: 2) {
                    Text("\(finished.count)").font(.system(size: 27, weight: .semibold, design: .rounded))
                    Text("of \(max(1, annualGoal))").font(.caption).foregroundStyle(.secondary)
                }
            }.frame(width: 90, height: 90)
                .accessibilityLabel("\(finished.count) of \(max(1, annualGoal)) titles finished")
            VStack(alignment: .leading, spacing: 6) {
                Text(finished.count >= annualGoal ? "You made room for good stories." : "Make a little room this year.")
                    .font(.headline)
                Text(finished.count >= annualGoal ? "You reached your annual goal. Everything else is a bonus." : "\(max(0, annualGoal - finished.count)) more titles to reach your goal. Every kind of media counts.")
                    .font(.caption).foregroundStyle(.secondary)
                Menu {
                    ForEach([6, 12, 24, 36, 52, 100], id: \.self) { goal in
                        Button("\(goal) titles") { annualGoal = goal }
                    }
                } label: {
                    Label("Goal: \(annualGoal) titles", systemImage: "slider.horizontal.3")
                        .font(.caption.weight(.medium))
                }
            }
            Spacer(minLength: 0)
        }
        .padding(20).background(Color.shelfCard, in: RoundedRectangle(cornerRadius: 20))
    }

    private var overviewGrid: some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 145), spacing: 12)], spacing: 12) {
            StatCardView(title: "Finished", value: "\(finished.count)", icon: "checkmark.seal.fill", subtitle: "this year")
            StatCardView(title: "Started", value: "\(calculator.startedCount(in: selectedYear))", icon: "play.fill", subtitle: "this year")
            StatCardView(title: "Avg. time", value: calculator.avgShelfTime(year: selectedYear), icon: "clock.fill", subtitle: "from start to finish")
            StatCardView(title: "Avg. rating", value: averageRating, icon: "star.fill", subtitle: "out of 5 stars")
        }
    }

    private var activityChart: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack {
                Text("A year of good things").font(.headline)
                Spacer()
                Text("Finished titles").font(.caption).foregroundStyle(.secondary)
            }
            Chart(1...12, id: \.self) { month in
                BarMark(x: .value("Month", calendar.shortMonthSymbols[month - 1]),
                        y: .value("Finished", calculator.finishedCount(inMonth: month, year: selectedYear)), width: .ratio(0.6))
                    .foregroundStyle(ShelfStyle.sage.gradient)
                    .cornerRadius(4)
            }
            .chartYScale(domain: 0...max(1, (1...12).map { calculator.finishedCount(inMonth: $0, year: selectedYear) }.max() ?? 1))
            .chartYAxis { AxisMarks(position: .leading, values: .automatic(desiredCount: 4)) }
            .chartXAxis { AxisMarks { _ in AxisValueLabel().font(.system(size: 9)) } }
            .frame(height: 170)
            .accessibilityLabel("Monthly completions in \(selectedYear)")
        }
        .padding(20).background(Color.shelfCard, in: RoundedRectangle(cornerRadius: 20))
    }

    private var favoritesSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("The ones you loved").font(.headline)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(alignment: .top, spacing: 15) {
                    ForEach(rated.prefix(8)) { item in
                        VStack(alignment: .leading, spacing: 8) {
                            CoverCardView(item: item, size: CGSize(width: 112, height: 156))
                            Text(item.title).font(.caption.weight(.semibold)).lineLimit(2)
                            Label("\(item.rating ?? 0) / 5", systemImage: "star.fill")
                                .font(.caption2).foregroundStyle(ShelfStyle.goldForeground)
                        }.frame(width: 112, alignment: .leading)
                    }
                }.padding(.bottom, 5)
            }
        }
    }

    private var mediaTypeSection: some View {
        let counts = calculator.typeCounts(year: selectedYear)
        return VStack(alignment: .leading, spacing: 18) {
            Text("Your media mix").font(.headline)
            HStack(spacing: 24) {
                Chart(counts, id: \.type) { entry in
                    SectorMark(angle: .value("Titles", entry.count), innerRadius: .ratio(0.68), angularInset: 3)
                        .foregroundStyle(entry.type.color).cornerRadius(4)
                }
                .frame(width: 115, height: 115)
                .overlay { Text("\(finished.count)").font(.title2.weight(.semibold)) }
                .accessibilityLabel("\(finished.count) titles across \(counts.count) media types")
                VStack(spacing: 9) {
                    ForEach(counts, id: \.type) { entry in
                        HStack {
                            Circle().fill(entry.type.color).frame(width: 7, height: 7)
                            Text(entry.type.displayName).font(.caption)
                            Spacer()
                            Text("\(entry.count)").font(.caption.weight(.semibold)).monospacedDigit()
                        }
                    }
                }
            }
        }
        .padding(20).background(Color.shelfCard, in: RoundedRectangle(cornerRadius: 20))
    }

    @ViewBuilder private var moodTagSection: some View {
        let counts = calculator.tagCountsSorted(year: selectedYear)
        if !counts.isEmpty {
            VStack(alignment: .leading, spacing: 15) {
                Text("The mood of your year").font(.headline)
                ForEach(counts.prefix(5), id: \.tag.persistentModelID) { entry in
                    HStack(spacing: 12) {
                        Text(entry.tag.label).font(.subheadline).frame(width: 105, alignment: .leading)
                        ProgressView(value: Double(entry.count), total: Double(counts.first?.count ?? 1)).tint(ShelfStyle.sageForeground)
                        Text("\(entry.count)").font(.caption).monospacedDigit().foregroundStyle(.secondary)
                    }
                }
            }
            .padding(20).background(Color.shelfCard, in: RoundedRectangle(cornerRadius: 20))
        }
    }
}
