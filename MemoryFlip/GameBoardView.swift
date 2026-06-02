import SwiftUI

struct GameBoardView: View {
    @StateObject private var model: GameModel
    @Environment(\.dismiss) private var dismiss

    init(difficulty: Difficulty) {
        _model = StateObject(wrappedValue: GameModel(difficulty: difficulty))
    }

    var body: some View {
        ZStack {
            background
            VStack(spacing: 0) {
                statsBar
                    .padding(.horizontal, 20)
                    .padding(.top, 12)
                    .padding(.bottom, 16)
                cardGrid
            }

            if model.isGameWon {
                WinOverlayView(model: model, onMenu: { dismiss() })
                    .transition(.opacity.combined(with: .scale(scale: 0.94)))
            }
        }
        .animation(.easeInOut(duration: 0.35), value: model.isGameWon)
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button { dismiss() } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "chevron.left")
                        Text("Menu")
                    }
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(.white)
                }
            }
            ToolbarItem(placement: .navigationBarTrailing) {
                Button { model.newGame() } label: {
                    Image(systemName: "arrow.clockwise")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(.white)
                }
            }
        }
        .toolbarBackground(.hidden, for: .navigationBar)
    }

    private var background: some View {
        LinearGradient(
            colors: [
                Color(red: 0.08, green: 0.04, blue: 0.22),
                Color(red: 0.18, green: 0.08, blue: 0.44)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()
    }

    private var statsBar: some View {
        HStack(spacing: 10) {
            StatPill(icon: "hand.tap", label: "Moves", value: "\(model.moves)")
            Spacer()
            StatPill(icon: "checkmark.circle", label: "Pairs", value: "\(model.matchedPairs)/\(model.difficulty.pairs)")
            Spacer()
            StatPill(icon: "clock", label: "Time", value: model.formattedTime)
        }
    }

    private var cardGrid: some View {
        GeometryReader { geo in
            let cols = model.difficulty.columns
            let rows = model.difficulty.rows
            let hPad: CGFloat = 14
            let hGap: CGFloat = 8
            let vGap: CGFloat = 8
            let cardW = (geo.size.width - 2 * hPad - CGFloat(cols - 1) * hGap) / CGFloat(cols)
            let cardH = (geo.size.height - CGFloat(rows - 1) * vGap) / CGFloat(rows)
            let size = min(cardW, cardH)

            let gridCols = Array(repeating: GridItem(.fixed(size), spacing: hGap), count: cols)

            ScrollView {
                LazyVGrid(columns: gridCols, spacing: vGap) {
                    ForEach(model.cards.indices, id: \.self) { index in
                        CardView(card: model.cards[index])
                            .frame(width: size, height: size)
                            .onTapGesture { model.flipCard(at: index) }
                    }
                }
                .padding(.horizontal, hPad)
            }
            .scrollDisabled(true)
        }
        .padding(.bottom, 10)
    }
}

struct StatPill: View {
    let icon: String
    let label: String
    let value: String

    var body: some View {
        VStack(spacing: 2) {
            Text(value)
                .font(.system(size: 19, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
            Text(label)
                .font(.system(size: 10, weight: .medium))
                .foregroundStyle(.white.opacity(0.55))
                .textCase(.uppercase)
                .tracking(0.8)
        }
        .frame(minWidth: 72)
        .padding(.vertical, 9)
        .padding(.horizontal, 14)
        .background(.white.opacity(0.09))
        .clipShape(RoundedRectangle(cornerRadius: 13))
    }
}
