import SwiftUI
import SwiftData

struct ShelfListView: View {
    @Query(sort: \Shelf.position) private var shelves: [Shelf]
    @Query private var allItems: [MediaItem]
    @State private var search = ""
    @State private var selectedType: MediaType?
    @State private var selectedShelf: Shelf?
    @State private var favoritesOnly = false
    @State private var sort: LibrarySort = .newest
    @State private var showAddItem = false
    @State private var showAddShelf = false
    @State private var nextPick: MediaItem?
    @AppStorage("library.compactLayout") private var compactLayout = false

    private var results: [MediaItem] {
        LibraryQuery(search: search, mediaType: selectedType, shelf: selectedShelf,
                     favoritesOnly: favoritesOnly, sort: sort).results(in: allItems)
    }
    private var hasFilters: Bool {
        !search.isEmpty || selectedType != nil || selectedShelf != nil || favoritesOnly
    }
    private var pickCandidates: [MediaItem] {
        let backlog = results.filter { $0.shelf?.isBacklogShelf == true && $0.finishedDate == nil }
        return backlog.isEmpty ? results.filter { $0.finishedDate == nil } : backlog
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 24) {
                    libraryHeader
                    if allItems.isEmpty {
                        welcomeCard
                    } else {
                        shelfFilters
                        typeFilters
                        resultsHeader
                        if results.isEmpty {
                            ContentUnavailableView {
                                Label("No matches on your shelf", systemImage: "magnifyingglass")
                            } description: {
                                Text("Try another title, creator, vibe, or media type.")
                            } actions: {
                                Button("Clear filters", action: clearFilters)
                                    .buttonStyle(.bordered)
                            }
                            .frame(maxWidth: .infinity)
                        } else if compactLayout {
                            LazyVStack(spacing: 10) {
                                ForEach(results) { item in LibraryListRow(item: item) }
                            }
                        } else {
                            LazyVGrid(columns: [GridItem(.adaptive(minimum: 145, maximum: 220), spacing: 18)],
                                      alignment: .leading, spacing: 24) {
                                ForEach(results) { item in LibraryGridCard(item: item) }
                            }
                        }
                    }
                }
                .padding(20)
                .frame(maxWidth: 1200, alignment: .leading)
                .frame(maxWidth: .infinity)
            }
            .background(ShelfStyle.canvas)
            .tint(ShelfStyle.sageForeground)
            .navigationTitle("Library")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .searchable(text: $search, prompt: "Titles, creators, notes, and vibes")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button { showAddItem = !shelves.isEmpty; showAddShelf = shelves.isEmpty } label: {
                        Label("Add item", systemImage: "plus")
                    }
                    .keyboardShortcut("n", modifiers: .command)
                }
            }
            .sheet(isPresented: $showAddItem) { AddItemSheet(initialShelf: selectedShelf) }
            .sheet(isPresented: $showAddShelf) { ShelfEditorView() }
            .sheet(item: $nextPick) { ItemDetailView(item: $0) }
        }
    }

    private var libraryHeader: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 7) {
                    Text("YOUR PERSONAL CULTURE CLUB")
                        .font(.system(size: 10, weight: .bold, design: .rounded))
                        .tracking(2)
                        .foregroundStyle(ShelfStyle.sageForeground)
                    Text("A shelf for every story.")
                        .font(.system(size: 29, weight: .medium, design: .serif))
                    Text("What you’re into. What’s up next. What stayed with you.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                Spacer(minLength: 8)
                Image(systemName: "books.vertical.fill")
                    .font(.system(size: 31))
                    .foregroundStyle(ShelfStyle.sageForeground)
                    .padding(15)
                    .background(ShelfStyle.sage.opacity(0.10), in: RoundedRectangle(cornerRadius: 18))
                    .accessibilityHidden(true)
            }
            if !allItems.isEmpty {
                HStack(spacing: 0) {
                    summary("In your library", value: allItems.count)
                    summary("In progress", value: allItems.filter { $0.startedDate != nil && $0.finishedDate == nil && $0.shelf?.isBacklogShelf != true && $0.shelf?.seedKey != "shelf.dropped" }.count)
                    summary("Finished", value: allItems.filter { $0.finishedDate != nil }.count)
                }
                .padding(.vertical, 15)
                .background(Color.shelfCard, in: RoundedRectangle(cornerRadius: 16))
            }
        }
    }

    private func summary(_ label: String, value: Int) -> some View {
        VStack(alignment: .leading, spacing: 5) {
            Text("\(value)").font(.system(size: 24, weight: .semibold, design: .rounded)).monospacedDigit()
            Text(label).font(.caption).foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.leading, 16)
    }

    private var welcomeCard: some View {
        VStack(alignment: .leading, spacing: 22) {
            Text("Good things deserve a place.")
                .font(.system(size: 25, weight: .medium, design: .serif))
            Text("Keep the books, games, shows, films, and albums you want to make time for together. Start with whatever you’re enjoying right now.")
                .foregroundStyle(.secondary)
            VStack(alignment: .leading, spacing: 17) {
                welcomeStep("01", title: "Save something you love", detail: "Add a title and choose its shelf.")
                welcomeStep("02", title: "Make it yours", detail: "Track progress, collect vibes, and leave a note.")
                welcomeStep("03", title: "Look back on your year", detail: "See the stories that stayed with you in Review.")
            }
            Button { showAddItem = !shelves.isEmpty; showAddShelf = shelves.isEmpty } label: {
                Label(shelves.isEmpty ? "Create your first shelf" : "Add your first title", systemImage: "plus")
                    .fontWeight(.semibold)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 7)
            }
            .buttonStyle(.borderedProminent)
            .tint(ShelfStyle.sage)
        }
        .padding(25)
        .background(Color.shelfCard, in: RoundedRectangle(cornerRadius: 24))
    }

    private func welcomeStep(_ number: String, title: String, detail: String) -> some View {
        HStack(alignment: .top, spacing: 14) {
            Text(number).font(.caption.monospaced()).foregroundStyle(ShelfStyle.sageForeground)
                .padding(10).background(ShelfStyle.sage.opacity(0.08), in: Circle())
            VStack(alignment: .leading, spacing: 3) {
                Text(title).font(.subheadline.weight(.semibold))
                Text(detail).font(.caption).foregroundStyle(.secondary)
            }
        }
    }

    private var shelfFilters: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                filterChip("All shelves", icon: "books.vertical", selected: selectedShelf == nil) { selectedShelf = nil }
                ForEach(shelves) { shelf in
                    filterChip(shelf.name, icon: shelf.systemImage, selected: selectedShelf?.persistentModelID == shelf.persistentModelID) {
                        selectedShelf = shelf
                    }
                }
            }
        }
    }

    private func filterChip(_ title: String, icon: String, selected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Label(title, systemImage: icon)
                .font(.caption.weight(.semibold))
                .padding(.horizontal, 14).padding(.vertical, 11)
                .foregroundStyle(selected ? .white : .primary)
                .background(selected ? ShelfStyle.sage : Color.shelfCard, in: Capsule())
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(selected ? .isSelected : [])
    }

    private var typeFilters: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 9) {
                Button { favoritesOnly.toggle() } label: {
                    Image(systemName: favoritesOnly ? "heart.fill" : "heart")
                        .foregroundStyle(favoritesOnly ? .pink : .secondary)
                        .padding(9).background(Color.shelfCard, in: Circle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel(favoritesOnly ? "Show all items" : "Show favorites only")
                Button("All types") { selectedType = nil }
                    .font(.caption.weight(selectedType == nil ? .bold : .regular))
                    .foregroundStyle(selectedType == nil ? Color.accentColor : .secondary)
                ForEach(MediaType.allCases) { type in
                    Button { selectedType = selectedType == type ? nil : type } label: {
                        TypeChip(type: type, isSelected: selectedType == type)
                    }.buttonStyle(.plain)
                }
            }
        }
    }

    private var resultsHeader: some View {
        HStack {
            VStack(alignment: .leading, spacing: 3) {
                Text(selectedShelf?.name ?? (favoritesOnly ? "Your favorites" : "Your collection"))
                    .font(.title3.weight(.semibold))
                Text("\(results.count) \(results.count == 1 ? "title" : "titles")")
                    .font(.caption).foregroundStyle(.secondary)
            }
            Spacer()
            if !pickCandidates.isEmpty {
                Button { nextPick = pickCandidates.randomElement() } label: {
                    Image(systemName: "shuffle")
                }
                .help("Pick something from your backlog")
                .accessibilityLabel("Pick something to enjoy next")
            }
            Menu {
                Picker("Sort by", selection: $sort) {
                    ForEach(LibrarySort.allCases) { Text($0.rawValue).tag($0) }
                }
                if hasFilters { Button("Clear filters", action: clearFilters) }
            } label: { Image(systemName: "arrow.up.arrow.down") }
            .accessibilityLabel("Sort collection")
            Button { compactLayout.toggle() } label: {
                Image(systemName: compactLayout ? "square.grid.2x2" : "list.bullet")
            }
            .accessibilityLabel(compactLayout ? "Use grid layout" : "Use list layout")
        }
        .buttonStyle(.borderless)
    }

    private func clearFilters() {
        search = ""; selectedType = nil; selectedShelf = nil; favoritesOnly = false
    }
}

