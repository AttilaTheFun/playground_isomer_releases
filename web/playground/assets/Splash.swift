// This website — as a Playground project. Same source as the example apps'.
import SwiftUI
import Isomer
import Observation
import Foundation

// The Isomer site's front page — a post about the framework, written in
// Isomer's SwiftUI and compiled to wasm, with the example apps embedded
// INLINE as subviews (the same Counter / 2048 / Pokédex sources every example
// app ships) inside framed cards you can use and scroll past. The pencil in
// each card's corner (and in the page's corner) opens the Playground on that
// source; the page's host handles the commands (`template:<name>`, `edit`,
// `playground`).


@main
struct SplashApp: App {
    var body: some Scene { WindowGroup { SplashPage() } }
}

struct SplashPage: View {
    @State private var command = ""
    @State private var commandCount = 0
    /// The Pokédex's caught record (kept in the app's Application Support).
    @State private var pokedex = PokedexStore()

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 36) {
                header
                section("What it is") {
                    Para("Isomer is a reimplementation of SwiftUI. Apps are written against Apple's SwiftUI API — `import SwiftUI`, `@State`, `NavigationStack`, `List`, gestures, animations — and the same source compiles for every platform: on iOS and macOS it is Apple's SwiftUI, and everywhere else (the web, Android, Linux, Windows) it is this reimplementation, which turns the view tree into a compact render tree and hands it to a renderer.")
                    Para("The whole page you are reading is one of those apps, running as WebAssembly in your browser. So are the examples below — they are the example apps' own screens, embedded here as ordinary subviews. Try them; then press the pencil to open the source in the Playground.")
                    DemoCard(title: "Counter", template: "Counter", note: "State and a button — the smallest app.", send: send) {
                        NavigationStack { CounterScreen() }
                    }
                }
                section("How it works: one tree, pluggable renderers") {
                    Para("Every frame, the app's SwiftUI body builds a render tree: stacks, text, images, shapes, scroll views, inputs, navigation chrome. It is diffed and serialized as patches on a small FlatBuffers wire format, and a renderer applies it. Renderers are pluggable and come in two kinds.")
                    Para("Component-system renderers build the platform's own components from the tree — React DOM on the web (this page), Jetpack Compose or classic Views on Android, SwiftUI or UIKit views on Apple when a feature runs as a bundle inside a native app. They get the platform's native feel for free: real text fields, real scrolling, real navigation bars.")
                    Para("The self-drawing renderer, SwiftGPU, draws everything itself — layout, text, chrome — identically on every backend, for hosts without a component system or for pixel-identical output across platforms.")
                    DemoCard(title: "2048", template: "2048", note: "Drag gestures, GeometryReader layout, withAnimation — swipe the board.", send: send) {
                        NavigationStack { Game2048Screen() }
                    }
                }
                section("Compiled, or WebAssembly") {
                    Para("The same Swift ships two ways. Compiled, it links straight into the app for the platform's native performance. As WebAssembly, it becomes a self-contained feature bundle a host runs in a wasm engine — WAMR, wasmtime, JavaScriptCore, WasmKit, or the browser — which is what makes hot reload possible: a native iOS or Android app can swap a feature's bundle live, and a phone can pull new versions of an app as they are published.")
                    Para("In the browser it goes one step further: the Playground compiles Swift itself, in the page, with swift-frontend and wasm-ld compiled to WebAssembly. Edit this page there and Run, and the site recompiles without leaving the browser.")
                }
                section("Pluggable GPUs") {
                    Para("The SwiftGPU renderer draws through a GPU abstraction with pluggable backends — Metal on Apple, OpenGL ES on Android, WebGPU in the browser — and a host can bring its own device. The same abstraction powers SwiftMap, an OpenStreetMap renderer that drops into Isomer apps as a map view on every platform.")
                }
                section("Apple's frameworks, everywhere") {
                    Para("Apps reach the network and their files the way they do on Apple platforms: URLSession, FileManager and UserDefaults from Foundation, with models made @Observable. Off Apple those are Isomer's own Foundation and Observation, in Swift — URLSession over the browser's fetch here and Android's HTTP client there, an app's files in the browser's storage or on disk — so the same source runs everywhere.")
                    Para("The Pokédex below loads its list and artwork with URLSession and remembers which Pokémon you have caught in a file in its Application Support — in your browser's storage here, on disk in the native apps.")
                    DemoCard(title: "Pokédex", template: "Pokédex", note: "URLSession and a file kept in Application Support.", send: send) {
                        NavigationStack { PokedexScreen() }.environment(pokedex)
                    }
                }
                section("Try it") {
                    Para("The Playground is a Swift compiler and an agent in a static web page: describe an app, and it writes the SwiftUI, compiles it in your browser, fixes its own errors, and runs it. Or open this page's source and change it.")
                    HStack(spacing: 12) {
                        Button { send("playground") } label: { Label("Open the Playground", systemImage: "play.fill") }
                            .buttonStyle(.borderedProminent)
                        Button { send("edit") } label: { Label("Edit this page", systemImage: "pencil") }
                            .buttonStyle(.bordered)
                    }
                }
                footer
            }
            .frame(maxWidth: 760)
            .padding(.horizontal, 24)
            .padding(.vertical, 36)
            .frame(maxWidth: .infinity)
        }
        .overlay(alignment: .topTrailing) {
            // The page's own pencil: this file, in the Playground.
            Button { send("edit") } label: { Image(systemName: "pencil") }
                .buttonStyle(.bordered)
                .accessibilityLabel("Edit this page")
                .accessibilityIdentifier("edit-page")
                .padding(14)
        }
        .platformCommand("splash", command, on: .wasm)
    }

    private func send(_ value: String) {
        // A distinct value each time, so repeated commands are delivered.
        // (A counter, not the epoch in ms: Int is 32-bit on wasm.)
        commandCount += 1
        command = value + "#" + String(commandCount)
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Isomer").font(.system(size: 44, weight: .bold))
            Text("SwiftUI, everywhere.").font(.system(size: 26, weight: .semibold)).foregroundColor(.secondary)
            Text("This website is written in SwiftUI. You can edit it and re-compile the code without leaving the page.")
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(.accentColor)
                .padding(.top, 4)
        }
    }

    private func section<Content: View>(_ title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(title).font(.system(size: 26, weight: .bold))
            content()
        }
    }

    private var footer: some View {
        VStack(alignment: .leading, spacing: 6) {
            Divider()
            Text("Isomer · SwiftUI reimplementation · wasm, Android, Linux, Windows, Apple")
                .font(.footnote).foregroundColor(.secondary)
        }
    }
}

