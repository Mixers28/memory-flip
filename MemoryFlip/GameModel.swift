import Foundation
import Combine

enum GamePhase: Hashable {
    case cards        // classic match-the-pairs
    case pattern      // Simon-style colour sequence
    case gridFlash    // spatial recall — memorise the lit cells
    case numberOrder  // chimp test — tap the numbers in order from memory
    case oddOneOut    // spot the one tile that differs, against the clock
    case stroop       // tap the ink colour of a colour-word, against the clock

    var title: String {
        switch self {
        case .cards:       return "Card Match"
        case .pattern:     return "Colour Patterns"
        case .gridFlash:   return "Grid Flash"
        case .numberOrder: return "Number Order"
        case .oddOneOut:   return "Odd One Out"
        case .stroop:      return "Colour Stroop"
        }
    }

    var icon: String {
        switch self {
        case .cards:       return "square.grid.2x2.fill"
        case .pattern:     return "waveform.path"
        case .gridFlash:   return "circle.grid.3x3.fill"
        case .numberOrder: return "textformat.123"
        case .oddOneOut:   return "eye.fill"
        case .stroop:      return "paintpalette.fill"
        }
    }

    // Modes that end the run on a wrong move (vs. modes you simply keep clearing).
    var canFailRun: Bool {
        switch self {
        case .cards:                                                    return false
        case .pattern, .gridFlash, .numberOrder, .oddOneOut, .stroop:   return true
        }
    }
}

// How a run is launched from the menu.
enum GameStart: Hashable {
    case practice(GamePhase)   // one mode, endless
    case marathon              // rotate through every mode, score carrying
}

struct LevelConfig {
    let cols: Int
    let rows: Int
    var pairs: Int { cols * rows / 2 }
    var totalCards: Int { cols * rows }
}

struct Card: Identifiable {
    let id: Int
    let emoji: String
    var isFlipped = false
    var isMatched = false
}

class GameModel: ObservableObject {
    // Screenshot/demo hook: when SCREENSHOT_MODE=1 is set in the environment, transient
    // states are frozen (reveals stay shown, timers don't tick) so captures are stable.
    static let screenshotMode = ProcessInfo.processInfo.environment["SCREENSHOT_MODE"] == "1"

    // Run configuration
    let isMarathon: Bool
    let marathonOrder: [GamePhase] = [.cards, .pattern, .gridFlash, .numberOrder, .oddOneOut, .stroop]

    // Run state
    @Published var phase: GamePhase = .cards
    @Published var score = 0
    @Published var lap = 1
    @Published var isLevelWon = false       // practice: a single level cleared (cards)
    @Published var isSegmentCleared = false // marathon: a mode segment cleared, handoff pending
    @Published var isRunOver = false
    @Published var isNewHighScore = false

    // Difficulty is per-mode and persists across marathon hand-offs so it always climbs.
    @Published private var modeLevel: [GamePhase: Int] = [:]
    var level: Int { modeLevel[phase, default: 1] }

    @Published private var currentModeIndex = 0
    private var segmentRoundsCleared = 0

    // Cumulative stages cleared this run — drives the "Best Level" record.
    @Published var stage = 0

    // Level stats (shown in overlays)
    @Published var lastLevelBase = 0
    @Published var lastLevelTimeBonus = 0
    @Published var lastLevelEfficiencyBonus = 0
    @Published var lastLevelWasPerfect = false

    // Card-board state
    @Published var cards: [Card] = []
    @Published var moves = 0
    @Published var matchedPairs = 0
    @Published var timeElapsed = 0

    // Pattern (Simon) state
    @Published var patternSequence: [Int] = []   // tile indices the player must repeat
    @Published var patternInputCount = 0          // correct taps so far this round
    @Published var litTile: Int? = nil            // tile currently highlighted (playback or tap feedback)
    @Published var isPlayingBack = false          // true while the sequence is being shown — input locked
    let patternTileCount = 4

    // Grid Flash (spatial recall) state
    @Published var flashCols = 3
    @Published var flashRows = 3
    @Published var flashLitCells: Set<Int> = []   // the cells the player must remember (solution)
    @Published var flashSelected: Set<Int> = []   // correct cells tapped so far
    @Published var flashRevealed = false          // true while the pattern is shown — input locked

