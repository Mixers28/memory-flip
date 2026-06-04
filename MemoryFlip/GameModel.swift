import Foundation
import Combine

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
    // Run state
    @Published var lives = 3
    @Published var level = 1
    @Published var score = 0
    @Published var isLevelWon = false
    @Published var isRunOver = false
    @Published var isNewHighScore = false

    // Level stats (shown in overlays)
    @Published var lastLevelBase = 0
    @Published var lastLevelTimeBonus = 0
    @Published var lastLevelEfficiencyBonus = 0
    @Published var lastLevelWasPerfect = false

    // Lives activate at this level (grids get large enough to matter)
    let livesActiveFromLevel = 5
    var livesActive: Bool { level >= livesActiveFromLevel }

    // Board state
    @Published var cards: [Card] = []
    @Published var moves = 0
    @Published var matchedPairs = 0
    @Published var timeElapsed = 0

    private var wrongFlipsThisLevel = 0
    private var firstFlippedIndex: Int?
    private var isChecking = false
    private var timerCancellable: AnyCancellable?

    // Persisted records (read/write directly, HomeView reads via @AppStorage)
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

    // Grid grows with each level; caps at 6×6 from level 9 onward
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

    init() { startRun() }

    func startRun() {
        lives = 3
        level = 1
        score = 0
        isLevelWon = false
        isRunOver = false
        isNewHighScore = false
        lastLevelBase = 0
        lastLevelTimeBonus = 0
        lastLevelEfficiencyBonus = 0
        lastLevelWasPerfect = false
        startLevel()
    }

    func startLevel() {
        let cfg = config
        let selected = Array(allEmojis.shuffled().prefix(cfg.pairs))
        let doubled = (selected + selected).shuffled()
        cards = doubled.enumerated().map { Card(id: $0.offset, emoji: $0.element) }
        moves = 0
        matchedPairs = 0
        timeElapsed = 0
        wrongFlipsThisLevel = 0
        firstFlippedIndex = nil
        isChecking = false
        isLevelWon = false
        startTimer()
    }

    func advanceLevel() {
        level += 1
        startLevel()
    }

    func flipCard(at index: Int) {
        guard !isChecking,
              !isLevelWon,
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
                    completeLevel()
                }
            } else {
                wrongFlipsThisLevel += 1
                let a = firstIdx, b = index
                DispatchQueue.main.asyncAfter(deadline: .now() + peekDuration) { [weak self] in
                    guard let self else { return }
                    self.cards[a].isFlipped = false
                    self.cards[b].isFlipped = false
                    self.isChecking = false
                    if self.livesActive {
                        self.lives -= 1
                        if self.lives <= 0 { self.endRun() }
                    }
                }
            }
        } else {
            firstFlippedIndex = index
        }
    }

    private func completeLevel() {
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

        if level > bestLevel { bestLevel = level }
        isLevelWon = true
    }

    private func endRun() {
        stopTimer()
        if level > bestLevel { bestLevel = level }
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
