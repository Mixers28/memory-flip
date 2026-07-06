import SwiftUI

struct GameBoardView: View {
    @StateObject private var model: GameModel
    @Environment(\.dismiss) private var dismiss

    init(start: GameStart) {
        _model = StateObject(wrappedValue: GameModel(start: start))
    }

    var body: some View {
        ZStack {
            background
            VStack(spacing: 0) {
                statsBar
                    .padding(.horizontal, 20)
                    .padding(.top, 12)
                    .padding(.bottom, 16)
                switch model.phase {
                case .cards:       cardGrid
                case .pattern:     PatternBoardView(model: model)
                case .gridFlash:   GridFlashBoardView(model: model)
                case .numberOrder: NumberOrderBoardView(model: model)
                case .oddOneOut:   OddOneOutBoardView(model: model)
                case .stroop:      ColourStroopBoardView(model: model)
                }
            }

            if model.isLevelWon && !model.isRunOver {
                LevelClearOverlay(model: model) {
                    model.advanceLevel()
                }
                .transition(.opacity.combined(with: .scale(scale: 0.94)))
            }

            if model.isSegmentCleared && !model.isRunOver {
                HandoffOverlay(model: model) {
                    model.advanceMarathon()
                }
                .transition(.opacity.combined(with: .scale(scale: 0.94)))
            }

            if model.isMarathonIntro {
                MarathonIntroOverlay(model: model) {
                    model.dismissMarathonIntro()
                }
                .transition(.opacity.combined(with: .scale(scale: 0.94)))
            }

            if model.isRunOver {
                RunOverOverlay(model: model, onRestart: { model.startRun() }, onMenu: { dismiss() })
                    .transition(.opacity.combined(with: .scale(scale: 0.94)))
            }
        }
        .animation(.easeInOut(duration: 0.35), value: model.isLevelWon)
        .animation(.easeInOut(duration: 0.35), value: model.isSegmentCleared)
        .animation(.easeInOut(duration: 0.35), value: model.isMarathonIntro)
        .animation(.easeInOut(duration: 0.35), value: model.isRunOver)
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
                Button { model.startRun() } label: {
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
        VStack(spacing: 10) {
            if model.isMarathon {
                Label("\(model.phase.title)", systemImage: model.phase.icon)
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(.white.opacity(0.85))
                    .padding(.horizontal, 14)
                    .padding(.vertical, 5)
                    .background(.white.opacity(0.10))
                    .clipShape(Capsule())
            }
            HStack(spacing: 10) {
                if model.isMarathon {
                    StatPill(icon: "flag.checkered", label: "Lap", value: "\(model.lap)")
                } else {
                    StatPill(icon: "list.number", label: "Level", value: "\(model.level)")
                }
                Spacer()
                StatPill(icon: "star.fill", label: "Score", value: "\(model.score)")
                Spacer()
                switch model.phase {
                case .cards:
                    StatPill(icon: "hand.tap", label: "Moves", value: "\(model.moves)")
                case .pattern:
                    StatPill(icon: "waveform.path", label: "Length", value: "\(model.patternSequence.count)")
                case .gridFlash:
                    StatPill(icon: "circle.grid.3x3.fill", label: "Find", value: "\(model.flashSelected.count)/\(model.flashLitCells.count)")
                case .numberOrder:
                    StatPill(icon: "textformat.123", label: "Next", value: "\(min(model.numberNextExpected, model.numberCount))/\(model.numberCount)")
                case .oddOneOut:
                    StatPill(icon: "eye.fill", label: "Grid", value: "\(model.oddCols)×\(model.oddRows)")
                case .stroop:
                    StatPill(icon: "paintpalette.fill", label: "Colours", value: "\(model.stroopOptions.count)")
                }
            }
        }
    }

    private var cardGrid: some View {
        GeometryReader { geo in
            let cols = model.config.cols
            let rows = model.config.rows
            let hPad: CGFloat = 14
            let hGap: CGFloat = 8
            let vGap: CGFloat = 8
            let cardW = (geo.size.width - 2 * hPad - CGFloat(cols - 1) * hGap) / CGFloat(cols)
            let cardH = (geo.size.height - CGFloat(rows - 1) * vGap) / CGFloat(rows)
            let gridCols = Array(repeating: GridItem(.fixed(cardW), spacing: hGap), count: cols)

            LazyVGrid(columns: gridCols, spacing: vGap) {
                ForEach(model.cards.indices, id: \.self) { index in
                    CardView(card: model.cards[index])
                        .frame(width: cardW, height: cardH)
                        .onTapGesture { model.flipCard(at: index) }
                }
            }
            .padding(.horizontal, hPad)
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