/// A paragraph of the post.
struct Para: View {
    let text: String
    init(_ text: String) { self.text = text }
    var body: some View {
        Text(text).font(.system(size: 17)).lineSpacing(5)
    }
}

/// An example app embedded inline: the screen inside a phone-sized, rounded,
/// bordered card with a shadow, usable in place, with a pencil that opens
/// its source in the Playground.
struct DemoCard<Content: View>: View {
    let title: String
    let template: String
    let note: String
    let send: (String) -> Void
    let content: Content

    init(title: String, template: String, note: String, send: @escaping (String) -> Void, @ViewBuilder content: () -> Content) {
        self.title = title
        self.template = template
        self.note = note
        self.send = send
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            content
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .frame(height: 560)
                .clipShape(RoundedRectangle(cornerRadius: 28))
                .overlay(RoundedRectangle(cornerRadius: 28).stroke(Color.gray.opacity(0.35), lineWidth: 1))
                .shadow(color: Color.black.opacity(0.25), radius: 24, x: 0, y: 12)
                .frame(maxWidth: 400)
            // The pencil sits beside the note, not over the example: the
            // example's own bar has the top-trailing corner (2048's new-game
            // button lives there), and a page control laid over an app's
            // control is two things in one place.
            HStack(alignment: .firstTextBaseline, spacing: 12) {
                Text(note).font(.footnote).foregroundColor(.secondary)
                Spacer(minLength: 0)
                Button { send("template:" + template) } label: { Image(systemName: "pencil") }
                    .buttonStyle(.bordered)
                    .accessibilityLabel("Edit \(title) in the Playground")
                    .accessibilityIdentifier("edit-" + template)
            }
            .frame(maxWidth: 400)
        }
        .padding(.vertical, 6)
    }
}


/// Chrome that arrived in iOS 17 / macOS 14. This app targets iOS 16, so the
/// two modifiers below are asked for only where they exist — the same shape a
/// native app at this deployment target would take. On the platforms Isomer
/// implements itself there is no such floor, and `#available` says so.
extension View {
    @ViewBuilder func inlineNavigationTitle() -> some View {
        if #available(iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0, *) {
            toolbarTitleDisplayMode(.inline)
        } else {
            self
        }
    }

    @ViewBuilder func restingAtBottom() -> some View {
        if #available(iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0, *) {
            defaultScrollAnchor(.bottom)
        } else {
            self
        }
    }
}