    // Number Order (chimp test) state
    @Published var numberCols = 4
    @Published var numberRows = 4
    @Published var numberAtCell: [Int: Int] = [:]   // cell index -> number (1...count) — the solution
    @Published var numberSolved: Set<Int> = []      // cells already tapped correctly
    @Published var numberNextExpected = 1           // the next number to tap
    @Published var numbersHidden = false            // numbers blank out after the first tap
    var numberCount: Int { numberAtCell.count }

    // Odd One Out state
    @Published var oddCols = 3
    @Published var oddRows = 3
    @Published var oddIndex = 0                      // the cell that differs (solution)
    @Published var oddBaseEmoji = "🙂"
    @Published var oddDifferentEmoji = "🙃"
    @Published var oddRoundStart = Date()
    private var oddSolved = false

    // Colour Stroop state
    @Published var stroopOptions: [Int] = []   // palette indices shown as tappable swatches
    @Published var stroopInkIndex = 0          // the colour the word is printed in (correct answer)
    @Published var stroopWordIndex = 0         // the colour name the word spells (the distractor)
    @Published var stroopRoundStart = Date()
    private var stroopSolved = false

    private var wrongFlipsThisLevel = 0
    private var firstFlippedIndex: Int?
    private var isChecking = false
    private var timerCancellable: AnyCancellable?
    // Invalidates stale async closures (playback, auto-advance) when the level/run is reset.
    private var transitionGeneration = 0

    // Persisted records
    var highScore: Int {
        get { UserDefaults.standard.integer(forKey: "highScore") }
        set { UserDefaults.standard.set(newValue, forKey: "highScore") }
    }
    var bestLevel: Int {
        get { UserDefaults.standard.integer(forKey: "bestLevel") }
        set { UserDefaults.standard.set(newValue, forKey: "bestLevel") }
    }

    private let allEmojis = [
        "🐶","🐱","🐭","🐹","🐰","🦊","🐻","🐼","🐨","🐯","🦁","🐸",
        "🦋","🐝","🦄","🦖","🦩","🦚","🦜","🐙","🦞","🦀","🦑","🐠",
        "🍎","🍊","🍋","🍇","🍓","🍒","🥝","🌈"
    ]

    // MARK: - Marathon shape

    // Rounds you must clear in a mode before it hands off (marathon only).
    private func segmentTarget(for mode: GamePhase) -> Int {
        switch mode {
        case .cards:       return 3
        case .pattern:     return 4
        case .gridFlash:   return 4
        case .numberOrder: return 4
        case .oddOneOut:   return 5
        case .stroop:      return 5
        }
    }

    var nextMarathonMode: GamePhase {
        marathonOrder[(currentModeIndex + 1) % marathonOrder.count]
    }
    var willCompleteLapNext: Bool {
        currentModeIndex + 1 >= marathonOrder.count
    }

    // MARK: - Difficulty curves

    // Grid grows with each card level; caps at 6×6 from level 9 onward
    static func config(for level: Int) -> LevelConfig {
        switch level {
        case 1:  return LevelConfig(cols: 2, rows: 2)   // 4 cards  / 2 pairs
        case 2:  return LevelConfig(cols: 2, rows: 3)   // 6 cards  / 3 pairs
        case 3:  return LevelConfig(cols: 2, rows: 4)   // 8 cards  / 4 pairs
        case 4:  return LevelConfig(cols: 3, rows: 4)   // 12 cards / 6 pairs
        case 5:  return LevelConfig(cols: 4, rows: 4)   // 16 cards / 8 pairs
        case 6:  return LevelConfig(cols: 4, rows: 5)   // 20 cards / 10 pairs
        case 7:  return LevelConfig(cols: 4, rows: 6)   // 24 cards / 12 pairs
        case 8:  return LevelConfig(cols: 5, rows: 6)   // 30 cards / 15 pairs
        default: return LevelConfig(cols: 6, rows: 6)   // 36 cards / 18 pairs
        }
    }

    var config: LevelConfig { GameModel.config(for: level) }

    // After level 9 the peek window shrinks, making wrong flips harder to memorise
    var peekDuration: Double {
        max(0.35, 0.9 - Double(max(0, level - 9)) * 0.1)
    }

