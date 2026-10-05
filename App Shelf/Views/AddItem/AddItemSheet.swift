import SwiftUI
import SwiftData
import PhotosUI

struct AddItemAvailability {
    let title: String
    let selectedShelf: Shelf?
    let shelves: [Shelf]
    var resolvedShelf: Shelf? { selectedShelf ?? shelves.first }
    var hasShelves: Bool { !shelves.isEmpty }
    var trimmedTitle: String { title.trimmingCharacters(in: .whitespacesAndNewlines) }
    var canSubmit: Bool { !trimmedTitle.isEmpty && resolvedShelf != nil }
}

struct AddItemSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context
    @Query(sort: \Shelf.position) private var shelves: [Shelf]
    @Query private var items: [MediaItem]
    @State private var title = ""
    @State private var creator = ""
    @State private var notes = ""
    @State private var mediaType: MediaType = .book
    @State private var selectedShelf: Shelf?
    @State private var photoItem: PhotosPickerItem?
    @State private var coverData: Data?
    @State private var startNow = true
    @State private var saveError: String?
    @State private var loadingCover = false
    @FocusState private var titleFocused: Bool

    init(initialShelf: Shelf? = nil) {
        _selectedShelf = State(initialValue: initialShelf)
        _startNow = State(initialValue: initialShelf?.isBacklogShelf != true)
    }

    private var availability: AddItemAvailability {
        AddItemAvailability(title: title, selectedShelf: selectedShelf, shelves: shelves)
    }
    private var duplicate: MediaItem? {
        items.first { $0.mediaType == mediaType && $0.title.localizedStandardCompare(availability.trimmedTitle) == .orderedSame }
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    HStack(spacing: 18) {
                        PhotosPicker(selection: $photoItem, matching: .images) {
                            CoverImageView(data: coverData, mediaType: mediaType, title: title,
                                           cornerRadius: 10, size: CGSize(width: 76, height: 106))
                                .overlay(alignment: .bottomTrailing) {
                                    Image(systemName: "camera.fill").font(.caption)
                                        .padding(6).background(.regularMaterial, in: Circle()).padding(5)
                                }
                        }.buttonStyle(.plain)
                        VStack(alignment: .leading, spacing: 8) {
                            Text("A new story for your shelf")
                                .font(.system(.headline, design: .serif))
                            Text("Cover art is optional. Your collection looks good either way.")
                                .font(.caption).foregroundStyle(.secondary)
                            if loadingCover { ProgressView("Loading cover…").font(.caption) }
                        }
                    }.padding(.vertical, 7)
                    TextField("Title", text: $title).focused($titleFocused)
                    TextField("Author, artist, or studio (optional)", text: $creator)
                } footer: {
                    if let duplicate {
                        Text("You already saved “\(duplicate.title)” in \(duplicate.shelf?.name ?? "your library"). You can still add another copy.")
                    }
                }

                Section("Media type") {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(MediaType.allCases) { type in
                                Button { mediaType = type } label: {
                                    TypeChip(type: type, isSelected: mediaType == type)
                                }.buttonStyle(.plain)
                            }
                        }.padding(.vertical, 4)
                    }
                }

                Section("Make room for it") {
                    if availability.hasShelves {
                        Picker("Shelf", selection: $selectedShelf) {
                            ForEach(shelves) { shelf in Text(shelf.name).tag(Optional(shelf)) }
                        }
                        if availability.resolvedShelf?.isFinishedShelf != true {
                            Toggle("I’ve started this", isOn: $startNow)
                        }
                    } else {
                        Text("Create a shelf before adding a title.").foregroundStyle(.secondary)
                    }
                }
                Section("A note for later") {
                    TextField("Why you saved it, who recommended it…", text: $notes, axis: .vertical)
                        .lineLimit(3...5)
                }
            }
            .formStyle(.grouped)
            .navigationTitle("Add to your library")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add", action: addItem).disabled(!availability.canSubmit || loadingCover).fontWeight(.semibold)
                }
            }
            .onAppear { if selectedShelf == nil { selectedShelf = shelves.first }; titleFocused = true }
            .onChange(of: selectedShelf) { _, shelf in startNow = shelf?.isBacklogShelf != true }
            .onChange(of: photoItem) { _, newItem in
                Task {
                    loadingCover = true
                    defer { loadingCover = false }
                    do {
                        if let data = try await newItem?.loadTransferable(type: Data.self), let compressed = ImageCompression.compress(data) {
                            coverData = compressed
                        } else if newItem != nil { saveError = "That image could not be read. Try another photo." }
                    } catch { saveError = error.localizedDescription }
                }
            }
            .shelfSaveAlert($saveError)
        }
        .tint(ShelfStyle.sageForeground)
        #if os(macOS)
        .frame(minWidth: 570, minHeight: 620)
        #endif
    }

    private func addItem() {
        guard availability.canSubmit, let shelf = availability.resolvedShelf else { return }
        let item = MediaItem(title: availability.trimmedTitle, mediaType: mediaType,
                             shelf: shelf, positionInShelf: shelf.nextItemPosition)
        item.creator = creator.trimmingCharacters(in: .whitespacesAndNewlines)
        item.notes = notes
        item.coverImageData = coverData
        item.startedDate = startNow && !shelf.isBacklogShelf ? .now : nil
        if shelf.isFinishedShelf { item.finishedDate = .now }
        context.insert(item)
        do { try context.save(); dismiss() }
        catch { context.rollback(); saveError = error.localizedDescription }
    }
}

struct TypeChip: View {
    let type: MediaType
    let isSelected: Bool
    var body: some View {
        Label(type.displayName, systemImage: type.systemImage)
            .font(.caption.weight(.medium))
            .padding(.horizontal, 12).padding(.vertical, 8)
            .background(isSelected ? type.color : type.color.opacity(0.08), in: Capsule())
            .foregroundStyle(isSelected ? .white : type.foregroundColor)
            .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}