// Counter — the smallest example: a button that counts taps. Shared by the
// example apps (a catalog entry) and the Playground (a project template).


struct CounterScreen: View {
    @State private var count = 0

    var body: some View {
        VStack(spacing: 16) {
            Text("Hello from Isomer!")
                .font(.title2)
            Text("Tapped \(count) times")
                .foregroundColor(.secondary)
            Button("Tap me") { count += 1 }
                .buttonStyle(.borderedProminent)
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .navigationTitle("Counter")
    }
}

// 2048 — a swipe-to-merge tile game. Swipe the board (the tiles that can
// move follow your finger, the blocked ones stretch a little, then the move
// commits when you let go); merged tiles slide into place and a new tile
// slides in from the edge you swiped away from. Exercises GeometryReader
// layout, drag gestures, `withAnimation` with animated offsets/scales,
// navigation chrome and `.ignoresSafeArea()`. Shared by the example apps
// (a catalog entry) and the Playground (a project template).


enum Direction { case up, down, left, right }

/// One tile on the board. `merging` tiles are the losers of a merge: they
/// slide under the surviving tile and are removed once the slide finishes.
/// `entering` marks a freshly spawned tile still off the board's edge.
struct Tile: Identifiable {
    let id: Int
    var row: Int
    var col: Int
    var value: Int
    var merging = false
    var entering: Direction? = nil
}

struct Game2048Screen: View {
    @State private var tiles: [Tile] = []
    @State private var nextID = 0
    @State private var score = 0
    @State private var best = 0
    @State private var spawnNumber = 0
    @State private var gameOver = false
    @State private var won = false
    /// The live drag translation along the locked axis (moving tiles follow it).
    @State private var dragOffset = CGSize.zero
    /// The axis locked by the first movement of a swipe (until the finger lifts).
    @State private var dragHorizontal: Bool? = nil
    /// The move the current drag would make, and the tiles it would move;
    /// the rest stay put and stretch a little against the pull.
    @State private var previewDirection: Direction? = nil
    @State private var movingIDs: Set<Int> = []

    private let cream = Color(red: 0.97, green: 0.95, blue: 0.90)
    private let boardColor = Color(red: 0.73, green: 0.67, blue: 0.60)
    private let emptyColor = Color(red: 0.80, green: 0.75, blue: 0.68)
    private let gap: CGFloat = 8

