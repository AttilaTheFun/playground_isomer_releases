// Meme Creator — as a Playground project. Same source as the example apps'.
import SwiftUI
import Isomer
import Observation
import Foundation
import PlatformServices

@main
struct MemeCreatorApp: App {
    var body: some Scene { WindowGroup { NavigationStack { MemeCreatorScreen() } } }
}

// An original "meme creator" — our own take on the kind of app in Apple's
// SwiftUI sample-app tutorials, built to exercise the framework across every
// platform: a background image with a draggable, styled caption plus live
// controls (text, size, color, image). Nothing here is copied from Apple's
// sample sources.


struct MemeCreatorScreen: View {
    @State private var caption = "SHIPS EVERYWHERE"
    @State private var fontSize = 30.0
    @State private var rotation = 0.0
    @State private var offset = CGSize.zero
    @State private var committedOffset = CGSize.zero
    @State private var colorIndex = 0
    @State private var imageIndex = 0
    /// A photo the user chose (a data URL from the platform image picker).
    @State private var ownPhoto: String?
    @State private var pickerBusy = false

    private let images = [
        "https://picsum.photos/id/237/600/400",
        "https://picsum.photos/id/1025/600/400",
        "https://picsum.photos/id/1062/600/400",
    ]
    private let captionColors: [Color] = [.white, .yellow, .red, .green]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                canvas
                Text("Caption").font(.headline)
                TextField("Caption text", text: $caption)
                Text("Font size: \(Int(fontSize))").font(.subheadline).foregroundColor(.secondary)
                Slider(value: $fontSize, in: 16 ... 64)
                Text("Rotation: \(Int(rotation))°").font(.subheadline).foregroundColor(.secondary)
                Slider(value: $rotation, in: -45 ... 45)
                Text("Color").font(.headline)
                colorSwatches
                Text("Background").font(.headline)
                Picker("Background", selection: $imageIndex) {
                    ForEach(0 ..< images.count, id: \.self) { index in
                        Text("Photo \(index + 1)").tag(index)
                    }
                    if ownPhoto != nil { Text("Your photo").tag(images.count) }
                }
                if PlatformDependencies.imagePicker != nil {
                    Button(pickerBusy ? "Choosing…" : "Choose your own photo…", action: choosePhoto)
                        .disabled(pickerBusy)
                }
                Text("Drag the caption to reposition it.")
                    .font(.footnote).foregroundColor(.secondary)
            }
            .padding(20)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .navigationTitle("Meme Creator")
    }

    /// The background: a bundled photo, or the user's own.
    private var backgroundURL: URL? {
        if imageIndex == images.count, let ownPhoto { return URL(string: ownPhoto) }
        return URL(string: images[min(imageIndex, images.count - 1)])
    }

    private func choosePhoto() {
        guard let picker = PlatformDependencies.imagePicker else { return }
        pickerBusy = true
        Task { @MainActor in
            let url = (try? await picker.pickImage(maxDimension: 1280)) ?? ""
            if !url.isEmpty {
                ownPhoto = url
                imageIndex = images.count
            }
            pickerBusy = false
        }
    }

    private var canvas: some View {
        ZStack {
            // The photo fills a fixed-height canvas as an overlay, so a
            // fill-scaled image never widens the layout (it would: scaledToFill
            // reports the filled size, and the column grows past the screen).
            Color.clear
                .frame(maxWidth: .infinity)
                .frame(height: 280)
                .overlay(
                    AsyncImage(url: backgroundURL) { image in
                        image.resizable().scaledToFill()
                    } placeholder: {
                        Color(white: 0, opacity: 0.1)
                    }
                )
                .clipped()
                .cornerRadius(14)

            Text(caption)
                .font(.system(size: fontSize))
                .bold()
                .foregroundColor(captionColors[colorIndex])
                .shadow(color: .black, radius: 1, x: 1, y: 1)
                .rotationEffect(.degrees(rotation))
                .offset(x: offset.width, y: offset.height)
                .gesture(
                    DragGesture()
                        .onChanged { value in
                            offset = CGSize(
                                width: committedOffset.width + value.translation.width,
                                height: committedOffset.height + value.translation.height)
                        }
                        .onEnded { _ in committedOffset = offset }
                )
        }
        .frame(height: 280)
    }

    private var colorSwatches: some View {
        HStack(spacing: 12) {
            ForEach(0 ..< captionColors.count, id: \.self) { index in
                ZStack {
                    Circle()
                        .fill(captionColors[index])
                        .frame(width: 30, height: 30)
                    Circle()
                        .stroke(index == colorIndex ? Color.accentColor : Color(white: 0, opacity: 0.2),
                                lineWidth: index == colorIndex ? 3 : 1)
                        .frame(width: 30, height: 30)
                }
                .onTapGesture { colorIndex = index }
            }
        }
    }
}

// How the example app reaches the network and its files: Foundation's own,
// as an app on Apple platforms does. `URLSession` goes through the host's
// networking (the browser's fetch on the web, Android's own client, Apple's
// URLSession in a WasmView), and the app's files are FileManager's, in its
// Application Support, which persists on every platform. The same code runs
// compiled (Apple / Linux / Windows / Android) and as a wasm reactor under
// every host.


/// GET `url` and hand back the body as text. A failed request (or a status
/// other than 2xx) throws; the completion form gives nil and the models show
/// their empty state.
enum Networking {
    static func fetchText(_ url: String) async throws -> String {
        guard let address = URL(string: url) else { throw URLError(.badURL) }
        let (data, response) = try await URLSession.shared.data(from: address)
        if let status = (response as? HTTPURLResponse)?.statusCode, !(200..<300).contains(status) {
            throw URLError(.badServerResponse)
        }
        return String(decoding: data, as: UTF8.self)
    }

    /// Completion form, delivered on the main actor (where the models mutate
    /// their published state).
    static func fetch(_ url: String, completion: @escaping @MainActor (String?) -> Void) {
        Task { @MainActor in
            do {
                completion(try await fetchText(url))
            } catch {
                completion(nil)
            }
        }
    }
}

/// Text files in the app's Application Support (FileManager's).
enum SandboxFiles {
    private static var directory: URL {
        FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("example_application", isDirectory: true)
    }

    static func read(_ name: String) -> String? {
        guard let data = try? Data(contentsOf: directory.appendingPathComponent(name, isDirectory: false)) else {
            return nil
        }
        return String(decoding: data, as: UTF8.self)
    }

    static func write(_ name: String, _ contents: String) {
        try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        try? Data(contents.utf8).write(to: directory.appendingPathComponent(name, isDirectory: false))
    }
}

