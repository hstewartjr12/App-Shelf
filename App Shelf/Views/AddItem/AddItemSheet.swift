import SwiftUI
import SwiftData
import PhotosUI

struct AddItemSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context
    @Query(sort: \Shelf.position) private var shelves: [Shelf]

    @State private var title = ""
    @State private var mediaType: MediaType = .other
    @State private var selectedShelf: Shelf?
    @State private var photoItem: PhotosPickerItem?
    @State private var coverData: Data?

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Title", text: $title)
                        .font(.body)
                }

                Section("Type") {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 10) {
                            ForEach(MediaType.allCases) { type in
                                TypeChip(type: type, isSelected: mediaType == type)
                                    .onTapGesture { mediaType = type }
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }

                Section("Shelf") {
                    Picker("Shelf", selection: $selectedShelf) {
                        ForEach(shelves) { shelf in
                            Text(shelf.name).tag(Optional(shelf))
                        }
                    }
                    .pickerStyle(.menu)
                    .labelsHidden()
                }

                Section("Cover Art (optional)") {
                    HStack(spacing: 16) {
                        if let coverData {
                            CoverImageView(
                                data: coverData,
                                mediaType: mediaType,
                                cornerRadius: 8,
                                size: CGSize(width: 60, height: 84)
                            )
                        }

                        PhotosPicker(selection: $photoItem, matching: .images) {
                            Label(
                                coverData == nil ? "Choose Image" : "Change Image",
                                systemImage: "photo"
                            )
                        }
                        .onChange(of: photoItem) { _, newItem in
                            Task {
                                if let data = try? await newItem?.loadTransferable(type: Data.self) {
                                    coverData = ImageCompression.compress(data) ?? data
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("Add to Shelf")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        addItem()
                    }
                    .disabled(title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    .fontWeight(.semibold)
                }
            }
            .onAppear {
                if selectedShelf == nil {
                    selectedShelf = shelves.first
                }
            }
        }
        .presentationDetents([.medium, .large])
    }

    private func addItem() {
        let trimmed = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        let shelf = selectedShelf ?? shelves.first
        let position = shelf?.items.count ?? 0

        let item = MediaItem(
            title: trimmed,
            mediaType: mediaType,
            shelf: shelf,
            positionInShelf: position
        )
        item.coverImageData = coverData
        context.insert(item)
        try? context.save()
        dismiss()
    }
}

// MARK: - Type Chip

struct TypeChip: View {
    let type: MediaType
    let isSelected: Bool

    var body: some View {
        HStack(spacing: 5) {
            Image(systemName: type.systemImage)
                .font(.caption2)
            Text(type.displayName)
                .font(.caption)
                .fontWeight(.medium)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 7)
        .background(isSelected ? Color.accentColor : Color.secondary.opacity(0.12))
        .foregroundStyle(isSelected ? .white : .primary)
        .clipShape(Capsule())
        .animation(.spring(response: 0.2), value: isSelected)
    }
}