    var body: some View {
        ZStack {
            cream.ignoresSafeArea()
            GeometryReader { geometry in
                let boardSize = max(200, min(geometry.size.width - 32, geometry.size.height - 120))
                let tileSize = (boardSize - gap * 5) / 4
                VStack(spacing: 20) {
                    scoreRow
                    board(boardSize: boardSize, tileSize: tileSize)
                    Text("Swipe the board to merge tiles.")
                        .font(.caption)
                        .foregroundColor(Color(red: 0.48, green: 0.42, blue: 0.36))
                }
                .padding(.top, 16)
                .frame(width: geometry.size.width, height: geometry.size.height, alignment: .top)
            }
        }
        .navigationTitle("2048")
        .inlineNavigationTitle()
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button(action: resetGame) {
                    Image(systemName: "arrow.clockwise")
                }
                .accessibilityLabel("New game")
            }
        }
        .onAppear { if tiles.isEmpty { resetGame() } }
    }

    // MARK: - Board

    private func board(boardSize: CGFloat, tileSize: CGFloat) -> some View {
        ZStack(alignment: .topLeading) {
            RoundedRectangle(cornerRadius: 10).fill(boardColor)
            ForEach(0..<16, id: \.self) { index in
                RoundedRectangle(cornerRadius: 7)
                    .fill(emptyColor)
                    .frame(width: tileSize, height: tileSize)
                    .offset(x: origin(index % 4, tileSize), y: origin(index / 4, tileSize))
            }
            // Losers of a merge first, so the surviving tile draws on top.
            ForEach(tiles.filter { $0.merging }) { tile in tileView(tile, tileSize: tileSize) }
            ForEach(tiles.filter { !$0.merging }) { tile in tileView(tile, tileSize: tileSize) }
            if gameOver {
                endCard(title: "Game over", message: "No more moves left.", boardSize: boardSize)
            } else if won {
                endCard(title: "You made 2048!", message: "Keep going for a higher score.", boardSize: boardSize)
            }
        }
        .frame(width: boardSize, height: boardSize)
        .cornerRadius(10) // clips tiles that follow the finger past the edge
        .gesture(
            DragGesture(minimumDistance: 6)
                .onChanged { value in
                    // The first movement locks the axis for the whole swipe;
                    // the tiles that can move follow the finger a little way
                    // (enough to feel the move before it commits).
                    let dx = value.translation.width
                    let dy = value.translation.height
                    let horizontal = dragHorizontal ?? (abs(dx) > abs(dy))
                    dragHorizontal = horizontal
                    let along = horizontal ? dx : dy
                    let direction: Direction = horizontal ? (along > 0 ? .right : .left) : (along > 0 ? .down : .up)
                    if direction != previewDirection {
                        previewDirection = direction
                        movingIDs = plan(direction).movingIDs
                    }
                    let limit = tileSize * 0.35
                    let clamped = max(-limit, min(limit, along))
                    dragOffset = horizontal ? CGSize(width: clamped, height: 0) : CGSize(width: 0, height: clamped)
                }
                .onEnded { value in
                    let horizontal = dragHorizontal ?? true
                    let along = horizontal ? value.translation.width : value.translation.height
                    let direction: Direction? = abs(along) < 20 ? nil
                        : horizontal ? (along > 0 ? .right : .left) : (along > 0 ? .down : .up)
                    dragHorizontal = nil
                    withAnimation(.easeOut(duration: 0.16)) {
                        dragOffset = .zero
                        previewDirection = nil
                        movingIDs = []
                        if let direction { move(direction, tileSize: tileSize) }
                    }
                }
        )
    }

    private func origin(_ index: Int, _ tileSize: CGFloat) -> CGFloat {
        gap + CGFloat(index) * (tileSize + gap)
    }

    private func tileView(_ tile: Tile, tileSize: CGFloat) -> some View {
        // A spawned tile starts one cell beyond the edge it enters from.
        var x = origin(tile.col, tileSize)
        var y = origin(tile.row, tileSize)
        var width = tileSize
        var height = tileSize
        switch tile.entering {
        case .left: x += tileSize + gap
        case .right: x -= tileSize + gap
        case .up: y += tileSize + gap
        case .down: y -= tileSize + gap
        case nil: break
        }
        if let direction = previewDirection {
            if movingIDs.contains(tile.id) || tile.merging {
                x += dragOffset.width
                y += dragOffset.height
            } else {
                // A blocked tile leans into the pull: it stretches a little
                // toward the swipe (its far edge stays put) and thins across.
                let limit = tileSize * 0.35
                let progress = min(1, max(abs(dragOffset.width), abs(dragOffset.height)) / limit)
                let stretch = tileSize * 0.08 * progress
                let squeeze = tileSize * 0.04 * progress
                switch direction {
                case .left: x -= stretch; width += stretch; height -= squeeze; y += squeeze / 2
                case .right: width += stretch; height -= squeeze; y += squeeze / 2
                case .up: y -= stretch; height += stretch; width -= squeeze; x += squeeze / 2
                case .down: height += stretch; width -= squeeze; x += squeeze / 2
                }
            }
        }
        return TileFace(value: tile.value, size: tileSize, width: width, height: height)
            .scaleEffect(tile.entering == nil ? 1 : 0.6)
            .opacity(tile.entering == nil ? 1 : 0.4)
            .offset(x: x, y: y)
    }

    // MARK: - Score row

    private var scoreRow: some View {
        HStack(spacing: 16) {
            ScoreBox(title: "SCORE", value: score)
            ScoreBox(title: "BEST", value: best)
        }
        .padding(.horizontal, 16)
    }

    private func endCard(title: String, message: String, boardSize: CGFloat) -> some View {
        VStack(spacing: 10) {
            Text(title).font(.title2.weight(.black)).foregroundColor(Color(red: 0.30, green: 0.23, blue: 0.16))
            Text(message).font(.subheadline).multilineTextAlignment(.center)
                .foregroundColor(Color(red: 0.38, green: 0.31, blue: 0.23))
            HStack(spacing: 10) {
                if won { Button("Keep going") { won = false }.buttonStyle(.bordered) }
                Button("New game", action: resetGame).buttonStyle(.borderedProminent)
            }
        }
        .padding(20)
        .frame(width: boardSize - 48)
        .background(Color(red: 0.97, green: 0.94, blue: 0.87))
        .cornerRadius(16)
        .shadow(radius: 8)
        .offset(x: 24, y: boardSize / 2 - 70)
    }

    // MARK: - Rules

    private func resetGame() {
        tiles = []
        score = 0
        spawnNumber = 0
        gameOver = false
        won = false
        spawn(from: nil)
        spawn(from: nil)
    }

    private func value(at row: Int, _ col: Int) -> Int {
        tiles.first { !$0.merging && $0.row == row && $0.col == col }?.value ?? 0
    }

    /// Slides and merges every line toward `direction`. Survivors move to
    /// their new cells (and double), merge losers move under them and are
    /// dropped once the slide has played; then a tile spawns from the far edge.
    /// The board after a move in `direction` (merges applied, losers marked
    /// `merging`), whether anything moved, the points gained, and the ids of
    /// the tiles that change cells — the drag preview uses the last one.
    private func plan(_ direction: Direction) -> (tiles: [Tile], moved: Bool, gained: Int, movingIDs: Set<Int>) {
        var updated = tiles.filter { !$0.merging }
        var moved = false
        var gained = 0
        var movingIDs = Set<Int>()
        for lineIndex in 0..<4 {
            // The tile ids along this line, nearest the destination edge first.
            var line: [Int] = []
            for position in 0..<4 {
                let (row, col): (Int, Int)
                switch direction {
                case .left: (row, col) = (lineIndex, position)
                case .right: (row, col) = (lineIndex, 3 - position)
                case .up: (row, col) = (position, lineIndex)
                case .down: (row, col) = (3 - position, lineIndex)
                }
                if let index = updated.firstIndex(where: { $0.row == row && $0.col == col }) {
                    line.append(index)
                }
            }
            var target = 0
            var index = 0
            while index < line.count {
                let current = line[index]
                let (row, col) = cell(direction, lineIndex, target)
                if index + 1 < line.count, updated[line[index + 1]].value == updated[current].value {
                    let partner = line[index + 1]
                    updated[current].value *= 2
                    gained += updated[current].value
                    updated[partner].merging = true
                    if updated[partner].row != row || updated[partner].col != col {
                        moved = true
                        movingIDs.insert(updated[partner].id)
                    }
                    updated[partner].row = row
                    updated[partner].col = col
                    index += 2
                } else {
                    index += 1
                }
                if updated[current].row != row || updated[current].col != col {
                    moved = true
                    movingIDs.insert(updated[current].id)
                }
                updated[current].row = row
                updated[current].col = col
                target += 1
            }
        }
        return (updated, moved, gained, movingIDs)
    }

    private func move(_ direction: Direction, tileSize: CGFloat) {
        guard !gameOver else { return }
        let (updated, moved, gained, _) = plan(direction)
        guard moved || gained > 0 else { return }
        tiles = updated
        score += gained
        if score > best { best = score }
        Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(180))
            tiles.removeAll { $0.merging }
        }
        spawn(from: direction)
        if tiles.contains(where: { $0.value >= 2048 }) && !won { won = true }
        if !canMove() { gameOver = true }
    }

    private func cell(_ direction: Direction, _ lineIndex: Int, _ position: Int) -> (Int, Int) {
        switch direction {
        case .left: return (lineIndex, position)
        case .right: return (lineIndex, 3 - position)
        case .up: return (position, lineIndex)
        case .down: return (3 - position, lineIndex)
        }
    }

    /// Adds a tile on a free cell. After a move it enters from the edge
    /// opposite the move (the side the tiles vacated) and slides into place.
    private func spawn(from direction: Direction?) {
        var free: [(Int, Int)] = []
        for row in 0..<4 {
            for col in 0..<4 where value(at: row, col) == 0 { free.append((row, col)) }
        }
        guard !free.isEmpty else { return }
        let picked = free[(spawnNumber * 7 + score) % free.count]
        let entering: Direction?
        switch direction {
        case .left: entering = .right
        case .right: entering = .left
        case .up: entering = .down
        case .down: entering = .up
        case nil: entering = nil
        }
        let id = nextID
        nextID += 1
        tiles.append(Tile(id: id, row: picked.0, col: picked.1,
                          value: spawnNumber % 7 == 6 ? 4 : 2, entering: entering))
        spawnNumber += 1
        if entering != nil {
            // Let the tile render off-edge once, then slide it in.
            Task { @MainActor in
                withAnimation(.easeOut(duration: 0.2)) {
                    if let index = tiles.firstIndex(where: { $0.id == id }) { tiles[index].entering = nil }
                }
            }
        }
    }

    private func canMove() -> Bool {
        for row in 0..<4 {
            for col in 0..<4 {
                let v = value(at: row, col)
                if v == 0 { return true }
                if row < 3 && value(at: row + 1, col) == v { return true }
                if col < 3 && value(at: row, col + 1) == v { return true }
            }
        }
        return false
    }
}