    // Playback flash speed in the pattern game — quickens as the sequence lengthens
    var patternFlashDuration: Double {
        max(0.26, 0.6 - Double(level) * 0.03)
    }

    // Grid Flash: grid grows in steps; lit-cell count climbs with the level.
    struct FlashConfig { let cols: Int; let rows: Int; let litCount: Int }
    static func flashConfig(for level: Int) -> FlashConfig {
        let side = level <= 4 ? 3 : (level <= 9 ? 4 : 5)
        let total = side * side
        let lit = min(2 + level, total - 2)   // always leave a couple of empties
        return FlashConfig(cols: side, rows: side, litCount: lit)
    }
    var flashConfig: FlashConfig { GameModel.flashConfig(for: level) }

    // How long the lit cells stay visible before the player must reproduce them.
    var flashRevealDuration: Double {
        max(0.7, 1.5 - Double(level) * 0.05)
    }

    // Number Order: count of numbers climbs with the level; grid is sized to hold them with spares.
    static func numberConfig(for level: Int) -> (cols: Int, rows: Int, count: Int) {
        let side = level <= 5 ? 4 : 5
        let count = min(3 + level, side * side - 2)
        return (side, side, count)
    }

    // Odd One Out: grid grows and the clock tightens with the level.
    static func oddSide(for level: Int) -> Int {
        level <= 3 ? 3 : (level <= 8 ? 4 : 5)
    }
    var oddRoundDuration: Double {
        max(1.3, 3.4 - Double(level) * 0.12)
    }

    // Colour Stroop palette (UI-agnostic: name + RGB so the model stays SwiftUI-free).
    struct StroopColor: Equatable { let name: String; let r: Double; let g: Double; let b: Double }
    static let stroopPalette: [StroopColor] = [
        .init(name: "RED",    r: 0.95, g: 0.23, b: 0.27),
        .init(name: "BLUE",   r: 0.25, g: 0.55, b: 1.00),
        .init(name: "GREEN",  r: 0.20, g: 0.85, b: 0.45),
        .init(name: "YELLOW", r: 1.00, g: 0.85, b: 0.25),
        .init(name: "ORANGE", r: 1.00, g: 0.55, b: 0.15),
        .init(name: "PURPLE", r: 0.70, g: 0.40, b: 1.00)
    ]
    var stroopRoundDuration: Double {
        max(1.3, 3.6 - Double(level) * 0.12)
    }

    // MARK: - Lifecycle

    init(start: GameStart = .practice(.cards)) {
        switch start {
        case .practice(let mode):
            isMarathon = false
            phase = mode
        case .marathon:
            isMarathon = true
            phase = marathonOrder[0]
        }
        startRun()
    }

    func startRun() {
        modeLevel = [:]
        currentModeIndex = 0
        segmentRoundsCleared = 0
        lap = 1
        stage = 0
        score = 0
        isLevelWon = false
        isSegmentCleared = false
        isRunOver = false
        isNewHighScore = false
        lastLevelBase = 0
        lastLevelTimeBonus = 0
        lastLevelEfficiencyBonus = 0
        lastLevelWasPerfect = false
        if isMarathon { phase = marathonOrder[0] }
        if GameModel.screenshotMode, phase == .cards { modeLevel[.cards] = 5 }   // 4×4 board for a fuller capture
        startLevel()
    }

    func startLevel() {
        transitionGeneration += 1   // cancel any in-flight playback / auto-advance
        isLevelWon = false
        timeElapsed = 0
        switch phase {
        case .cards:       startCardsLevel()
        case .pattern:     startPatternLevel()
        case .gridFlash:   startGridFlashLevel()
        case .numberOrder: startNumberOrderLevel()
        case .oddOneOut:   startOddOneOutLevel()
        case .stroop:      startStroopLevel()
        }
        startTimer()
    }

    // Practice "continue" button.
    func advanceLevel() {
        incrementLevel()
        startLevel()
    }

    // Marathon handoff "continue" button.
    func advanceMarathon() {
        currentModeIndex += 1
        if currentModeIndex >= marathonOrder.count {
            currentModeIndex = 0
            lap += 1
        }
        phase = marathonOrder[currentModeIndex]
        segmentRoundsCleared = 0
        isSegmentCleared = false
        startLevel()
    }

    private func incrementLevel() { modeLevel[phase, default: 1] += 1 }

