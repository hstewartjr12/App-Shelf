import SwiftUI
import SwiftData
import PhotosUI

struct ItemDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context
    @Query(sort: \MoodTag.label) private var allTags: [MoodTag]
    @Query(sort: \Shelf.position) private var shelves: [Shelf]
    let item: MediaItem
    @State private var draft: MediaItemDraft
    @State private var addedTags: [String] = []
    @State private var newTag = ""
    @State private var photoItem: PhotosPickerItem?
    @State private var loadingCover = false
    @State private var saveError: String?

    init(item: MediaItem) {
        self.item = item
        _draft = State(initialValue: MediaItemDraft(item: item))
    }

    private var tagLabels: [String] { Array(Set(allTags.map(\.label) + addedTags)).sorted() }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    VStack(spacing: 16) {
                        PhotosPicker(selection: $photoItem, matching: .images) {
                            CoverImageView(data: draft.cover, mediaType: draft.mediaType, title: draft.title,
                                           cornerRadius: 14, size: CGSize(width: 140, height: 196))
                                .shadow(color: .black.opacity(0.15), radius: 10, y: 5)
                                .overlay(alignment: .bottomTrailing) {
                                    Image(systemName: "camera.fill").font(.caption)
                                        .padding(8).background(.regularMaterial, in: Circle()).padding(7)
                                }
                        }.buttonStyle(.plain)
                        if loadingCover { ProgressView("Loading cover…") }
                        StarRatingView(rating: $draft.rating)
                        Text(draft.rating.map(ratingLabel) ?? "How did it make you feel?")
                            .font(.caption).foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity).padding(.vertical, 14)
                    if draft.cover != nil {
                        Button("Remove cover", role: .destructive) { draft.cover = nil; photoItem = nil }
                            .font(.caption)
                    }
                }

                Section("Details") {
                    TextField("Title", text: $draft.title)
                    TextField("Author, artist, or studio", text: $draft.creator)
                    Picker("Media type", selection: $draft.mediaType) {
                        ForEach(MediaType.allCases) { Label($0.displayName, systemImage: $0.systemImage).tag($0) }
                    }
                    Picker("Shelf", selection: $draft.shelf) {
                        if draft.shelf == nil { Text("Choose a shelf").tag(Optional<Shelf>.none) }
                        ForEach(shelves) { Text($0.name).tag(Optional($0)) }
                    }
                    Toggle(isOn: $draft.favorite) { Label("Favorite", systemImage: "heart") }
                }

                Section {
                    if draft.total > 0 {
                        ProgressView(value: min(1, max(0, Double(draft.current) / Double(draft.total))))
                            .tint(draft.mediaType.foregroundColor)
                            .padding(.vertical, 5)
                    }
                    HStack {
                        Text("Progress")
                        Spacer()
                        TextField("0", value: $draft.current, format: .number)
                            .multilineTextAlignment(.trailing).frame(width: 75)
                        Text("of").foregroundStyle(.secondary)
                        TextField("Total", value: $draft.total, format: .number)
                            .multilineTextAlignment(.trailing).frame(width: 75)
                    }
                    TextField("Unit (pages, episodes, hours…)", text: $draft.unit)
                    Stepper("Log one more", value: $draft.current, in: 0...(draft.total > 0 ? draft.total : max(1_000_000, draft.current)))
                    if draft.finished == nil {
                        Button { markFinished() } label: { Label("Mark finished", systemImage: "checkmark.seal") }
                    } else {
                        Label("Finished \(draft.finished!.formatted(date: .abbreviated, time: .omitted))", systemImage: "checkmark.seal.fill")
                            .foregroundStyle(ShelfStyle.sageForeground)
                    }
                } header: { Text("Your progress") } footer: {
                    Text("Leave the total at zero to track without a target. Changes are saved when you tap Save.")
                }

                Section("Vibes") {
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 95))], spacing: 9) {
                        ForEach(tagLabels, id: \.self) { label in
                            Button {
                                if draft.tags.contains(label) { draft.tags.remove(label) } else { draft.tags.insert(label) }
                            } label: {
                                Text(label).font(.caption.weight(.medium))
                                    .frame(maxWidth: .infinity).padding(.vertical, 9)
                                    .background(draft.tags.contains(label) ? ShelfStyle.sage.opacity(0.16) : Color.secondary.opacity(0.06), in: Capsule())
                                    .foregroundStyle(draft.tags.contains(label) ? ShelfStyle.sageForeground : .secondary)
                            }.buttonStyle(.plain)
                                .accessibilityAddTraits(draft.tags.contains(label) ? .isSelected : [])
                        }
                    }.padding(.vertical, 5)
                    HStack {
                        TextField("Create a vibe", text: $newTag)
                        Button("Add", action: addTag).disabled(newTag.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    }
                }
                Section("Dates") {
                    OptionalDatePicker(label: "Started", date: $draft.started)
                    OptionalDatePicker(label: "Finished", date: $draft.finished)
                }
                Section("Your notes") {
                    TextField("Session logs, reactions, where you left off…", text: $draft.notes, axis: .vertical)
                        .lineLimit(5...12)
                }
                if let validation = draft.validation { Section { Text(validation).font(.caption).foregroundStyle(.red) } }
            }
            .formStyle(.grouped)
            .navigationTitle("Edit item")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save", action: save).fontWeight(.semibold).disabled(draft.validation != nil || loadingCover)
                }
            }
            .onChange(of: draft.shelf) { previous, next in
                if next?.isFinishedShelf == true {
                    if draft.finished == nil { draft.finished = .now }
                    if draft.total > 0 { draft.current = draft.total }
                } else if previous?.isFinishedShelf == true { draft.finished = nil }
            }
            .onChange(of: photoItem) { _, photo in
                Task {
                    loadingCover = true
                    defer { loadingCover = false }
                    do {
                        if let data = try await photo?.loadTransferable(type: Data.self), let compressed = ImageCompression.compress(data) {
                            draft.cover = compressed
                        } else if photo != nil { saveError = "That image could not be read. Try another photo." }
                    } catch { saveError = error.localizedDescription }
                }
            }
            .shelfSaveAlert($saveError)
        }
        .tint(ShelfStyle.sageForeground)
        .interactiveDismissDisabled()
        #if os(macOS)
        .frame(minWidth: 620, minHeight: 760)
        #endif
    }

    private func addTag() {
        let label = newTag.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !label.isEmpty else { return }
        if !tagLabels.contains(label) { addedTags.append(label) }
        draft.tags.insert(label)
        newTag = ""
    }
    private func markFinished() {
        if let shelf = shelves.first(where: \.isFinishedShelf) { draft.shelf = shelf }
        draft.finished = .now
        if draft.total > 0 { draft.current = draft.total }
    }
    private func save() {
        guard draft.validation == nil else { return }
        draft.apply(to: item, context: context, existingTags: allTags)
        do { try context.save(); dismiss() }
        catch { context.rollback(); saveError = error.localizedDescription }
    }
    private func ratingLabel(_ value: Int) -> String {
        ["", "Not for me", "It was okay", "Pretty good", "Really liked it", "A personal favorite"][min(5, max(0, value))]
    }
}

struct OptionalDatePicker: View {
    let label: String
    @Binding var date: Date?
    var body: some View {
        HStack {
            Text(label)
            Spacer()
            if date != nil {
                DatePicker("", selection: Binding(get: { date ?? .now }, set: { date = $0 }), displayedComponents: .date)
                    .labelsHidden()
                Button { date = nil } label: { Image(systemName: "xmark.circle.fill").foregroundStyle(.secondary) }
                    .buttonStyle(.plain).accessibilityLabel("Clear \(label.lowercased()) date")
            } else {
                Button("Set date") { date = .now }.buttonStyle(.borderless)
            }
        }
    }
}