struct ScoreBox: View {
    let title: String
    let value: Int

    var body: some View {
        VStack(spacing: 2) {
            Text(title).font(.caption2.weight(.bold)).foregroundColor(Color(red: 0.93, green: 0.89, blue: 0.83))
            Text("\(value)").font(.title3.weight(.bold)).foregroundColor(.white)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
        .background(Color(red: 0.55, green: 0.49, blue: 0.42))
        .cornerRadius(10)
    }
}

struct TileFace: View {
    let value: Int
    let size: CGFloat
    var width: CGFloat? = nil
    var height: CGFloat? = nil

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 7).fill(tileColor)
            Text("\(value)")
                .font(.system(size: value < 128 ? 28 : (value < 1024 ? 23 : 18), weight: .black, design: .rounded))
                .foregroundColor(value <= 4 ? Color(red: 0.45, green: 0.38, blue: 0.31) : .white)
        }
        .frame(width: width ?? size, height: height ?? size)
    }

    private var tileColor: Color {
        switch value {
        case 2: return Color(red: 0.93, green: 0.89, blue: 0.82)
        case 4: return Color(red: 0.92, green: 0.84, blue: 0.70)
        case 8: return Color(red: 0.94, green: 0.68, blue: 0.45)
        case 16: return Color(red: 0.95, green: 0.57, blue: 0.37)
        case 32: return Color(red: 0.94, green: 0.45, blue: 0.34)
        case 64: return Color(red: 0.91, green: 0.34, blue: 0.27)
        case 128: return Color(red: 0.93, green: 0.76, blue: 0.35)
        case 256: return Color(red: 0.91, green: 0.70, blue: 0.25)
        case 512: return Color(red: 0.88, green: 0.63, blue: 0.18)
        case 1024: return Color(red: 0.78, green: 0.50, blue: 0.14)
        default: return Color(red: 0.55, green: 0.35, blue: 0.16)
        }
    }
}

