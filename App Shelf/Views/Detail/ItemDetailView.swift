import SwiftUI
import SwiftData
import PhotosUI

struct ItemDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context
    @Query(sort: \MoodTag.label) private var allTags: [MoodTag]
    @Query(sort: \Shelf.position) private var shelves: [Shelf]

    @Bindable var item: MediaItem

    @State private var photoItem: PhotosPickerItem?
    @State private var showMoveSheet = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    coverSection
                    ratingSection
                    infoSection
                    moodTagSection
                    datesSection
                    notesSection
                }
                .padding()
            }
            .navigationTitle(item.title)
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }

    // MARK: - Cover

    private var coverSection: some View {
        HStack {
            Spacer()
            PhotosPicker(selection: $photoItem, matching: .images) {
                ZStack(alignment: .bottomTrailing) {
                    CoverImageView(
                        data: item.coverImageData,
                        mediaType: item.mediaType,
                        cornerRadius: 16,
                        size: CGSize(width: 160, height: 224)
                    )
                    .shadow(color: .black.opacity(0.25), radius: 8, x: 0, y: 4)

                    Image(systemName: "camera.fill")
                        .font(.caption)
                        .padding(7)
                        .background(.ultraThinMaterial)
                        .clipShape(Circle())
                        .padding(6)
                }
            }
            .onChange(of: photoItem) { _, newItem in
                Task {
                    if let data = try? await newItem?.loadTransferable(type: Data.self) {
                        item.coverImageData = ImageCompression.compress(data) ?? data
                    }
                }
            }
            Spacer()
        }
    }

    // MARK: - Rating

    private var ratingSection: some View {
        VStack(spacing: 4) {
            StarRatingView(rating: $item.rating)
            if let r = item.rating {
                Text(ratingLabel(r))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } else {
                Text("Tap to rate")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
        }
    }

    // MARK: - Info

    private var infoSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            DetailRow(label: "Type") {
                Menu(item.mediaType.displayName) {
                    ForEach(MediaType.allCases) { type in
                        Button(type.displayName) { item.mediaType = type }
                    }
                }
                .foregroundStyle(.primary)
            }

            DetailRow(label: "Shelf") {
                Button(item.shelf?.name ?? "No shelf") {
                    showMoveSheet = true
                }
                .foregroundStyle(Color.accentColor)
            }
        }
        .padding()
        .background(.secondary.opacity(0.07))
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .sheet(isPresented: $showMoveSheet) {
            MoveToShelfSheet(item: item)
        }
    }

    // MARK: - Mood Tags

    private var moodTagSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Vibes")
                .font(.headline)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(allTags) { tag in
                        MoodTagChipView(
                            tag: tag,
                            isSelected: item.moodTags.contains(where: {
                                $0.persistentModelID == tag.persistentModelID
                            })
                        ) {
                            toggleTag(tag)
                        }
                    }
                }
                .padding(.vertical, 4)
            }
        }
    }

    // MARK: - Dates

    private var datesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Dates")
                .font(.headline)

            VStack(spacing: 0) {
                OptionalDatePicker(label: "Started", date: $item.startedDate)
                Divider().padding(.leading)
                OptionalDatePicker(label: "Finished", date: $item.finishedDate)
            }
            .padding(.horizontal)
            .background(.secondary.opacity(0.07))
            .clipShape(RoundedRectangle(cornerRadius: 14))
        }
    }

    // MARK: - Notes

    private var notesSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Notes")
                .font(.headline)

            TextEditor(text: $item.notes)
                .frame(minHeight: 120)
                .padding(10)
                .background(.secondary.opacity(0.07))
                .clipShape(RoundedRectangle(cornerRadius: 14))
                .font(.body)
                .overlay(alignment: .topLeading) {
                    if item.notes.isEmpty {
                        Text("Session logs, reactions, where you left off…")
                            .foregroundStyle(.tertiary)
                            .padding(16)
                            .allowsHitTesting(false)
                    }
                }
        }
    }

    // MARK: - Helpers

    private func toggleTag(_ tag: MoodTag) {
        if let idx = item.moodTags.firstIndex(where: {
            $0.persistentModelID == tag.persistentModelID
        }) {
            item.moodTags.remove(at: idx)
        } else {
            item.moodTags.append(tag)
        }
    }

    private func ratingLabel(_ r: Int) -> String {
        switch r {
        case 1: return "Not for me"
        case 2: return "Mid"
        case 3: return "Pretty good"
        case 4: return "Really liked it"
        case 5: return "Masterpiece"
        default: return ""
        }
    }
}

// MARK: - Supporting Views

struct DetailRow<Content: View>: View {
    let label: String
    @ViewBuilder let content: () -> Content

    var body: some View {
        HStack {
            Text(label)
                .foregroundStyle(.secondary)
                .frame(width: 60, alignment: .leading)
            Spacer()
            content()
        }
    }
}

struct OptionalDatePicker: View {
    let label: String
    @Binding var date: Date?

    var body: some View {
        HStack {
            Text(label)
                .foregroundStyle(.secondary)

            Spacer()

            if let d = date {
                DatePicker("", selection: Binding(
                    get: { d },
                    set: { date = $0 }
                ), displayedComponents: .date)
                .labelsHidden()

                Button {
                    date = nil
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
            } else {
                Button("Set") {
                    date = .now
                }
                .foregroundStyle(Color.accentColor)
            }
        }
        .padding(.vertical, 12)
    }
}
