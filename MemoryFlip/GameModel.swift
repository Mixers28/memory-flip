import Foundation
import Combine

enum Difficulty: String, CaseIterable, Hashable {
    case easy = "Easy"
    case medium = "Medium"
    case hard = "Hard"

    var columns: Int {
        switch self {
        case .easy: return 4
        case .medium: return 4
        case .hard: return 6
        }
    }

    var rows: Int {
        switch self {
        case .easy: return 4
        case .medium: return 6
        case .hard: return 6
        }
    }

    var pairs: Int { columns * rows / 2 }

    var gridLabel: String { "\(columns)×\(rows)" }
    var pairsLabel: String { "\(pairs) pairs" }

    var emoji: String {
        switch self {
        case .easy: return "🌱"
        case .medium: return "🔥"
        case .hard: return "💀"
        }
    }
}

struct Card: Identifiable {
    let id: Int
    let emoji: String
    var isFlipped = false
    var isMatched = false
}

class GameModel: ObservableObject {
    @Published var cards: [Card] = []
    @Published var moves = 0
    @Published var matchedPairs = 0
    @Published var timeElapsed = 0
    @Published var isGameWon = false

    let difficulty: Difficulty

    private var firstFlippedIndex: Int?
    private var isChecking = false
    private var timerCancellable: AnyCancellable?

    private let allEmojis = [
        "🐶","🐱","🐭","🐹","🐰","🦊","🐻","🐼","🐨","🐯","🦁","🐸",
        "🦋","🐝","🦄","🦖","🦩","🦚","🦜","🐙","🦞","🦀","🦑","🐠",
        "🍎","🍊","🍋","🍇","🍓","🍒","🥝","🌈"
    ]

    init(difficulty: Difficulty) {
        self.difficulty = difficulty
        newGame()
    }

    func newGame() {
        let selected = Array(allEmojis.shuffled().prefix(difficulty.pairs))
        let doubled = (selected + selected).shuffled()
        cards = doubled.enumerated().map { Card(id: $0.offset, emoji: $0.element) }
        moves = 0
        matchedPairs = 0
        timeElapsed = 0
        isGameWon = false
        firstFlippedIndex = nil
        isChecking = false
        startTimer()
    }

    func flipCard(at index: Int) {
        guard !isChecking,
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
                if matchedPairs == difficulty.pairs {
                    isGameWon = true
                    stopTimer()
                }
            } else {
                let a = firstIdx, b = index
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.9) { [weak self] in
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