// The Pokédex mini-app: a list/search interface over https://pokeapi.co
// (URLSession), a detail page per Pokémon, and a "caught" record persisted to
// the app's files (FileManager). All of it is platform-agnostic: the same
// Foundation calls on every platform.


// MARK: - Models

struct PokemonRef: Identifiable, Hashable {
    let id: Int
    let name: String

    /// Small sprite for list rows.
    var sprite: String {
        "https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/\(id).png"
    }

    /// High-resolution artwork for the detail page.
    var artwork: String {
        "https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/other/official-artwork/\(id).png"
    }
}

// MARK: - Persisted "caught" record (shared business logic)

/// Records which game versions each Pokémon has been caught in, persisted as a
/// JSON file in Application Support (`SandboxFiles`, over FileManager).
@Observable final class PokedexStore {
    private(set) var caught: [Int: Set<String>] = [:]
    init() {
        load()
    }

    func isCaught(_ id: Int, game: String) -> Bool {
        caught[id]?.contains(game) ?? false
    }

    func gameCount(_ id: Int) -> Int {
        caught[id]?.count ?? 0
    }

    var totalCaught: Int { caught.count }

    func toggle(_ id: Int, game: String) {
        var games = caught[id] ?? []
        if games.contains(game) {
            games.remove(game)
        } else {
            games.insert(game)
        }
        caught[id] = games.isEmpty ? nil : games
        save()
    }

    private func load() {
        guard let text = SandboxFiles.read("pokedex.json"),
              let object = parseJSON(text)?.object else { return }
        var result: [Int: Set<String>] = [:]
        for (key, value) in object {
            guard let id = Int(key), let array = value.array else { continue }
            result[id] = Set(array.compactMap { $0.string })
        }
        caught = result
    }

    private func save() {
        var object: [String: JSONValue] = [:]
        for (id, games) in caught {
            object["\(id)"] = .array(games.sorted().map { .string($0) })
        }
        SandboxFiles.write("pokedex.json", JSONValue.object(object).encoded())
    }
}

// MARK: - List + search

@Observable final class PokemonListModel {
    private(set) var all: [PokemonRef] = []
    private(set) var loading = false
    private var requested = false