private struct LibraryGridCard: View {
    let item: MediaItem
    var body: some View {
        VStack(alignment: .leading, spacing: 9) {
            GeometryReader { proxy in
                CoverCardView(item: item, size: proxy.size)
            }
            .aspectRatio(0.72, contentMode: .fit)
            HStack(spacing: 4) {
                Label(item.mediaType.displayName.uppercased(), systemImage: item.mediaType.systemImage)
                    .font(.system(size: 9, weight: .bold)).tracking(0.7)
                    .foregroundStyle(item.mediaType.foregroundColor)
                Spacer(minLength: 0)
                if item.isFavorite { Image(systemName: "heart.fill").font(.caption2).foregroundStyle(.pink) }
            }
            Text(item.title).font(.subheadline.weight(.semibold)).lineLimit(2)
            Text(item.creator.isEmpty ? item.shelf?.name ?? "No shelf" : item.creator)
                .font(.caption).foregroundStyle(.secondary).lineLimit(1)
            if let progress = item.progressFraction, item.finishedDate == nil {
                ProgressView(value: progress).tint(item.mediaType.foregroundColor)
                Text("\(item.progressCurrent) / \(item.progressTotal) \(item.displayProgressUnit)")
                    .font(.caption2).foregroundStyle(.secondary)
            } else if let rating = item.rating {
                Label("\(rating) / 5", systemImage: "star.fill")
                    .font(.caption2).foregroundStyle(ShelfStyle.goldForeground)
            } else if item.progressCurrent > 0 {
                Text("\(item.progressCurrent) \(item.displayProgressUnit) logged")
                    .font(.caption2).foregroundStyle(.secondary)
            }
            Spacer(minLength: 0)
        }
    }
}

