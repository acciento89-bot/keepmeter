import SwiftUI
import SwiftData
import PhotosUI
import UniformTypeIdentifiers
import UIKit
import ImageIO

struct PurchaseOrganisationView: View {
    @Environment(\.modelContext) private var context
    let purchase: Purchase
    @State private var photo: PhotosPickerItem?
    @State private var error: String?
    @State private var loading = false

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(String(localized: "Purchase folder")).font(.title3.bold())
            Picker(String(localized: "Category"), selection: Binding(
                get: { purchase.categoryRawValue },
                set: { value in
                    purchase.categoryRawValue = value
                    save()
                })) {
                ForEach(PurchaseCategory.allCases) { category in Text(category.title).tag(category.rawValue) }
            }.disabled(purchase.outcome != .active)
            if let bytes = purchase.receiptPhoto, let image = UIImage(data: bytes) {
                Image(uiImage: image).resizable().scaledToFit().frame(maxHeight: 340)
                    .accessibilityLabel(String(localized: "Receipt photo"))
                if purchase.outcome == .active {
                    Button(String(localized: "Remove receipt photo"), role: .destructive) {
                        purchase.receiptPhoto = nil; save()
                    }
                }
            }
            if purchase.outcome == .active {
                PhotosPicker(selection: $photo, matching: .images) {
                    Label(String(localized: "Add receipt photo"), systemImage: "photo.badge.plus")
                        .frame(minHeight: 44)
                }.disabled(loading)
            }
            if loading { ProgressView() }
            Text(String(localized: "Receipt photos stay on this device. Export contains purchase details, not photos."))
                .font(.caption).foregroundStyle(.secondary)
            if let error { Text(error).font(.caption).foregroundStyle(.red) }
        }
        .padding(18).kmCard()
        .onChange(of: photo) { _, selected in
            guard let selected else { return }
            loading = true
            Task {
                defer { loading = false; photo = nil }
                do {
                    guard let data = try await selected.loadTransferable(type: Data.self), data.count <= 35_000_000,
                          let source = CGImageSourceCreateWithData(data as CFData, nil),
                          let thumbnail = CGImageSourceCreateThumbnailAtIndex(source, 0, [
                            kCGImageSourceCreateThumbnailFromImageAlways: true,
                            kCGImageSourceThumbnailMaxPixelSize: 1600,
                            kCGImageSourceCreateThumbnailWithTransform: true
                          ] as CFDictionary),
                          let jpeg = UIImage(cgImage: thumbnail).jpegData(compressionQuality: 0.8)
                    else { throw CocoaError(.fileReadCorruptFile) }
                    purchase.receiptPhoto = jpeg
                    save()
                } catch { self.error = String(localized: "Couldn't save receipt photo. Please try another image.") }
            }
        }
    }

    private func save() {
        do { try context.save(); error = nil }
        catch { context.rollback(); self.error = String(localized: "Couldn't save change") }
    }
}

struct PurchaseCSVDocument: FileDocument {
    static var readableContentTypes: [UTType] { [.commaSeparatedText] }
    var text: String
    init(text: String) { self.text = text }
    init(configuration: ReadConfiguration) throws {
        text = String(decoding: configuration.file.regularFileContents ?? Data(), as: UTF8.self)
    }
    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        FileWrapper(regularFileWithContents: Data(text.utf8))
    }
}