    func loadIfNeeded() {
        guard !requested else { return }
        requested = true
        loading = true
        Networking.fetch("https://pokeapi.co/api/v2/pokemon?limit=1025") { [weak self] text in
            guard let self else { return }
            self.loading = false
            guard let text, let results = parseJSON(text)?["results"].array else { return }
            self.all = results.compactMap { entry in
                guard let name = entry["name"].string,
                      let url = entry["url"].string,
                      let id = pokemonID(fromURL: url) else { return nil }
                return PokemonRef(id: id, name: name)
            }
        }
    }

    /// Case-insensitive prefix/substring filter, capped so the list stays light.
    func filter(_ query: String) -> [PokemonRef] {
        let trimmed = query.lowercased()
        let matches = trimmed.isEmpty ? all : all.filter { $0.name.contains(trimmed) }
        return Array(matches.prefix(40))
    }
}

/// Pokédex list screen, designed to drop into a shared NavigationStack (the
/// Apps tab) so it pushes detail onto the same stack.
struct PokedexScreen: View {
    @State private var model = PokemonListModel()
    @State private var query = ""

    var body: some View {
        content
            .searchable(text: $query, prompt: "Search Pokémon")
            .navigationTitle("Pokédex")
            .onAppear { model.loadIfNeeded() }
    }

    @ViewBuilder
    private var content: some View {
        if model.all.isEmpty && model.loading {
            VStack(spacing: 12) {
                ProgressView()
                Text("Loading Pokédex…").font(.subheadline).foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity).padding(.top, 80)
        } else {
            List {
                ForEach(model.filter(query)) { pokemon in
                    NavigationLink {
                        PokemonDetailView(pokemon: pokemon)
                    } label: {
                        PokemonRow(pokemon: pokemon)
                    }
                }
            }
        }
    }
}

struct PokemonRow: View {
    let pokemon: PokemonRef
    @Environment(PokedexStore.self) private var pokedex

    var body: some View {
        HStack(spacing: 12) {
            AsyncImage(url: URL(string: pokemon.sprite)) { image in
                image.resizable().scaledToFit()
            } placeholder: {
                Color(white: 0, opacity: 0.05)
            }
            .frame(width: 56, height: 56)

            VStack(alignment: .leading, spacing: 2) {
                Text(capitalizeName(pokemon.name))
                    .font(.headline).foregroundColor(.primary).lineLimit(1)
                Text("#\(String(format3(pokemon.id)))")
                    .font(.subheadline).foregroundColor(.secondary)
            }
            Spacer(minLength: 0)
            if pokedex.gameCount(pokemon.id) > 0 {
                Text("✓ \(pokedex.gameCount(pokemon.id))")
                    .font(.footnote)
                    .foregroundColor(.white)
                    .padding(.horizontal, 8).padding(.vertical, 3)
                    .background(Color.green)
                    .cornerRadius(8)
            }
        }
        .padding(.vertical, 10)
    }
}

// MARK: - Detail

@Observable final class PokemonDetailModel {
    var loading = false
    var types: [String] = []
    var games: [String] = []
    var heightM = 0.0
    var weightKg = 0.0
    private var loadedID: Int?

    func load(id: Int) {
        guard loadedID != id else { return }
        loadedID = id
        loading = true
        Networking.fetch("https://pokeapi.co/api/v2/pokemon/\(id)") { [weak self] text in
            guard let self else { return }
            self.loading = false
            guard let text, let json = parseJSON(text) else { return }
            self.types = (json["types"].array ?? []).compactMap { $0["type"]["name"].string }
            self.heightM = (json["height"].double ?? 0) / 10
            self.weightKg = (json["weight"].double ?? 0) / 10
            var seen = Set<String>()
            var games: [String] = []
            for entry in json["game_indices"].array ?? [] {
                guard let version = entry["version"]["name"].string, !seen.contains(version) else { continue }
                seen.insert(version)
                games.append(version)
            }
            self.games = games
        }
    }
}

struct PokemonDetailView: View {
    let pokemon: PokemonRef
    @State private var model = PokemonDetailModel()
    @Environment(PokedexStore.self) private var pokedex