private struct LibraryListRow: View {
    let item: MediaItem
    @State private var showDetail = false
    var body: some View {
        Button { showDetail = true } label: {
        HStack(spacing: 14) {
            CoverImageView(data: item.coverImageData, mediaType: item.mediaType, title: item.title,
                           size: CGSize(width: 58, height: 80))
            VStack(alignment: .leading, spacing: 5) {
                Text(item.title).font(.headline).lineLimit(2)
                Text([item.mediaType.displayName, item.shelf?.name ?? "No shelf"].joined(separator: " · "))
                    .font(.caption).foregroundStyle(.secondary)
                if let fraction = item.progressFraction, item.finishedDate == nil {
                    ProgressView(value: fraction).tint(item.mediaType.foregroundColor)
                } else if !item.notes.isEmpty {
                    Text(item.notes).font(.caption).foregroundStyle(.secondary).lineLimit(1)
                }
            }
            Spacer(minLength: 0)
            if item.isFavorite { Image(systemName: "heart.fill").foregroundStyle(.pink) }
            if let rating = item.rating {
                Label("\(rating)", systemImage: "star.fill").font(.caption).foregroundStyle(ShelfStyle.goldForeground)
            }
        }
        .padding(12)
        .background(Color.shelfCard, in: RoundedRectangle(cornerRadius: 16))
        }
        .buttonStyle(.plain)
        .sheet(isPresented: $showDetail) { ItemDetailView(item: item) }
    }
}