    // The single seam every mode's round-completion routes through.
    private func roundCleared() {
        registerStageCleared()
        if isMarathon {
            segmentRoundsCleared += 1
            if segmentRoundsCleared >= segmentTarget(for: phase) {
                stopTimer()
                isSegmentCleared = true   // GameBoardView shows the handoff overlay
                return
            }
        }
        continueCurrentMode()
    }

    private func continueCurrentMode() {
        switch phase {
        case .cards:
            if isMarathon {
                // Mid-segment: no modal — briefly hold the cleared board, then deal the next.
                incrementLevel()
                let gen = transitionGeneration
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.55) { [weak self] in
                    guard let self, gen == self.transitionGeneration else { return }
                    self.startLevel()
                }
            } else {
                isLevelWon = true   // practice: show the level-clear overlay
            }
        case .pattern:
            extendPatternAndReplay()
        case .gridFlash, .numberOrder, .oddOneOut, .stroop:
            // Briefly hold the solved board, then deal the next (harder) round.
            incrementLevel()
            let gen = transitionGeneration
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.55) { [weak self] in
                guard let self, gen == self.transitionGeneration else { return }
                self.startLevel()
            }
        }
    }

    // MARK: - Cards mode

    private func startCardsLevel() {
        let cfg = config
        let selected = Array(allEmojis.shuffled().prefix(cfg.pairs))
        let doubled = (selected + selected).shuffled()
        cards = doubled.enumerated().map { Card(id: $0.offset, emoji: $0.element) }
        moves = 0
        matchedPairs = 0
        wrongFlipsThisLevel = 0
        firstFlippedIndex = nil
        isChecking = false

        if GameModel.screenshotMode {
            // Showcase the board: reveal several cards and mark one matched pair (green).
            for i in 0..<min(5, cards.count) { cards[i].isFlipped = true }
            var byEmoji: [String: Int] = [:]
            for i in cards.indices {
                if let j = byEmoji[cards[i].emoji] {
                    cards[i].isFlipped = true;  cards[i].isMatched = true
                    cards[j].isFlipped = true;  cards[j].isMatched = true
                    break
                }
                byEmoji[cards[i].emoji] = i
            }
        }
    }

    func flipCard(at index: Int) {
        guard phase == .cards,
              !isChecking,
              !isLevelWon,
              !isSegmentCleared,
              !isRunOver,
              index < cards.count,
              !cards[index].isFlipped,
              !cards[index].isMatched else { return }

        cards[index].isFlipped = true

        if let firstIdx = firstFlippedIndex {
            moves += 1
            isChecking = true
            firstFlippedIndex = nil

            if cards[firstIdx].emoji == cards[index].emoji {
                cards[firstIdx].isMatched = true
                cards[index].isMatched = true
                matchedPairs += 1
                isChecking = false
                if matchedPairs == config.pairs {
                    completeCardsLevel()
                }
            } else {
                wrongFlipsThisLevel += 1
                let a = firstIdx, b = index
                DispatchQueue.main.asyncAfter(deadline: .now() + peekDuration) { [weak self] in
                    guard let self else { return }
                    self.cards[a].isFlipped = false
                    self.cards[b].isFlipped = false
                    self.isChecking = false
                }
            }
        } else {
            firstFlippedIndex = index
        }
    }

    private func completeCardsLevel() {
        stopTimer()

        let base = config.pairs * 100 * level
        let timeBonus = max(0, 60 - timeElapsed) * 10
        // Graduated bonus: each avoided mistake earns points, so fewer moves always scores higher
        let efficiencyBonus = max(0, config.pairs - wrongFlipsThisLevel) * level * 30

        lastLevelBase = base
        lastLevelTimeBonus = timeBonus
        lastLevelEfficiencyBonus = efficiencyBonus
        lastLevelWasPerfect = wrongFlipsThisLevel == 0
        score += base + timeBonus + efficiencyBonus

        roundCleared()
    }

    // MARK: - Pattern (Simon) mode

    private func startPatternLevel() {
        // Sequence length tracks the level, so re-entering at a higher marathon level is harder.
        patternSequence = (0..<level).map { _ in Int.random(in: 0..<patternTileCount) }
        patternInputCount = 0
        litTile = nil
        if GameModel.screenshotMode {
            litTile = patternSequence.first   // hold one tile lit for a clean capture
        } else {
            playBackSequence()
        }
    }

    func tapTile(_ index: Int) {
        guard phase == .pattern,
              !isPlayingBack,
              !isLevelWon,
              !isSegmentCleared,
              !isRunOver,
              patternInputCount < patternSequence.count else { return }

        flashTile(index)

        if index == patternSequence[patternInputCount] {
            patternInputCount += 1
            if patternInputCount == patternSequence.count {
                completePatternRound()
            }
        } else {
            endRun()
        }
    }

    private func completePatternRound() {
        // Each correct sequence banks points immediately, so the score visibly climbs.
        score += level * 60
        roundCleared()
    }

    private func extendPatternAndReplay() {
        incrementLevel()
        patternInputCount = 0
        patternSequence.append(Int.random(in: 0..<patternTileCount))
        // Lock input during the brief pause before the longer sequence plays,
        // otherwise a tap would be checked against the not-yet-shown pattern.
        isPlayingBack = true
        let gen = transitionGeneration
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.7) { [weak self] in
            guard let self, gen == self.transitionGeneration else { return }
            self.playBackSequence()
        }
    }

    private func flashTile(_ index: Int) {
        let gen = transitionGeneration
        litTile = index
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.18) { [weak self] in
            guard let self, gen == self.transitionGeneration else { return }
            if self.litTile == index { self.litTile = nil }
        }
    }

    private func playBackSequence() {
        transitionGeneration += 1
        let gen = transitionGeneration
        isPlayingBack = true
        patternInputCount = 0

        let flashOn = patternFlashDuration
        let gap = flashOn * 0.55
        var t = 0.45
        for tile in patternSequence {
            let onAt = t
            DispatchQueue.main.asyncAfter(deadline: .now() + onAt) { [weak self] in
                guard let self, gen == self.transitionGeneration else { return }
                self.litTile = tile
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + onAt + flashOn) { [weak self] in
                guard let self, gen == self.transitionGeneration else { return }
                if self.litTile == tile { self.litTile = nil }
            }
            t += flashOn + gap
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + t) { [weak self] in
            guard let self, gen == self.transitionGeneration else { return }
            self.isPlayingBack = false
        }
    }

    // MARK: - Grid Flash mode

    private func startGridFlashLevel() {
        let cfg = flashConfig
        flashCols = cfg.cols
        flashRows = cfg.rows
        flashLitCells = Set((0..<(cfg.cols * cfg.rows)).shuffled().prefix(cfg.litCount))
        flashSelected = []
        flashRevealed = true   // show the pattern; input locked until it hides

        if GameModel.screenshotMode { return }   // keep the lit cells visible for the capture
        let gen = transitionGeneration
        DispatchQueue.main.asyncAfter(deadline: .now() + flashRevealDuration) { [weak self] in
            guard let self, gen == self.transitionGeneration else { return }
            self.flashRevealed = false
        }
    }

    func tapFlashCell(_ index: Int) {
        guard phase == .gridFlash,
              !flashRevealed,
              !isSegmentCleared,
              !isRunOver,
              !flashSelected.contains(index) else { return }

        if flashLitCells.contains(index) {
            flashSelected.insert(index)
            if flashSelected == flashLitCells {
                completeGridFlashRound()
            }
        } else {
            endRun()
        }
    }

    private func completeGridFlashRound() {
        score += flashLitCells.count * level * 25
        roundCleared()
    }

    // MARK: - Number Order mode

    private func startNumberOrderLevel() {
        let cfg = GameModel.numberConfig(for: level)
        numberCols = cfg.cols
        numberRows = cfg.rows
        let cells = Array(0..<(cfg.cols * cfg.rows)).shuffled().prefix(cfg.count)
        var placed: [Int: Int] = [:]
        for (n, cell) in cells.enumerated() { placed[cell] = n + 1 }
        numberAtCell = placed
        numberSolved = []
        numberNextExpected = 1
        numbersHidden = false   // numbers stay visible until the first correct tap
    }

    func tapNumberCell(_ index: Int) {
        guard phase == .numberOrder,
              !isSegmentCleared,
              !isRunOver,
              !numberSolved.contains(index) else { return }

        guard let num = numberAtCell[index] else { endRun(); return }   // tapped an empty cell

        if num == numberNextExpected {
            if numberNextExpected == 1 { numbersHidden = true }   // hide the rest after the first tap
            numberSolved.insert(index)
            numberNextExpected += 1
            if numberNextExpected > numberCount {
                completeNumberOrderRound()
            }
        } else {
            endRun()
        }
    }

    private func completeNumberOrderRound() {
        score += numberCount * level * 20
        roundCleared()
    }

    // MARK: - Odd One Out mode

    private func startOddOneOutLevel() {
        let side = GameModel.oddSide(for: level)
        oddCols = side
        oddRows = side
        oddIndex = Int.random(in: 0..<(side * side))
        let pair = allEmojis.shuffled().prefix(2)
        oddBaseEmoji = pair[0]
        oddDifferentEmoji = pair[1]
        oddSolved = false
        oddRoundStart = Date()

        if GameModel.screenshotMode { return }   // no countdown timeout during captures
        // Miss the clock and the run is over.
        let gen = transitionGeneration
        let duration = oddRoundDuration
        DispatchQueue.main.asyncAfter(deadline: .now() + duration) { [weak self] in
            guard let self, gen == self.transitionGeneration,
                  !self.oddSolved, !self.isRunOver, !self.isSegmentCleared else { return }
            self.endRun()
        }
    }

    func tapOddCell(_ index: Int) {
        guard phase == .oddOneOut,
              !oddSolved,
              !isSegmentCleared,
              !isRunOver else { return }

        if index == oddIndex {
            oddSolved = true
            completeOddRound()
        } else {
            endRun()
        }
    }

    private func completeOddRound() {
        let elapsed = Date().timeIntervalSince(oddRoundStart)
        let speedBonus = max(0, Int((oddRoundDuration - elapsed) * 40))
        score += level * 50 + speedBonus
        roundCleared()
    }

    // MARK: - Colour Stroop mode

    private func startStroopLevel() {
        let paletteCount = GameModel.stroopPalette.count
        let optionCount = min(3 + (level - 1), paletteCount)
        stroopOptions = Array(0..<paletteCount).shuffled().prefix(optionCount).shuffled()
        stroopInkIndex = stroopOptions.randomElement() ?? 0
        // The word spells a *different* colour than its ink (an incongruent Stroop).
        let distractors = stroopOptions.filter { $0 != stroopInkIndex }
        stroopWordIndex = distractors.randomElement() ?? ((stroopInkIndex + 1) % paletteCount)
        stroopSolved = false
        stroopRoundStart = Date()

        if GameModel.screenshotMode { return }   // no countdown timeout during captures
        let gen = transitionGeneration
        let duration = stroopRoundDuration
        DispatchQueue.main.asyncAfter(deadline: .now() + duration) { [weak self] in
            guard let self, gen == self.transitionGeneration,
                  !self.stroopSolved, !self.isRunOver, !self.isSegmentCleared else { return }
            self.endRun()
        }
    }

    func tapStroopOption(_ paletteIndex: Int) {
        guard phase == .stroop,
              !stroopSolved,
              !isSegmentCleared,
              !isRunOver else { return }

        if paletteIndex == stroopInkIndex {
            stroopSolved = true
            completeStroopRound()
        } else {
            endRun()
        }
    }

    private func completeStroopRound() {
        let elapsed = Date().timeIntervalSince(stroopRoundStart)
        let speedBonus = max(0, Int((stroopRoundDuration - elapsed) * 40))
        score += level * 60 + speedBonus
        roundCleared()
    }

    // MARK: - Records & run lifecycle

    private func registerStageCleared() {
        stage += 1
        if stage > bestLevel { bestLevel = stage }
    }

    private func endRun() {
        stopTimer()
        transitionGeneration += 1
        litTile = nil
        if score > highScore {
            highScore = score
            isNewHighScore = true
        }
        isRunOver = true
    }

    var formattedTime: String {
        String(format: "%02d:%02d", timeElapsed / 60, timeElapsed % 60)
    }

    private func startTimer() {
        stopTimer()
        timerCancellable = Timer.publish(every: 1, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in self?.timeElapsed += 1 }
    }

    private func stopTimer() {
        timerCancellable?.cancel()
        timerCancellable = nil
    }

    deinit { stopTimer() }
}