    var body: some View {
        List {
            // Hero section: artwork, name, types, and size, as one grouped block.
            Section {
                VStack(alignment: .leading, spacing: 16) {
                    AsyncImage(url: URL(string: pokemon.artwork)) { image in
                        image.resizable().scaledToFit()
                    } placeholder: {
                        Color(white: 0, opacity: 0.04)
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 220)
                    .background(Color(white: 0, opacity: 0.04))
                    .cornerRadius(16)

                    HStack(alignment: .firstTextBaseline, spacing: 8) {
                        Text(capitalizeName(pokemon.name)).font(.title).bold()
                        Text("#\(String(format3(pokemon.id)))").font(.title3).foregroundColor(.secondary)
                    }

                    if !model.types.isEmpty {
                        HStack(spacing: 8) {
                            ForEach(model.types, id: \.self) { type in
                                Text(capitalizeName(type))
                                    .font(.subheadline).foregroundColor(.white)
                                    .padding(.horizontal, 12).padding(.vertical, 5)
                                    .background(typeColor(type))
                                    .cornerRadius(12)
                            }
                        }
                    }

                    if model.heightM > 0 || model.weightKg > 0 {
                        HStack(spacing: 28) {
                            stat("Height", "\(model.heightM) m")
                            stat("Weight", "\(model.weightKg) kg")
                        }
                    }
                }
                .padding(.vertical, 6)
            }

            // "Caught in" — a proper list section, one selectable row per game.
            Section("Caught in \(pokedex.gameCount(pokemon.id)) game\(pokedex.gameCount(pokemon.id) == 1 ? "" : "s")") {
                if model.loading && model.games.isEmpty {
                    HStack(spacing: 10) {
                        ProgressView()
                        Text("Loading games…").font(.subheadline).foregroundColor(.secondary)
                    }
                } else if model.games.isEmpty {
                    Text("No game appearances found.")
                        .font(.subheadline).foregroundColor(.secondary)
                } else {
                    ForEach(model.games, id: \.self) { game in
                        GameRow(game: game, pokemonID: pokemon.id)
                    }
                }
            }
        }
        .navigationTitle(capitalizeName(pokemon.name))
        .onAppear { model.load(id: pokemon.id) }
    }

    private func stat(_ label: String, _ value: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label).font(.caption).foregroundColor(.secondary)
            Text(value).font(.headline)
        }
    }
}

struct GameRow: View {
    let game: String
    let pokemonID: Int
    @Environment(PokedexStore.self) private var pokedex

    var body: some View {
        let caught = pokedex.isCaught(pokemonID, game: game)
        Button {
            pokedex.toggle(pokemonID, game: game)
        } label: {
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(caught ? Color.green : Color(white: 0, opacity: 0.12))
                        .frame(width: 24, height: 24)
                    if caught {
                        Text("✓").font(.footnote).foregroundColor(.white)
                    }
                }
                Text(prettyGame(game)).foregroundColor(.primary)
                Spacer(minLength: 0)
            }
        }
    }
}

// MARK: - Helpers

func pokemonID(fromURL url: String) -> Int? {
    url.split(separator: "/").filter { !$0.isEmpty }.last.flatMap { Int($0) }
}

func capitalizeName(_ name: String) -> String {
    name.split(separator: "-").map { part -> String in
        guard let first = part.first else { return "" }
        return String(first).uppercased() + part.dropFirst()
    }.joined(separator: " ")
}

func prettyGame(_ game: String) -> String {
    capitalizeName(game)
}

/// Zero-pads a Pokédex number to three digits without Foundation formatting.
func format3(_ id: Int) -> String {
    let s = String(id)
    return String(repeating: "0", count: max(0, 3 - s.count)) + s
}

func typeColor(_ type: String) -> Color {
    switch type {
    case "fire": return .orange
    case "water": return .blue
    case "grass": return .green
    case "electric": return .yellow
    case "psychic": return .pink
    case "ice": return .teal
    case "dragon": return .purple
    case "dark": return Color(white: 0.25)
    case "fairy": return .pink
    case "poison": return .purple
    case "ground", "rock": return .brown
    case "fighting": return .red
    default: return Color(white: 0.45)
    }
}

// URL helpers shared by the example screens (and their Playground templates).

/// Percent-encodes a query for a URL without Foundation (so it compiles on the
/// wasm / Android reimplementation, which doesn't link Foundation).
func percentEncoded(_ text: String) -> String {
    let unreserved = Set("ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-_.~")
    var result = ""
    for scalar in text.unicodeScalars {
        let ch = Character(scalar)
        if unreserved.contains(ch) {
            result.append(ch)
        } else {
            for byte in String(scalar).utf8 {
                result += "%"
                result += hexByte(byte)
            }
        }
    }
    return result
}

private func hexByte(_ byte: UInt8) -> String {
    let digits = Array("0123456789ABCDEF")
    return String(digits[Int(byte >> 4)]) + String(digits[Int(byte & 0xF)])
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

